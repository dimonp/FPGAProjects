-- Example 52: clock divider
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity clkdiv is
    port(
        mclk    : in std_logic;
        clr     : in std_logic;
        clk190  : out std_logic;
        clk12   : out std_logic);
end entity clkdiv;

architecture rtl of clkdiv is
    signal q : std_logic_vector(23 downto 0) := (others => '0');
begin
    -- clock divider
    process (mclk, clr) is
    begin
        if clr = '1' then
            q <= x"000000";
        elsif rising_edge(mclk) then
            q <= q + 1;
        end if;
    end process;

    clk12    <= q(21);  -- 12 Hz
    clk190   <= q(17);  -- 190 Hz

end architecture rtl;

