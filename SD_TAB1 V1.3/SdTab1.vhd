library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- =========================================================================
-- DEBOUNCE
-- =========================================================================

entity debauncer is
    port (
        -- INPUT
        clk         : in STD_LOGIC; -- 50 MHz clock indicates when the button has stopped vibrating.
        rst         : in STD_LOGIC; -- Reset button. Resets the entire code.
        btn_in      : in STD_LOGIC; -- Signal input button.

        --OUTPUT
        btn_pulse   : out STD_LOGIC -- Signal output to the board.
    );
end debauncer;

architecture Behavioral of debauncer is
    constant MAX_COUNT : integer := 1_000_000;                      -- The time the circuit will wait until it is certain that the vibration has stopped.
    signal sync : std_logic_vector (1 downto 0) := (others => '0'); -- 2-bit bus, ensures the press is read rhythmically, the board quickly alternates energy between 1 and 0, and these two FFs will clean it up, (others => '0') ensures it's 00 on power up.
    signal btn_stable : std_logic := '0';                           -- Connection line between components that initializes at 0, cleans and filters the button, becoming 1 when 100% sure the btn was pressed
    signal btn_prev : std_logic := '0';                             -- Stores the previous state of the button to detect changes
    signal count : integer range 0 to MAX_COUNT := 0;               -- Counter to measure the button's stability time
    
	begin

 -- Stage 1: Two-flip-flop synchronizer
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                sync <= (others => '0'); -- Flip-flops reset
            else
                sync(0) <= btn_in;       -- First flip-flop captures the button signal
                sync(1) <= sync(0);      -- Second flip-flop synchronizes the signal to the clock
            end if;
        end if;
    end process;

 -- Stage 2: Stability counter
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                count <= 0;                     -- Counter reset
                btn_stable <= '0';              -- Stability signal reset
            elsif sync(1) /= btn_stable then    -- Signal changed: count cycles until stable
                if count = MAX_COUNT then
                    btn_stable <= sync(1);      -- Accepts the new level after 20 ms
                    count      <= 0;
                else
                    count <= count + 1;
                end if;
            else
                -- Signal equal to the accepted level: any glitch resets
                count <= 0;
            end if;
        end if;
    end process;

 -- Stage 3: Rising-edge pulse generator
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                btn_prev  <= '0';
                btn_pulse <= '0';
            else
                btn_prev  <= btn_stable;
                btn_pulse <= btn_stable and (not btn_prev); -- Detects 0->1 rising edge
            end if;
        end if;
    end process;

end Behavioral;

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

-- =========================================================================
-- FSM - MEMORY CONTROL  
-- =========================================================================

entity fsm_controller is
    port (
        clk         : in  STD_LOGIC;
        rst         : in  STD_LOGIC;
        btn_pulse   : in  STD_LOGIC;                      -- "Enter" button signal (debounced)
        switches    : in  STD_LOGIC_VECTOR(3 downto 0);   -- The 4 selector switches of the FPGA board

        out_op      : out STD_LOGIC_VECTOR(2 downto 0);   -- Operation output (3 bits for the ALU)
        out_a       : out STD_LOGIC_VECTOR(3 downto 0);   -- Output A (4 bits for the ALU)
        out_b       : out STD_LOGIC_VECTOR(3 downto 0);   -- Output B (4 bits for the ALU)
        state_out   : out STD_LOGIC_VECTOR(1 downto 0)    -- Output to LEDs indicating current state
    );
end fsm_controller;

architecture Behavioral of fsm_controller is

    type state_type is (S_WAIT_OP, S_WAIT_A, S_WAIT_B, S_COMPUTE);
    signal current_state : state_type := S_WAIT_OP;

    signal reg_op   : STD_LOGIC_VECTOR(2 downto 0) := (others => '0'); -- Register for the operation
    signal reg_a    : STD_LOGIC_VECTOR(3 downto 0) := (others => '0'); -- Register for operand A
    signal reg_b    : STD_LOGIC_VECTOR(3 downto 0) := (others => '0'); -- Register for operand B

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                current_state <= S_WAIT_OP;
                reg_op <= (others => '0');
                reg_a  <= (others => '0');
                reg_b  <= (others => '0');
            elsif btn_pulse = '1' then -- State transition occurs on the button pulse
                case current_state is
                    when S_WAIT_OP =>
                            reg_op <= switches(2 downto 0); -- Captures the 3 least significant bits for the operation
                            current_state <= S_WAIT_A;

                    when S_WAIT_A =>
                        reg_a <= switches; -- Captures the 4 bits from the switches for operand A
                        current_state <= S_WAIT_B;

                    when S_WAIT_B =>
                        reg_b <= switches; -- Captures the 4 bits from the switches for operand B
                        current_state <= S_COMPUTE;

                    when S_COMPUTE =>
                        current_state <= S_WAIT_OP; -- After displaying the result, returns to wait for a new operation

                    when others =>
                        current_state <= S_WAIT_OP; -- Protection against invalid states
                end case;
            end if;
        end if;
    end process;

    -- Connects internal registers to outputs
    out_op <= reg_op;
    out_a  <= reg_a;
    out_b  <= reg_b;

    -- Decoder for state LEDs
    with current_state select
        state_out <= "00" when S_WAIT_OP,
                     "01" when S_WAIT_A,
                     "10" when S_WAIT_B,
                     "11" when S_COMPUTE,
                     "00" when others;

end Behavioral;

-- =========================================================================
-- TOP_LEVEL Pinage
-- =========================================================================

entity top_level is
    port (
        clk         : in  STD_LOGIC;
        rst         : in  STD_LOGIC;
        btn_in      : in  STD_LOGIC;
        switches    : in  STD_LOGIC_VECTOR(3 downto 0);
        led         : out STD_LOGIC_VECTOR(7 downto 0)
    );
end top_level;

architecture Structural of top_level is
--Internal wires

signal w_btn_pulse : STD_LOGIC;
signal w_op_code : STD_LOGIC_VECTOR(2 downto 0);
signal w_operando_a : STD_LOGIC_VECTOR(3 downto 0);
signal w_operando_b : STD_LOGIC_VECTOR(3 downto 0);
signal w_state_out : STD_LOGIC_VECTOR(1 downto 0);
signal w_result : STD_LOGIC_VECTOR(3 downto 0);
signal w_flag_zero : std_logic;
signal w_flag_neg : std_logic;
signal w_flag_carry : std_logic;
signal w_flag_ovf : std_logic;

begin

    --Debouncer instance: filters raw button input 
    U_DEB : entity work.debauncer
        port map (
            clk => clk,
            rst => rst,
            btn_in => btn_in,
            btn_pulse => w_btn_pulse
        );

--FSM Controller instance: manages the state transitions and captures inputs

    U_FSM : entity work.fsm_controller
        port map (
            clk => clk,
            rst => rst,
            btn_pulse => w_btn_pulse,
            switches => switches,
            out_op => w_op_code,
            out_a => w_operando_a,
            out_b => w_operando_b,
            state_out => w_state_out
        );


 --ALU instance: combinational computation
    U_ALU: entity work.ULA
        port map (
            op => w_op_code,
            a => w_operando_a,
            b => w_operando_b,
            result => w_result,
            flag_z => w_flag_zero,
            flag_n => w_flag_neg,
            flag_c => w_flag_carry,
            flag_ov => w_flag_ovf
        );

-- LED Outputs multiplexing
    p_led_mux : process(w_state_out, w_result,
                        w_flag_zero, w_flag_neg, w_flag_carry, w_flag_ovf)
    begin
        if w_state_out = "11" then
            -- RESULT mode (S_COMPUTE): displays results and flags.
            led(3 downto 0) <= w_result;      -- result bits
            led(4)          <= w_flag_zero;   -- Zero flag
            led(5)          <= w_flag_neg;    -- Negative flag
            led(6)          <= w_flag_carry;  -- Carry flag
            led(7)          <= w_flag_ovf;    -- Overflow flag
        else
            -- INPUT mode: displays current status on the 2 lower LEDs.
            --w_state_out = "00" waiting for op | "01" waiting for A | "10" waiting for B
            led(1 downto 0) <= w_state_out;   -- state on LEDs 0 and 1
            led(7 downto 2) <= (others => '0'); -- other LEDs are off
        end if;
    end process p_led_mux;

end Structural;