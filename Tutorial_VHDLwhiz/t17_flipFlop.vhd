library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity t17_flipFlop is
    port(
        clk     : in std_logic;
        nRst    : in std_logic;
        data	: in std_logic;
        output0 : out std_logic);
end entity;

architecture rtl of t17_flipFlop is
begin

    -- Flip-flop with syncronized reset
    process(clk) is
    begin
        if rising_edge(clk) then
            if nRst = '0' then
                output0 <= '0';
            else
                output0 <= data;
            end if;
        end if;
    end process;

end architecture;
