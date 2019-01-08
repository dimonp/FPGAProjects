library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package snake_game is
    constant DISPLAY_WIDTH  : natural := 80;
    constant DISPLAY_HEIGHT : natural := 30;

    type t_Coords is record
        xc : natural range 0 to DISPLAY_WIDTH - 1;
        yc : natural range 0 to DISPLAY_HEIGHT - 1;
    end record;
    
    function calcAddr(coords : t_Coords) return std_logic_vector;
end package snake_game;

package body snake_game is
    function calcAddr(coords : t_Coords) 
            return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(coords.yc * DISPLAY_WIDTH + coords.xc, 12));
    end function calcAddr;
end package body snake_game;
