# Target Architecture & Platform Policy

- **Development & Debug Platform (Host)**: **Linux x86_64 (amd64)**.
  - O runner desktop (`nds_runner`) é utilizado para testes iterativos, emulação interativa (SDL2), logs de execução (`dispatch_misses.log`) e depuração rápida com ferramentas nativas do Linux.
  - Ghidra, Python, CMake e `nds_recompile` rodam neste host.
- **Final Deployment Platform (Game Binaries)**: **Android ARM64 (`arm64-v8a`)**.
  - O objetivo final de entrega é rodar no Android arm64.
  - As correções, mapeamentos e ajustes de código validados no PC serão subsequentemente compilados via Android NDK (`build_android.sh`) para gerar a biblioteca `libnds_runner.so` para o app Android.

---

# Contexto do Projeto: Castlevania: Dawn of Sorrow (NDS Recomp)

## 1. Status Atual
- **Estado**: **100% Jogável e Estável no PC (Linux x86_64)**.
- **Desempenho**: **60 FPS estáveis**, tempo de emulação de CPU em **~6.35 ms por quadro** (orçamento total: 16.66 ms, folga de **>61.8%**).
- **Sobrecarga do Interpretador**: Praticamente **ZERO** (ARM9: 0.0014 ms/frame, ARM7: 0.0016 ms/frame).
- **Funções Estáticas**: **32.343 funções nativas compiladas** em 6 bancos.
- **Sessões validadas**: Mais de 44.600 quadros consecutivos jogados sem crashes, com savegame EEPROM funcional.

---

## 2. Histórico de Problemas Críticos e Soluções

### A. Binários Extraídos vs ROM Bruta (Causa raiz do erro de boot)
- **Problema**: A ROM de 64 MB (`Castlevania - Dawn of Sorrow .nds`) começava com o cabeçalho do cartucho (0x0..0x200), enquanto o ARM9 executável fica no offset `0x4000` da ROM (813 KB) e o ARM7 no offset `0x3B3E00` (157 KB). Recompilar a ROM inteira deslocava todas as instruções em 0x4000 bytes e gerava shards gigantes de 80 MB com lixo de dados.
- **Solução**: Extraídos os binários puros:
  - `extracted/arm9.bin` (813.976 bytes, entry `0x02000800`, load `0x02000000`, sha1 `08f7ceafa212c9204ee7e5f72e29cb2cbff227df`).
  - `extracted/arm7.bin` (157.268 bytes, entry `0x02380000`, load `0x02380000`, sha1 `f87b32c7cad9a670a49fae7f1de055103c4cd580`).

### B. Modo de Boot Obrigatório
- Jogos comerciais recompilados exigem inicialização direta:
  `--freebios --boot direct --interactive`
  Sem `--boot direct`, o runner tenta executar o Firmware/BIOS oficial LLE da Nintendo (tela de relógio do DS) que não está mapeado e aborta com `dispatch-miss pc=0x00000000`.

### C. Otimizações de Quedas de FPS (Eliminação do Fallback de Interpretação)
- **ARM7 WRAM Alias (`0x037F7E90`)**:
  Em tempo de execução, o jogo copia o driver de áudio e I/O para a memória WRAM rápida (`0x037F7E90`). Foi criado o banco `castlevania_arm7_wram`, reduzindo as quedas de interpretação do ARM7 de **60 milhões para menos de 500 mil** (redução de 99.1%).
- **ARM9 ITCM Alias (`0x01F378C0`)**:
  O ARM9 copia loops críticos de renderização e matemática para o ITCM (`0x01FF8000`). Foi criado o banco `castlevania_arm9_itcm`.
- **Ingestão de Seeds Contínua**:
  A ferramenta `tools/ingest_coverage_manifests.py` lê os manifestos gerados em gameplay (`*-coverage-*.json`) e insere novos pontos de entrada diretamente em `config/arm9.toml` e `config/arm9_itcm.toml` (+1.500 funções capturadas).
- **Tempo de Compilação do GCC**:
  O ARM9 foi dividido em 10 shards rápidos (`--shards 10`), reduzindo o tempo de compilação de 45 minutos para **menos de 2 minutos**.

### D. Mapeamento de Memória dos Overlays
- **Overlays Exclusivos (Compilados Nativamente)**:
  - **Overlay #00** (`0x0219E3E0..0x02230740`, 600 KB): Motor central permanente de gameplay (física, monstros, armas). Não colide com nenhum outro overlay.
  - **Overlay #01** (`0x02230A00..0x0229A920`, 434 KB): Módulo permanente auxiliar. Também 100% exclusivo.
- **Overlays Compartilhados (Deixar no Interpretador Dinâmico)**:
  - Overlays #06 a #22 (área `0x022DA4A0`) e #23 a #40 (área `0x022FF9C0`) chaveiam dinamicamente o mesmo endereço de memória em tempo de execução. Não devem ser compilados estaticamente sem live swap.

---

## 3. Estrutura de Arquivos

- `ndsrecomp/config/`:
  - `arm9.toml`: Configuração do ARM9 principal com 1.562 entry points do jogo.
  - `arm7.toml`: Configuração do ARM7 base (0x02380000).
  - `arm7_wram.toml`: Configuração do ARM7 WRAM (0x037F7E90).
  - `arm9_itcm.toml`: Configuração do ARM9 ITCM (0x01F378C0).
  - `arm9_overlay_0000.toml`: Motor central permanente (7.395 funções).
  - `arm9_overlay_0001.toml`: Módulo auxiliar permanente (1.696 funções).
- `ndsrecomp/extracted/`:
  - `arm9.bin` e `arm7.bin`: Binários originais extraídos do ROM.
  - `overlays/` e `overlays.json`: 42 overlays extraídos com metadados de offsets.
- `ndsrecomp/game.toml`: Configuração do jogo para o runner (layout stacked, freebios, eeprom).
- `ndsrecomp/recompile_optimized.sh`: Script mestre que executa a recompilação limpa de todos os 6 bancos e constrói o `nds_runner`.

---

## 4. Comandos de Operação

### Recompilar e Construir o Runner PC:
```bash
cd "/media/windroid/SSD KING/Recomp-NDS/ndsrecomp" && ./recompile_optimized.sh
```

### Executar o Jogo no PC (Modo Interativo com FreeBIOS e Boot Direto):
```bash
cd "/media/windroid/SSD KING/Recomp-NDS/ndsrecomp" && \
./runner/build-pc/nds_runner bios/ --rom "/media/windroid/SSD KING/Recomp-NDS/Castlevania - Dawn of Sorrow .nds" --freebios --boot direct --interactive
```

### Compilar e Gerar o APK Android ARM64 com SDL3:
```bash
cd "/media/windroid/SSD KING/Recomp-NDS/android" && ./build_android_sdl3.sh
```
O APK final será gerado em:
`android/app/build/outputs/apk/debug/app-debug.apk`

---

## 5. Estrutura do Projeto Android (`android/`)
- `thirdparty/SDL3`: Código fonte oficial limpo do SDL 3.2.8.
- `installed-sdl3-arm64`: Binários e headers do SDL3 instalados para `arm64-v8a`.
- `build_android_sdl3.sh`: Script mestre automatizado de compilação cruzada e empacotamento.
- `app/src/main/jniLibs/arm64-v8a`:
  - `libSDL3.so` (Runtime SDL3 3.2.8).
  - `libc++_shared.so` (LLVM libc++ do NDK 27.2).
  - `libmain.so` (Runner nativo contendo todas as 32.343 funções estáticas recompiladas do Castlevania).
- `app/src/main/java/`:
  - `org/libsdl/app/`: Framework Java oficial limpo do SDL3.
  - `com/windroid/castlevania/TitleActivity.java`: Tela de título responsiva edge-to-edge que se adapta sem cortes a qualquer tela ultrawide, com solicitação de permissão de arquivos e detecção automática de ROM.
  - `com/windroid/castlevania/CastlevaniaActivity.java`: Atividade nativa do jogo que configura inicialização direta (`--freebios`, `--boot direct`, `--generated-firmware`, `--interactive`).

---

## 6. Validação no Dispositivo Físico (moto g100 - Snapdragon 870 / ARM64)
- **Status**: **100% Funcional e Validado em Tempo Real via ADB**.
- **Instalação**: APK instalado com sucesso (`app-debug.apk`, 35 MB).
- **Ícone Adaptativo**: Suporte completo a todas as resoluções e densidades (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi, anydpi-v26) com proporção ótica ajustada para a zona segura (safe-zone), garantindo que 100% da arte, castelo, lua e logo fiquem visíveis sem corte em launchers circulares, squircles ou quadrados.
- **Tela Título**: Arte original exibida sem cortes em tela cheia 21:9 (2520x1080) com efeito pulsante "TOCAR PARA INICIAR" e trilha sonora imersiva em loop (*Requiem for the Throne* via `MediaPlayer`).
- **Gameplay**: Ao tocar na tela, o runner nativo SDL3 inicia instantaneamente com áudio de baixa latência e renderização a 60 FPS com os 32.343 métodos estáticos recompilados em execução!
- **Mapeamento de Controles (START in-game vs Menu Runtime)**:
  - O runner original interceptava o botão START do gamepad para abrir o menu `recomp-ui` ("Runtime Settings") na tela superior, bloqueando o envio de `KEY_START` (bit 3) para o jogo.
  - O mapeamento foi corrigido em `runner/src/frontend.cpp`: o botão START agora envia diretamente `1u << 3` para o Castlevania (abrindo o menu de pausa, status, almas e mapa do jogo).
  - **Otimização de Telemetria e Desempenho (60 FPS Nativos)**:
  - **Mito do Interpretador**: A telemetria microsegundo revelou que o interpretador ARM7 executou **0** instruções e o ARM9 executou menos de **100** instruções/s (<0.008 ms/frame). Todas as 32.343 funções estáticas rodam nativamente em ARM64, com o tempo de emulação de CPU em impressionantes **5.4 ms a 6.2 ms por quadro**.
  - **Causa Raiz da Lentidão Anterior**: O kernel do Android aplica por padrão uma folga de temporizador (`PR_SET_TIMERSLACK`) de 10–40 ms no processo foreground. Isso fazia o `drain_audio` (`SDL_Delay(1)`) dormir por mais de 13 ms artificiais a cada frame, afunilando a taxa para ~38 FPS.
  - **Solução Implementada**:
    1. Ajustado `prctl(PR_SET_TIMERSLACK, 50000)` para temporização precisa de 50 µs no Android.
    2. Adicionado teto de orçamento no `drain_audio` (`runner/src/frontend.cpp`) para garantir que o temporizador de áudio nunca force espera além do deadline do frame de 16.7 ms.
  - **Resultado**: Taxa de quadros cravada em **58.6 - 60.0 FPS** (taxa de atualização nativa do NDS é 59.826 Hz), áudio sem cortes e fluidez perfeita.
