library IEEE;

use IEEE.STD_LOGIC.1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- =========================================================================
-- DEBAUNCER
-- =========================================================================

entity debauncer is
    port (
        -- INPUT
        clk         : in STD_LOGIC; -- Clock de 50 Mhz da placa, para saber qunado o botão "parou" de vibrar.
        rst         : in STD_LOGIC; -- Botão de reset. Reinicia o código todo.
        btn_in      : in STD_LOGIC; -- Botão de entrada de sinal

        --OUTPUT
        btn_pulse   : out STD_LOGIC; -- Saida de sinal para a placa, saida já limpa
    );
end debauncer;

architecture Behavioral of debauncer is
    constant MAX_COUNT : interger := 1_000_000;                     -- Tempo que o circuito vai esperar até ter certeza que parou de trpidar
    signal sync : std_logic_vector (1 downto 0) := (others => '0'); -- Barramento de 2 bits, garante que o aperto seja lido ritmica, a placa altera rapidante energia entre 1 e 0, e essees dois FFs vai fazer a limpagem, (others => '0') essa parte garante que quando ligar a placa seja 00.
    signal btn_stable : std_logic := '0';                           -- Linha de conexão entre componentes que inicializa em 1, ele limpa  efiltra o botão, passando a ser 1 qunado tem 100% de certeza que foi pressionado o btn

 -- MAIS CÓDIGO POR VIRM















-- ULA - SELEÇÃO DE OPERAÇÃO ADIÇÃO, SUBTRAÇÃO, AND, OR, NOT, XOR, SHIFT L, SHIFT R
-- ULA - OPERATION SELECTION ADD, SUB, AND, OR, NOT, XOR, SHIFT_L, SHIFT_R

entity ULA is
    port (
        -- ENTRADAS / INPUT
        op        :  in STD_LOGIC_VECTOR (2 downto 0); -- OPERATION SELECTION 3 BIT, 000, 001, 010, 011, 100, 101, 110 ,111
        a         :  in STD_LOGIC_VECTOR (3 downto 0); -- NUMBER IN BINARY
        b         :  in STD_LOGIC_VECTOR (3 downto 0); -- NUMBER IN BINARY

        -- SAIDAS / OUTPUT
        result    :  out STD_LOGIC_VECTOR (3 downto 0); -- RESULT NUMBER IN BINARY
        flag_z    :  out std_logic; -- FLAG RESULT NUMBER 0
        flag_n    :  out std_logic; -- FLAG RESULT NUMBER NEGATIV
        flag_c    :  out std_logic; -- FLAG CARRY OUT
        flag_ov   :  out std_logic; -- FLAG OVERFLOW
end ULA;

architecture Behavioral of ULA is
    signal rest5 : STD_LOGIC_VECTOR (4 downto 0); -- CAPTURE THE CARRY AND SHIFT OUT IN 4 BIT

process(a, b, op)
    variable ext_a              : unsigned (4 downto 0); -- Turn 4 bit into 5 bit
    variable ext_b              : unsigned (4 downto 0); -- Turn 4 bit into 5 bit
    variable tempResult         : unsigned (4 downto 0); -- Turn 4 bit into 5 bit

begin
    ext_a      := unsigned ('0' & a);       -- Concatenarion, places a '0' in front of every bit
    ext_b      := unsigned ('0' & a);       -- Concatenarion, places a '0' in front of every bit
    tempResult := unsigned (others => '0'); -- Take note of the result before send to the LEDS, "(others => '0')" this part will turn every bit in 0. This part of the code serves to avoid unwanted memory, trash;

    case op is

        -- Soma a complemento de 2
        when "000" => tempResult := ext_a + ext_b;   

        -- Subtração a complemento de 2, COMPLEMENTO A 2: A + (-B) + 1, to_unsigned (1, 5) representa a soma +1, gera um valor número 1 de tamanho de 5 bits
        when "001" => tempResult := ext_a + (NOT ext_b) + to_unsigned (1, 5); 
        
        -- AND, '0' & Faz a concatenação obrigando a ter 5 bits, (unsigned(a) AND unsigned(b)) compara bit a bit, bit 0 de A com o bit 0 de B
        when "010" => tempResult := '0' & (unsigned(a) AND unsigned(b)); 

        -- OR, '0' & Faz a concatenação obrigando a ter 5 bits, (unsigned(a) AND unsigned(b)) compara bit a bit, bit 0 de A com o bit 0 de B
        when "011" => tempResult := '0' & (unsigned(a) OR unsigned(b));

        -- CONTIAR AS OUTRAS OPERAÇÕES

    end case;

    rest5 <= std_logic_vector(tempResult); -- Act as a output signal, electric signal

end process;

-- OUTPUT

--resultado de 4 bits vai receber o sinal
result <= rest5 (3 downto 0);

--FLAG DE 0 - quando o resultado for 0000, ou seja, todos os bits sao 0
flag_z <= '1' when rest5 (3 downto 0) = "0000" else '0';

-- FLAG DE NUMEROS NEGATIVOS - quando o resultado da operação tem como resultado numeros negativos e necessita do complemento de 2
flag_n <=  rest5 (3);

--FLAG DE CARRY - quando necessitar do carry (vai um), a sequencia é ativa nos leds


-- FMS - CONTROLE DE MEMÓRIA  



-- TOP_LEVEL PINAGE
end Behavioral;