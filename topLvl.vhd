------------------------------------------------------------------------
-- Module:      top_level.vhd
-- Description: Top-level entity for the 4-bit ALU system.
--              Instantiates and interconnects the debouncer,
--              FSM controller, and ALU modules.
--              Maps physical FPGA pins (switches, button, LEDs)
--              to internal module ports.
--
-- Pin mapping for Xilinx Spartan 3 Starter Kit:
--   SW(3:0)   -> 4 slide switches (operation / operands)
--   BTN       -> Push-button for confirmation
--   LED(3:0)  -> ALU result (4 bits)
--   LED(4)    -> Zero flag
--   LED(5)    -> Negative flag
--   LED(6)    -> Carry flag
--   LED(7)    -> Overflow flag
--
-- Target: Xilinx Spartan 3
------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top_level is
    port (
        clk      : in  STD_LOGIC;                        -- 50 MHz board clock
        rst      : in  STD_LOGIC;                        -- Reset button (active high)
        switches : in  STD_LOGIC_VECTOR(3 downto 0);     -- 4 slide switches
        btn      : in  STD_LOGIC;                        -- Confirm push-button (active high)
        leds     : out STD_LOGIC_VECTOR(7 downto 0)      -- 8 output LEDs
    );
end top_level;

architecture Structural of top_level is

    -- Component declarations
    component debouncer is
        generic (
            DEBOUNCE_LIMIT : integer := 500000
        );
        port (
            clk       : in  STD_LOGIC;
            rst       : in  STD_LOGIC;
            btn_in    : in  STD_LOGIC;
            btn_pulse : out STD_LOGIC
        );
    end component;

    component fsm_controller is
        port (
            clk       : in  STD_LOGIC;
            rst       : in  STD_LOGIC;
            btn_pulse : in  STD_LOGIC;
            switches  : in  STD_LOGIC_VECTOR(3 downto 0);
            op_code   : out STD_LOGIC_VECTOR(3 downto 0);
            operand_a : out STD_LOGIC_VECTOR(3 downto 0);
            operand_b : out STD_LOGIC_VECTOR(3 downto 0);
            alu_enable: out STD_LOGIC;
            state_out : out STD_LOGIC_VECTOR(2 downto 0)
        );
    end component;

    component alu_4bit is
        port (
            op_code   : in  STD_LOGIC_VECTOR(3 downto 0);
            operand_a : in  STD_LOGIC_VECTOR(3 downto 0);
            operand_b : in  STD_LOGIC_VECTOR(3 downto 0);
            result    : out STD_LOGIC_VECTOR(3 downto 0);
            flag_zero : out STD_LOGIC;
            flag_neg  : out STD_LOGIC;
            flag_carry: out STD_LOGIC;
            flag_ovf  : out STD_LOGIC
        );
    end component;

    -- Internal wires
    signal w_btn_pulse  : STD_LOGIC;
    signal w_op_code    : STD_LOGIC_VECTOR(3 downto 0);
    signal w_operand_a  : STD_LOGIC_VECTOR(3 downto 0);
    signal w_operand_b  : STD_LOGIC_VECTOR(3 downto 0);
    signal w_alu_enable : STD_LOGIC;
    signal w_state      : STD_LOGIC_VECTOR(2 downto 0);

    signal w_result     : STD_LOGIC_VECTOR(3 downto 0);
    signal w_flag_zero  : STD_LOGIC;
    signal w_flag_neg   : STD_LOGIC;
    signal w_flag_carry : STD_LOGIC;
    signal w_flag_ovf   : STD_LOGIC;

begin

    -- Debouncer instance: filters raw button input
    U_DEBOUNCE: debouncer
        generic map (
            DEBOUNCE_LIMIT => 500000   -- ~10 ms at 50 MHz
        )
        port map (
            clk       => clk,
            rst       => rst,
            btn_in    => btn,
            btn_pulse => w_btn_pulse
        );

    -- FSM Controller instance: manages input capture sequence
    U_FSM: fsm_controller
        port map (
            clk       => clk,
            rst       => rst,
            btn_pulse => w_btn_pulse,
            switches  => switches,
            op_code   => w_op_code,
            operand_a => w_operand_a,
            operand_b => w_operand_b,
            alu_enable=> w_alu_enable,
            state_out => w_state
        );

    -- ALU instance: combinational computation
    U_ALU: alu_4bit
        port map (
            op_code   => w_op_code,
            operand_a => w_operand_a,
            operand_b => w_operand_b,
            result    => w_result,
            flag_zero => w_flag_zero,
            flag_neg  => w_flag_neg,
            flag_carry=> w_flag_carry,
            flag_ovf  => w_flag_ovf
        );

    -- LED output multiplexing:
    -- When ALU result is active (S_SHOW_RESULT), display result and flags.
    -- Otherwise, display the current FSM state on lower LEDs for user feedback.
    process(w_alu_enable, w_result, w_flag_zero, w_flag_neg,
            w_flag_carry, w_flag_ovf, w_state)
    begin
        if w_alu_enable = '1' then
            -- Result mode: LEDs show result (3:0) and flags (7:4)
            leds(3 downto 0) <= w_result;
            leds(4)          <= w_flag_zero;
            leds(5)          <= w_flag_neg;
            leds(6)          <= w_flag_carry;
            leds(7)          <= w_flag_ovf;
        else
            -- Input mode: show current state on lower LEDs, upper LEDs off
            leds(2 downto 0) <= w_state;
            leds(3)          <= '0';
            leds(7 downto 4) <= (others => '0');
        end if;
    end process;

end Structural;
