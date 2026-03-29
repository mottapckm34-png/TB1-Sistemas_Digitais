library IEEE;

use IEEE.STD_LOGIC.1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- DEBAUNCER





-- ULA - SELEÇÃO DE OPERAÇÃO ADIÇÃO, SUBTRAÇÃO, AND, OR, NOT, XOR, SHIFT L, SHIFT R
-- ULA - OPERATION SELECTION ADD, SUB, AND, OR, NOT, XOR, SHIFT_L, SHIFT_R

entity ULA is
    port (
        -- ENTRADAS / INPUT
        op        :  in STD_LOGIC_VECTOR (3 downto 0); -- OPERATION SELECTION 3 BIT, 000, 001, 010, 011, 100, 101, 110 ,111
        a         :  in STD_LOGIC_VECTOR (4 downto 0); -- NUMBER IN BINARY
        b         :  in STD_LOGIC_VECTOR (4 downto 0); -- NUMBER IN BINARY

        -- SAIDAS / OUTOUT
        result    :  out STD_LOGIC_VECTOR (4 downto 0); -- RESULT NUMBER IN BINARY
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
    variable temporaryResult    : unsigned (4 downto 0); -- Turn 4 bit into 5 bit

begin
    ext_a           := unsigned ('0' & a); -- Concatenarion, places a '0' in front of every bit
    ext_b           := unsigned ('0' & a); -- Concatenarion, places a '0' in front of every bit
    temporaryResult := unsigned (others => '0'); -- Take note of the result before send to the LEDS, "(others => '0')" this part will turn every bit in 0. This part of the code serves to avoid unwanted memory, trash;

    case op is
        --Entra as operações
    end case;

    rest5 <= std_logic_vector(temporaryResult); -- Recive 



-- FMS - CONTROLE DE MEMÓRIA  





-- TOP_LEVEL PINAGE