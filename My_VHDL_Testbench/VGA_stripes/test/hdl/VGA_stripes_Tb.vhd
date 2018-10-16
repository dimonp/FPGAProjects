library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VGA_stripes_Tb is
end entity VGA_stripes_Tb;

architecture sim of VGA_stripes_Tb is
    constant CLOCK_FREQUENCY : integer := 50e6; -- 50MHz
    constant CLOCK_PERIOD    : time    := 1000 ms / CLOCK_FREQUENCY;

    component VGA_stripes
        port
        (
            clk50       :   in std_logic;
            VGA_HSync   :   out std_logic;
            VGA_VSync   :   out std_logic;
            VGA_BlankN  :   out std_logic;
            VGA_Clock   :   out std_logic;
            VGA_SyncN   :   out std_logic;
            VGA_Red     :   out std_logic_vector(4 downto 0);
            VGA_Green   :   out std_logic_vector(5 downto 0);
            VGA_Blue    :   out std_logic_vector(4 downto 0));
    end component;

    signal clk          : std_logic := '0';
    signal vgaClk       : std_logic;
    signal blankN       : std_logic;
    signal syncN        : std_logic;
    signal vgaR         : std_logic_vector(4 downto 0);
    signal vgaG         : std_logic_vector(5 downto 0);
    signal vgaB         : std_logic_vector(4 downto 0);
    signal vSync, hSync : std_logic;
begin
    clk <= not clk after CLOCK_PERIOD / 2;

    vgaStripes : VGA_stripes port map (
            clk50 => clk,
            VGA_HSync => hSync,
            VGA_VSync => vSync,
            VGA_BlankN  => blankN,
            VGA_Clock  => vgaClk,
            VGA_SyncN  => syncN,
            VGA_Red => vgaR,
            VGA_Green => vgaG,
            VGA_Blue => vgaB);

end architecture sim;
