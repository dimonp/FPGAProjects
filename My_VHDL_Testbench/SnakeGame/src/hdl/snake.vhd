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
        i_ps2Code : in  std_logic_vector(7 downto 0);
        o_xc      : out natural range 0 to DISPLAY_WIDTH - 1;
        o_yc      : out natural range 0 to DISPLAY_HEIGHT - 1;
        o_data    : out std_logic_vector(15 downto 0)
    );
end entity Snake;

architecture behavioral of Snake is
    type t_Snake_state is (sRunUp, sRunDown, sRunLeft, sRunRight, sStop);
    type t_Draw_state is (sHead, sBody, sTail);

    signal clkDivider : unsigned(1 downto 0) := (others => '0');

    type t_Coords is record
        xc : natural range 0 to DISPLAY_WIDTH - 1;
        yc : natural range 0 to DISPLAY_HEIGHT - 1;
    end record;
    type t_Coords_fifo is array (0 to FIFO_MAX_SIZE - 1) of t_Coords;
    signal fifo : t_Coords_fifo := (others => (others => 0));

    procedure updateFifo(x : natural range 0 to DISPLAY_WIDTH-1;
                         y : natural range 0 to DISPLAY_HEIGHT-1) is
    begin
        -- This loop is unrolled by the synthesis tool.
        for i in FIFO_MAX_SIZE - 1 downto 1 loop
            fifo(i) <= fifo(i - 1);
        end loop;

        -- insert into position zero
        fifo(0) <= (xc => x, yc => y);
    end procedure updateFifo;

begin

    process(i_rst, i_clk)
    begin
        if (i_rst = '1') then
            clkDivider <= (others => '0');
        elsif (rising_edge(i_clk)) then
            clkDivider <= clkDivider + 1;
        end if;
    end process;

    process(clkDivider(1), i_rst)
        variable x       : natural range 0 to DISPLAY_WIDTH - 1  := 0;
        variable y       : natural range 0 to DISPLAY_HEIGHT - 1 := 0;
        variable state   : t_Snake_state                         := sStop;
        variable delta_x : integer;
        variable delta_y : integer;

        procedure changeState(currentState : t_Snake_state) is
        begin
            if i_ps2Code = x"75" and state /= sRunDown then
                state := sRunUp;
            elsif i_ps2Code = x"72" and state /= sRunUp then
                state := sRunDown;
            elsif i_ps2Code = x"6B" and state /= sRunRight then
                state := sRunLeft;
            elsif i_ps2Code = x"74" and state /= sRunLeft then
                state := sRunRight;
            end if;
        end procedure changeState;

        function updateX(x     : natural range 0 to DISPLAY_WIDTH-1;
                         delta : integer)
        return natural is
            variable tmp_x : integer;
        begin
            tmp_x := x + delta;

            if tmp_x > DISPLAY_WIDTH - 1 then
                tmp_x := 0;
            elsif tmp_x < 0 then
                tmp_x := DISPLAY_WIDTH - 1;
            end if;

            return tmp_x;
        end function updateX;

        function updateY(y     : natural range 0 to DISPLAY_HEIGHT-1;
                         delta : integer)
        return natural is
            variable tmp_y : integer;
        begin
            tmp_y := y + delta;

            if tmp_y > DISPLAY_HEIGHT - 1 then
                tmp_y := 0;
            elsif tmp_y < 0 then
                tmp_y := DISPLAY_HEIGHT - 1;
            end if;

            return tmp_y;
        end function updateY;

    begin
        if i_rst = '1' then
            x      := 0;
            y      := 0;
            state  := sStop;
        elsif rising_edge(clkDivider(1)) then
            case state is
                when sRunUp =>
                    delta_x := 0;
                    delta_y := -1;
                when sRunDown =>
                    delta_x := 0;
                    delta_y := 1;
                when sRunLeft =>
                    delta_x := -1;
                    delta_y := 0;
                when sRunRight =>
                    delta_x := 1;
                    delta_y := 0;
                when sStop =>
                    delta_x := 1;
                    delta_y := 0;
            end case;

            changeState(state);

            x := updateX(x, delta_x);
            y := updateY(y, delta_y);

            updateFifo(x, y);
        end if;
    end process;

    process(i_clk, i_rst)
        variable state    : t_Draw_State := sHead;
    begin
        if i_rst = '1' then
            state  := sHead;
        elsif rising_edge(i_clk) then
            case state is
                when sHead =>
                    state := sBody;
                    o_xc   <= fifo(0).xc;
                    o_yc   <= fifo(0).yc;
                    o_data <= "0000001000000010";
                when sBody =>
                    state := sTail;
                    o_xc   <= fifo(1).xc;
                    o_yc   <= fifo(1).yc;
                    o_data <= "0000001000000001";
                when sTail =>
                    state := sHead;
                    o_xc   <= fifo(FIFO_MAX_SIZE - 1).xc;
                    o_yc   <= fifo(FIFO_MAX_SIZE - 1).yc;
                    o_data <= (others => '0');
            end case;
        end if;
    end process;

end architecture behavioral;
