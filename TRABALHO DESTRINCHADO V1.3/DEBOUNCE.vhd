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