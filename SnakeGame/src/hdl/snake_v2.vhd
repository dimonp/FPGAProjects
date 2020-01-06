library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.snake_game.all;

entity Snake_v2 is
    generic(
        FIFO_MAX_SIZE : natural := 32;
        SNAKE_COLOR  : std_logic_vector (7 downto 0) := "00000010");
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
end entity Snake_v2;

architecture behavioral of Snake_v2 is
    type t_Draw_state is (sIdle, sPrepare, sPreCollision, sCollision, sHead, sBody, sTail);

    signal snake_head : t_Coords := (others => 0);
    signal snake_body : t_Coords := (others => 0);
    signal snake_tail : t_Coords := (others => 0);
    
    signal fifo_full        : std_logic;
    signal fifo_empty_next  : std_logic;
    signal fifo_write_en    : std_logic;
    signal fifo_read_en     : std_logic;
    signal fifo_write_data  : std_logic_vector(15 downto 0);
    signal fifo_read_data   : std_logic_vector(15 downto 0);
    signal fifo_count       : integer range FIFO_MAX_SIZE - 1 downto 0;

    component Ring_Buffer is
      generic (
        RAM_WIDTH : natural;
        RAM_DEPTH : natural);
      port (
        clk : in std_logic;
        rst : in std_logic;
     
        -- Write port
        wr_en : in std_logic;
        wr_data : in std_logic_vector(RAM_WIDTH - 1 downto 0);
     
        -- Read port
        rd_en : in std_logic;
        rd_valid : out std_logic;
        rd_data : out std_logic_vector(RAM_WIDTH - 1 downto 0);
     
        -- Flags
        empty : out std_logic;
        empty_next : out std_logic;
        full : out std_logic;
        full_next : out std_logic;
     
        -- The number of elements in the FIFO
        fill_count : out integer range RAM_DEPTH - 1 downto 0);
    end component;

begin
    ringBuffer_inst : component Ring_Buffer
        generic map(
            RAM_WIDTH => 16,
            RAM_DEPTH => FIFO_MAX_SIZE
        )
        port map (
            clk => i_clk,
            rst => not i_nrst,
            wr_en => fifo_write_en,
            wr_data => fifo_write_data,
            rd_en => fifo_read_en,
            rd_valid => open,
            rd_data => fifo_read_data,
            empty => open,
            empty_next => fifo_empty_next,
            full => fifo_full,
            full_next => open,
            fill_count => fifo_count
        );

    
    process(i_clk, i_nrst)
        variable state : t_Draw_State;
    begin
        if i_nrst = '0' then
            o_busy <= '0';
            o_wen <= '0';
            state  := sIdle;
        elsif rising_edge(i_clk) then
            case state is
                when sIdle =>
                    o_busy <= '0';
                    o_wen <= '0';
                    if i_en = '1' then
                        o_busy <= '1';
                        state := sPrepare;
                    else
                        state := sIdle;
                    end if;
                when sPrepare =>
                    o_eaten <= (others => '0');
                    if snake_head.xc /= i_coords.xc or snake_head.yc /= i_coords.yc then

                        snake_head <= i_coords;
                        snake_body <= snake_head;

                        if fifo_count >= i_length or fifo_full = '1' then
                            fifo_read_en <= '1';
                            snake_tail.xc <= to_integer(unsigned(fifo_read_data(7 downto 0)));
                            snake_tail.yc <= to_integer(unsigned(fifo_read_data(15 downto 8)));
                        end if;

                        fifo_write_data <= std_logic_vector(to_unsigned(snake_head.yc, 8)) & std_logic_vector(to_unsigned(snake_head.xc, 8));

                        state := sPreCollision;
                    else
                        state := sHead;
                    end if;
                when sPreCollision =>
                    fifo_read_en <= '0';
                    fifo_write_en <= '1';

                    o_addr <= calcAddr(i_coords);
                    state := sCollision;
                when sCollision =>
                    fifo_write_en <= '0';

                    o_eaten <= i_data(7 downto 0);
                    state := sHead;
                when sHead =>
                    o_wen <= '1';
                    o_addr <= calcAddr(snake_head);
                    o_data <= SNAKE_COLOR & "00000010";

                    if fifo_empty_next = '1' then 
                        state := sIdle;
                    else
                        state := sBody;
                    end if;
                when sBody =>
                    o_addr <= calcAddr(snake_body);
                    o_data <= SNAKE_COLOR & "00000001";

                    if fifo_count >= i_length or fifo_full = '1' then
                        state := sTail;
                    else
                        state := sIdle;
                    end if;
                when sTail =>
                    o_addr <= calcAddr(snake_tail);
                    o_data <= (others => '0');
                    state := sIdle;
            end case;
        end if;
    end process;
end architecture behavioral;
