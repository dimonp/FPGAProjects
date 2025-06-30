library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

use work.snake_game.all;

entity Snake_Game_top is
    port(
        clk         : in std_logic;
        nrst        : in std_logic;
        ps2Data     : in std_logic;
        ps2Clock    : in std_logic;
        vgaHs       : out std_logic;
        vgaVs       : out std_logic;
        vgaR        : out std_logic_vector(4 downto 0);
        vgaG        : out std_logic_vector(5 downto 0);
        vgaB        : out std_logic_vector(4 downto 0));
end entity Snake_Game_top;

architecture behavioral of Snake_Game_top is
    signal addr             : std_logic_vector (11 downto 0);
    signal write_data, read_data  : std_logic_vector(15 downto 0);
    signal wen              : std_logic;
    signal cnt              : std_logic_vector(23 downto 0) := (others => '0');

    signal ps2_code             : std_logic_vector(7 downto 0);
    signal ps2_code_new         : std_logic;
    signal ps2_code_new_prev    : std_logic;

    signal coords               : t_Coords;
    signal random               : std_logic_vector(15 downto 0);

    signal controller_en        : std_logic;

    signal fill_vram_en, fill_vram_busy : std_logic;
    signal fill_vram_wen        : std_logic;
    signal fill_vram_addr       : std_logic_vector (11 downto 0);
    signal fill_vram_data       : std_logic_vector(15 downto 0);

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
    signal logic_food           : std_logic;
    signal logic_loose          : std_logic;
    signal logic_score          : natural range 0 to 255;
    signal logic_length         : natural range 0 to 255;
    signal logic_brake          : natural range 0 to 255;

    signal food_en, food_busy   : std_logic;
    signal food_wen             : std_logic;
    signal food_addr            : std_logic_vector (11 downto 0);
    signal food_data            : std_logic_vector(15 downto 0);
    
    signal vgaClk           : std_logic;
  
    component ClockGen
        port ( areset   : in std_logic  := '0';
               inclk0   : in std_logic;
               c0       : out std_logic);
    end component;
    
    component VGA_text
        port (
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
    end component;

    component Fill_VRAM
        generic(
            MAX_WIDTH  : natural;
            MAX_HEIGHT : natural;
            FILL_VALUE : std_logic_vector (15 downto 0));
        port(
            i_clk     : in std_logic;
            i_nrst    : in std_logic;
            i_en      : in  std_logic;
            o_addr    : out std_logic_vector (11 downto 0);
            o_data    : out std_logic_vector(15 downto 0);
            o_busy    : out std_logic;
            o_wen     : out std_logic);
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
            MAX_WIDTH  : natural;
            MAX_HEIGHT : natural;
            INITIAL_X  : natural;
            INITIAL_Y  : natural);
        port(
            i_clk         : in  std_logic;
            i_nrst        : in  std_logic;
            i_ps2Code     : in  std_logic_vector(7 downto 0);
            i_ps2CodeNew  : in  std_logic;
            i_brake       : in  natural range 0 to 255;
            i_en          : in  std_logic;
            o_coords      : out t_Coords);
    end component;

    component Score
        port(
            i_clk       : in  std_logic;
            i_nrst      : in  std_logic;
            i_en        : in  std_logic;
            i_score     : in  natural;
            o_busy      : out std_logic;
            o_wen       : out std_logic;
            o_addr      : out std_logic_vector (11 downto 0);
            o_data      : out std_logic_vector(15 downto 0));
    end component;

    component Snake_v2
        generic(FIFO_MAX_SIZE  : natural);
        port(
            i_clk     : in  std_logic;
            i_nrst    : in  std_logic;
            i_en      : in  std_logic;
            i_coords  : in  t_Coords;
            i_length  : in natural range 0 to 255;
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
            o_LFSR_Done : out std_logic);
    end component LFSR;

    component Logic
        port(
            i_clk       : in  std_logic;
            i_nrst      : in  std_logic;
            i_en        : in  std_logic;
            i_eaten     : in std_logic_vector(7 downto 0);
            o_busy      : out std_logic;
            o_loose     : out std_logic;
            o_food      : out std_logic;
            o_score     : out natural range 0 to 255;
            o_length    : out natural range 0 to 255;
            o_brake     : out natural range 0 to 255);
        end component;

    component Food
        generic(
            MAX_WIDTH  : natural := 80;
            MAX_HEIGHT : natural := 30);
        port(
            i_clk     : in  std_logic;
            i_nrst    : in  std_logic;
            i_en      : in  std_logic;
            i_rnd     : in  std_logic_vector(15 downto 0);
            i_data    : in  std_logic_vector(15 downto 0);
            o_addr    : out std_logic_vector (11 downto 0);
            o_data    : out std_logic_vector(15 downto 0);
            o_busy    : out std_logic;
            o_wen     : out std_logic);
        end component;
begin
    addr <= fill_vram_addr when fill_vram_busy='1' else
            snake_addr when snake_busy='1' else
            score_addr when score_busy='1' else
            food_addr when food_busy='1' else
            (others=>'U');

    write_data <= fill_vram_data when fill_vram_busy='1' else
            snake_data when snake_busy='1' else
            score_data when score_busy='1' else
            food_data when food_busy='1' else
            (others=>'U');

    clockGen_inst : ClockGen port map (
            areset => not nrst,
            inclk0 => clk,
            c0     => vgaClk);
            
    vgaText_inst : VGA_text port map (
            i_clockVga => vgaClk,
            i_clockMem => clk,
            i_nrst => nrst,
            i_wen   => (not cnt(4)) and (fill_vram_wen or snake_wen or score_wen or food_wen),
            i_addr  => addr,
            i_dataW => write_data,
            o_dataR => read_data,
            o_syncH => vgaHs,
            o_syncV => vgaVs,
            o_colorR => vgaR,
            o_colorG => vgaG,
            o_colorB => vgaB);

    fill_vram_inst: component Fill_VRAM
        generic map(
            MAX_WIDTH  => 80,
            MAX_HEIGHT => 30,
            FILL_VALUE => (others => '0'))
        port map(
            i_clk   => cnt(4),
            i_nrst  => nrst,
            i_en    => fill_vram_en,
            o_busy  => fill_vram_busy,
            o_wen   => fill_vram_wen,
            o_addr  => fill_vram_addr,
            o_data  => fill_vram_data);

    keyboardPs2_inst: component ps2_keyboard
        port map(
            clk          => clk,
            ps2_clk      => ps2Clock,
            ps2_data     => ps2Data,
            ps2_code_new => ps2_code_new,
            ps2_code     => ps2_code);

    controller_inst: component Controller
        generic map(
            MAX_WIDTH  => DISPLAY_WIDTH,
            MAX_HEIGHT => DISPLAY_HEIGHT-1,
            INITIAL_X  => 40,
            INITIAL_Y  => 10)
        port map(
            i_clk         => cnt(17),
            i_nrst        => nrst,
            i_ps2Code     => ps2_code,
            i_ps2CodeNew  => ps2_code_new,
            i_brake       => logic_brake,
            i_en          => controller_en,
            o_coords      => coords);

    snake_inst: component Snake_v2
        generic map(FIFO_MAX_SIZE  => 128)
        port map(
            i_clk     => cnt(4),
            i_nrst    => nrst,
            i_en      => snake_en,
            i_coords  => coords,
            i_length  => logic_length,
            i_data    => read_data,
            o_busy    => snake_busy,
            o_wen     => snake_wen,
            o_addr    => snake_addr,
            o_data    => snake_data,
            o_eaten   => snake_eaten
        );

    score_inst: component Score
        port map(
            i_clk   => cnt(4),
            i_nrst  => nrst,
            i_en    => score_en,
            i_score => logic_score,
            o_busy  => score_busy,
            o_wen   => score_wen,
            o_addr  => score_addr,
            o_data  => score_data);

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
            o_LFSR_Done => open);

    logic_inst: component Logic
        port map(
            i_clk   => cnt(4),
            i_nrst  => nrst,
            i_en    => logic_en,
            i_eaten => snake_eaten,
            o_loose => logic_loose,
            o_food  => logic_food,
            o_score => logic_score,
            o_brake => logic_brake,
            o_length => logic_length,
            o_busy  => logic_busy);

    food_inst: component Food
        generic map(
            MAX_WIDTH => DISPLAY_WIDTH,
            MAX_HEIGHT => DISPLAY_HEIGHT-1)
        port map(
            i_clk   => cnt(4),
            i_nrst  => nrst,
            i_en    => food_en,
            i_rnd   => random,
            i_data  => read_data,
            o_addr  => food_addr,
            o_data  => food_data,
            o_busy  => food_busy,
            o_wen   => food_wen);
     
    -- control state counter increment process
    process(clk) is
    begin
        if rising_edge(clk) then
            cnt <= cnt + 1;
            --clock period is 20ns, counter is 23 bits, should roll over every 524ms
            --trigger each time counter rolls over back to zero
        end if;
    end process;

    -- general game process definition
    process(cnt(5), nrst)
        type t_Game_state is (sIdle, sClearField, sPreLogic, sLogic, sPreShowScore, sShowScore, sPreSnake, sSnake, sPreFood, sFood, sLoose);
        variable state : t_Game_state;
    begin
        if nrst = '0' then
            fill_vram_en <= '1';
            controller_en <= '0';
            score_en <= '0';
            snake_en <= '0';
            logic_en <= '0';
            food_en <= '0';
            state  := sIdle;
        elsif rising_edge(cnt(5)) then

            case state is
                when sIdle =>
                    state := sClearField;
                when sClearField =>
                    if fill_vram_busy = '1'  then
                        fill_vram_en <= '0';
                        state := sClearField;
                    else
                        state := sPreFood;
                        -- put food on the field
                    end if;    
                when sPreFood =>
                    if logic_food = '1' then
                        food_en <= '1';
                        state := sFood;
                    else
                        food_en <= '0';
                        state := sPreLogic;
                    end if;
                when sFood =>
                    if food_busy = '1'  then
                        food_en <= '0';
                        state := sFood;
                    else
                        state := sPreLogic;
                        -- do game logic
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
                        -- show score
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
                        -- draw snake
                    end if;    
                when sPreSnake =>
                    snake_en <= '1';
                    controller_en <= '1';
                    state := sSnake;
                when sSnake =>
                    if snake_busy = '1' then
                        snake_en <= '0';
                        state := sSnake;
                    else
                        state := sLoose;
                        -- check loose state
                    end if;    
                when sLoose =>
                    if logic_loose = '1' then
                        -- game over
                        state := sLoose;
                    else
                        state := sPreFood;
                    end if;    
            end case;
        end if;
    end process;
end architecture behavioral;
