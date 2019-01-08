library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.uniform;

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
    constant DISPLAY_WIDTH  : natural := 80;
    constant DISPLAY_HEIGHT : natural := 30;
    constant FIFO_SIZE      : natural := 20;
    constant INITIAL_X      : natural := 40;
    constant INITIAL_Y      : natural := 10;

    signal addr             : std_logic_vector (11 downto 0);
    signal write_data, read_data  : std_logic_vector(15 downto 0);
    signal wen              : std_logic;
    signal cnt              : std_logic_vector(23 downto 0) := (others => '0');

    signal ps2Code : std_logic_vector(7 downto 0);

    signal xc, yc               : natural;
    signal random               : std_logic_vector(15 downto 0);

    signal snake_en, snake_busy : std_logic;
    signal snake_wen            : std_logic;
    signal snake_addr           : std_logic_vector (11 downto 0);
    signal snake_data           : std_logic_vector(15 downto 0);
    signal snake_eaten          : std_logic_vector(7 downto 0);

    signal score_en, score_busy : std_logic;
    signal score_wen            : std_logic;
    signal score_addr           : std_logic_vector (11 downto 0);
    signal score_data           : std_logic_vector(15 downto 0);

    signal logic_en, logic_busy : std_logic;
    signal logic_food          : std_logic;
    signal logic_loose          : std_logic;
    signal logic_score          : natural range 0 to 255;

    signal food_en, food_busy   : std_logic;
    signal food_wen             : std_logic;
    signal food_addr            : std_logic_vector (11 downto 0);
    signal food_data            : std_logic_vector(15 downto 0);

    signal txc, tyc               : natural;

    function calcAddr(x : natural; y : natural) 
            return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(y * DISPLAY_WIDTH + x, 12));
    end function calcAddr;

    component VGA_text
        port (
            clock   : in std_logic;
            reset   : in std_logic;
            wen     : in std_logic;
            addr    : in std_logic_vector (11 downto 0);
            dataW   : in std_logic_vector(15 downto 0);
            dataR   : out std_logic_vector(15 downto 0);
            hsync   : out std_logic;
            vsync   : out std_logic;
            r       : out std_logic_vector(4 downto 0);
            g       : out std_logic_vector(5 downto 0);
            b       : out std_logic_vector(4 downto 0));
    end component;

    component PS2_keyboard
        port(
            clk          : in  std_logic;
            ps2_clk      : in  std_logic;
            ps2_data     : in  std_logic;
            ps2_code_new : out std_logic;
            ps2_code     : out std_logic_vector(7 downto 0));
    end component;
    
    component Controller is
        generic(
            MAX_WIDTH  : natural := 80;
            MAX_HEIGHT : natural := 30;
            INITIAL_X      : natural := INITIAL_X;
            INITIAL_Y      : natural := INITIAL_Y);
        port(
            i_clk     : in  std_logic;
            i_rst     : in  std_logic;
            i_ps2Code : in  std_logic_vector(7 downto 0);
            i_brake   : in  natural;
            i_en      : in  std_logic;
            o_xc      : out natural range 0 to DISPLAY_WIDTH - 1;
            o_yc      : out natural range 0 to DISPLAY_HEIGHT - 1);
    end component;

    component Score
        port(
            i_clk       : in  std_logic;
            i_rst       : in  std_logic;
            i_en        : in  std_logic;
            i_xc        : in  natural;
            i_yc        : in  natural;
            i_score     : in  natural;
            o_busy      : out std_logic;
            o_wen       : out std_logic;
            o_addr      : out std_logic_vector (11 downto 0);
            o_data      : out std_logic_vector(15 downto 0));
    end component;

    component Snake
        generic(
            FIFO_MAX_SIZE  : natural;
            DISPLAY_WIDTH  : natural;
            DISPLAY_HEIGHT : natural);
        port(
            i_clk     : in  std_logic;
            i_rst     : in  std_logic;
            i_en      : in  std_logic;
            i_xc      : in  natural range 0 to DISPLAY_WIDTH - 1;
            i_yc      : in  natural range 0 to DISPLAY_HEIGHT - 1;
            i_data    : in  std_logic_vector(15 downto 0);
            o_busy    : out std_logic;
            o_wen     : out std_logic;
            o_addr    : out std_logic_vector (11 downto 0);
            o_data    : out std_logic_vector(15 downto 0);
            o_eaten   : out std_logic_vector(7 downto 0));
    end component;

    component LFSR
        generic(g_Num_Bits : integer);
        port(
            i_Clk       : in  std_logic;
            i_Enable    : in  std_logic;
            i_Seed_DV   : in  std_logic;
            i_Seed_Data : in  std_logic_vector(g_Num_Bits - 1 downto 0);
            o_LFSR_Data : out std_logic_vector(g_Num_Bits - 1 downto 0);
            o_LFSR_Done : out std_logic
        );
    end component LFSR;

    component Logic
        port(
            i_clk       : in  std_logic;
            i_rst       : in  std_logic;
            i_en        : in  std_logic;
            i_eaten     : in std_logic_vector(7 downto 0);
            o_busy      : out std_logic;
            o_loose     : out std_logic;
            o_food      : out std_logic;
            o_score     : out natural range 0 to 255);
        end component;

    component Food
        generic(
            DISPLAY_WIDTH  : natural := 80;
            DISPLAY_HEIGHT : natural := 30;
            MAX_WIDTH  : natural := 80;
            MAX_HEIGHT : natural := 30);
        port(
            i_clk       : in  std_logic;
            i_rst       : in  std_logic;
            i_en        : in  std_logic;
            i_rnd       : in  std_logic_vector(15 downto 0);
            o_addr      : out std_logic_vector (11 downto 0);
            o_data      : out std_logic_vector(15 downto 0);
            o_busy      : out std_logic;
            o_wen     : out std_logic);
        end component;
begin
    addr <= snake_addr when snake_busy='1' else
            score_addr when score_busy='1' else
            food_addr when food_busy='1' else
            (others=>'U');

    write_data <= snake_data when snake_busy='1' else
            score_data when score_busy='1' else
            food_data when food_busy='1' else
            (others=>'U');

    vgaText_inst : VGA_text port map (
            clock => clk,
            reset => not rst,
            wen   => (not cnt(16)) and (snake_wen or score_wen or food_wen),
            addr  => addr,
            dataW => write_data,
            dataR => read_data,
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

    controller_inst: component Controller
        generic map(
            MAX_WIDTH  => DISPLAY_WIDTH,
            MAX_HEIGHT => DISPLAY_HEIGHT-1)
        port map(
            i_clk      => cnt(16),
            i_rst      => rst,
            i_ps2Code  => ps2Code,
            i_brake    => 100,
            i_en       => '1',
            o_xc       => xc,
            o_yc       => yc
        );

    snake_inst: component Snake
        generic map(
            FIFO_MAX_SIZE  => FIFO_SIZE,
            DISPLAY_WIDTH  => DISPLAY_WIDTH,
            DISPLAY_HEIGHT => DISPLAY_HEIGHT)
        port map(
            i_clk     => cnt(16),
            i_rst     => rst,
            i_en      => snake_en,
            i_xc      => xc,
            i_yc      => yc,
            i_data    => read_data,
            o_busy    => snake_busy,
            o_wen     => snake_wen,
            o_addr    => snake_addr,
            o_data    => snake_data,
            o_eaten   => snake_eaten
        );

    score_inst: component Score
        port map(
            i_clk   => cnt(16),
            i_rst   => rst,
            i_en    => score_en,
            i_xc    => txc,
            i_yc    => tyc,
            i_score => logic_score,
            o_busy  => score_busy,
            o_wen   => score_wen,
            o_addr  => score_addr,
            o_data  => score_data
        );

    lfsr_inst: component LFSR
        generic map(
            g_Num_Bits => 16
        )
        port map(
            i_Clk       => clk,
            i_Enable    => '1',
            i_Seed_DV   => '0',
            i_Seed_Data => (others => '0'),
            o_LFSR_Data => random,
            o_LFSR_Done => open
        );

    logic_inst: component Logic
        port map(
            i_clk   => cnt(16),
            i_rst   => rst,
            i_en    => logic_en,
            i_eaten => snake_eaten,
            o_loose => logic_loose,
            o_food  => logic_food,
            o_score => logic_score,
            o_busy  => logic_busy
        );

    food_inst: component Food
        generic map(
            DISPLAY_WIDTH  => DISPLAY_WIDTH,
            DISPLAY_HEIGHT => DISPLAY_HEIGHT,
            MAX_WIDTH => DISPLAY_WIDTH,
            MAX_HEIGHT => DISPLAY_HEIGHT-1)
        port map(
            i_clk   => cnt(16),
            i_rst   => rst,
            i_en    => food_en,
            i_rnd   => random,
            o_addr  => food_addr,
            o_data  => food_data,
            o_busy  => food_busy,
            o_wen   => food_wen
        );
     
    process(clk) is
    begin
        if rising_edge(clk) then
            cnt <= cnt + 1;
        end if;
    end process;

    process(cnt(17), rst)
        type t_Game_state is (sIdle, sPreLogic, sLogic, sPreShowScore, sShowScore, sPreSnake, sSnake, sPreFood, sFood);
        variable state : t_Game_state;
    begin
        if rst = '0' then
            score_en <= '0';
            snake_en <= '0';
            logic_en <= '0';
            food_en <= '0';
            txc <= 0; 
            tyc <= 0;
            state  := sIdle;
        elsif rising_edge(cnt(17)) then
            case state is
                when sIdle =>
                    state := sIdle;
                    if ps2Code = x"75" or ps2Code = x"72" or ps2Code = x"6B" or ps2Code = x"74" then
                        state := sPreFood;
                    end if;
                when sPreFood =>
                    if logic_food = '1' then
                        txc <= txc + 1; 
                        food_en <= '1';
                        state := sFood;
                    else
                        food_en <= '0';
                        state := sPreLogic;
                    end if;
                when sFood =>
                    tyc <= tyc + 1; 
                    if food_busy = '1'  then
                        food_en <= '0';
                        state := sFood;
                    else
                        state := sPreLogic;
                    end if;    
                when sPreLogic =>
                    logic_en <= '1';
                    state := sLogic;
                when sLogic =>
                    if logic_busy = '1' then
                        logic_en <= '0';
                        state := sLogic;
                    else
                        state := sPreShowScore;
                    end if;    
                when sPreShowScore =>
                    score_en <= '1';
                    state := sShowScore;
                when sShowScore =>
                    if score_busy = '1' then
                        score_en <= '0';
                        state := sShowScore;
                    else
                        state := sPreSnake;
                    end if;    
                when sPreSnake =>
                    snake_en <= '1';
                    state := sSnake;
                when sSnake =>
                    if snake_busy = '1' then
                        snake_en <= '0';
                        state := sSnake;
                    else
                        state := sIdle;
                    end if;    
--                when sDone =>
--                    state := sDone;
            end case;
        end if;
    end process;
end architecture behavioral;
