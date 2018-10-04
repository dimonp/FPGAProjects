library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity t19_procedureTimerTb is
end entity;

architecture sim of t19_procedureTimerTb is
    constant clockFrequency : integer := 10; -- 10Hz
    constant clockPeriod    : time    := 1000 ms / clockFrequency;

    signal clk      : std_logic := '1';
    signal nRst     : std_logic := '0';
    signal seconds  : integer;
    signal minutes  : integer;
    signal hours    : integer;
begin
    -- The Device Under Test (DUT)
    iTimer : entity work.t19_procedureTimer(rtl)
        generic map(clockFrequency => clockFrequency)
        port map(
            clk     => clk, 
            nRst     => nRst, 
            seconds => seconds, 
            minutes => minutes, 
            hours     => hours);

    -- Process generating the clock
    clk <= not clk after clockPeriod / 2;            
    
    -- Testbench sequence
    process is
    begin
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        
        nRst <= '1';
        
        wait;
    end process;

end architecture;
