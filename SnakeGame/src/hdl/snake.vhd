library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.snake_game.all;

entity Snake is
    generic(
        FIFO_MAX_SIZE : natural := 16;
        SNAKE_COLOR  : std_logic_vector (7 downto 0) := "00000010");
    port(
        i_clk     : in  std_logic;
        i_rst     : in  std_logic;
        i_en      : in  std_logic;
        i_coords  : in  t_Coords;
        i_data    : in  std_logic_vector(15 downto 0);
        o_busy    : out std_logic;
        o_wen     : out std_logic;
        o_addr    : out std_logic_vector (11 downto 0);
        o_data    : out std_logic_vector(15 downto 0);
        o_eaten   : out std_logic_vector(7 downto 0)
    );
end entity Snake;

architecture behavioral of Snake is
    type t_Coords_fifo is array (0 to FIFO_MAX_SIZE - 1) of t_Coords;
    signal fifo : t_Coords_fifo := (others => (others => 0));

    procedure updateFifo(coords : t_Coords) is
    begin
        -- This loop is unrolled by the synthesis tool.
        for i in FIFO_MAX_SIZE - 1 downto 1 loop
            fifo(i) <= fifo(i-1);
        end loop;

        -- insert into position zero
        fifo(0) <= coords;
    end procedure updateFifo;

begin
    process(i_clk, i_rst)
        type t_Draw_state is (sIdle, sPrepare, sPreCollision, sCollision, sHead, sBody, sTail);
        variable state : t_Draw_State;
    begin
        if i_rst = '0' then
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
                    if fifo(0).xc /= i_coords.xc or fifo(0).yc /= i_coords.yc then
                        updateFifo(i_coords);
                        state := sPreCollision;
                    else
                        state := sHead;
                    end if;
                when sPreCollision =>
                    o_addr <= calcAddr(i_coords);
                    state := sCollision;
                when sCollision =>
                    o_eaten <= i_data(7 downto 0);
                    state := sHead;
                when sHead =>
                    o_wen <= '1';
                    o_addr <= calcAddr(fifo(0));
                    o_data <= SNAKE_COLOR & "00000010";
                    state := sBody;
                when sBody =>
                    o_addr <= calcAddr(fifo(1));
                    o_data <= SNAKE_COLOR & "00000001";
                    state := sTail;
                when sTail =>
                    o_addr <= calcAddr(fifo(FIFO_MAX_SIZE-1));
                    o_data <= (others => '0');
                    state := sIdle;
            end case;
        end if;
    end process;
end architecture behavioral;
