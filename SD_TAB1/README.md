# TB1-Sistemas_Digitais
Trabalho de Sistemas Digitais onde esta sendo criada uma ula de 4 bits que realiza 8 operações usando VHDL

-------------------------------------------------------

INPUT:

op = Seletor de operaç~eso
a  = Valor de A
b  = Valor de B

-------------------------------------------------------

OUTPUT:

result   = Resultado final
flag_z   = Flah para valor 0
flag_n   = Flag números negativos
flag_c   = Flag números Carrry Out
flag_ov  = Flag OverFlow

-------------------------------------------------------

SIGNAL: Conexão interna entre os componentes, não é saida nem entrada

rest5 = Saida para ceceber Carry In, Carry Out EU ACHO 

-------------------------------------------------------

VARIÁVEL

ext_a        = Valor de A em forma binária de 5 vetores 
ext_b        = Valor de B em forma binária de 5 vetores 
tempResult   = Valor temporário armazenado    

-------------------------------------------------------

DEBAUNCER : 

Quando você aperta um botão mecânico, as lâminas metálicas internas quicam entre si por 5 a 20 ms antes de estabilizar. Para um humano isso é imperceptível — mas a FPGA rodando a 50 MHz vê cada quique como um aperto de botão separado. Sem debouncer, cada aperto de botão pode gerar 10, 20 ou 50 transições. A FSM transitaria de estado múltiplas vezes por um único clique — o projeto não funcionaria.

---------------------------------------------------------


# Controlador FSM para ULA (Máquina de Estados Finita)

Este módulo (`fsm_controller.vhd`) implementa um controlador sequencial desenvolvido em VHDL. O objetivo principal deste circuito é atuar como uma interface de entrada para uma Unidade Lógica Aritmética (ULA), utilizando o conceito de **multiplexação no tempo**. 

Em vez de exigir 14 chaves físicas diferentes para inserir uma operação e dois operandos, este controlador reaproveita um único barramento de 4 chaves (`switches`), capturando os dados em etapas sequenciais guiadas pelo usuário através de um botão.

## 🎯 Funcionalidades Principais

* **Multiplexação no Tempo:** Reduz drasticamente a quantidade de pinos de entrada necessários na placa FPGA.
* **Trava de Segurança (Input Validation):** O controlador só avança do primeiro estado se o usuário inserir um código de operação válido (suportado pela ULA). Operações inválidas são ignoradas.
* **Ajuste Automático de Barramento:** Converte automaticamente as entradas físicas de 4 bits para vetores de 5 bits (concatenando um `'0'` à esquerda) para manter a compatibilidade com a arquitetura da ULA.
* **Reset Síncrono:** Maior confiabilidade e proteção contra ruídos elétricos na placa.

## 🔄 Máquina de Estados (FSM)

O controlador avança entre os estados sempre que recebe um pulso limpo de 1 ciclo de clock (`btn_pulse = '1'`).

1. **`S_WAIT_OP` (Estado 00):** Aguarda o usuário inserir o código da operação (Aceita apenas `0000` Soma, `0001` Subtração, `0010` AND, `0011` OR).
2. **`S_WAIT_A` (Estado 01):** Lê as chaves e salva o valor como Operando A (5 bits).
3. **`S_WAIT_B` (Estado 10):** Lê as chaves e salva o valor como Operando B (5 bits).
4. **`S_COMPUTE` (Estado 11):** Congela as saídas, enviando os dados estabilizados para a ULA calcular. O sistema aguarda um novo aperto de botão para reiniciar o ciclo.

## 🔌 Portas de Entrada e Saída (Pinout)

### Entradas (Inputs)
| Nome | Tamanho | Descrição |
| :--- | :--- | :--- |
| `clk` | 1 bit | Sinal de relógio (Clock) do sistema. |
| `rst` | 1 bit | Reset síncrono (Ativo em nível alto '1'). Zera a FSM. |
| `btn_pulse`| 1 bit | Pulso de confirmação do usuário (Deve passar por um Debouncer e Detector de Borda). |
| `switches` | 4 bits | Barramento de chaves físicas da placa para entrada de dados. |

### Saídas (Outputs)
| Nome | Tamanho | Descrição |
| :--- | :--- | :--- |
| `out_op` | 4 bits | Código da operação salvo. Conecta-se à entrada `op` da ULA. |
| `out_a` | 5 bits | Operando A salvo e ajustado. Conecta-se à entrada `a` da ULA. |
| `out_b` | 5 bits | Operando B salvo e ajustado. Conecta-se à entrada `b` da ULA. |
| `state_out`| 2 bits | Saída de debug visual. Conecta-se aos LEDs da placa para indicar o estado atual da FSM. |

## 🛠️ Tecnologias e Target
* **Linguagem:** VHDL (IEEE.STD_LOGIC_1164)
* **Target recomendado:** FPGAs da família Xilinx Spartan-3 (ou similares).

