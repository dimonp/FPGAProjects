library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VGA_text is
    port(
        vgaClock : in std_logic; -- (25MHz)
        memClock : in std_logic; -- VGA clock * 2 (50MHz)
        reset    : in std_logic;
        wen      : in std_logic;
        addr     : in natural range 0 to 2400;
        data     : in std_logic_vector(15 downto 0);
        hsync    : out std_logic;
        vsync    : out std_logic;
        rColor   : out std_logic_vector(4 downto 0);
        gColor   : out std_logic_vector(5 downto 0);
        bColor   : out std_logic_vector(4 downto 0));
end entity VGA_text;

architecture behavioral of VGA_text is
    constant DISPLAY_WIDTH : natural := 80;
    constant DISPLAY_HEIGHT : natural := 30;

    component VGA_sync
        generic (
            H_ACTIVE_VIDEO : natural;
            H_FRONT_PORCH  : natural;
            H_SYNC_PULSE   : natural;
            H_BACK_PORCH   : natural;
            V_ACTIVE_VIDEO : natural;
            V_FRONT_PORCH  : natural;
            V_SYNC_PULSE   : natural;
            V_BACK_PORCH   : natural);
        port(
            clk      : in std_logic;
            rst      : in std_logic;
            vgaBlank : out  std_logic;
            vSync    : out  std_logic;
            hSync    : out  std_logic;
            pixelX   : out  integer;
            pixelY   : out  integer);
    end component VGA_sync;

    component Font_ROM
        generic (
            ROM_FILE : string;
            ROM_SIZE : natural);
        port(
            clk     : in std_logic;
            addr    : in natural range 0 to 4095;
            q       : out std_logic_vector(0 to 7));
    end component Font_ROM;

    component Video_RAM
        generic (
            RAM_SIZE : natural;
            RAM_FILE : string
        );
        port(
            clk     : in std_logic;
            raddr   : in natural range 0 to RAM_SIZE-1;
            waddr   : in natural range 0 to RAM_SIZE-1;
            data    : in std_logic_vector(15 downto 0);
            we      : in std_logic;
            q       : out std_logic_vector(15 downto 0));
    end component Video_RAM;

    type Color_t is array (0 to 15) of std_logic_vector(15 downto 0);
    signal palleteColor: Color_t := (
        0 => x"0000", -- black
        1 => x"001F", -- blue
        2 => x"07E0", -- green
        3 => x"07FF", -- cyan
        4 => x"F800", -- red
        5 => x"F81F", -- magenta 
        6 => x"FFE0", -- yellow
        7 => x"FFFF", -- white
       others => x"FFFF");

    signal palleteAddr: natural range 0 to 31;

    signal vgaBlank         : std_logic;
    signal pixelX, pixelY   : integer;
    signal textAddr         : natural;
    signal textData, textData0: std_logic_vector(15 downto 0);
    signal symAddr          : natural;
    signal symData          : std_logic_vector(0 to 7);
    
    signal symX, symX0      : integer;
    signal symY             : integer;

    signal vgaColor     : std_logic_vector(15 downto 0);

begin
    vgaSync : VGA_sync 
        generic map (
            -- 640 x 480 at 60 Hz
            -- Horizontal timing
            H_ACTIVE_VIDEO  => 640,
            H_FRONT_PORCH   => 16,
            H_SYNC_PULSE    => 96,
            H_BACK_PORCH    => 48,
            -- 640 x 480 at 60 Hz
            -- Vertical timing
            V_ACTIVE_VIDEO  => 480,
            V_FRONT_PORCH   => 10,
            V_SYNC_PULSE    => 2,
            V_BACK_PORCH    => 33)
        port map (
            clk      => vgaClock,
            rst		 => reset,
            vgaBlank => vgaBlank,
            vSync    => vsync,
            hSync    => hsync,
            pixelX   => pixelX,
            pixelY   => pixelY);

    videoRAM : Video_RAM
        generic map (
            RAM_SIZE => DISPLAY_WIDTH*DISPLAY_HEIGHT,
            RAM_FILE => "../ram.mif"
        ) 
        port map (
            clk     => memClock,
            raddr   => textAddr,
            waddr   => addr,
            we      => wen,
            data    => data,
            q       => textData);

    fontROM : Font_ROM 
        generic map (
            ROM_FILE => "../8X16.hex",
            ROM_SIZE => 256*16) 
        port map (
            clk   => memClock,
            addr  => symAddr,
            q     => symData);

    process (vgaClock) is
        variable textX, textY : integer;
        variable symCode      : integer range 0 to 255;
    begin
        if rising_edge(vgaClock) then
            textX := (pixelX + 3)/8;
            textY := pixelY/16;

            -- 0
            symX <= (pixelX + 3) mod 8;
            symY <= pixelY mod 16;
            textAddr <= textY*DISPLAY_WIDTH + textX;

            -- 1
            symCode := to_integer(unsigned(textData(7 downto 0)));
            symAddr <= symCode*16 + symY;
            textData0 <= textData; 
            symX0 <= symX;

            -- 2
            if symData(symX0) = '1' then
                vgaColor <= palleteColor(to_integer(unsigned(textData0(11 downto 8))));
            else
                vgaColor <= palleteColor(to_integer(unsigned(textData0(15 downto 12))));
            end if;
        end if;
    end process;

    rColor <= vgaColor(15 downto 11) when vgaBlank = '0' else "00000";
    gColor <= vgaColor(10 downto 5) when vgaBlank = '0' else "000000";
    bColor <= vgaColor(4 downto 0) when vgaBlank = '0' else "00000";

end architecture behavioral;
