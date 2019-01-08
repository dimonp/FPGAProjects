library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity Food is
    generic(
        DISPLAY_WIDTH  : natural := 80;
        DISPLAY_HEIGHT : natural := 30;
        MAX_WIDTH  : natural := 80;
        MAX_HEIGHT : natural := 30);
    port(
        i_clk       : in  std_logic;
        i_rst       : in  std_logic;
        i_en        : in  std_logic;
        i_rnd       : in  std_logic_vector(15 downto 0);
        o_addr      : out std_logic_vector (11 downto 0);
        o_data      : out  std_logic_vector(15 downto 0);
        o_busy      : out std_logic;
        o_wen     : out std_logic
    );
end entity Food;

architecture behavioral of Food is
    function calcAddr(x : natural; y : natural) 
            return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(y * DISPLAY_WIDTH + x, 12));
    end function calcAddr;
    
begin
    
    process(i_clk, i_rst)
        type t_State is (sIdle, sThrowFood);
        variable state : t_State;
        variable fx, fy : natural;
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
                        state := sThrowFood;
                    else
                        state := sIdle;
                    end if;
                when sThrowFood =>
                    fx := to_integer(unsigned(i_rnd(7 downto 0))) mod MAX_WIDTH;
                    fy := to_integer(unsigned(i_rnd(15 downto 8))) mod MAX_HEIGHT;

                    o_wen <= '1';
                    o_addr <= calcAddr(fx, fy);
                    o_data <= "0000001000000011";

                    state := sIdle;
            end case;
        end if;
    end process;
end architecture behavioral;