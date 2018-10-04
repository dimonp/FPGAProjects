library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity t21_functionTb is
end entity;

architecture sim of t21_functionTb is
    constant clockFrequency : integer := 100; -- 100Hz
    constant clockPeriod    : time    := 1000 ms / clockFrequency;

    signal clk          : std_logic := '1';
    signal nRst         : std_logic := '0';
    signal NorthRed     : std_logic;
    signal NorthYellow     : std_logic;
    signal NorthGreen     : std_logic;
    signal WestRed         : std_logic;
    signal WestYellow     : std_logic;
    signal WestGreen     : std_logic;
begin
    -- The Device Under Test (DUT)
    iTrafficLights : entity work.t21_trafficLight(rtl)
        generic map(clockFrequency => clockFrequency)
        port map(
            clk         => clk,
            nRst         => nRst,
            NorthRed     => NorthRed,     
            NorthYellow => NorthYellow,
            NorthGreen     => NorthGreen, 
            WestRed     => WestRed,     
            WestYellow     => WestYellow, 
            WestGreen   => WestGreen);

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
