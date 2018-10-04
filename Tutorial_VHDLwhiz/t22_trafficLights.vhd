library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity t22_trafficLights is
    generic(clockFrequency : integer);
    port(
        clk         : in std_logic;
        nRst        : in std_logic; -- Negative reset
        NorthRed     : out std_logic;
        NorthYellow : out std_logic;
        NorthGreen     : out std_logic;
        WestRed     : out std_logic;
        WestYellow     : out std_logic;
        WestGreen     : out std_logic);
end entity;

architecture rtl of t22_trafficLights is
    
    -- Calcualte the number of clock cycles in minutes/seconds
    function counterVal(
            minutes : integer := 0;
            seconds : integer := 0) return integer is
        variable totalSeconds : integer;                
    begin
        totalSeconds := seconds + minutes * 60;
        return totalSeconds * clockFrequency - 1;
    end function counterVal;
    
    
    -- Enumerated type declaration and state signal declararion
    type t_State is (NorthNext, StartNorth, North, StopNorth,
                    WestNext, StartWest, West, StopWest);
    signal state : t_State;
    
    -- Counter for counting clock periods, 1 minute max
    signal counter : integer range 0 to clockFrequency * 60;
    
begin

    process(clk) is
        impure function counterExpired(
            minutes : integer := 0;
            seconds : integer := 0) return boolean is
        begin
            if counter = counterVal(minutes, seconds) then
                counter <= 0;
                return true;
            else
                return false;                
            end if;
        end function;        
    begin
        if rising_edge(clk) then
            if nRst = '0' then 
                -- Reset values
                state <= NorthNext;
                counter <= 0;
                NorthRed     <= '1';
                NorthYellow <= '0';
                NorthGreen     <= '0';
                WestRed     <= '1';
                WestYellow     <= '0';
                WestGreen     <= '0';
            else 
                -- Default values
                NorthRed     <= '0';
                NorthYellow <= '0';
                NorthGreen     <= '0';
                WestRed     <= '0';
                WestYellow     <= '0';
                WestGreen     <= '0';
                
                counter <= counter + 1;
                
                case state is 
                    -- Red in all directions 
                    when NorthNext =>
                        NorthRed     <= '1';
                        WestRed     <= '1';
                        
                        -- If 5 seconds have passed
                        if counterExpired(seconds => 5) then
                            state <= StartNorth;
                        end if;

                    -- Red and yellow in north/souht direction
                    when StartNorth =>
                        NorthRed     <= '1';
                        NorthYellow <= '1';
                        WestRed     <= '1';

                        -- If 5 seconds have passed
                        if counterExpired(seconds => 5) then
                            state <= North;
                        end if;

                    -- Green in north/south direction
                    when North =>
                        NorthGreen     <= '1';
                        WestRed     <= '1';

                        -- If 1 minute has passed
                        if counterExpired(minutes => 1) then
                            state <= StopNorth;
                        end if;

                    -- Yellow in north south direction
                    when StopNorth =>
                        NorthYellow <= '1';
                        WestRed     <= '1';

                        -- If 5 seconds have passed
                        if counterExpired(seconds => 5) then
                            state <= WestNext;
                        end if;

                    -- Red in all directions
                    when WestNext =>
                        NorthRed     <= '1';
                        WestRed     <= '1';
                        -- If 5 seconds have passed
                        if counterExpired(seconds => 5) then
                            state <= StartWest;
                        end if;

                    -- Red and yellow in west/east direction
                    when StartWest =>
                        NorthRed     <= '1';
                        WestRed     <= '1';
                        WestYellow     <= '1';
                        -- If 5 seconds have passed
                        if counterExpired(seconds => 5) then
                            state <= West;
                        end if;

                    -- Green in west/east direction
                    when West =>
                        NorthRed     <= '1';
                        WestGreen     <= '1';
                        -- If 1 minute has passed
                        if counterExpired(minutes => 1) then
                            state <= StopWest;
                        end if;

                    -- Yellow in west/east direction
                    when StopWest =>
                        NorthRed     <= '1';
                        WestYellow     <= '1';
                        -- If 5 seconds have passed
                        if counterExpired(seconds => 5) then
                            state <= NorthNext;
                        end if;
                end case;
            end if;
        end if;
    end process;

end architecture;
