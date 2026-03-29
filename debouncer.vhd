------------------------------------------------------------------------
-- Module:      debouncer.vhd
-- Description: Button debouncer using a counter-based approach.
--              Filters out mechanical bounce noise from push-button
--              inputs by requiring the signal to remain stable for
--              a defined number of clock cycles before registering
--              a change. Outputs a single-cycle pulse on the rising
--              edge of the debounced signal.
-- Target:      Xilinx Spartan 3 (50 MHz clock assumed)
------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity debouncer is
    generic (
        -- Number of stable cycles required before accepting input.
        -- At 50 MHz: 500_000 cycles = 10 ms debounce window.
        DEBOUNCE_LIMIT : integer := 500000
    );
    port (
        clk        : in  STD_LOGIC;                -- System clock
        rst        : in  STD_LOGIC;                -- Asynchronous reset (active high)
        btn_in     : in  STD_LOGIC;                -- Raw button input (active high)
        btn_pulse  : out STD_LOGIC                 -- Single-cycle debounced pulse
    );
end debouncer;

architecture Behavioral of debouncer is
    signal counter      : integer range 0 to DEBOUNCE_LIMIT := 0;
    signal btn_stable   : STD_LOGIC := '0';        -- Debounced level
    signal btn_prev     : STD_LOGIC := '0';        -- Previous stable state (for edge detection)
begin

    -- Counter-based debounce process
    process(clk, rst)
    begin
        if rst = '1' then
            counter    <= 0;
            btn_stable <= '0';
            btn_prev   <= '0';
        elsif rising_edge(clk) then
            btn_prev <= btn_stable;

            if btn_in /= btn_stable then
                -- Input differs from current stable state: count up
                if counter = DEBOUNCE_LIMIT then
                    btn_stable <= btn_in;           -- Accept new level
                    counter    <= 0;
                else
                    counter <= counter + 1;
                end if;
            else
                -- Input matches stable state: reset counter
                counter <= 0;
            end if;
        end if;
    end process;

    -- Generate a single-cycle pulse on the rising edge of btn_stable
    btn_pulse <= '1' when (btn_stable = '1' and btn_prev = '0') else '0';

end Behavioral;
