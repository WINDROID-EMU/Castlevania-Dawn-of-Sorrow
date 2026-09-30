# Análise com Ghidra para Configuração Confiável

Este documento descreve como usar o Ghidra para gerar uma configuração 100% confiável para o Castlevania: Dawn of Sorrow.

## Pré-requisitos

1. **Ghidra instalado** (versão 11.0 ou superior recomendada)
   - Download: https://ghidra-sre.org/
   - Instale em um diretório acessível

2. **Python 3** (para scripts auxiliares)

3. **ROM do Castlevania** em:
   ```
   /media/windroid/SSD KING/Recomp-NDS/Castlevania - Dawn of Sorrow .nds
   ```

## Arquivos Criados

### 1. **ghidra/import_castlevania.sh**
Script que:
- Extrai os binários ARM9 e ARM7 do ROM
- Importa cada binário no Ghidra com as configurações corretas
- Executa análise automática do Ghidra
- Exporta listas de funções em JSON

### 2. **tools/ghidra_to_toml.py**
Script Python que converte:
- JSON exportado pelo Ghidra → formato TOML do ndsrecomp
- Preserva endereços, nomes e modos (ARM/Thumb)

### 3. **ghidra/analyze_castlevania.sh**
Script principal que automatiza todo o processo:
1. Executa `import_castlevania.sh`
2. Converte JSON para TOML
3. Gera configuração final `castlevania_dos.toml`

## Como Usar

### Passo 1: Executar análise completa do Ghidra

```bash
cd "/media/windroid/SSD KING/Recomp-NDS/ndsrecomp"
./ghidra/analyze_castlevania.sh /caminho/para/ghidra
```

Exemplo:
```bash
./ghidra/analyze_castlevania.sh /home/user/ghidra_11.0_PUBLIC
```

### O que o script faz:

1. **Extrai binários** do ROM:
   - ARM9 binary (carrega em 0x02000000)
   - ARM7 binary (carrega em 0x03800000)

2. **Importa no Ghidra**:
   - ARM9: `ARM:LE:32:v5t` @ `0x02000000`
   - ARM7: `ARM:LE:32:v4t` @ `0x03800000`

3. **Executa análise automática**:
   - Identificação de funções
   - Análise de ponteiros
   - Descoberta de chamadas
   - Identificação de dados

4. **Exporta funções**:
   - `generated/castlevania_function_starts_arm9.json`
   - `generated/castlevania_function_starts_arm7.json`

5. **Converte para TOML**:
   - `generated/castlevania_arm9_ghidra.toml`
   - `generated/castlevania_arm7_ghidra.toml`

6. **Gera configuração final**:
   - `castlevania_dos.toml` (com todas as funções do Ghidra)

### Passo 2: Recompilar o jogo

```bash
./recompile_castlevania.sh
```

### Passo 3: Compilar para Android

```bash
./build_android.sh /caminho/para/android-ndk
```

## Vantagens da Análise com Ghidra

### 1. **Funções Reais**
- O Ghidra identifica funções através de análise estática
- Entra em funções chamadas indiretamente
- Identifica jump tables e estruturas complexas

### 2. **Nomes Significativos**
- O Ghidra pode nomear funções automaticamente
- Preserva nomes de símbolos se disponíveis
- Facilita debugging futuro

### 3. **Modos Corretos**
- Identifica corretamente ARM vs Thumb
- Trata exception vectors adequadamente
- Reseta alinhamento de instruções

### 4. **Cobertura Completa**
- Analisa todo o código do binário
- Não depende de heurísticas simples
- Mais confiável que discovery automático

## Estrutura do ROM NDS

O script extrai automaticamente:

```
NDS ROM (.nds)
├── Header (0x00000000)
├── ARM9 Binary (offset 0x20)
│   └── Carrega em 0x02000000
├── ARM7 Binary (offset variável)
│   └── Carrega em 0x03800000
└── Data/Assets
```

## Arquivos Gerados

Após executar `analyze_castlevania.sh`:

```
generated/
├── castlevania_function_starts_arm9.json  # Funções ARM9 do Ghidra
├── castlevania_function_starts_arm7.json  # Funções ARM7 do Ghidra
├── castlevania_arm9_ghidra.toml          # Config ARM9 convertida
└── castlevania_arm7_ghidra.toml          # Config ARM7 convertida

castlevania_dos.toml  # Config final (merge + header + cartridge)
```

## Solução de Problemas

### Erro: "Ghidra not found"

Verifique o caminho para o Ghidra:
```bash
ls /caminho/para/ghidra/support/analyzeHeadless
```

No Windows, pode ser:
```bash
ls "C:/ghidra/support/analyzeHeadless.bat"
```

### Erro: "ROM not found"

Verifique se o ROM está no caminho correto:
```bash
ls "/media/windroid/SSD KING/Recomp-NDS/Castlevania - Dawn of Sorrow .nds"
```

### Erro: "Python 3 not found"

Instale Python 3:
```bash
sudo apt install python3  # Linux
# ou use o gerenciador de pacotes do seu sistema
```

### Análise demorada demais

A análise do Ghidra pode levar vários minutos para ROMs grandes. Isso é normal. Seja paciente.

### Funções faltando após análise

Se a análise automática não encontrar todas as funções:

1. Abra o projeto no Ghidra GUI:
   ```bash
   /caminho/para/ghidra/ghidraRun
   ```
2. Abra o projeto `ghidra/Castlevania.gpr`
3. Execute análise manual adicional:
   - Window → Script Manager
   - Execute scripts adicionais se necessário
4. Re-exporte as funções:
   - File → Export Program
   - Ou use o script `export_functions.py` manualmente

## Comparação: Automático vs Ghidra

| Aspecto | Config Automática | Config Ghidra |
|---------|------------------|---------------|
| Confiabilidade | Média | Alta |
| Cobertura | Parcial | Completa |
| Nomes de funções | Genéricos | Significativos |
| Tempo de setup | Rápido | Lento |
| Manutenção | Difícil | Fácil |

## Referências

- **Ghidra**: https://ghidra-sre.org/
- **Documentação ndsrecomp**: docs/
- **Bios analysis**: docs/bios_analysis.md
- **Ghidra scripts**: ghidra/README.md

## Próximos Passos

Após gerar a configuração com Ghidra:

1. **Revise a configuração**:
   ```bash
   cat castlevania_dos.toml
   ```

2. **Recompile o jogo**:
   ```bash
   ./recompile_castlevania.sh
   ```

3. **Teste no Android**:
   ```bash
   ./build_android.sh /caminho/para/ndk
   ```

4. **Se funcionar**: Você tem uma configuração 100% confiável!
5. **Se não funcionar**: Revise a análise no Ghidra GUI e ajuste manualmente
