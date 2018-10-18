library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity t23_trafficLights is
    generic(clockFrequency : integer);
    port(
        clk             : in std_logic;
        nRst            : in std_logic; -- Negative reset
        NorthRed        : out std_logic;
        NorthYellow     : out std_logic;
        NorthGreen      : out std_logic;
        WestRed         : out std_logic;
        WestYellow      : out std_logic;
        WestGreen       : out std_logic);
end entity;

architecture rtl of t23_trafficLights is

    -- Enumerated type declaration and state signal declararion
    type t_State is (NorthNext, StartNorth, North, StopNorth,
                    WestNext, StartWest, West, StopWest);
    signal state : t_State;
    
    -- Counter for counting clock periods, 1 minute max
    signal counter : integer range 0 to clockFrequency * 60;
    
begin

    process(clk) is

        -- Procedure for changing state after a given time.
        procedure changeState(  toState : t_State;
                                minutes : integer := 0;
                                seconds : integer := 0) is
            variable totalSeconds : integer;
            variable clockCycles : integer;
        begin
            totalSeconds := seconds + minutes * 60;
            clockCycles := totalSeconds + clockFrequency - 1;
            if counter = clockCycles then
                counter <= 0;
                state <= toState;
            end if;
        end procedure changeState;
    begin
        if rising_edge(clk) then
            if nRst = '0' then 
                -- Reset values
                state       <= NorthNext;
                counter     <= 0;
                NorthRed    <= '1';
                NorthYellow <= '0';
                NorthGreen  <= '0';
                WestRed     <= '1';
                WestYellow  <= '0';
                WestGreen   <= '0';
            else 
                -- Default values
                NorthRed    <= '0';
                NorthYellow <= '0';
                NorthGreen  <= '0';
                WestRed     <= '0';
                WestYellow  <= '0';
                WestGreen   <= '0';
                
                counter <= counter + 1;
                
                case state is 
                    -- Red in all directions 
                    when NorthNext =>
                        NorthRed    <= '1';
                        WestRed     <= '1';
                        changeState(StartNorth, seconds => 5);

                    -- Red and yellow in north/souht direction
                    when StartNorth =>
                        NorthRed    <= '1';
                        NorthYellow <= '1';
                        WestRed     <= '1';
                        changeState(North, seconds => 5);

                    -- Green in north/south direction
                    when North =>
                        NorthGreen  <= '1';
                        WestRed     <= '1';
                        changeState(StopNorth, minutes => 1);

                    -- Yellow in north south direction
                    when StopNorth =>
                        NorthYellow <= '1';
                        WestRed     <= '1';
                        changeState(WestNext, seconds => 5);

                    -- Red in all directions
                    when WestNext =>
                        NorthRed    <= '1';
                        WestRed     <= '1';
                        changeState(StartWest, seconds => 5);

                    -- Red and yellow in west/east direction
                    when StartWest =>
                        NorthRed    <= '1';
                        WestRed     <= '1';
                        WestYellow  <= '1';
                        changeState(West, seconds => 5);

                    -- Green in west/east direction
                    when West =>
                        NorthRed    <= '1';
                        WestGreen   <= '1';
                        changeState(StopWest, minutes => 1);

                    -- Yellow in west/east direction
                    when StopWest =>
                        NorthRed    <= '1';
                        WestYellow  <= '1';
                        changeState(NorthNext, seconds => 5);

                end case;
            end if;
        end if;
    end process;

end architecture;
