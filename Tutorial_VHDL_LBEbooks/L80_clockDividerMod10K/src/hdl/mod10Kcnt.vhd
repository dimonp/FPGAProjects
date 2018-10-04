-- Example 50: 10K clock divider
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity mod10Kcnt is
    port(
        clr     : in std_logic;
        clk     : in std_logic;
        q       : out std_logic_vector(13 downto 0));
end entity mod10Kcnt;

architecture rtl of mod10Kcnt is
    signal count : std_logic_vector(13 downto 0) := (others => '0');    
begin
    -- 10K clock divider
    clock : process (clk, clr) is
    begin
        if clr = '1' then
            count <= (others => '0');
        elsif rising_edge(clk) then
            if conv_integer(count) = 9999 then
                count <= (others => '0');
            else
                count <= count + 1;
            end if;            
        end if;
    end process clock;

    q <= count;

end architecture rtl;

