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

SIGNAL:

rest5 = Saida para ceceber Carry In, Carry Out EU ACHO 

-------------------------------------------------------

VARIÁVEL

ext_a        = Valor de A em forma binária de 5 vetores 
ext_b        = Valor de B em forma binária de 5 vetores 
tempResult   = Valor temporário armazenado    

-------------------------------------------------------


DEBAUNCER : 

Quando você aperta um botão mecânico, as lâminas metálicas internas quicam entre si por 5 a 20 ms antes de estabilizar. Para um humano isso é imperceptível — mas a FPGA rodando a 50 MHz vê cada quique como um aperto de botão separado. Sem debouncer, cada aperto de botão pode gerar 10, 20 ou 50 transições. A FSM transitaria de estado múltiplas vezes por um único clique — o projeto não funcionaria.