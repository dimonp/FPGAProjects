library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity t17_clockProcessTb is
end entity;

architecture sim of t17_clockProcessTb is
    constant clockFrequency : integer := 100e6; -- 100MHz
    constant clockPeriod    : time    := 1000 ms / clockFrequency;

    signal clk      : std_logic := '1';
    signal nRst     : std_logic := '0';
    signal data   	: std_logic := '0';
    signal output0  : std_logic;
begin
    -- The Device Under Test (DUT)
    iFlipFlop : entity work.t17_flipFlop(rtl)
        port map(
            clk => clk,
            nRst => nRst,
            data => data,
            output0 => output0);

    -- Process generating the clock
    clk <= not clk after clockPeriod / 2;            
    
    -- Testbench sequence
    process is
    begin
        -- Take DUT out of reset
        nRst <= '1';

        wait for 20 ns;
        data <= '1';
        wait for 22 ns;
        data <= '0';
        wait for 6 ns;
        data <= '1';
        wait for 20 ns;

        -- Reset DUT
        nRst <= '0';
        wait;
    end process;

end architecture;
