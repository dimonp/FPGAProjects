library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity Logic is
    port(
        i_clk       : in  std_logic;
        i_rst       : in  std_logic;
        i_en        : in  std_logic;
        i_eaten     : in std_logic_vector(7 downto 0);
        o_busy      : out std_logic;
        o_loose     : out std_logic;
        o_food      : out std_logic;
        o_score     : out natural range 0 to 255
    );
end entity Logic;

architecture behavioral of Logic is
    
begin
    
    process(i_clk, i_rst)
        type t_State is (sIdle, sCheck);
        variable state : t_State;
        variable score : natural range 0 to 255;
    begin
        if i_rst = '0' then
            score := 0;
            o_busy <= '0';
            o_loose <= '0';
            o_food <= '1';
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
                    if unsigned(i_eaten) = 0 then
                        o_loose <= '0';
                        o_food <= '0';
                    elsif unsigned(i_eaten) = 3 then
                        score := score + 1; 
                        o_loose <= '0';
                        o_food <= '1';
                    else
                        o_loose <= '1';
                        o_food <= '0';
                    end if;

                    state := sIdle;
            end case;

            o_score <= score;
        end if;
    end process;
end architecture behavioral;