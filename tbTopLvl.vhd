------------------------------------------------------------------------
-- Module:      tb_top_level.vhd
-- Description: Testbench for the complete ALU system.
--              Simulates the full user interaction flow:
--              setting switches, pressing the button, and verifying
--              results on the LED outputs.
--              Uses a short debounce limit for faster simulation.
------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_top_level is
end tb_top_level;

architecture Behavioral of tb_top_level is

    -- Component under test
    component top_level is
        port (
            clk      : in  STD_LOGIC;
            rst      : in  STD_LOGIC;
            switches : in  STD_LOGIC_VECTOR(3 downto 0);
            btn      : in  STD_LOGIC;
            leds     : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;

    -- Testbench signals
    signal tb_clk      : STD_LOGIC := '0';
    signal tb_rst      : STD_LOGIC := '0';
    signal tb_switches : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    signal tb_btn      : STD_LOGIC := '0';
    signal tb_leds     : STD_LOGIC_VECTOR(7 downto 0);

    -- Clock period
    constant CLK_PERIOD : time := 20 ns;  -- 50 MHz

    -- Procedure to simulate a clean button press
    -- (in simulation, debounce counter is set to default;
    --  hold button for sufficient cycles)
    procedure press_button(
        signal btn : out STD_LOGIC;
        constant hold_time : time := 15 ms
    ) is
    begin
        btn <= '1';
        wait for hold_time;
        btn <= '0';
        wait for 5 ms;  -- Wait for button release settling
    end procedure;

begin

    -- Clock generation
    tb_clk <= not tb_clk after CLK_PERIOD / 2;

    -- Device under test
    DUT: top_level
        port map (
            clk      => tb_clk,
            rst      => tb_rst,
            switches => tb_switches,
            btn      => tb_btn,
            leds     => tb_leds
        );

    -- Stimulus process
    stim_proc: process
    begin
        -- ============================================================
        -- Test 1: Addition  3 + 2 = 5 (0011 + 0010 = 0101)
        -- Expected: result=0101, Z=0, N=0, C=0, V=0
        -- ============================================================

        -- Apply reset
        tb_rst <= '1';
        wait for 100 ns;
        tb_rst <= '0';
        wait for 100 ns;

        -- Step 1: Set operation code = "000" (ADD)
        tb_switches <= "0000";
        wait for 100 ns;
        press_button(tb_btn);

        -- Step 2: Set operand A = 3 ("0011")
        tb_switches <= "0011";
        wait for 100 ns;
        press_button(tb_btn);

        -- Step 3: Set operand B = 2 ("0010")
        tb_switches <= "0010";
        wait for 100 ns;
        press_button(tb_btn);

        -- Check result on LEDs
        wait for 1 us;
        assert tb_leds(3 downto 0) = "0101"
            report "TEST 1 FAIL: 3+2 result should be 5" severity ERROR;
        assert tb_leds(4) = '0'
            report "TEST 1 FAIL: Zero flag should be 0" severity ERROR;

        -- ============================================================
        -- Test 2: Subtraction 2 - 5 = -3 (0010 - 0101 = 1101)
        -- Expected: result=1101, Z=0, N=1, C=0, V=0
        -- ============================================================

        -- Press button to return to S_WAIT_OP
        press_button(tb_btn);

        -- Step 1: Set operation code = "001" (SUB)
        tb_switches <= "0001";
        wait for 100 ns;
        press_button(tb_btn);

        -- Step 2: Set operand A = 2 ("0010")
        tb_switches <= "0010";
        wait for 100 ns;
        press_button(tb_btn);

        -- Step 3: Set operand B = 5 ("0101")
        tb_switches <= "0101";
        wait for 100 ns;
        press_button(tb_btn);

        -- Check result on LEDs
        wait for 1 us;
        assert tb_leds(3 downto 0) = "1101"
            report "TEST 2 FAIL: 2-5 result should be -3 (1101)" severity ERROR;
        assert tb_leds(5) = '1'
            report "TEST 2 FAIL: Negative flag should be 1" severity ERROR;

        -- ============================================================
        -- Test 3: AND  1111 AND 1010 = 1010
        -- ============================================================

        press_button(tb_btn);

        tb_switches <= "0010";  -- op = AND
        wait for 100 ns;
        press_button(tb_btn);

        tb_switches <= "1111";  -- A = 15
        wait for 100 ns;
        press_button(tb_btn);

        tb_switches <= "1010";  -- B = 10
        wait for 100 ns;
        press_button(tb_btn);

        wait for 1 us;
        assert tb_leds(3 downto 0) = "1010"
            report "TEST 3 FAIL: F AND A should be A" severity ERROR;

        -- ============================================================
        -- End simulation
        -- ============================================================
        report "=== All tests completed ===" severity NOTE;
        wait;

    end process;

end Behavioral;
