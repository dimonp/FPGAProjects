library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity Snake_Game_top is
    port(
        clk         : in std_logic;
        rst         : in std_logic;
        ps2Data     : in std_logic;
        ps2Clock    : in std_logic;
        vgaHs       : out std_logic;
        vgaVs       : out std_logic;
        vgaR        : out std_logic_vector(4 downto 0);
        vgaG        : out std_logic_vector(5 downto 0);
        vgaB        : out std_logic_vector(4 downto 0));

end entity Snake_Game_top;

architecture behavioral of Snake_Game_top is
    constant FIFO_SIZE  : natural := 20;
    constant DONE       : string := "Done!";
    constant DONE_X     : natural := 35;
    constant DONE_Y     : natural := 6;

    constant DISPLAY_WIDTH : natural := 80;
    constant DISPLAY_HEIGHT : natural := 30;

    signal wen      : std_logic := '0';
    signal addr     : std_logic_vector (11 downto 0);
    signal data     : std_logic_vector(15 downto 0);
    signal q        : std_logic_vector(23 downto 0) := (others => '0');
    signal isDone   : boolean := false;
    signal ps2Code  : std_logic_vector(7 downto 0);
    signal snake_xc : natural range 0 to DISPLAY_WIDTH - 1;
    signal snake_yc : natural range 0 to DISPLAY_HEIGHT - 1;

    function calcAddr(x : natural range 0 to DISPLAY_WIDTH-1;
                      y : natural range 0 to DISPLAY_HEIGHT-1) 
            return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(y * 80 + x, 12));
    end function calcAddr;

    component VGA_text
        port (
            clock   : in std_logic;
            reset   : in std_logic;
            wen     : in std_logic;
            addr    : in std_logic_vector (11 downto 0);
            data    : in std_logic_vector(15 downto 0);
            hsync   : out std_logic;
            vsync   : out std_logic;
            r       : out std_logic_vector(4 downto 0);
            g       : out std_logic_vector(5 downto 0);
            b       : out std_logic_vector(4 downto 0));
    end component;
    
    component ps2_keyboard
        port(
            clk          : in  std_logic;
            ps2_clk      : in  std_logic;
            ps2_data     : in  std_logic;
            ps2_code_new : out std_logic;
            ps2_code     : out std_logic_vector(7 downto 0));
    end component;

    component Snake
        port(
            i_clk     : in  std_logic;
            i_rst     : in  std_logic;
            i_ps2Code : in  std_logic_vector(7 downto 0);
            i_brake   : in  natural;
            o_xc      : out natural range 0 to DISPLAY_WIDTH - 1;
            o_yc      : out natural range 0 to DISPLAY_HEIGHT - 1;
            o_data    : out std_logic_vector(15 downto 0));
    end component;
begin
    addr <= calcAddr(snake_xc, snake_yc);

    vgaText_inst : VGA_text port map (
            clock => clk,
            reset => not rst,
            wen   => not q(16),
            addr  => addr,
            data  => data,
            hsync => vgaHs,
            vsync => vgaVs,
            r => vgaR,
            g => vgaG,
            b => vgaB);

    keyboardPs2_inst: component ps2_keyboard
        port map(
            clk          => clk,
            ps2_clk      => ps2Clock,
            ps2_data     => ps2Data,
            ps2_code_new => open,
            ps2_code     => ps2Code
        );
        
    snake_inst: component Snake
        port map(
            i_clk     => q(16),
            i_rst     => not rst,
            i_ps2Code => ps2Code,
            i_brake   => 10,
            o_xc      => snake_xc,
            o_yc      => snake_yc,
            o_data    => data
        );
     
    process(clk) is
    begin
        if rising_edge(clk) then
            q <= q + 1;
        end if;
    end process;

    process(q(20))
        variable idx : natural range 0 to DONE'length-1 := 0;
    begin
        if rising_edge(q(20)) then
            if isDone then -- show done message
                if idx < DONE'length then
                    idx := idx + 1;
                end if;

                --addr <= calcAddr(DONE_X + idx, DONE_Y);
                --data <= "00000010" &  std_logic_vector(to_unsigned(character'pos(DONE(idx)),8));
            end if;
        end if;
    end process;
    
end architecture behavioral;
