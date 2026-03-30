------------------------------------------------------------------------
-- Module:      alu_4bit.vhd
-- Description: 4-bit Arithmetic and Logic Unit (combinational).
--              Supports 8 operations selected by a 3-bit opcode
--              (only bits 2 downto 0 of op_code are used).
--              Generates 4 status flags: Zero, Negative, Carry, Overflow.
--
-- Operation Table:
--   OpCode | Operation           | Description
--   -------+---------------------+-----------------------------------
--    000   | A + B               | Addition (two's complement)
--    001   | A - B               | Subtraction (two's complement)
--    010   | A AND B             | Bitwise AND
--    011   | A OR  B             | Bitwise OR
--    100   | A XOR B             | Bitwise XOR
--    101   | NOT A               | Bitwise complement of A
--    110   | SHL A (by 1)        | Shift left A by 1 position
--    111   | SHR A (by 1)        | Shift right A by 1 position (arithmetic)
--
-- Flag definitions (active high):
--   Zero     (Z) : Result equals "0000"
--   Negative (N) : MSB of result is '1' (negative in two's complement)
--   Carry    (C) : Carry out from addition/subtraction
--   Overflow (V) : Signed overflow on addition/subtraction
--
-- Target: Xilinx Spartan 3
------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity alu_4bit is
    port (
        op_code   : in  STD_LOGIC_VECTOR(3 downto 0);  -- Operation selector (bits 2:0 used)
        operand_a : in  STD_LOGIC_VECTOR(3 downto 0);  -- First operand
        operand_b : in  STD_LOGIC_VECTOR(3 downto 0);  -- Second operand

        result    : out STD_LOGIC_VECTOR(3 downto 0);  -- 4-bit result
        flag_zero : out STD_LOGIC;                      -- Zero flag
        flag_neg  : out STD_LOGIC;                      -- Negative flag
        flag_carry: out STD_LOGIC;                      -- Carry out flag
        flag_ovf  : out STD_LOGIC                       -- Overflow flag
    );
end alu_4bit;

architecture Behavioral of alu_4bit is

    -- Internal signals for computation
    signal sel          : STD_LOGIC_VECTOR(2 downto 0);
    signal res_internal : STD_LOGIC_VECTOR(3 downto 0);
    signal carry_int    : STD_LOGIC;
    signal ovf_int      : STD_LOGIC;

    -- Extended 5-bit signals for carry detection
    signal ext_a        : UNSIGNED(4 downto 0);
    signal ext_b        : UNSIGNED(4 downto 0);
    signal ext_sum      : UNSIGNED(4 downto 0);

begin

    sel <= op_code(2 downto 0);

    -- Extend operands to 5 bits for unsigned carry computation
    ext_a <= '0' & UNSIGNED(operand_a);
    ext_b <= '0' & UNSIGNED(operand_b);

    -- Main ALU combinational logic
    process(sel, operand_a, operand_b, ext_a, ext_b, ext_sum)
    begin
        -- Default values
        res_internal <= (others => '0');
        carry_int    <= '0';
        ovf_int      <= '0';

        case sel is

            -- 000: Addition (A + B)
            when "000" =>
                ext_sum      <= ext_a + ext_b;
                res_internal <= STD_LOGIC_VECTOR(ext_sum(3 downto 0));
                carry_int    <= STD_LOGIC(ext_sum(4));
                -- Signed overflow: both operands same sign, result different sign
                ovf_int <= (not operand_a(3) and not operand_b(3) and STD_LOGIC(ext_sum(3)))
                        or (operand_a(3) and operand_b(3) and not STD_LOGIC(ext_sum(3)));

            -- 001: Subtraction (A - B) via A + (~B) + 1
            when "001" =>
                ext_sum      <= ext_a + (not ext_b) + 1;
                res_internal <= STD_LOGIC_VECTOR(ext_sum(3 downto 0));
                carry_int    <= STD_LOGIC(ext_sum(4));  -- Borrow (inverted carry)
                -- Signed overflow: A positive, B negative (or vice-versa) and result sign wrong
                ovf_int <= (not operand_a(3) and operand_b(3) and STD_LOGIC(ext_sum(3)))
                        or (operand_a(3) and not operand_b(3) and not STD_LOGIC(ext_sum(3)));

            -- 010: Bitwise AND
            when "010" =>
                res_internal <= operand_a and operand_b;

            -- 011: Bitwise OR
            when "011" =>
                res_internal <= operand_a or operand_b;

            -- 100: Bitwise XOR
            when "100" =>
                res_internal <= operand_a xor operand_b;

            -- 101: Bitwise NOT (complement of A)
            when "101" =>
                res_internal <= not operand_a;

            -- 110: Shift Left Logical by 1 (A << 1)
            when "110" =>
                res_internal <= operand_a(2 downto 0) & '0';
                carry_int    <= operand_a(3);  -- Bit shifted out goes to carry

            -- 111: Shift Right Arithmetic by 1 (A >> 1, preserving sign)
            when "111" =>
                res_internal <= operand_a(3) & operand_a(3 downto 1);
                carry_int    <= operand_a(0);  -- Bit shifted out goes to carry

            when others =>
                res_internal <= (others => '0');

        end case;
    end process;

    -- Output assignments
    result     <= res_internal;
    flag_zero  <= '1' when res_internal = "0000" else '0';
    flag_neg   <= res_internal(3);
    flag_carry <= carry_int;
    flag_ovf   <= ovf_int;

end Behavioral;
