-- Single-Port ROM

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TestROM is

    generic (
        DATA_WIDTH : natural := 8;
        ADDR_WIDTH : natural := 8
    );

    port (
        clk     : in std_logic;
        addr    : in natural range 0 to 2**ADDR_WIDTH - 1;
        q       : out std_logic_vector((DATA_WIDTH -1) downto 0)
    );

end entity;

architecture rtl of TestROM is

    -- Build a 2-D array type for the ROM
    subtype word_t is std_logic_vector((DATA_WIDTH-1) downto 0);
    type memory_t is array(2**ADDR_WIDTH-1 downto 0) of word_t;

    signal rom : memory_t;
    attribute ram_init_file : string; -- Quartus specific
    attribute ram_init_file of rom : signal is "TestROM.hex";

begin

    process(clk)
    begin
        if(rising_edge(clk)) then
            q <= rom(addr);
        end if;
    end process;

end rtl;
