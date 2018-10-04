library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity t13_concurrentProcsTb is
end entity;

architecture sim of t13_concurrentProcsTb is
    signal uns  : unsigned(5 downto 0) := (others => '0');
    signal mul1 : unsigned(7 downto 0);
    signal mul2 : unsigned(7 downto 0);
    signal mul3 : unsigned(7 downto 0);
begin

    process is
    begin
        uns <= uns + 1;
        wait for 10 ns;
    end process;

    -- Process multiplying uns by 4
    process is
    begin
        mul1 <= uns & "00";
        wait on uns;
    end process;

    -- Equivalent process using sensitivity list
    process(uns) is
    begin
        mul2 <= uns & "00";
    end process;

    -- Equivalent process using a concurent statement
    mul3 <= uns & "00";
        
end architecture;
