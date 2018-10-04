library ieee;
use ieee.std_logic_1164.all;

entity t10_stdLogicTb is
end entity;

architecture sim of t10_stdLogicTb is
    signal signal1   : std_logic := '0';
    signal signal2   : std_logic;
    signal signal3   : std_logic;
    -- '1' - Logic 1
    -- '0' - Logic 0
    -- 'Z' - High impedance
    -- 'W' - Weak signal, can't tell if 0 or 1
    -- 'L' - Weak 0 pulldown
    -- 'H' - Weak 1 pullup
    -- '-' - Don't care
    -- 'U' - Uninitialized
    -- 'X' - Logic Unknown, multiple drivers

begin

    process is
    begin
        wait for 10 ns;
        signal1 <= not signal1;
    end process;
    
    -- Driver A
    process is
    begin
        signal2 <= 'Z';
        signal3 <= '0';
        wait;
    end process;

    -- Driver B
    process(signal1) is
    begin
        if signal1 = '0' then
            signal2 <= 'Z';
            signal3 <= 'Z';
        else
            signal2 <= '1';
            signal3 <= '1';
        end if;
    end process;
        
end architecture;
