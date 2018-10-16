-- Single-Port ROM

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library altera;
use altera.altera_syn_attributes.all;

entity Font_ROM is
    generic (
        ROM_FILE : string := "rom.hex";
        ROM_SIZE : natural := 16);
    port (
        clk     : in std_logic;
        addr    : in natural range 0 to ROM_SIZE-1;
        q       : out std_logic_vector(0 to 7)
    );
end entity Font_ROM;

architecture rtl of Font_ROM is

    -- Build a 2-D array type for the ROM
    subtype Word_t is std_logic_vector(0 to 7);
    type Memory_t is array(0 to ROM_SIZE-1) of Word_t;

    signal rom : Memory_t;
    attribute ram_init_file : string;
    attribute ram_init_file of rom : signal is ROM_FILE;
begin

    process(clk)
    begin
        if(rising_edge(clk)) then
            q <= rom(addr);
        end if;
    end process;

end rtl;
