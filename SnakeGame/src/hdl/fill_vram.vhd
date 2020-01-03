library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.snake_game.all;

entity Fill_VRAM is
    generic(
        MAX_WIDTH  : natural := 80;
        MAX_HEIGHT : natural := 30;
        FILL_VALUE : std_logic_vector (15 downto 0) := (others => '0'));
    port(
        i_clk     : in std_logic;
        i_nrst    : in std_logic;
        i_en      : in  std_logic;
        o_addr    : out std_logic_vector (11 downto 0);
        o_data    : out std_logic_vector(15 downto 0);
        o_busy    : out std_logic;
        o_wen     : out std_logic);
end entity Fill_VRAM;

architecture behavioral of Fill_VRAM is
    type t_State is (sIdle, sFill);
begin

    process(i_clk, i_nrst) is
        variable state : t_State := sIdle;
        variable idx   : natural range 0 to MAX_WIDTH * MAX_HEIGHT;
    begin
        if i_nrst = '0' then
            o_busy <= '0';
            o_wen <= '0';
            idx := 0;
            state := sIdle;
        elsif rising_edge(i_clk) then
            case state is
                when sIdle =>
                    o_busy <= '0';
                    o_wen <= '0';
                    idx := 0;
                    if i_en = '1' then
                        o_busy <= '1';
                        state := sFill;
                    else
                        state := sIdle;
                    end if;
                when sFill =>
                    o_wen <= '1';

                    o_addr <= std_logic_vector(to_unsigned(idx, 12));
                    o_data <= FILL_VALUE;

                    idx := idx + 1;

                    if idx < MAX_WIDTH * MAX_HEIGHT then
                        state := sFill;
                    else
                        state := sIdle;
                    end if;
            end case;
        end if;
    end process;

end architecture behavioral;
