library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity t19_procedureTimer is
    generic(clockFrequency : integer);
    port(
        clk     : in std_logic;
        nRst    : in std_logic; -- Negative reset
        seconds : inout integer;
        minutes : inout integer;
        hours   : inout integer);
end entity;

architecture rtl of t19_procedureTimer is
    signal ticks : integer; -- Signal for counting clock periods
    
    procedure incrementWrap(
        signal counter         : inout    integer;
        constant wrapValue    : in     integer;
        constant enable        : in    boolean;
        variable wrapped    : out    boolean) is
    begin
        if enable then
            if counter = wrapValue-1 then
                wrapped := true;
                counter <= 0;
            else
                wrapped := false;
                counter <= counter + 1;
            end if;
        end if;
    end procedure incrementWrap;
    
begin

    process(clk) is
        variable wrap : boolean;        
    begin
        if rising_edge(clk) then
            -- If negative reset signal is active
            if nRst = '0' then
                ticks <= 0;
                seconds <= 0;
                minutes <= 0;
                hours <= 0;
            else
                -- Cascade counters
                incrementWrap(ticks, clockFrequency, true, wrap);
                incrementWrap(seconds, 60, wrap, wrap);
                incrementWrap(minutes, 60, wrap, wrap);
                incrementWrap(hours, 24, wrap, wrap);
            end if;
        end if;
    end process;

end architecture;
