library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

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