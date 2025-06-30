library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VGA_text_Tb is
end entity VGA_text_Tb;

architecture sim of VGA_text_Tb is
    constant CLOCK_FREQUENCY : integer := 50e6; -- 50MHz
    constant CLOCK_PERIOD    : time    := 1000 ms / CLOCK_FREQUENCY;

    component VGA_text
        port(
            vgaClock : in std_logic; -- (25MHz)
            sysClock : in std_logic; -- VGA clock * 2 (50MHz)
            nrst     : in std_logic;
            wen      : in std_logic;
            addr     : in natural range 0 to 2400;
            data     : in std_logic_vector(15 downto 0);
            qdata    : inout std_logic_vector(15 downto 0);
            hSync    : out std_logic;
            vSync    : out std_logic;
            hBlank   : out std_logic;
            vBlank   : out std_logic;
            rColor   : out std_logic_vector(4 downto 0);
            gColor   : out std_logic_vector(5 downto 0);
            bColor   : out std_logic_vector(4 downto 0));
    end component;

    signal vgaClk          : std_logic := '0';
    signal sysClk          : std_logic := '0';
    signal addr     : natural range 0 to 2400;
    signal data     : std_logic_vector(15 downto 0);

begin
    sysClk <= not sysClk after CLOCK_PERIOD / 2;
    vgaClk <= not vgaClk after CLOCK_PERIOD;

    vgaText_inst : VGA_text port map (
            vgaClock => vgaClk,
            sysClock => sysClk,
            nrst  => '1',
            wen   => '0',
            addr  => addr,
            data  => data,
            hSync => open,
            vSync => open,
            hBlank => open,
            vBlank => open,
            rColor => open,
            gColor => open,
            bColor => open);

end architecture sim;
