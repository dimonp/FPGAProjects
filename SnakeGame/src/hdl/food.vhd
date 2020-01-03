library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.snake_game.all;

entity Food is
    generic(
        MAX_WIDTH  : natural := 80;
        MAX_HEIGHT : natural := 30;
        FOOD_COLOR : std_logic_vector (7 downto 0) := "00000100");
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
end entity Food;

architecture behavioral of Food is
    type t_State is (sIdle, sSetPosition, sCheckPosition, sThrowFood);
begin
    process(i_clk, i_nrst)
        variable state : t_State;
        variable fx, fy : natural;
        variable test : natural;
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
                        state := sSetPosition;
                    else
                        state := sIdle;
                    end if;
                when sSetPosition =>
                    fx := to_integer(unsigned(i_rnd(7 downto 0))) mod MAX_WIDTH;
                    fy := to_integer(unsigned(i_rnd(15 downto 8))) mod MAX_HEIGHT;
                    o_addr <= calcAddr((fx, fy));
                    state := sCheckPosition;
                when sCheckPosition =>
                    if unsigned(i_data) = 0 then
                        state := sThrowFood;
                    else
                        state := sSetPosition;
                    end if;
                when sThrowFood =>
                    o_wen <= '1';
                    o_data <= FOOD_COLOR & "00000011";

                    state := sIdle;
            end case;
        end if;
    end process;
end architecture behavioral;
