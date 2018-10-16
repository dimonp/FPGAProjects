-- Single port RAM with single read/write address 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library altera;
use altera.altera_syn_attributes.all;

entity Video_RAM is
    generic (
        RAM_SIZE : natural := 1024;
        RAM_FILE : string := "ram.hex"
    );
    port (
        clk     : in std_logic;
        addr    : in natural range 0 to RAM_SIZE-1;
        we      : in std_logic := '0';
        data    : in std_logic_vector(15 downto 0);
        q       : out std_logic_vector(15 downto 0));

end entity Video_RAM;

architecture rtl of Video_RAM is

    -- Build a 2-D array type for the RAM
    subtype word_t is std_logic_vector(15 downto 0);
    type memory_t is array(0 to RAM_SIZE-1) of word_t;

    signal ram : memory_t;
    attribute ram_init_file : string;
    attribute ram_init_file of ram : signal is RAM_FILE;

    -- Register to hold the address 
    signal addr_reg : natural range 0 to RAM_SIZE-1;
begin

    process(clk)
    begin
        if(rising_edge(clk)) then
            if(we = '1') then
                ram(addr) <= data;
            end if;
    
            -- Register the address for reading
            addr_reg <= addr;
        end if;
    end process;

    q <= ram(addr_reg);
end rtl;
