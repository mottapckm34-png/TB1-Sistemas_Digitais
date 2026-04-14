library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--============================================================================
-- TOP_LEVEL PINAGE
--============================================================================
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
            -- Modo RESULTADO (S_COMPUTE): exibe resultado e flags
            led(3 downto 0) <= w_result;      -- bits do resultado
            led(4)          <= w_flag_zero;   -- flag Zero
            led(5)          <= w_flag_neg;    -- flag Negativo
            led(6)          <= w_flag_carry;  -- flag Carry
            led(7)          <= w_flag_ovf;    -- flag Overflow
        else
            -- Modo ENTRADA: exibe estado atual nos 2 LEDs inferiores
            -- w_state_out = "00" aguardando op | "01" aguardando A | "10" aguardando B
            led(1 downto 0) <= w_state_out;   -- estado nos LEDs 0 e 1
            led(7 downto 2) <= (others => '0'); -- demais LEDs apagados
        end if;
    end process p_led_mux;

end Structural;