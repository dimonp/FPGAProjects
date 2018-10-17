library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity VGA_text_top is
    port(
        clk     : in std_logic;
        rst     : in std_logic;
        vgaHs   : out std_logic;
        vgaVs   : out std_logic;
        vgaR    : out std_logic_vector(4 downto 0);
        vgaG    : out std_logic_vector(5 downto 0);
        vgaB    : out std_logic_vector(4 downto 0));

end entity VGA_text_top;

architecture behavioral of VGA_text_top is
    constant FIFO_SIZE : natural := 20;

    component VGA_text
        port (
            clock   : in std_logic;
            reset   : in std_logic;
            wen     : in std_logic;
            addr    : in natural range 0 to 2400;
            data    : in std_logic_vector(15 downto 0);
            hsync   : out std_logic;
            vsync   : out std_logic;
            r       : out std_logic_vector(4 downto 0);
            g       : out std_logic_vector(5 downto 0);
            b       : out std_logic_vector(4 downto 0));
    end component;

    type state_type is (xp, yp, xn, yn, itp, fin);
    
    signal wen      : std_logic := '0';
    signal addr     : natural range 0 to 2400;
    signal addrH, addrT : natural range 0 to 2400;
    signal data     : std_logic_vector(15 downto 0);
    signal q        : std_logic_vector(23 downto 0) := (others => '0');

    type t_Coords is record
        xc : natural range 0 to 79;
        yc : natural range 0 to 39;
    end record;
    type t_Coords_fifo is array(0 to FIFO_SIZE-1) of t_Coords;
    signal fifo : t_Coords_fifo := (others=>(others=>0));

begin
    vgaText_inst : VGA_text port map (
            clock => clk,
            reset => not rst,
            wen   => not q(21),
            addr  => addr,
            data  => data,
            hsync => vgaHs,
            vsync => vgaVs,
            r => vgaR,
            g => vgaG,
            b => vgaB);

    process(clk) is
    begin
        if rising_edge(clk) then
            q <= q + 1;
        end if;
    end process;

    -- State Machine
    -- 12 Hz
    process (q(21), rst)
        variable x      : natural range 0 to 79 := 0;
        variable y      : natural range 0 to 39 := 0;
        variable it     : natural range 0 to 20 := 0;
        variable state  : state_type := xp;
    begin   
        if rst = '0' then
            state := xp;
        elsif rising_edge(q(21)) then
            if q(22) = '1' then 
                case state is
                    when xp =>
                        if x = 79-it then
                            state := yp;
                        else
                            x := x + 1;
                            state := xp;
                        end if;
                    when yp =>
                        if y = 29-it then
                            state := xn;
                        else
                            y := y + 1;
                            state := yp;
                        end if;
                    when xn =>
                        if x = it then
                            state := yn;
                        else
                            x := x - 1;
                            state := xn;
                        end if;
                    when yn =>
                        if y = it + 1 then
                            state := itp;
                        else
                            y := y - 1;
                            state := yn;
                        end if;
                    when itp =>
                        if it = 10 then
                            state := fin;
                        else
                            it := it + 1;
                            state := xp;
                        end if;
                    when fin =>
                        state := fin;
                end case;

                -- This loop is unrolled by the synthesis tool.
                for i in FIFO_SIZE-1 downto 1 loop
                    fifo(i) <= fifo(i-1);
                end loop;

                -- insert into position zero
                fifo(0) <= (xc=>x, yc=>y);
            end if;
        end if;
    end process;
    
    process(q(21))
    begin
        if rising_edge(q(21)) then
            if q(22) = '1' then
                addr <= fifo(0).yc * 80 + fifo(0).xc;
                data <= (others=>'1');
            else
                addr <= fifo(FIFO_SIZE-1).yc * 80 + fifo(FIFO_SIZE-1).xc;
                data <= (others=>'0');
            end if;
        end if;
    end process;

end architecture behavioral;
