# Documento de Arquitetura: Motor de Renderização Offline (Render Show) e SetlistExportService

**Versão:** 1.0  
**Data:** 2025-02-27  
**Escopo:** Orquestração Dart (SetlistExportService), Smart Bypass, I/O, FFI e análise do C++ (audio_renderer / decoder).

---

## 1. Visão geral

O **Render Show** exporta um Setlist completo para arquivos de áudio pré-processados (EQ, Pitch, Tempo, Trim quando aplicável), permitindo reprodução em “live” sem DSP em tempo real. O C++ já expõe `engine_render_track_offline` e `engine_get_render_progress` em `audio_renderer.cpp`. Este documento define a arquitetura do **maestro em Dart**: o **SetlistExportService**, com foco em **performance**, **evitar OOM** e **UI responsiva**.

---

## 2. Orquestração sequencial (fila)

### 2.1 Regra de processamento

- **Uma track por vez:** o Dart deve iterar sobre o Setlist na ordem **Músicas → Tracks** e processar **estritamente uma track por vez**.
- **Sem paralelismo de tracks:** não disparar `engine_render_track_offline` para mais de uma track simultaneamente, para:
  - Limitar pico de memória (decoder C++ carrega o arquivo inteiro em RAM — ver seção 7).
  - Evitar contenção de I/O e CPU no dispositivo.

### 2.2 Fluxo de dados

```
Setlist (List<SetlistItem>)
  └─ for each SetlistItem item (ordem do setlist):
       └─ for each Track track in item.originalMusic.tracks (ordem da música):
            └─ 1) Decidir: bypass (copy) ou render (C++)
            └─ 2) Se bypass → File.copy / link para pasta do show
            └─ 3) Se render → chamar FFI → aguardar conclusão (polling progress)
            └─ 4) Atualizar progresso para a UI
            └─ 5) Próxima track
```

### 2.3 Reporte de progresso para a UI

- **Granularidade:** por track (e opcionalmente percentual interno da track via C++).
- **Modelo sugerido:** um `Stream<ExportProgress>` ou `ValueNotifier<ExportProgress>` consumido pela tela de loading.

**Estrutura de progresso (exemplo):**

```dart
class ExportProgress {
  final int totalTracks;           // total de tracks do setlist
  final int completedTracks;      // tracks já processadas (copy ou render)
  final String? currentMusicTitle; // ex: "Leão de Judá"
  final String? currentTrackName;  // ex: "Bateria"
  final double trackProgress;     // 0.0..1.0 da track atual (do C++)
  final bool isBypass;             // true se foi copy, false se render
}
```

- **Cálculo do percentual global:**  
  `globalPercent = (completedTracks + trackProgress) / totalTracks` (em 0.0..1.0).  
  Exibir na UI como “Renderizando Leão de Judá - Bateria (45%)” usando `currentMusicTitle`, `currentTrackName` e `globalPercent * 100`.

- **Quem emite:** o **SetlistExportService** atualiza o estado de progresso a cada:
  - início/fim de cada track (nome da música, nome da track, 0% ou 100%);
  - durante o render de uma track: **polling** de `engine_get_render_progress` (ver seção 5).

---

## 3. Lógica de Smart Bypass (regra exata)

Objetivo: **não enviar ao C++** tracks que não sofreram alterações; em vez disso, **copiar** o arquivo original para a pasta do show (ex.: `File.copy`), economizando CPU e memória.

### 3.1 Condição de bypass (uma track precisa passar pelo C++?)

Uma track **não** precisa passar pelo C++ (pode usar **bypass = copy**) se e somente se **todas** as condições abaixo forem verdadeiras.

**A) Nível do SetlistItem (master da música):**

| Parâmetro            | Condição de bypass |
|---------------------|--------------------|
| Tempo                | `tempoFactor == 1.0` |
| Pitch (transpose)    | `transposeSemitones == 0` |
| Volume master        | `volume == 1.0` |
| EQ master            | “flat”: todas as bandas com `gainDb == 0.0` (ou lista vazia / null). |

**B) Nível da Track (e se aplica transpose):**

| Parâmetro   | Condição de bypass |
|-------------|--------------------|
| Volume      | `volume == 1.0` |
| Pan         | `pan == 0.0` |
| Mute        | `!isMuted` (não mutada) |
| EQ da track | “flat”: todas as bandas com `gain == 0.0` (ou lista vazia / null). |
| Transpose   | Se o setlist aplica transpose à música, a track só pode bypass se **não** for transponível: `!applyTranspose` ou `transposableTrackIds` não contém esta track; **e** `octaveShift == 0`. Se `transposeSemitones != 0` e a track é transponível, **não** bypass. |
| Trim        | Sem trim aplicado (quando o modelo tiver trim: `trimStart == 0` e `trimEnd == duration`). Hoje o domínio não tem trim; quando existir, incluir na condição. |

**C) Arquivo fonte:**

- Arquivo existe e é acessível: `File(track.filePath).existsSync()` (ou async equivalente).

### 3.2 Regra em código (pseudo Dart)

```dart
bool shouldBypassRender(SetlistItem item, Track track) {
  // Master
  if (item.tempoFactor != 1.0) return false;
  if (item.transposeSemitones != 0) {
    if (item.transposableTrackIds?.contains(track.id) ?? true) return false;
    if ((track.octaveShift ?? 0) != 0) return false;
  }
  if (item.volume != 1.0) return false;
  if (!_isEqFlat(item.masterEqBands)) return false;

  // Track
  if (track.volume != 1.0) return false;
  if (track.pan != 0.0) return false;
  if (track.isMuted == true) return false;
  if (!_isEqFlat(track.eqBands)) return false;
  if (track.applyTranspose && (item.transposeSemitones != 0)) return false;
  if ((track.octaveShift ?? 0) != 0) return false;

  // Trim: quando existir no modelo
  // if (track.trimStart != 0 || track.trimEnd != track.duration) return false;

  return true;
}

bool _isEqFlat(List<EqBandData>? bands) {
  if (bands == null || bands.isEmpty) return true;
  return bands.every((b) => b.gain == 0.0);
}
```

(No Isar/Model usar os mesmos critérios com `EqBandModel` e `gainDb`.)

### 3.3 Estratégia quando bypass = true

- **Ação:** copiar o arquivo fonte para a pasta do show com nome determinístico, por exemplo:  
  `{exportedItemDirectory}/{track.id}.wav` (ou manter extensão original para bypass: `{track.id}{extension}`).
- **Implementação:** `File(track.filePath).copy(join(exportedItemDirectory, '${track.id}.wav'))` (ou path com extensão original).
- **Não** chamar `engine_render_track_offline` nesse caso.

---

## 4. I/O e armazenamento (path_provider)

### 4.1 Estrutura de pastas dos shows renderizados

- **Raiz:** `path_provider`: `getApplicationDocumentsDirectory()`.
- **Convenção:**

```
{ApplicationDocumentsDirectory}/
  shows/
    {setlist_id}/           <- SetlistModel.exportedShowDirectory
      {setlist_item_id}/    <- SetlistItemModel.exportedItemDirectory
        {track_id}.wav      <- arquivo renderizado ou cópia (bypass)
        ...
      ...
```

- `setlist_id`: usar o `domainId` do Setlist (ou id de domínio do Setlist).
- `setlist_item_id`: id do SetlistItem.
- Nome do arquivo da track: `{track.id}.wav` (para render C++ já ser WAV; para bypass pode ser `.wav` ou mesma extensão do original, conforme decisão de formato único na pasta).

### 4.2 Atualização no Isar (liveFilePath / paths do show)

- **SetlistModel:** adicionar campo opcional, por exemplo:
  - `String? exportedShowDirectory`  
  Ex.: `.../shows/abc-123`.

- **SetlistItemModel:** adicionar campo opcional, por exemplo:
  - `String? exportedItemDirectory`  
  Ex.: `.../shows/abc-123/item-uuid`.

- **Resolução do “live” file path por track:**  
  Não é obrigatório persistir path por track. O path do arquivo da track no show pode ser derivado por convenção:
  - `liveFilePath(track) = "${item.exportedItemDirectory}/${track.id}.wav"`  
  (ou com extensão original no caso de bypass, se não normalizar para .wav.)

- **Quando atualizar:**
  - No **final** do export de **todo** o setlist (sucesso):  
    - Gravar `SetlistModel.exportedShowDirectory` e, para cada item, `SetlistItemModel.exportedItemDirectory`.
  - Transação Isar: atualizar o `SetlistModel` e cada `SetlistItemModel` dentro do mesmo `writeTxn` para manter consistência.

- **Limpeza:** ao excluir setlist ou ao “re-exportar”, apagar a pasta `exportedShowDirectory` (ou cada `exportedItemDirectory`) antes de recriar, para evitar arquivos órfãos.

---

## 5. Integração FFI segura (background C++ e polling no Dart)

### 5.1 Comportamento atual do C++

- `engine_render_track_offline` inicia um **std::thread** que roda `renderWorker` e faz **detach**. Ou seja, o trabalho é assíncrono no C++; a chamada FFI retorna imediatamente.
- O progresso é consultado via `engine_get_render_progress(trackId)`, retornando 0.0..1.0, ou -1.0 (erro), -2.0 (cancelado).

### 5.2 Evitar travar a UI

- **Problema:** se o Dart ficar em um loop síncrono esperando `engine_get_render_progress == 1.0` (ou < 0) no isolate principal, a UI congela.
- **Solução:** **não** fazer polling no isolate principal em loop apertado.

**Opção A (recomendada):** todo o export rodar em um **isolate de background** (ex.: `Isolate.run` ou isolate dedicado que recebe mensagens “export setlist”). Dentro desse isolate:
- Chamar `engine_render_track_offline` (FFI é válido em isolates que carregaram a mesma dynamic library).
- Fazer polling com **await Future.delayed(Duration(milliseconds: 200))** (ou 100–300 ms) e então `engine_get_render_progress(trackId)`.
- Enviar eventos de progresso para o isolate principal via `SendPort` (ex.: `ExportProgress` serializável).
- O main isolate só escuta o `ReceivePort` e atualiza um `ValueNotifier<ExportProgress>` ou um `StreamController<ExportProgress>`, que a UI consome.

**Opção B:** manter o export no main isolate mas usar **microtasks / timers** para não bloquear:
- Após chamar `engine_render_track_offline`, agendar um `Future.delayed(...)`; no callback, ler `engine_get_render_progress` e atualizar estado; se não terminou (progress < 1.0 e > 0), agendar novo `Future.delayed` (polling com intervalo fixo).  
- Menos ideal que A, pois o export em si (iterar setlist, copiar arquivos, etc.) ainda pode dar picos de trabalho no main isolate.

Recomendação: **Opção A** (isolate de background para o export + polling com delay + SendPort para progresso).

### 5.3 Cancelamento

- Ao cancelar o export (ação do usuário), o Dart deve:
  - Chamar `engine_cancel_render(trackId)` para a track atual (se estiver em render).
  - Deixar de agendar o próximo passo da fila e sinalizar “cancelado” para a UI.
- O C++ já suporta `cancelRender` e remove o arquivo incompleto no worker.

### 5.4 Resumo da sequência por track (render path)

1. Dart (no isolate de export) chama `engine_render_track_offline(...)` com parâmetros da track/setlist.
2. Loop no isolate de export:  
   `while (true) { await Future.delayed(200); p = engine_get_render_progress(trackId); sendProgress(p); if (p >= 1.0 || p < 0) break; }`
3. Se `p >= 1.0`: sucesso; seguir para a próxima track.  
   Se `p == -1.0`: erro; abortar ou registrar e seguir conforme política.  
   Se `p == -2.0`: cancelado; abortar export e notificar UI.

---

## 6. Escopo do SetlistExportService (Dart)

- **Entrada:** Setlist (entity ou id para carregar do repositório), diretório base opcional (default: `getApplicationDocumentsDirectory()` + `shows`).
- **Saída:** 
  - Sucesso: paths atualizados no Isar (`exportedShowDirectory`, `exportedItemDirectory` por item); `Stream`/callback de progresso fechado com “completed”.
  - Erro/cancelamento: `Stream`/callback com erro ou cancelado; não atualizar paths (ou limpar pasta parcial).
- **Dependências sugeridas:**  
  Path provider, repositório Isar (ler setlist, salvar setlist com novos campos), FFI bindings para `engine_render_track_offline`, `engine_get_render_progress`, `engine_cancel_render`, e opcionalmente um “native renderer facade” que encapsula FFI e traduz entidades (Track, SetlistItem) para parâmetros C++ (paths, tempo, pitch, eqBands).
- **Responsabilidades:**
  - Montar a fila: lista plana (item, track) na ordem desejada.
  - Para cada (item, track): decidir bypass vs render (smart bypass).
  - Bypass: copiar arquivo para `exportedItemDirectory`.
  - Render: chamar FFI, polling de progresso no isolate de export, enviar progresso para a UI.
  - Ao finalizar todo o setlist: criar/atualizar pastas, persistir `exportedShowDirectory` e `exportedItemDirectory` no Isar.
  - Suportar cancelamento e reportar progresso (música atual, track atual, percentual).

---

## 7. Gargalos e melhorias no C++ atual

### 7.1 Decoder: arquivo inteiro em RAM (risco de OOM)

- Em **audio_decoder.cpp**:
  - **MP3:** `mp3dec_load` carrega o arquivo **inteiro** em `info.buffer`; depois esse buffer é copiado para `result.pcmData`. Ou seja, **dois picos de memória** (buffer do decoder + vector).
  - **WAV/FLAC:** `result.pcmData.resize(totalSamples)` aloca **todo** o PCM de uma vez; a leitura é em chunks, mas o destino já está totalmente alocado.

Para setlists longos ou arquivos grandes (ex.: 1h em WAV), isso pode causar OOM em dispositivos móveis.

**Recomendações:**

- **Curto prazo:** manter “uma track por vez” no Dart e, se possível, limitar no app o tamanho máximo de arquivo para export (ex.: avisar o usuário para arquivos > X minutos).
- **Médio prazo:** evoluir o decoder para **streaming por chunks**: decoder produz blocos (ex.: 4096 frames), o renderer consome e escreve no WAV em blocos, sem manter o arquivo inteiro em RAM. Isso exige refatoração do `renderWorker` para um pipeline decode → process → write em janelas.

### 7.2 Renderer: processamento em chunks (OK)

- **audio_renderer.cpp** já processa em **chunks** (CHUNK_SIZE = 4096) no loop de SoundTouch + EQ + dr_wav. O gargalo de memória não é o loop de processamento, e sim o **decode** que alimenta esse loop com o buffer completo.

### 7.3 Trim não implementado no C++

- O header/comentário do usuário menciona “Trim” como parâmetro de export. Hoje **audio_renderer** e **engine_render_track_offline** **não** recebem parâmetros de trim (start/end).
- No domínio Dart, **Track** atualmente não tem `trimStart`/`trimEnd`; quando existir:
  - Incluir na condição de **smart bypass** (sem trim = não cortar).
  - Estender o C++ para aceitar trim (em segundos ou em frames) e processar apenas esse intervalo (decode + processar apenas a região, ou decode completo e cortar no buffer). Isso também impacta o decoder se continuar full-load (menor impacto se for streaming).

### 7.4 Volume e Pan

- O C++ de render **não** aplica volume nem pan no arquivo de saída; o renderer só aplica tempo, pitch e EQ. Para o “show” exportado refletir volume/pan da mixagem:
  - **Opção 1:** aplicar ganho e pan no Dart (pós-processamento ou mixagem) — fora do escopo do render atual.
  - **Opção 2:** estender o C++ para aceitar volume e pan e aplicar no buffer antes de escrever no WAV (recomendado para fidelidade ao “live”).

O **smart bypass** já considera volume/pan (bypass só se volume == 1 e pan == 0); quando o C++ suportar volume/pan, as tracks que precisam de volume/pan deixarão de fazer bypass e passarão pelo C++.

---

## 8. Plano de ação resumido

| # | Tarefa | Responsável |
|---|--------|-------------|
| 1 | Adicionar ao Isar: `SetlistModel.exportedShowDirectory`, `SetlistItemModel.exportedItemDirectory`; rodar build_runner. | Dart |
| 2 | Implementar helper `shouldBypassRender(item, track)` e `_isEqFlat` conforme seção 3. | Dart |
| 3 | Definir estrutura de pastas e criar `getShowExportDirectory(setlistId)`, `getItemExportDirectory(setlistId, itemId)` com path_provider. | Dart |
| 4 | Implementar FFI bindings para `engine_render_track_offline`, `engine_get_render_progress`, `engine_cancel_render` (e tradução de EqBandData → tipos C++). | Dart |
| 5 | Implementar SetlistExportService: fila sequencial, bypass (File.copy), render (FFI + polling em isolate), progresso via SendPort, persistência ao final. | Dart |
| 6 | UI de progresso: tela/dialog que subscreve progresso e exibe “Renderizando {música} - {track} (X%)”. | Dart |
| 7 | (Opcional) Limitar tamanho de arquivo ou duração para export; documentar no app. | Dart/Product |
| 8 | (Futuro) Decoder streaming no C++ para reduzir OOM. | C++ |
| 9 | (Futuro) Suporte a Trim e Volume/Pan no audio_renderer e na bridge. | C++ |

---

## 9. Referências no código

- **C++:** `android/app/src/main/cpp/audio_renderer.cpp`, `audio_renderer.h`, `bridge.cpp` (engine_render_track_offline, engine_get_render_progress, engine_cancel_render).
- **Decoder:** `android/app/src/main/cpp/audio_decoder.cpp` (decode full-load).
- **Dart:** `lib/features/player_mixer/data/models/setlist_model.dart`, `setlist_item_model.dart`, `track_model.dart`; `lib/core/audio_engine/native_audio_engine.dart` (padrão FFI).
- **path_provider:** já em uso em `lib/injection_container.dart`.
