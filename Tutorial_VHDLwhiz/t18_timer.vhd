library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity t18_timer is
    generic(clockFrequency : integer);
    port(
        clk     : in std_logic;
        nRst    : in std_logic; -- Negative reset
        seconds : inout integer;
        minutes : inout integer;
        hours   : inout integer);
end entity;

architecture rtl of t18_timer is
    signal ticks : integer; -- Signal for counting clock periods
begin

    process(clk) is
    begin
        if rising_edge(clk) then
            -- If negative reset signal is active
            if nRst = '0' then
                ticks <= 0;
                seconds <= 0;
                minutes <= 0;
                hours <= 0;
            else
                -- True once every second
                if ticks = clockFrequency-1 then
                    ticks <= 0;
                    
                    -- True once every minute
                    if seconds = 59 then
                        seconds <= 0;

                        -- True once every hour
                        if minutes = 59 then
                            minutes <= 0;

                            -- True once every day
                            if hours = 23 then
                                hours <= 0;
                            else
                                hours <= hours + 1;
                            end if;

                        else
                            minutes <= minutes + 1;
                        end if;

                    else
                        seconds <= seconds + 1;
                    end if;                    
                else
                    ticks <= ticks + 1; 
                end if;
                
            end if;
        end if;
    end process;

end architecture;
