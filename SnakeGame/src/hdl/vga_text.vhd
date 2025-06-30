library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VGA_text is
    generic(
        MAX_WIDTH  : natural := 80;
        MAX_HEIGHT : natural := 30;
        FOOD_COLOR : std_logic_vector (7 downto 0) := "00000100");
    port(
        i_clockVga : in std_logic; -- (25MHz)
        i_clockMem : in std_logic; -- VGA clock * 2 (50MHz)
        i_nrst   : in std_logic;
        i_wen    : in std_logic;
        i_addr   : in std_logic_vector (11 downto 0);
        i_dataW  : in std_logic_vector(15 downto 0);
        o_dataR  : out std_logic_vector(15 downto 0);
        o_syncH  : out std_logic;
        o_syncV  : out std_logic;
        o_blankH : out std_logic;
        o_blankV : out std_logic;
        o_colorR : out std_logic_vector(4 downto 0);
        o_colorG : out std_logic_vector(5 downto 0);
        o_colorB : out std_logic_vector(4 downto 0));
end entity VGA_text;

architecture behavioral of VGA_text is
    constant DISPLAY_WIDTH : natural := 80;
    constant DISPLAY_HEIGHT : natural := 30;

    -- RGB565 palette table
    type Color_t is array (0 to 15) of std_logic_vector(15 downto 0);
    signal palleteColor: Color_t := (
        0 => x"0000", -- black
        1 => x"001F", -- blue
        2 => x"07E0", -- green
        3 => x"07FF", -- cyan
        4 => x"F800", -- red
        5 => x"F81F", -- magenta 
        6 => x"FFE0", -- yellow
        7 => x"2104", -- dark gray
        8 => x"8C51", -- gray
        9 => x"CE59", -- light gray
        15 => x"FFFF", -- white
        others => x"FFFF");

    signal palleteAddr: natural range 0 to 31;

    signal vgaBlank         : std_logic;
    signal pixelX, pixelY   : integer;
    signal textAddr         : std_logic_vector (11 downto 0);
    signal textData, textDataM : std_logic_vector(15 downto 0);
    signal charAddr          : std_logic_vector (11 downto 0);
    signal charData          : std_logic_vector(0 to 7);

    signal vgaColor         : std_logic_vector(15 downto 0);

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
            i_clock  : in std_logic;
            i_nrst   : in std_logic;
            o_syncH  : out  std_logic;
            o_syncV  : out  std_logic;
            o_blankH : out  std_logic;
            o_blankV : out  std_logic;
            o_pixelX : out  integer;
            o_pixelY : out  integer);
    end component VGA_sync;

    component VideoRAM
        port
        (
            address_a : in std_logic_vector (11 downto 0);
            address_b : in std_logic_vector (11 downto 0);
            clock     : in std_logic;
            data_a    : in std_logic_vector (15 downto 0);
            data_b    : in std_logic_vector (15 downto 0);
            wren_a    : in std_logic  := '0';
            wren_b    : in std_logic  := '0';
            q_a       : out std_logic_vector (15 downto 0);
            q_b       : out std_logic_vector (15 downto 0)
        );
    end component;

    component FontROM
        port (
            address : in std_logic_vector (11 downto 0);
            clock   : in std_logic;
            q       : out std_logic_vector (7 downto 0));
    end component;
begin
    vgaSync_inst : VGA_sync
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
            i_clock    => i_clockVga,
            i_nrst	   => i_nrst,
            o_blankH   => o_blankH,
            o_blankV   => o_blankV,
            o_syncH    => o_syncH,
            o_syncV    => o_syncV,
            o_pixelX   => pixelX,
            o_pixelY   => pixelY);

    videoRAM_inst : VideoRAM
        port map (
            clock     => i_clockMem,
            address_a => textAddr,
            address_b => i_addr,
            wren_a    => '0',
            wren_b    => i_wen,
            data_a    => (others=>'0'),
            data_b    => i_dataW,
            q_a       => textData,
            q_b       => o_dataR);

    fontROM_inst : FontROM 
        port map (
            clock   => i_clockMem,
            address => charAddr,
            q       => charData);

    process (i_clockVga, i_nrst) is
        variable prePosX      : integer;
        variable textX, textY : integer;
        variable charCode     : integer range 0 to 255;
        variable charX, charY : integer;
        variable textAddrC : std_logic_vector (11 downto 0);
    begin
        if rising_edge(i_clockVga) and i_nrst = '1' then
            prePosX := (pixelX+8) mod 8; -- precalculate one cell before
            
            textX := (pixelX+3)/8; -- precalculate at least three pixels before
            textY := pixelY/16;
            
            charX := (pixelX+1) mod 8; -- precalculate one pixel before
            charY := pixelY mod 16;
            
            textAddrC := std_logic_vector(to_unsigned(textY*DISPLAY_WIDTH + textX, 12));

            if prePosX = 5 then
                textAddr <= textAddrC;
            elsif prePosX = 6 then
                charCode := to_integer(unsigned(textData(7 downto 0)));
                charAddr <= std_logic_vector(to_unsigned(charCode*16 + charY, 12));
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

    vgaBlank <= o_blankH or o_blankV;
    
    o_colorR <= vgaColor(15 downto 11) when vgaBlank = '0' else "00000";
    o_ColorG <= vgaColor(10 downto 5) when vgaBlank = '0' else "000000";
    o_ColorB <= vgaColor(4 downto 0) when vgaBlank = '0' else "00000";

end architecture behavioral;
