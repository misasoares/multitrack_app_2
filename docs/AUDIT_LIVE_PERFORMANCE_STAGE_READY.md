# Auditoria: Live Performance — Pronto para o Palco

**Data:** 2025-02-27  
**Escopo:** LivePerformancePage, LivePerformanceStore, integração NativeAudioEngine.

---

## 1. Memory Leaks no Ciclo de Vida (Dispose)

### Problemas identificados

| # | Problema | Severidade |
|---|----------|------------|
| 1.1 | **LivePerformanceStore.dispose()** existe mas **não para o áudio nem limpa o motor**. Apenas cancela `_positionSubscription`. Ao dar pop, o engine continua com tracks carregadas e, se estava tocando, o áudio pode continuar em background. | **Crítico** |
| 1.2 | **Nenhuma chamada a pausePreview() ou clearAllTracks()** ao sair da tela. Buffers C++ e stream Oboe permanecem ativos → risco de leak e comportamento incorreto em outras telas (ex.: Create Music). | **Crítico** |
| 1.3 | **MixerLevelController** é disposto na página (`_levelController?.dispose()`), o que cancela o `Timer.periodic` — OK. | OK |
| 1.4 | **Stream onPreviewPosition**: ao cancelar a subscription paramos de receber eventos; o `Stream.periodic` continua vivo no engine (singleton). Não é leak do Store; o engine é compartilhado. | OK |

### Correções obrigatórias

- Em **LivePerformanceStore.dispose()**: chamar **pausePreview()** e em seguida **clearAllTracks()** antes de cancelar a subscription, para parar o áudio e liberar os buffers nativos.
- Manter a ordem: `pause → clearAllTracks → cancel subscription`, e considerar um flag `_disposed` para evitar que callbacks assíncronos (ex.: `.then` após troca de música) executem após o dispose.

---

## 2. Transição Segura entre Músicas (nextSong / prevSong / goToSong)

### Problemas identificados

| # | Problema | Severidade |
|---|----------|------------|
| 2.1 | **clearAllTracks() é chamado sem pause antes**. Interromper o mix abruptamente pode gerar **pop/click** no áudio (corte de buffer no C++). | **Alto** |
| 2.2 | O motor C++ (**engine_clear_all_tracks**) libera os ponteiros; a **ordem** no Dart deve ser: parar reprodução → limpar → carregar nova música. | — |
| 2.3 | **Callbacks assíncronos**: `_loadCurrentSong().then((_) { ... playPreview(); })` pode rodar **depois** do usuário ter saído da tela (dispose). Sem guard, podemos chamar `playPreview()` em store já disposto. | **Alto** |

### Correções obrigatórias

- Em **nextSong**, **prevSong** e **goToSong**:  
  1. **pausePreview()** (mini “fade” conceitual: para o stream antes de mexer nos buffers).  
  2. **clearAllTracks()**.  
  3. Atualizar índice e **currentPosition**.  
  4. **isLoadingSong = true**, depois **await _loadCurrentSong()**, e no `.then`: se **!(_disposed)** então **isLoadingSong = false** e, se `wasPlaying`, **playPreview()**.
- Usar um flag **\_disposed** no Store: setado em **dispose()**, checado em todos os `.then`/callbacks assíncronos para não tocar nem atualizar estado após sair da tela.

---

## 3. Bloqueio da Main Thread (Micro-Jank)

### Análise

| # | Ponto | Conclusão |
|---|--------|-----------|
| 3.1 | **NativeAudioEngine.loadPreview()** já delega o decode pesado a **Isolate.run** (`_decodeTracksInBackground`). O trabalho de **engine_load_file** ocorre no isolate; a main thread só aplica volume/pan/mute/solo após o await. | **Não bloqueia** a UI durante o carregamento das tracks. |
| 3.2 | **LivePerformanceStore.loadSetlist()** e **_loadCurrentSong()** usam **await _audioEngine.loadPreview()**; como o trabalho pesado é no isolate, a UI permanece responsiva. | OK |
| 3.3 | Não é necessário envelopar novamente em **Isolate.run** na tela de palco; o padrão já está correto. | Nenhuma alteração necessária. |

---

## 4. UX de Carregamento (Loading State)

### Problemas identificados

| # | Problema | Severidade |
|---|----------|------------|
| 4.1 | **Não existe** variável **@observable bool isLoadingSong** no Store. | **Médio** |
| 4.2 | **Nenhum feedback visual** enquanto a próxima música está sendo carregada (troca de faixa ou entrada na tela). O usuário pode achar que o app travou ou tocar múltiplas vezes em Next/Prev. | **Médio** |

### Correções obrigatórias

- Adicionar **@observable bool isLoadingSong** no Store.
- Colocar **isLoadingSong = true** no início de qualquer fluxo que chame **_loadCurrentSong()** (loadSetlist, nextSong, prevSong, goToSong) e **isLoadingSong = false** ao terminar (no `.then`, e em **catchError** se houver).
- Na UI:  
  - **Desabilitar** botões de transporte (Play/Pause, Next, Prev) e toques no setlist ribbon enquanto **isLoadingSong == true**.  
  - Opcional: indicador discreto (ex.: pequeno spinner no header ou overlay sutil) com **Observer** em **store.isLoadingSong**.

---

## Resumo das alterações no código

| Arquivo | Alteração |
|---------|-----------|
| **live_performance_store.dart** | 1) dispose: chamar pausePreview() e clearAllTracks(); 2) Flag _disposed, setado em dispose e checado em callbacks; 3) isLoadingSong observável; 4) nextSong/prevSong/goToSong: pause antes de clear e set isLoadingSong com guard em .then; 5) loadSetlist: isLoadingSong e guard no .then da subscription. |
| **live_performance_page.dart** | 1) Observer em isLoadingSong: desabilitar botões de transporte e ribbon; 2) Opcional: spinner ou overlay de “Carregando…” quando isLoadingSong; 3) Ordem em dispose: levelController → store.dispose() (já OK). |

---

## Checklist final “Pronto para o Palco”

- [x] Store.dispose() chama pausePreview() e clearAllTracks().
- [x] Flag _disposed impede callbacks após dispose.
- [x] nextSong/prevSong/goToSong fazem pause → clear → load e usam isLoadingSong + guard.
- [x] isLoadingSong observável e UI desabilita transporte/ribbon durante carga.
- [x] Feedback visual de loading (spinner no header) quando isLoadingSong.
- [x] MixerLevelController e position subscription dispostos na página/store.

Com essas melhorias, o fluxo fica seguro contra vazamentos, estouro de áudio na troca de faixa e micro-jank, com UX clara durante o carregamento.
