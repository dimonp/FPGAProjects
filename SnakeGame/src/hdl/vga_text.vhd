library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VGA_text is
    generic(
        MAX_WIDTH  : natural := 80;
        MAX_HEIGHT : natural := 30;
        FOOD_COLOR : std_logic_vector (7 downto 0) := "00000100");
    port(
        i_clock  : in std_logic;
        i_reset  : in std_logic;
        i_wen    : in std_logic;
        i_addr   : in std_logic_vector (11 downto 0);
        i_dataW  : in std_logic_vector(15 downto 0);
        o_dataR  : out std_logic_vector(15 downto 0);
        o_hsync  : out std_logic;
        o_vsync  : out std_logic;
        o_r      : out std_logic_vector(4 downto 0);
        o_g      : out std_logic_vector(5 downto 0);
        o_b      : out std_logic_vector(4 downto 0));
end entity VGA_text;

architecture behavioral of VGA_text is
    constant DISPLAY_WIDTH : natural := 80;
    constant DISPLAY_HEIGHT : natural := 30;

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

    signal baseClk          : std_logic;
    signal vgaClk           : std_logic := '0';
    signal vgaBlank         : std_logic;
    signal pixelX, pixelY   : integer;
    signal textAddr         : std_logic_vector (11 downto 0);
    signal textData, textData0, textData1 : std_logic_vector(15 downto 0);
    signal symAddr          : std_logic_vector (11 downto 0);
    signal symData          : std_logic_vector(0 to 7);

    signal symX, symX0, symX1, symX2   : integer;
    signal symY, symY0      : integer;

    signal vgaColor         : std_logic_vector(15 downto 0);

    component ClockGen
        port ( areset   : in std_logic  := '0';
               inclk0   : in std_logic;
               c0       : out std_logic);
    end component;
    
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
            i_rst    : in std_logic;
            o_vgaBlank : out  std_logic;
            o_vSync    : out  std_logic;
            o_hSync    : out  std_logic;
            o_pixelX   : out  integer;
            o_pixelY   : out  integer);
    end component VGA_sync;

    component VideoRAM
        port
        (
            address_a : in std_logic_vector (11 downto 0);
            address_b : in std_logic_vector (11 downto 0);
            clock     : in std_logic  := '1';
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
            clock   : in std_logic  := '1';
            q       : out std_logic_vector (7 downto 0));
    end component;
begin
    clockGen_inst : ClockGen port map (
            areset => i_reset,
            inclk0 => i_clock,
            c0     => baseClk);

    vgaSync_inst : VGA_sync
        generic map (
            -- 640 x 480 at 73 Hz
            -- Horizontal timing
            H_ACTIVE_VIDEO  => 640,
            H_FRONT_PORCH   => 24,
            H_SYNC_PULSE    => 40,
            H_BACK_PORCH    => 128,
            -- 640 x 480 at 73 Hz
            -- Vertical timing
            V_ACTIVE_VIDEO  => 480,
            V_FRONT_PORCH   => 9,
            V_SYNC_PULSE    => 2,
            V_BACK_PORCH    => 29)
        port map (
            i_clock  => vgaClk,
            i_rst	 => i_reset,
            o_vgaBlank => vgaBlank,
            o_vSync    => o_vsync,
            o_hSync    => o_hsync,
            o_pixelX   => pixelX,
            o_pixelY   => pixelY);


    videoRAM_inst : VideoRAM
        port map (
            clock     => baseClk,
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
            clock   => baseClk,
            address => symAddr,
            q       => symData);

    process(baseClk) is
    begin
        if rising_edge(baseClk) then
            vgaClk <= not vgaClk;
        end if;
    end process;


    process (vgaClk, i_reset) is
        variable textX, textY : integer;
        variable symCode      : integer range 0 to 255;
    begin
        if i_reset = '1' then
            vgaColor <= (0 => '1', 1 => '1', 2 => '1', 3 => '1', 4 => '1',others=>'0');
        elsif rising_edge(vgaClk) then
            -- 0
            textX := (pixelX+5)/8;
            textY := pixelY/16;
            symX <= (pixelX+5) mod 8;
            symY <= pixelY mod 16;
            textAddr <= std_logic_vector(to_unsigned(textY*DISPLAY_WIDTH + textX, 12));

            -- 1
            symX0 <= symX;
            symY0 <= symY;

            -- 2
            symX1 <= symX0;
            symCode := to_integer(unsigned(textData(7 downto 0)));
            symAddr <= std_logic_vector(to_unsigned(symCode*16 + symY0, 12));
            textData0 <= textData;

            -- 3
            symX2 <= symX1;
            textData1 <= textData0;

            -- 4
            if symData(symX2) = '1' then
                vgaColor <= palleteColor(to_integer(unsigned(textData1(11 downto 8))));
            else
                vgaColor <= palleteColor(to_integer(unsigned(textData1(15 downto 12))));
            end if;

        end if;
    end process;

    o_r <= vgaColor(15 downto 11) when vgaBlank = '0' else "00000";
    o_g <= vgaColor(10 downto 5) when vgaBlank = '0' else "000000";
    o_b <= vgaColor(4 downto 0) when vgaBlank = '0' else "00000";

end architecture behavioral;
