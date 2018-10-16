library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Stripes_Gen is
    port(
        pixelClk    : in std_logic;
        blankN      : in std_logic;
        rgb         : out std_logic_vector(15 downto 0));
end entity Stripes_Gen;

architecture rtl of Stripes_Gen is
    constant BAR_WIDTH : natural := 160; -- =1280/8

    signal bar      : unsigned(7 downto 0);
    signal color    : unsigned(2 downto 0) := (others=>'1');
    
    signal red      : std_logic_vector(4 downto 0);
    signal green    : std_logic_vector(5 downto 0);
    signal blue     : std_logic_vector(4 downto 0);
begin
    
    blue <= (others=>'1') when color(0)='1' else (others=>'0');
    red <= (others=>'1') when color(1)='1' else (others=>'0');
    green <= (others=>'1') when color(2)='1' else (others=>'0');
    
    rgb <= (blue & green & red) when blankN='1' else (others=>'0');
    
    process (pixelClk) is
    begin
        if rising_edge(pixelClk) then
            if blankN = '0' then
                bar <= (others=>'0');
                color <= (others=>'1');
            elsif bar < BAR_WIDTH then
                bar <= bar + 1;
            else
                bar <= (others=>'0');
                color <= color - 1;
            end if;
        end if;
    end process;

end architecture rtl;
