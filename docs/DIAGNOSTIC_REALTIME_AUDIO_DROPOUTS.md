# Diagnóstico: Real-Time Safety no Loop de Mixagem (Audio Dropouts)

**Data:** 2025-02-27  
**Contexto:** 11 tracks no Galaxy Tab S10 Lite — áudio “engasga” após os primeiros segundos (buffer underruns).  
**Escopo:** `audio_mixer.cpp` (função `process()` chamada pelo callback Oboe), `oboe_player.cpp`, configuração do stream Oboe.

---

## Resumo executivo

Há **três violações graves** de real-time safety que explicam os dropouts:

1. **Alocação dinâmica dentro do callback de áudio** — `std::vector<float>` alocado **por track, a cada callback**, em `AudioMixer::process()` (e um segundo vector no path SoundTouch mono).
2. **Uso de mutex dentro do callback** — `process()` adquire **dois** mutexes (`queueMutex_` e `mutex_`); se a thread principal estiver segurando o lock (ex.: carregando UI ou processando comando), a thread de áudio bloqueia → underrun.
3. **Oboe em modo não low-latency** — `setPerformanceMode(oboe::PerformanceMode::None)`; o stream não está configurado para prioridade de tempo real.

---

## 1. Alocação dinâmica de memória (principal suspeito)

### 1.1 Vector por track a cada callback — **CRÍTICO**

**Arquivo:** `android/app/src/main/cpp/audio_mixer.cpp`  
**Função:** `AudioMixer::process()`  
**Linha:** **336**

```cpp
for (auto& [id, trackPtr] : tracks_) {
    MixerTrack& track = *trackPtr;
    // ...
    std::vector<float> trackOutput(numFrames * 2, 0.0f);   // ← LINHA 336
    int samplesReceived = 0;
    // ...
}
```

- **O que acontece:** A cada invocação do callback Oboe (a cada ~5–10 ms, dependendo do buffer), para **cada uma das 11 tracks**, é construído um `std::vector<float>` de tamanho `numFrames * 2` (ex.: 512*2 = 1024 ou 1024*2 = 2048 floats).
- **Impacto:** São 11 alocações de heap **por callback**. Em 44,1 kHz com buffer de 512 frames, isso significa ~86 callbacks/segundo → **centenas de alocações/segundo** só neste ponto. `malloc`/`new` no caminho de áudio podem levar de dezenas a centenas de microsegundos e provocar picos de latência e contenção no allocator, levando a underruns.
- **Conclusão:** Esta é a **causa mais provável** dos engasgos: alocação dinâmica repetida no loop de mixagem.

### 1.2 Vector no path SoundTouch (mono) — **CRÍTICO**

**Arquivo:** `android/app/src/main/cpp/audio_mixer.cpp`  
**Função:** `AudioMixer::process()`  
**Linha:** **372**

```cpp
} else {
    std::vector<float> stInput(feed * 2);   // ← LINHA 372 (feed = 1024, logo 2048 floats)
    const float* pcm = track.pcmData.data() + track.playheadFrame;
    for (int i = 0; i < feed; ++i) {
        stInput[i * 2] = pcm[i];
        stInput[i * 2 + 1] = pcm[i];
    }
    st->putSamples(stInput.data(), feed);
}
```

- **Onde ocorre:** Dentro do branch SoundTouch (tempo/pitch ≠ 1.0/0), quando a track é **mono** (`numChannels != 2`), dentro do loop `while (samplesReceived < numFrames)` (linhas 363–388).
- **O que acontece:** A cada “feed” de 1024 frames, é alocado um `std::vector<float>` de 2048 elementos. Com 11 tracks e possíveis múltiplos feeds por callback, isso adiciona **mais alocações no callback**.
- **Conclusão:** Segunda fonte clara de alocação dinâmica no caminho de áudio; reforça o diagnóstico de que **std::vector no callback** está causando os dropouts.

### 1.3 Buffers no OboePlayer (resize no primeiro callback)

**Arquivo:** `android/app/src/main/cpp/oboe_player.cpp`  
**Função:** `OboePlayer::onAudioReady()`  
**Linhas:** **86–90**

```cpp
if (static_cast<int32_t>(tempL_.size()) < numFrames) {
    tempL_.resize(numFrames);
    tempR_.resize(numFrames);
}
```

- **O que acontece:** Na primeira vez que `numFrames` é maior que o tamanho atual dos buffers, ou se o tamanho do buffer do stream mudar, `resize()` é chamado dentro do callback → alocação no caminho de áudio.
- **Impacto:** Ocorre apenas quando o tamanho do buffer “sobe” (ex.: primeiro callback ou mudança de buffer), mas mesmo assim é uma violação de real-time safety e pode causar um underrun pontual no início ou após reconexão.

### 1.4 Resposta direta às perguntas

- **Existe alocação dinâmica (new, malloc, std::vector) dentro do loop de mixagem chamado a cada frame?**  
  **Sim.** Em `AudioMixer::process()`: linha 336 (`trackOutput`) a cada track a cada callback; linha 372 (`stInput`) no path SoundTouch mono, possivelmente várias vezes por track por callback.

- **As tracks estão alocando buffers temporários a cada iteração em vez de usar buffer pré-alocado reutilizável?**  
  **Sim.** O buffer `trackOutput` (linha 336) é criado por iteração do loop sobre as tracks; não há buffer por track pré-alocado e reutilizável. O path mono SoundTouch também aloca `stInput` por feed em vez de um buffer mono→stereo reutilizável.

---

## 2. Bloqueios de thread (locks / mutexes)

### 2.1 Mutexes dentro de `AudioMixer::process()`

**Arquivo:** `android/app/src/main/cpp/audio_mixer.cpp`  
**Função:** `AudioMixer::process()`  
**Linhas:** **366–374** e **374**

```cpp
// Linhas 366–371: lock no queue
std::queue<CommandMessage> localQueue;
{
    std::lock_guard<std::mutex> qLock(queueMutex_);   // ← LINHA 369
    std::swap(localQueue, commandQueue_);
}

std::lock_guard<std::mutex> lock(mutex_);   // ← LINHA 374 — lock no mixer por TODO o process()
```

- **O que acontece:**  
  - O callback de áudio adquire `queueMutex_` para trocar a fila de comandos.  
  - Em seguida adquire `mutex_` e o mantém durante **todo** o `process()` (mixagem das 11 tracks, incluindo as alocações e o path SoundTouch).
- **Risco:**  
  - Se a thread principal (ou outra) segurar `mutex_` ao fazer operações pesadas (ex.: atualizar UI, processar algo no bridge), a thread de áudio fica bloqueada em `lock(mutex_)` → atraso no callback → buffer underrun e “engasgo”.  
  - O inverso também é verdadeiro: enquanto o áudio segura `mutex_` por todo o `process()`, nenhuma chamada de controle (setVolume, setMute, loadTrack, etc.) consegue adquirir o mesmo mutex; se o `process()` demorar por causa das alocações e do trabalho por track, a thread principal pode bloquear.
- **Conclusão:** Sim, estamos usando **std::lock_guard<std::mutex>** dentro do callback de áudio (e por tempo prolongado). Isso viola as boas práticas de áudio em tempo real e contribui para os dropouts quando há contenção ou quando o próprio process() demora.

---

## 3. Oboe stream setup (bridge.cpp / engine_init)

A abertura do stream Oboe está em `oboe_player.cpp` em `OboePlayer::start()`, chamado a partir de `engine_init()` em `bridge.cpp`. Não há configuração adicional do stream em `bridge.cpp` além de criar o mixer e o player.

### 3.1 PerformanceMode

**Arquivo:** `android/app/src/main/cpp/oboe_player.cpp`  
**Linha:** **29**

```cpp
builder.setPerformanceMode(oboe::PerformanceMode::None);   // ← LINHA 29
```

- **Problema:** Deveria ser **`oboe::PerformanceMode::LowLatency`** para um stream de saída de áudio em tempo real.  
- **Efeito de `PerformanceMode::None`:** O sistema não trata o stream como de baixa latência; a thread de callback pode não ter prioridade elevada nem ser agendada de forma adequada para prazo curto, aumentando o risco de atrasos e underruns quando a CPU está ocupada (ex.: 11 tracks + alocações).

### 3.2 setUsage

**Arquivo:** `android/app/src/main/cpp/oboe_player.cpp`  
**Função:** `OboePlayer::start()` (linhas 26–34)

- **Situação atual:** Não há chamada a **`setUsage()`** no builder. O uso do stream fica o padrão do Oboe/AAudio.  
- **Sobre Usage::Media:** Para playback de música, é comum usar `oboe::Usage::Media`. Para aplicativo de “palco” com necessidade de baixa latência, `Usage::Game` ou `Usage::Media` com **ContentType** adequado (ex.: Music) pode ser mais apropriado. O ponto aqui é que **não está configurado explicitamente** — não está definido como `oboe::Usage::Media` (nem outro), apenas usa o default.

### 3.3 Outros parâmetros

- **setSharingMode(oboe::SharingMode::Exclusive):** Adequado para baixa latência.  
- **setBufferSizeInFrames(stream_->getFramesPerBurst() * 4):** Aumenta o buffer para dar margem de CPU; ajuda em estabilidade, mas não resolve alocação nem mutex no callback.

---

## 4. Tabela resumo das violações

| # | Local (arquivo:linha) | Violação | Gravidade |
|---|------------------------|----------|-----------|
| 1 | audio_mixer.cpp:336 | `std::vector<float> trackOutput(numFrames * 2)` por track, a cada callback | Crítica |
| 2 | audio_mixer.cpp:372 | `std::vector<float> stInput(feed * 2)` no path SoundTouch mono, dentro do callback | Crítica |
| 3 | audio_mixer.cpp:369 | `std::lock_guard<std::mutex> qLock(queueMutex_)` no callback | Alta |
| 4 | audio_mixer.cpp:374 | `std::lock_guard<std::mutex> lock(mutex_)` no callback, mantido por todo process() | Alta |
| 5 | oboe_player.cpp:86–90 | `tempL_.resize()` / `tempR_.resize()` no callback (quando numFrames aumenta) | Média |
| 6 | oboe_player.cpp:29 | `setPerformanceMode(PerformanceMode::None)` em vez de LowLatency | Alta |

---

## 5. Conclusão

- A **causa principal** dos engasgos é muito provavelmente a **alocação dinâmica repetida no callback**, em especial o **`std::vector<float> trackOutput` na linha 336** (uma vez por track, a cada callback), seguida do **`std::vector<float> stInput` na linha 372** no path SoundTouch mono.
- Os **mutexes** nas linhas 369 e 374 dentro de `process()` expõem o áudio a bloqueios e amplificam o risco de underruns quando há contenção ou quando o próprio `process()` fica lento por causa das alocações.
- O **PerformanceMode::None** no Oboe impede que o stream seja tratado como low-latency e pode piorar a sensibilidade a picos de CPU.

**Confirmação pedida:** Sim — a causa dos engasgos está alinhada com o uso de **std::vector no callback**: alocação por track em cada chamada a `process()` (linha 336) e, quando aplicável, no path mono do SoundTouch (linha 372), violando real-time safety e levando a buffer underruns após os primeiros segundos, quando o allocator e a CPU ficam mais carregados.
