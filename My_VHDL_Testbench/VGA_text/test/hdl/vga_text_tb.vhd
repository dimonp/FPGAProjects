library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VGA_text_Tb is
end entity VGA_text_Tb;

architecture sim of VGA_text_Tb is
    constant CLOCK_FREQUENCY : integer := 50e6; -- 50MHz
    constant CLOCK_PERIOD    : time    := 1000 ms / CLOCK_FREQUENCY;

    component VGA_text
        port ( 
            clock   : in std_logic;
            reset   : in std_logic;
            wen     : in std_logic;
            addr    : in natural range 0 to 2400;
            data    : in std_logic_vector(15 downto 0);
            hsync   : out std_logic;
            vsync   : out std_logic;
            r       : out std_logic_vector(4 downto 0);
            g       : out std_logic_vector(5 downto 0);
            b       : out std_logic_vector(4 downto 0));
    end component;

    signal clk          : std_logic := '0';
begin
    clk <= not clk after CLOCK_PERIOD / 2;

    vgaText_inst : VGA_text port map (
            clock => clk,
            reset => '0',
            wen   => '0',
            addr  => 0,
            data  => (others=>'0'),
            hsync => open,
            vsync => open,
            r => open,
            g => open,
            b => open);

end architecture sim;
