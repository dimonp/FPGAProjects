library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.snake_game.all;

entity Controller is
    generic(
        MAX_WIDTH   : natural := 80;
        MAX_HEIGHT  : natural := 30;
        INITIAL_X   : natural := 40;
        INITIAL_Y   : natural := 10);
    port(
        i_clk         : in  std_logic;
        i_nrst        : in  std_logic;
        i_ps2Code     : in  std_logic_vector(7 downto 0);
        i_ps2CodeNew  : in  std_logic;
        i_brake       : in  natural;
        i_en          : in  std_logic;
        o_coords      : out t_Coords);
end entity Controller;

architecture behavioral of Controller is
    type t_Move_state is (sRunUp, sRunDown, sRunLeft, sRunRight, sStop);

    signal xc, yc : natural;
begin
    o_coords <= (xc, yc);

    process(i_clk, i_nrst)
        variable state   : t_Move_state;
        variable delta_x : integer;
        variable delta_y : integer;
        variable brake   : natural := 0;

        procedure changeState(currentState : t_Move_state) is
        begin
            if i_ps2Code = x"75" and state /= sRunDown then
                state := sRunUp;
            elsif i_ps2Code = x"72" and state /= sRunUp then
                state := sRunDown;
            elsif i_ps2Code = x"6B" and state /= sRunRight then
                state := sRunLeft;
            elsif i_ps2Code = x"74" and state /= sRunLeft then
                state := sRunRight;
            else
                state := sStop;
            end if;
        end procedure changeState;

        function updateX(x : natural range 0 to MAX_WIDTH-1; delta : integer)
        return natural is
            variable tmp_x : integer;
        begin
            tmp_x := x + delta;

            if tmp_x > MAX_WIDTH - 1 then
                tmp_x := 0;
            elsif tmp_x < 0 then
                tmp_x := MAX_WIDTH - 1;
            end if;

            return tmp_x;
        end function updateX;

        function updateY(y : natural range 0 to MAX_HEIGHT-1; delta : integer)
        return natural is
            variable tmp_y : integer;
        begin
            tmp_y := y + delta;

            if tmp_y > MAX_HEIGHT - 1 then
                tmp_y := 0;
            elsif tmp_y < 0 then
                tmp_y := MAX_HEIGHT - 1;
            end if;

            return tmp_y;
        end function updateY;

    begin
        if i_nrst = '0' then
            xc <= INITIAL_X;
            yc <= INITIAL_Y;
            state := sStop;
            brake := 0;
            delta_x := 0;
            delta_y := 0;
        elsif rising_edge(i_clk)then

            if i_en = '1' then
                if i_ps2CodeNew = '1' then
                    changeState(state);
                end if;

                if brake = 0 then
                    brake := i_brake;
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
                            delta_x := 0;
                            delta_y := 0;
                    end case;

                    xc <= updateX(xc, delta_x);
                    yc <= updateY(yc, delta_y);
                else
                    brake := brake - 1;
                end if;
            end if;
        end if;
    end process;

end architecture behavioral;
