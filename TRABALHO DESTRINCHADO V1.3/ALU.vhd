library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- =========================================================================
-- ALU - OPERATION SELECTION ADDITION, SUBTRACTION, AND, OR, NOT, XOR, SHIFT L, SHIFT R "main" OF THE PROJECT
-- =========================================================================

entity ULA is
    port (
        -- INPUT
        op        :  in STD_LOGIC_VECTOR (2 downto 0); -- OPERATION SELECTION 3 BIT, 000, 001, 010, 011, 100, 101, 110 ,111
        a         :  in STD_LOGIC_VECTOR (3 downto 0); -- NUMBER IN BINARY
        b         :  in STD_LOGIC_VECTOR (3 downto 0); -- NUMBER IN BINARY

        -- SAIDAS / OUTPUT
        result    :  out STD_LOGIC_VECTOR (3 downto 0); -- RESULT NUMBER IN BINARY
        flag_z    :  out std_logic; -- FLAG RESULT NUMBER 0
        flag_n    :  out std_logic; -- FLAG RESULT NUMBER NEGATIV
        flag_c    :  out std_logic; -- FLAG CARRY OUT
        flag_ov   :  out std_logic  -- FLAG OVERFLOW
    );
end ULA;

architecture Behavioral of ULA is
    signal rest5 : STD_LOGIC_VECTOR (4 downto 0); -- CAPTURE THE CARRY AND SHIFT OUT IN 4 BIT

begin

    process(a, b, op)
        variable ext_a              : unsigned (4 downto 0); -- Turn 4 bit into 5 bit
        variable ext_b              : unsigned (4 downto 0); -- Turn 4 bit into 5 bit
        variable tempResult         : unsigned (4 downto 0); -- Turn 4 bit into 5 bit
        variable shift_amt : integer range 0 to 15;          -- NEW: converts operand B to integer to control the amount of shifts
                                                             -- Range 0 to 15 covers all possible values of a 4-bit vector

    begin
        ext_a      := unsigned ('0' & a);       -- Concatenarion, places a '0' in front of every bit
        ext_b      := unsigned ('0' & b);       -- Concatenarion, places a '0' in front of every bit
        tempResult := (others => '0');          -- Take note of the result before send to the LEDS, "(others => '0')" this part will turn every bit in 0. This part of the code serves to avoid unwanted memory, trash;

        case op is

            -- 2's complement addition
            when "000" => tempResult := ext_a + ext_b;   

            -- 2's complement subtraction, 2's COMPLEMENT: A + (-B) + 1, to_unsigned (1, 5) represents the +1 addition, generates a numeric value of 1 with a 5-bit size
            when "001" => tempResult := ext_a + (NOT ext_b) + to_unsigned (1, 5); 
        
            -- AND, '0' & Performs concatenation forcing it to 5 bits, (unsigned(a) AND unsigned(b)) compares bitwise, bit 0 of A with bit 0 of B
            when "010" => tempResult := '0' & (unsigned(a) AND unsigned(b)); 

            -- OR, '0' & Performs concatenation forcing it to 5 bits, (unsigned(a) OR unsigned(b)) compares bitwise, bit 0 of A with bit 0 of B
            when "011" => tempResult := '0' & (unsigned(a) OR unsigned(b));

            -- XOR: bitwise
            when "100" => tempResult := '0' & (unsigned(a) xor unsigned(b));
 
            -- NOT: complement of A (B ignored)
            when "101" => tempResult := '0' & (not unsigned(a));
 
            ----------------------------------------------------------------
            -- SHL: logical shift LEFT
            --
            -- Operand A = number to be shifted
            -- Operand B = number of positions (controlled by shift_amt)
            --
            -- Control logic:
            --   shift_amt converts B to integer.
            --   The case selects which slice of A forms the result and which bit
            --   of A was the last to exit from the left side (goes to carry).
            --
            --   Shift N to the left:
            --     result = a(3-N downto 0) concatenated with N trailing zeros
            --     carry  = a(4-N), the last bit that exited through the MSB
            --
            --   N=0 : no shift, carry=0
            --   N=1 : result = a(2:0) & '0',     carry = a(3)
            --   N=2 : result = a(1:0) & "00",    carry = a(2)
            --   N=3 : result = a(0)  & "000",    carry = a(1)
            --   N=4 : result = "0000",           carry = a(0)
            --   N>4 : result = "0000",           carry = '0'
            -- SHL: shift left — MSB goes to carry (bit 4)
            when "110" =>
                shift_amt := to_integer(unsigned(b));
                case shift_amt is
                    when 0 =>
                        tempResult := '0' & unsigned(a);           -- no shift
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
                        tempResult(4)          := a(0);            -- carry = LSB (last to exit)
                        tempResult(3 downto 0) := (others => '0');
                    when others =>                                 -- N > 4: everything zeroed
                        tempResult := (others => '0');
                end case;
 
            ----------------------------------------------------------------
            -- SHR: logical shift RIGHT
            --
            -- Operand A = number to be shifted
            -- Operand B = number of positions (controlled by shift_amt)
            --
            -- Control logic:
            --   Mirror of SHL, but bits exit from the right side (LSB).
            --
            --   N=0 : no shift, carry=0
            --   N=1 : result = '0' & a(3:1),    carry = a(0)
            --   N=2 : result = "00" & a(3:2),   carry = a(1)
            --   N=3 : result = "000" & a(3),    carry = a(2)
            --   N=4 : result = "0000",          carry = a(3)
            --   N>4 : result = "0000",          carry = '0'
            -- SHR: shift right — LSB goes to carry (bit 4)
            when others =>
                shift_amt := to_integer(unsigned(b));
                case shift_amt is
                    when 0 =>
                        tempResult := '0' & unsigned(a);           -- No shift
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
                        tempResult(4)          := a(3);            -- carry = MSB (last to exit)
                        tempResult(3 downto 0) := (others => '0');
                    when others =>                                 -- N > 4: everything zeroed
                        tempResult := (others => '0');
                end case;

        end case;

        rest5 <= std_logic_vector(tempResult); -- Act as a output signal, electric signal

end process;

-- OUTPUT

-- 4-bit result will receive the signal
result <= rest5 (3 downto 0);

-- ZERO FLAG - when the result is 0000, meaning all bits are 0
flag_z <= '1' when rest5 (3 downto 0) = "0000" else '0';

-- NEGATIVE NUMBERS FLAG - when the operation result is a negative number and requires 2's complement
flag_n <=  rest5 (3);

-- CARRY FLAG - when a carry is needed, the sequence is activated on the LEDs
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