library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VGA_text is
    port(
        vgaClock : in std_logic; -- (25MHz)
        sysClock : in std_logic; -- VGA clock * 2 (50MHz)
        nrst     : in std_logic;
        wen      : in std_logic;
        addr     : in natural range 0 to 2400;
        wdata    : in std_logic_vector(15 downto 0);
        hSync    : out std_logic;
        vSync    : out std_logic;
        hBlank   : out std_logic;
        vBlank   : out std_logic;
        rColor   : out std_logic_vector(4 downto 0);
        gColor   : out std_logic_vector(5 downto 0);
        bColor   : out std_logic_vector(4 downto 0));
end entity VGA_text;

architecture behavioral of VGA_text is
    constant DISPLAY_WIDTH : natural := 80;
    constant DISPLAY_HEIGHT : natural := 30;
  
    component VGA_sync
        generic (
            -- Horizontal timing (line)
            H_ACTIVE_VIDEO : natural;
            H_FRONT_PORCH  : natural;
            H_SYNC_PULSE   : natural;
            H_BACK_PORCH   : natural;
            -- Vertical timing (frame)
            V_ACTIVE_VIDEO : natural;
            V_FRONT_PORCH  : natural;
            V_SYNC_PULSE   : natural;
            V_BACK_PORCH   : natural);
        port(
            i_clock  : in std_logic;
            i_nrst   : in std_logic;
            o_syncH  : out  std_logic;
            o_syncV  : out  std_logic;
            o_blankH : out  std_logic;
            o_blankV : out  std_logic;
            o_pixelX : out  integer;
            o_pixelY : out  integer);
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
    signal textData, textDataM : std_logic_vector(15 downto 0);
    signal charAddr         : natural;
    signal charData         : std_logic_vector(0 to 7);
    
    signal vgaColor         : std_logic_vector(15 downto 0);

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
            i_clock  => vgaClock,
            i_nrst   => nrst,
            o_syncV  => vSync,
            o_syncH  => hSync,
            o_blankH => hBlank,
            o_blankV => vBlank,
            o_pixelX => pixelX,
            o_pixelY => pixelY);

    --  Memory cell 16bit:
    --  xxxx_xxxx_xxxxxxxx
    --   bg   fg    char
    -- color color symbol 
    videoRAM : Video_RAM
        generic map (
            RAM_SIZE => DISPLAY_WIDTH*DISPLAY_HEIGHT,
            RAM_FILE => "ram.hex"
        ) 
        port map (
            clk     => sysClock,
            raddr   => textAddr,
            waddr   => addr,
            we      => wen,
            data    => wdata,
            q       => textData);

    fontROM : Font_ROM 
        generic map (
            ROM_FILE => "8X16.hex",
            ROM_SIZE => 256*16) 
        port map (
            clk   => sysClock,
            addr  => charAddr,
            q     => charData);
            
    process (vgaClock) is
        variable prePosX      : integer;
        variable textX, textY : integer;
        variable charCode     : integer range 0 to 255;
        variable charX, charY : integer;
        variable textAddrC : integer;
    begin
        if rising_edge(vgaClock) then
            prePosX := (pixelX+8) mod 8; -- precalculate one cell before
            
            textX := (pixelX+3)/8; -- precalculate at least three pixels before
            textY := pixelY/16;
            
            charX := (pixelX+1) mod 8; -- precalculate one pixel before
            charY := pixelY mod 16;
            
            textAddrC := textY*DISPLAY_WIDTH + textX;

            if prePosX = 5 then
                if textAddrC >= 0 and textAddrC < 2400 then
                    textAddr <= textAddrC;
                end if;
            elsif prePosX = 6 then
                charCode := to_integer(unsigned(textData(7 downto 0)));
                charAddr <= charCode*16 + charY;
                textDataM <= textData;
            end if;
            
            if charData(charX) = '1' then
                -- foreground
                vgaColor <= palleteColor(to_integer(unsigned(textDataM(11 downto 8))));
            else
                -- background
                vgaColor <= palleteColor(to_integer(unsigned(textDataM(15 downto 12))));
            end if;
        end if;
    end process;
    
    vgaBlank <= hBlank or vBlank;
   
    -- get color from palette
    rColor <= vgaColor(15 downto 11) when vgaBlank = '0' else "00000";
    gColor <= vgaColor(10 downto 5) when vgaBlank = '0' else "000000";
    bColor <= vgaColor(4 downto 0) when vgaBlank = '0' else "00000";
   
end architecture behavioral;
