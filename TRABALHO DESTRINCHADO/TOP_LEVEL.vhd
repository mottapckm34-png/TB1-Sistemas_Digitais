library IEEE;

use IEEE.STD_LOGIC.1164.ALL;
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

        result      : out STD_LOGIC_VECTOR(4 downto 0);
        flag_z      : out std_logic;
        flag_n      : out std_logic;
        flag_c      : out std_logic;
        flag_ov     : out std_logic;
        state_out   : out STD_LOGIC_VECTOR(1 downto 0)
    );
end top_level;

architecture Structural of top_level is
-- Componentes
    component debauncer is
        port (
            clk         : in STD_LOGIC;
            rst         : in STD_LOGIC;
            btn_in      : in STD_LOGIC;
            btn_pulse   : out STD_LOGIC
        );
    end component;

    component ULA is
        port (
            op        :  in STD_LOGIC_VECTOR (2 downto 0);
            a         :  in STD_LOGIC_VECTOR (3 downto 0);
            b         :  in STD_LOGIC_VECTOR (3 downto 0);
            result    :  out STD_LOGIC_VECTOR (4 downto 0);
            flag_z    :  out std_logic;
            flag_n    :  out std_logic;
            flag_c    :  out std_logic;
            flag_ov   :  out std_logic
        );
    end component;

    component fsm_controller is
        port (
            clk         : in  STD_LOGIC;
            rst         : in  STD_LOGIC;
            btn_pulse   : in  STD_LOGIC;
            switches    : in  STD_LOGIC_VECTOR(3 downto 0);
            out_op      : out STD_LOGIC_VECTOR(2 downto 0);
            out_a       : out STD_LOGIC_VECTOR(3 downto 0);
            out_b       : out STD_LOGIC_VECTOR(3 downto 0);
            state_out   : out STD_LOGIC_VECTOR(1 downto 0)
        );
    end component;


    --Componentes

componentes fsm_controller is
    port (
        clk         : in  STD_LOGIC;
        rst         : in  STD_LOGIC;
        btn_pulse   : in  STD_LOGIC;
        switches    : in  STD_LOGIC_VECTOR(3 downto 0);
        out_op      : out STD_LOGIC_VECTOR(2 downto 0);
        out_a       : out STD_LOGIC_VECTOR(3 downto 0);
        out_b       : out STD_LOGIC_VECTOR(3 downto 0);
        state_out   : out STD_LOGIC_VECTOR(1 downto 0)
    );
end component;

component alu_4bit is
    port (
        op        :  in STD_LOGIC_VECTOR (2 downto 0);
        a         :  in STD_LOGIC_VECTOR (3 downto 0);
        b         :  in STD_LOGIC_VECTOR (3 downto 0);
        result    :  out STD_LOGIC_VECTOR (4 downto 0);
        flag_z    :  out std_logic;
        flag_n    :  out std_logic;
        flag_c    :  out std_logic;
        flag_ov   :  out std_logic
    );
end component;

--Internal wires

signal w_btn_pulse : STD_LOGIC;
signal w_op_code : STD_LOGIC_VECTOR(3 downto 0);
signal w_operando_a : STD_LOGIC_VECTOR(3 downto 0);
signal w_operando_b : STD_LOGIC_VECTOR(3 downto 0);
signal w_alu_enable : STD_LOGIC;
signal w_state_out : STD_LOGIC_VECTOR(2 downto 0);

signal w_result : STD_LOGIC_VECTOR(4 downto 0);
signal w_flag_zero : std_logic;
signal w_flag_neg : std_logic;
signal w_flag_carry : std_logic;
signal w_flag_ovf : std_logic;


begin

    --Debouncer instance: filters raw button input 
    generic map (
        DEBOUNCE_LIMIT => 500000 -- Adjust this value based on the expected debounce time and clock frequency(10MS at 50MHZ)
    )
    port map (
        clk => clk,
        rst => rst,
        btn_in => btn_in,
        btn_pulse => w_btn_pulse
    )
--FSM Controller instance: manages the state transitions and captures inputs

    U_FSM: fsm_controller
        port map (
            clk => clk,
            rst => rst,
            btn_pulse => w_btn_pulse,
            switches => switches,
            op_op => w_op_code,
            operando_a => w_operando_a,
            operando_b => w_operando_b,
            alu_enable => w_alu_enable,
            state_out => w_state
        );


 --ALU instance: combinational computation
 U_ALU: alu_4bit
    port map (
        op_code => w_op_code,
        operand_a => w_operando_a,
        operand_b => w_operando_b,
        result => w_result,
        flag_zero => w_flag_zero,
        flag_neg => w_flag_neg,
        flag_carry => w_flag_carry,
        flag_ovf => w_flag_ovf
    );

-- LED Outputs multiplexing
-- Whwn ALU result is active (S_SHOW_RESULT), display result and flags, otherwise show state
-- Otherwise, display the current state on the LEDs
    process(w_state, w_result, w_flag_zero, w_flag_neg, w_flag_carry, w_flag_ovf)

    begin


        if w_alu_enable = '1' then
            leds(4 downto 0) <= w_result; -- Display ALU result on LEDs

            leds(4) <= w_flag_zero; -- Display zero flag on LED 4
            leds(5) <= w_flag_neg;  -- Display negative flag on LED 5  
            leds(6) <= w_flag_carry; -- Display carry flag on LED 6
            leds(7) <= w_flag_ovf;  -- Display overflow flag on LED 7
        else

            --Imput mode: show current state on LEDs, upper LEDs off
            leds(3 downto 0) <= w_state_out; -- Display current state
            leds(3) <= '0'; -- Turn off upper LEDs
            leds(7 downto 4) <= (others => '0'); -- Turn off upper LEDs
        end if;
    end process;

end Structural;
