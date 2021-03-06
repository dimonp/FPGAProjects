library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Logic is
    generic(
        EMPTY_SYM  : std_logic_vector (7 downto 0) := "00000000";
        FOOD_SYM   : std_logic_vector (7 downto 0) := "00000011");
    port(
        i_clk       : in std_logic;
        i_nrst      : in std_logic;
        i_en        : in std_logic;
        i_eaten     : in std_logic_vector(7 downto 0);
        o_busy      : out std_logic;
        o_loose     : out std_logic;
        o_food      : out std_logic;
        o_score     : out natural range 0 to 255;
        o_length    : out natural range 0 to 255;
        o_brake     : out natural range 0 to 255);
end entity Logic;

architecture behavioral of Logic is
    type t_State is (sIdle, sCheck);

    signal score  : natural range 0 to 255;
    signal length : natural range 0 to 255;
    signal brake : natural range 0 to 255;
begin
    o_score <= score;
    o_length <= length;
    o_brake <= brake;

    process(i_clk, i_nrst)
        variable state  : t_State;
    begin
        if i_nrst = '0' then
            o_busy <= '0';
            o_loose <= '0';
            o_food <= '1';
            score <= 0;
            length <= 16;
            brake <= 32;
            state  := sIdle;
        elsif rising_edge(i_clk) then
            case state is
                when sIdle =>
                    o_busy <= '0';
                    if i_en = '1' then
                        o_busy <= '1';
                        state := sCheck;
                    else
                        state  := sIdle;
                    end if;
                when sCheck =>
                    if i_eaten = EMPTY_SYM then
                        o_loose <= '0';
                        o_food <= '0';
                    elsif i_eaten = FOOD_SYM then
                        if score < 255 then
                            score <= score + 1;
                        end if;
                        
                        if brake < 255 then
                            length <= length + 1;
                        end if;
                        
                        if brake > 0 and score mod 4 = 0 then
                            brake <= brake - 1;
                        end if;

                        -- throw new food
                        o_loose <= '0';
                        o_food <= '1';
                    else
                        -- game over
                        o_loose <= '1';
                        o_food <= '0';
                    end if;

                    state := sIdle;
            end case;
        end if;
    end process;
end architecture behavioral;
