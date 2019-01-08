library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Snake is
    generic(
        FIFO_MAX_SIZE  : natural := 20;
        DISPLAY_WIDTH  : natural := 80;
        DISPLAY_HEIGHT : natural := 30);
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
        o_eaten   : out std_logic_vector(7 downto 0)
    );
end entity Snake;

architecture behavioral of Snake is
    type t_Coords is record
        xc : natural range 0 to DISPLAY_WIDTH - 1;
        yc : natural range 0 to DISPLAY_HEIGHT - 1;
    end record;
    type t_Coords_fifo is array (0 to FIFO_MAX_SIZE - 1) of t_Coords;
    signal fifo : t_Coords_fifo := (others => (others => 0));

    function calcAddr(x : natural; y : natural) 
            return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(y * DISPLAY_WIDTH + x, 12));
    end function calcAddr;

    procedure updateFifo(x : natural range 0 to DISPLAY_WIDTH-1;
                         y : natural range 0 to DISPLAY_HEIGHT-1) is
    begin
        -- This loop is unrolled by the synthesis tool.
        for i in FIFO_MAX_SIZE - 1 downto 1 loop
            fifo(i) <= fifo(i-1);
        end loop;

        -- insert into position zero
        fifo(0) <= (xc => x, yc => y);
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
                    if fifo(0).xc /= i_xc or fifo(0).yc /= i_yc then
                        updateFifo(i_xc, i_yc);
                        state := sPreCollision;
                    else
                        state := sHead;
                    end if;
                when sPreCollision =>
                    o_addr <= calcAddr(i_xc, i_yc);
                    state := sCollision;
                when sCollision =>
                    o_eaten <= i_data(7 downto 0);
                    state := sHead;
                when sHead =>
                    o_wen <= '1';
                    o_addr <= calcAddr(fifo(0).xc, fifo(0).yc);
                    o_data <= "0000001000000010";
                    state := sBody;
                when sBody =>
                    o_addr <= calcAddr(fifo(1).xc, fifo(1).yc);
                    o_data <= "0000001000000001";
                    state := sTail;
                when sTail =>
                    o_addr <= calcAddr(fifo(FIFO_MAX_SIZE-1).xc, fifo(FIFO_MAX_SIZE-1).yc);
                    o_data <= (others => '0');
                    state := sIdle;
            end case;
        end if;
    end process;
end architecture behavioral;
