library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.snake_game.all;

entity Score is
    generic(
        SCORE_X     : natural := 10;
        SCORE_Y     : natural := 29;
        TEXT_COLOR  : std_logic_vector (7 downto 0) := "00000110");
    port(
        i_clk     : in  std_logic;
        i_nrst    : in  std_logic;
        i_en      : in  std_logic;
        i_score   : in  natural;
        o_busy    : out std_logic;
        o_wen     : out std_logic;
        o_addr    : out std_logic_vector (11 downto 0);
        o_data    : out std_logic_vector(15 downto 0));
end entity Score;

architecture behavioral of Score is
    type t_Draw_state is (sIdle, sPrepare, sDraw);

    function to_ascii(digit : unsigned(3 downto 0)) return character is
    begin
        return character'val(to_integer(digit(3 downto 0)) + 48);
    end to_ascii;

    function to_bcd(bin : unsigned(7 downto 0)) return unsigned is
        variable i    : integer               := 0;
        variable bcd  : unsigned(11 downto 0) := (others => '0');
        variable bint : unsigned(7 downto 0)  := bin;

    begin
        for i in 0 to 7 loop        -- repeating 8 times.
            bcd(11 downto 1) := bcd(10 downto 0); --shifting the bits.
            bcd(0)           := bint(7);
            bint(7 downto 1) := bint(6 downto 0);
            bint(0)          := '0';

            if (i < 7 and bcd(3 downto 0) > "0100") then --add 3 if BCD digit is greater than 4.
                bcd(3 downto 0) := bcd(3 downto 0) + "0011";
            end if;

            if (i < 7 and bcd(7 downto 4) > "0100") then --add 3 if BCD digit is greater than 4.
                bcd(7 downto 4) := bcd(7 downto 4) + "0011";
            end if;

            if (i < 7 and bcd(11 downto 8) > "0100") then --add 3 if BCD digit is greater than 4.
                bcd(11 downto 8) := bcd(11 downto 8) + "0011";
            end if;

        end loop;
        return bcd;
    end to_bcd;
begin
    process(i_clk, i_nrst)
        variable state : t_Draw_state;
    
        variable text   : string(1 to 9);
        variable idx    : natural;
        variable bcdX   : unsigned(11 downto 0);
        variable bcdY   : unsigned(11 downto 0);
        variable bcdS   : unsigned(11 downto 0);
    begin
        if i_nrst = '0' then
            o_busy <= '0';
            o_wen <= '0';
            state := sIdle;
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
                    bcdS:= to_bcd(to_unsigned(i_score, 8));

                    text := "Score:" & to_ascii(bcdS(11 downto 8))
                        & to_ascii(bcdS(7 downto 4)) 
                        & to_ascii(bcdS(3 downto 0));

                    idx := 0; 
                    state := sDraw;
                when sDraw =>
                    if idx < text'length then
                        idx := idx + 1;
                        o_wen <= '1';
                        o_addr <= calcAddr((SCORE_X + idx, SCORE_Y));
                        o_data <= TEXT_COLOR & std_logic_vector(to_unsigned(character'pos(text(idx)), 8));
                        state := sDraw;
                    else
                        state := sIdle;
                    end if;
            end case;
        end if;
    end process;

end architecture behavioral;
