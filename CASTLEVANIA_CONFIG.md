# Configuração do Castlevania: Dawn of Sorrow

## Arquivos Criados

1. **castlevania_dos.toml** - Configuração do jogo para o recompilador
2. **recompile_castlevania.sh** - Script automatizado para recompilar o jogo

## Informações do ROM

- **Nome**: Castlevania: Dawn of Sorrow (USA)
- **SHA-1**: `9d4b6f7e4c473954c763d27c59c33f57b8b2f9f9`
- **Tamanho**: 64 MB
- **Save Type**: EEPROM 64KB

## Como Usar

### Opção 1: Usar o script automatizado (Recomendado)

```bash
cd "/media/windroid/SSD KING/Recomp-NDS/ndsrecomp"
./recompile_castlevania.sh
```

Este script irá:
1. Compilar o recompilador (se necessário)
2. Recompilar o código ARM9 do Castlevania
3. Recompilar o código ARM7 do Castlevania
4. Gerar os bancos em `generated/`

### Opção 2: Manualmente

#### Passo 1: Compilar o recompilador

```bash
cd "/media/windroid/SSD KING/Recomp-NDS/ndsrecomp"
cmake -G Ninja -B recompiler/build recompiler
cmake --build recompiler/build
```

#### Passo 2: Recompilar o jogo

```bash
# ARM9 (processador principal)
./recompiler/build/nds_recompile \
  --config castlevania_dos.toml \
  --bin "/media/windroid/SSD KING/Recomp-NDS/Castlevania - Dawn of Sorrow .nds" \
  --out generated \
  --bank castlevania_arm9

# ARM7 (sub-processador)
./recompiler/build/nds_recompile \
  --config castlevania_dos.toml \
  --bin "/media/windroid/SSD KING/Recomp-NDS/Castlevania - Dawn of Sorrow .nds" \
  --out generated \
  --bank castlevania_arm7 \
  --cpu arm7
```

## Limitações Importantes

⚠️ **Esta é uma configuração mínima.** O function finder (descobridor de funções) automático pode não encontrar todas as funções necessárias para o jogo funcionar perfeitamente.

### Possíveis Problemas

1. **Funções não encontradas**: O descobridor automático pode perder funções que são chamadas indiretamente
2. **Código auto-modificável**: Se o jogo modificar código em tempo de execução, pode não funcionar
3. **CRC do save**: Castlevania usa CRC para proteger o save data (veja nota abaixo)

### Como Resolver Problemas

Se o jogo não funcionar após a recompilação:

1. **Verificar logs**: O recompilador gera logs que mostram quantas funções foram encontradas
2. **Análise manual**: Use Ghidra ou outra ferramenta para analisar o ROM e adicionar entry points manualmente
3. **Comparar com jogos funcionais**: Veja as configurações de SM64DS, Mario Kart DS, etc. como referência

## CRC do Save Data

Castlevania: Dawn of Sorrow usa o BIOS SWI CRC para proteger o save data. Isso pode causar problemas se você trocar entre BIOS diferentes. Veja a discussão em:
- https://drastic-ds.com/viewtopic.php?t=4243

## Próximos Passos Após Recompilação

Depois de gerar os bancos com sucesso:

1. **Compilar o runner Android**:

```bash
./build_android.sh /caminho/para/android-ndk
```

2. **Integrar no seu projeto Android**:

```bash
cp runner/build-android/libnds_runner.so app/src/main/jniLibs/arm64-v8a/
```

3. **Criar arquivo game.toml** no diretório do seu app Android:

```toml
[game]
sha1 = "9d4b6f7e4c473954c763d27c59c33f57b8b2f9f9"

[cartridge]
save_type = "eeprom"
save_size = 65536
```

## Suporte

Se encontrar problemas:

1. Verifique o arquivo `ISSUES.md` para problemas conhecidos
2. Consulte `docs/` para documentação técnica
3. Revise `PRINCIPLES.md` e `DEBUG.md` para diretrizes de desenvolvimento

## Notas Técnicas

O ndsrecomp é um projeto experimental em estágio early pre-alpha (v0.6.10). Não há garantia de compatibilidade com todos os jogos. Os jogos demonstrados (SM64DS, Mario Kart DS, Metroid Prime Hunters) passaram por extensa análise e teste manual.
