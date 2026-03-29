------------------------------------------------------------------------
-- Module:      fsm_controller.vhd
-- Description: Finite State Machine that controls the ALU data flow.
--              Sequentially captures the operation code, operand A,
--              and operand B from the same 4-bit switch input, using
--              a debounced button press to advance through states.
--              After capturing all inputs, it triggers ALU computation
--              and holds the result on the outputs.
-- Target:      Xilinx Spartan 3
------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity fsm_controller is
    port (
        clk         : in  STD_LOGIC;               -- System clock
        rst         : in  STD_LOGIC;               -- Asynchronous reset (active high)
        btn_pulse   : in  STD_LOGIC;               -- Debounced single-cycle button pulse
        switches    : in  STD_LOGIC_VECTOR(3 downto 0);  -- 4-bit switch input

        op_code     : out STD_LOGIC_VECTOR(3 downto 0);  -- Captured operation code
        operand_a   : out STD_LOGIC_VECTOR(3 downto 0);  -- Captured first operand
        operand_b   : out STD_LOGIC_VECTOR(3 downto 0);  -- Captured second operand
        alu_enable  : out STD_LOGIC;                      -- High when result is valid
        state_out   : out STD_LOGIC_VECTOR(2 downto 0)    -- Current state encoding (for debug LEDs)
    );
end fsm_controller;

architecture Behavioral of fsm_controller is

    -- State enumeration for the control FSM
    type state_type is (
        S_WAIT_OP,      -- Waiting for user to set operation code
        S_WAIT_A,       -- Waiting for user to set operand A
        S_WAIT_B,       -- Waiting for user to set operand B
        S_SHOW_RESULT   -- Result computed and displayed
    );

    signal current_state : state_type := S_WAIT_OP;

    -- Internal registered copies of captured values
    signal reg_op   : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal reg_a    : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal reg_b    : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');

begin

    -- Main FSM process (synchronous with async reset)
    process(clk, rst)
    begin
        if rst = '1' then
            current_state <= S_WAIT_OP;
            reg_op <= (others => '0');
            reg_a  <= (others => '0');
            reg_b  <= (others => '0');
        elsif rising_edge(clk) then
            case current_state is

                when S_WAIT_OP =>
                    -- User sets switches to desired op code, then presses button
                    if btn_pulse = '1' then
                        reg_op <= switches;
                        current_state <= S_WAIT_A;
                    end if;

                when S_WAIT_A =>
                    -- User sets switches to operand A, then presses button
                    if btn_pulse = '1' then
                        reg_a <= switches;
                        current_state <= S_WAIT_B;
                    end if;

                when S_WAIT_B =>
                    -- User sets switches to operand B, then presses button
                    if btn_pulse = '1' then
                        reg_b <= switches;
                        current_state <= S_SHOW_RESULT;
                    end if;

                when S_SHOW_RESULT =>
                    -- Result is displayed; pressing button restarts the cycle
                    if btn_pulse = '1' then
                        current_state <= S_WAIT_OP;
                    end if;

                when others =>
                    current_state <= S_WAIT_OP;

            end case;
        end if;
    end process;

    -- Output assignments
    op_code   <= reg_op;
    operand_a <= reg_a;
    operand_b <= reg_b;
    alu_enable <= '1' when current_state = S_SHOW_RESULT else '0';

    -- State encoding for debug/status LEDs
    with current_state select
        state_out <= "000" when S_WAIT_OP,
                     "001" when S_WAIT_A,
                     "010" when S_WAIT_B,
                     "011" when S_SHOW_RESULT,
                     "111" when others;

end Behavioral;
