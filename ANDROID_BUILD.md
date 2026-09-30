# Build Android Otimizado

Este documento descreve como compilar o ndsrecomp para Android com otimizações de performance.

## Pré-requisitos

- Android NDK (versão 21 ou superior recomendada)
- CMake 3.20+
- Ninja (opcional, mas recomendado para builds mais rápidos)

## Configurações Aplicadas

### 1. Otimizações de Compilação ARM64

O `runner/CMakeLists.txt` foi modificado para incluir flags de otimização específicas para ARM64 quando compilando para Android:

```cmake
-O3                          # Máxima otimização
-march=armv8-a              # Arquitetura ARMv8
-mtune=cortex-a76           # Otimizado para CPUs similares ao Snapdragon 870
-ffast-math                 # Otimizações agressivas de matemática
-fomit-frame-pointer        # Remove frame pointer para ganho de performance
```

### 2. Variáveis de Ambiente de Performance

O `runner/src/main.cpp` foi modificado para definir automaticamente variáveis de ambiente que melhoram a performance no Android:

- `NDS_3D_RENDERER=soft`: Força o uso do software renderer (OpenGL 4.3 compute não funciona no Android)
- `NDS_3D_THREADED=1`: Habilita renderização multithread (ganho de ~16-20%)
- `NDS_CPU_FAST_POLL=1`: Habilita otimização de polling de CPU

### 3. Configuração do CMake

O script de build desativa o compute renderer (incompatível com Android) e usa SDL2:

```cmake
-DNDS_SDL_BACKEND=SDL2
-DNDS_ENABLE_COMPUTE_RENDERER=OFF
-DNDS_ENABLE_PCAP_BACKEND=OFF
```

## Como Compilar

### Usando o script fornecido

```bash
cd /media/windroid/SSD KING/Recomp-NDS/ndsrecomp
./build_android.sh /caminho/para/android-ndk
```

### Manualmente

```bash
cd /media/windroid/SSD KING/Recomp-NDS/ndsrecomp

cmake -S runner -B runner/build-android \
    -DCMAKE_TOOLCHAIN_FILE=/caminho/para/ndk/build/cmake/android.toolchain.cmake \
    -DANDROID_ABI=arm64-v8a \
    -DANDROID_PLATFORM=android-24 \
    -DANDROID_STL=c++_shared \
    -DCMAKE_BUILD_TYPE=Release \
    -DNDS_SDL_BACKEND=SDL2 \
    -DNDS_ENABLE_COMPUTE_RENDERER=OFF \
    -DNDS_ENABLE_PCAP_BACKEND=OFF

cmake --build runner/build-android -j$(nproc)
```

## Integração no Projeto Android

### 1. Copiar as bibliotecas

Após o build, copie as bibliotecas geradas para o seu projeto Android:

```bash
cp runner/build-android/libnds_runner.so app/src/main/jniLibs/arm64-v8a/
```

Você também precisará das dependências SDL2 e outras bibliotecas necessárias.

### 2. Carregar a biblioteca no Java/Kotlin

```java
static {
    System.loadLibrary("nds_runner");
}
```

### 3. Chamar o main do runner

As variáveis de ambiente já são definidas automaticamente no código C++, então você não precisa configurá-las no Java/Kotlin.

## Performance Esperada

Com estas otimizações aplicadas no seu Snapdragon 870 com Adreno 650:

- **Sem otimizações**: ~20-30 FPS (software renderer single-thread)
- **Com otimizações**: ~40-50 FPS (software renderer multithread + flags de compilação)

Note que o software renderer ainda é limitado pela CPU. Para performance máxima (60 FPS), seria necessário portar o compute renderer para Vulkan, o que exigiria trabalho significativo de desenvolvimento.

## Solução de Problemas

### Build falha com erro de OpenGL

Se você ver erros relacionados a OpenGL 4.3, certifique-se de que `NDS_ENABLE_COMPUTE_RENDERER=OFF` está definido no CMake.

### Jogo ainda está lento

Verifique no log se as variáveis de ambiente foram definidas corretamente:

```
Renderer: soft, Threaded: 1
```

Se não estiverem, você pode forçá-las no seu código Java/Kotlin antes de carregar a biblioteca:

```java
ProcessBuilder pb = new ProcessBuilder();
Map<String, String> env = pb.environment();
env.put("NDS_3D_RENDERER", "soft");
env.put("NDS_3D_THREADED", "1");
env.put("NDS_CPU_FAST_POLL", "1");
```

### Verificar otimizações de compilação

Durante o build, você deve ver:

```
-- Android ARM64 optimizations enabled for arm64-v8a
```

Se não aparecer, verifique se `ANDROID` está definido corretamente no CMake.

## Referências

- [ISSUES.md](ISSUES.md) - Detalhes sobre otimizações de performance implementadas
- [BUILD_PERFORMANCE.md](docs/BUILD_PERFORMANCE.md) - Configurações de build
- [README.md](README.md) - Documentação geral do projeto
