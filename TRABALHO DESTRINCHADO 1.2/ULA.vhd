library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- =========================================================================
-- ULA - SELEÇÃO DE OPERAÇÃO ADIÇÃO, SUBTRAÇÃO, AND, OR, NOT, XOR, SHIFT L, SHIFT R "main" DO PROJETO
-- =========================================================================

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
        flag_ov   :  out std_logic -- FLAG OVERFLOW
    );
end ULA;

architecture Behavioral of ULA is
    signal rest5 : STD_LOGIC_VECTOR (4 downto 0); -- CAPTURE THE CARRY AND SHIFT OUT IN 4 BIT

begin

    process(a, b, op)
        variable ext_a              : unsigned (4 downto 0); -- Turn 4 bit into 5 bit
        variable ext_b              : unsigned (4 downto 0); -- Turn 4 bit into 5 bit
        variable tempResult         : unsigned (4 downto 0); -- Turn 4 bit into 5 bit
        variable shift_amt : integer range 0 to 15;         -- NEW: converte o operando B em inteiro para controlar a quantidade de shifts
                                                             -- Intervalo 0 a 15 cobre todos os valores possiveis de um vetor de 4 bits

    begin
        ext_a      := unsigned ('0' & a);       -- Concatenarion, places a '0' in front of every bit
        ext_b      := unsigned ('0' & b);       -- Concatenarion, places a '0' in front of every bit
        tempResult := (others => '0');          -- Take note of the result before send to the LEDS, "(others => '0')" this part will turn every bit in 0. This part of the code serves to avoid unwanted memory, trash;

        case op is

            -- Soma a complemento de 2
            when "000" => tempResult := ext_a + ext_b;   

            -- Subtração a complemento de 2, COMPLEMENTO A 2: A + (-B) + 1, to_unsigned (1, 5) representa a soma +1, gera um valor número 1 de tamanho de 5 bits
            when "001" => tempResult := ext_a + (NOT ext_b) + to_unsigned (1, 5); 
        
            -- AND, '0' & Faz a concatenação obrigando a ter 5 bits, (unsigned(a) AND unsigned(b)) compara bit a bit, bit 0 de A com o bit 0 de B
            when "010" => tempResult := '0' & (unsigned(a) AND unsigned(b)); 

            -- OR, '0' & Faz a concatenação obrigando a ter 5 bits, (unsigned(a) AND unsigned(b)) compara bit a bit, bit 0 de A com o bit 0 de B
            when "011" => tempResult := '0' & (unsigned(a) OR unsigned(b));

            -- XOR: bit a bit
            when "100" => tempResult := '0' & (unsigned(a) xor unsigned(b));
 
            -- NOT: complemento de A (B ignorado)
            when "101" => tempResult := '0' & (not unsigned(a));
 
            ----------------------------------------------------------------
            -- SHL: deslocamento logico a ESQUERDA
            --
            -- Operando A = numero que sera deslocado
            -- Operando B = quantidade de casas (controlado por shift_amt)
            --
            -- Logica de controle:
            --   shift_amt converte B para inteiro.
            --   O case seleciona qual fatia de A forma o resultado e qual bit
            --   de A foi o ultimo a sair pelo lado esquerdo (vai para carry).
            --
            --   Deslocamento N para a esquerda:
            --     resultado  = a(3-N downto 0) concatenado com N zeros a direita
            --     carry      = a(4-N), o ultimo bit que saiu pelo MSB
            --
            --   N=0 : sem deslocamento, carry=0
            --   N=1 : resultado = a(2:0) & '0',     carry = a(3)
            --   N=2 : resultado = a(1:0) & "00",    carry = a(2)
            --   N=3 : resultado = a(0)  & "000",    carry = a(1)
            --   N=4 : resultado = "0000",            carry = a(0)
            --   N>4 : resultado = "0000",            carry = '0'
            -- SHL: deslocamento a esquerda — MSB vai para carry (bit 4)
            when "110" =>
                shift_amt := to_integer(unsigned(b));
                case shift_amt is
                    when 0 =>
                        tempResult := '0' & unsigned(a);           -- sem deslocamento
                    when 1 =>
                        tempResult(4)          := a(3);            -- carry = MSB
                        tempResult(3 downto 0) := unsigned(a(2 downto 0) & '0');
                    when 2 =>
                        tempResult(4)          := a(2);            -- carry = bit 2
                        tempResult(3 downto 0) := unsigned(a(1 downto 0) & STD_LOGIC_VECTOR'("00"));
                    when 3 =>
                        tempResult(4)          := a(1);            -- carry = bit 1
                        tempResult(3 downto 0) := unsigned(a(0) & STD_LOGIC_VECTOR'("000"));
                    when 4 =>
                        tempResult(4)          := a(0);            -- carry = LSB (ultimo a sair)
                        tempResult(3 downto 0) := (others => '0');
                    when others =>                                 -- N > 4: tudo zerado
                        tempResult := (others => '0');
                end case;
 
            ----------------------------------------------------------------
            -- SHR: deslocamento logico a DIREITA
            --
            -- Operando A = numero que sera deslocado
            -- Operando B = quantidade de casas (controlado por shift_amt)
            --
            -- Logica de controle:
            --   Espelho do SHL, mas os bits saem pelo lado direito (LSB).
            --
            --   N=0 : sem deslocamento, carry=0
            --   N=1 : resultado = '0' & a(3:1),    carry = a(0)
            --   N=2 : resultado = "00" & a(3:2),   carry = a(1)
            --   N=3 : resultado = "000" & a(3),    carry = a(2)
            --   N=4 : resultado = "0000",           carry = a(3)
            --   N>4 : resultado = "0000",           carry = '0'
            -- SHR: deslocamento a direita — LSB vai para carry (bit 4)
            when others =>
                shift_amt := to_integer(unsigned(b));
                case shift_amt is
                    when 0 =>
                        tempResult := '0' & unsigned(a);           -- sem deslocamento
                    when 1 =>
                        tempResult(4)          := a(0);            -- carry = LSB
                        tempResult(3 downto 0) := unsigned('0' & a(3 downto 1));
                    when 2 =>
                        tempResult(4)          := a(1);            -- carry = bit 1
                        tempResult(3 downto 0) := unsigned(STD_LOGIC_VECTOR'("00") & a(3 downto 2));
                    when 3 =>
                        tempResult(4)          := a(2);            -- carry = bit 2
                        tempResult(3 downto 0) := unsigned(STD_LOGIC_VECTOR'("000") & a(3));
                    when 4 =>
                        tempResult(4)          := a(3);            -- carry = MSB (ultimo a sair)
                        tempResult(3 downto 0) := (others => '0');
                    when others =>                                 -- N > 4: tudo zerado
                        tempResult := (others => '0');
                end case;

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
flag_c <= rest5 (4);

-- FLAG DE OVERFLOW
-- ADD overflow
flag_ov <= 
    -- ADD overflow
        ((NOT (a(3) XOR b(3))) AND (a(3) XOR rest5(3))) when op = "000"
    else
    -- SUB overflow
        ((a(3) XOR b(3)) AND (a(3) XOR rest5(3))) when op = "001" 
    else
        '0'; -- Overflow undefined for logical/shift operations

end Behavioral;