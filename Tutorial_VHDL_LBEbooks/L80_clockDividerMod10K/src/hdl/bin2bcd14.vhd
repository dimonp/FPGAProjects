-- Example 52: 14-bit Binary-to-BCD converter
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity bin2bcd14 is
    port(
        b : in std_logic_vector(13 downto 0);
        p : out std_logic_vector(16 downto 0));
end entity bin2bcd14;

architecture rtl of bin2bcd14 is
begin
    bcd1 : process (b) is
        variable z : std_logic_vector(32 downto 0);
    begin
        for i in 0 to 32 loop
            z(i) := '0';
        end loop;

        z(16 downto 3) := b;

        for i in 0 to 10 loop
            if z(17 downto 14) > 4 then
                z(17 downto 14) := z(17 downto 14) + 3;
            end if;
            if z(21 downto 18) > 4 then
                z(21 downto 18) := z(21 downto 18) + 3;
            end if;
            if z(25 downto 22) > 4 then
                z(25 downto 22) := z(25 downto 22) + 3;
            end if;
            if z(29 downto 26) > 4 then
                z(29 downto 26) := z(29 downto 26) + 3;
            end if;
            z(32 downto 1) := z(31 downto 0);
        end loop;
        p <= z(30 downto 14);
    end process bcd1;
end architecture rtl;

