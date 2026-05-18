library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


-- TOP_LEVEL Pinage

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
