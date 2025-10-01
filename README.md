# Processador com Protocolo SPI
## Trabalho 1 - Sistemas Digitais 2025-2 - 01 de Outubro de 2025

### Informações do Projeto
- **Disciplina:** Sistemas Digitais 
- **Professor:** Anderson Domingues
- **Alunos:** Marcelo Henrique Fernandes, Marcelo Vaz Barros, Samy Haileen Chapaca Toapanta

## 1. Descrição do Projeto

Implementação de um processador de 4 estágios (FETCH, DECODE, EXECUTE, WRITE-BACK) com comunicação SPI entre os blocos de execução (ALU, Multiplicador e Barrel Shifter).

## 2. Estrutura do Projeto

```
cpu_spi/
├── cpu/
│   ├── cpu.sv
│   └── tb_cpu.sv
├── memory/
│   ├── single_port_ram_port_if.sv
│   └── single_port_ram.sv
├── regbank/
│   ├── regbank_if.sv
│   └── regbank.sv
└── spi/
    ├── alu_spi.sv
    ├── barrel_shifter.sv
    ├── multiplier.sv
    └── spi_if.sv
```

## 3. Evolução do Desenvolvimento

### Fase 1: Implementação Local
Iniciamos o projeto de forma simplificada, implementando a lógica básica do processador **sem o protocolo SPI**, mas já com as **barreiras temporais** (registradores de pipeline) entre os estágios. Isso permitiu validar a arquitetura geral e o fluxo de dados entre FETCH, DECODE, EXECUTE e WRITE-BACK.

### Fase 2: Integração do SPI
Posteriormente, evoluímos a comunicação para utilizar o **protocolo SPI** na interação com os blocos de execução (ALU, Multiplicador e Barrel Shifter), conforme especificado no enunciado.

## 4. Problema Identificado

Atualmente, o projeto está **travado em um problema crítico relacionado ao SPI**:

- As instruções são **corretamente buscadas** (FETCH) e **decodificadas** (DECODE)
- Porém, **nenhuma instrução gera resultado correto** no banco de registradores
- Mesmo operações básicas como **ADD não funcionam** corretamente
- A origem do problema está nos sinais **MISO/MOSI** do protocolo SPI

Tentamos diversas abordagens para corrigir:
- Verificação da máquina de estados do SPI
- Análise de sincronização dos sinais
- Validação da ordem dos bits transmitidos

Inclusive **solicitamos ajuda ao professor**, mas até o momento não conseguimos resolver o problema.

## 5. Como Executar

1. Abra o Questa/ModelSim
2. No console, navegue até o diretório:
   ```
   cd /caminho/para/cpu_spj
   ```
3. Execute o script de simulação:
   ```
   do sim.do
   ```

## 6. Resultados da Simulação


### Forma de Onda Completa - 1:
<img width="1794" height="736" alt="image" src="https://github.com/user-attachments/assets/91561346-a825-4ab1-8226-1834b799819d" />


### Forma de Onda Completa - 2:
<img width="1797" height="737" alt="image" src="https://github.com/user-attachments/assets/901c63f2-72b6-4a81-9d4b-99e34ce5ec41" />


### Forma de Onda Completa - 3:
<img width="1801" height="537" alt="image" src="https://github.com/user-attachments/assets/28b3e81a-b5ec-4c11-9051-27b544bbaf06" />


---

## 7. Observações

O projeto implementa todas as barreiras temporais e a estrutura do protocolo SPI conforme especificado. O problema atual impede a validação completa das instruções, mas a arquitetura e o fluxo de controle estão implementados.
