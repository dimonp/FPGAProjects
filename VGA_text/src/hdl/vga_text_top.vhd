library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
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
    constant FIFO_SIZE  : natural := 20;
    constant DONE       : string := "Done!";
    constant DONE_X     : natural := 35;
    constant DONE_Y     : natural := 6;

    type state_type is (fill, xp, yp, xn, yn, itp, fin);

    signal vgaClk   : std_logic;
    signal wen      : std_logic := '0';
    signal addr     : natural range 0 to 2400;
    signal data     : std_logic_vector(15 downto 0);
    signal q        : std_logic_vector(23 downto 0) := (others => '0');
    signal isDone   : boolean := false;
    
    signal fill_vram_en   : std_logic := '0';
    signal fill_vram_busy : std_logic;
    signal fill_vram_wen  : std_logic;
    signal fill_vram_addr : natural range 0 to 2400;
    signal fill_vram_data : std_logic_vector(15 downto 0);

    signal write_addr  : natural range 0 to 2400;
    signal write_data  : std_logic_vector(15 downto 0);    

    type t_Coords is record
        xc : natural range 0 to 79;
        yc : natural range 0 to 39;
    end record;
    type t_Coords_fifo is array(0 to FIFO_SIZE-1) of t_Coords;
    signal fifo : t_Coords_fifo := (others=>(others=>0));

    function calcAddr(x : natural range 0 to 79;
                      y : natural range 0 to 29) return natural is
    begin
        return y * 80 + x;
    end function calcAddr;

    procedure updateFifo(x : natural range 0 to 79;
                         y : natural range 0 to 29) is
    begin
        -- This loop is unrolled by the synthesis tool.
        for i in FIFO_SIZE-1 downto 1 loop
            fifo(i) <= fifo(i-1);
        end loop;

        -- insert into position zero
        fifo(0) <= (xc=>x, yc=>y);
    end procedure updateFifo;
    
    component Fill_VRAM
        generic(
            MAX_WIDTH  : natural := 80;
            MAX_HEIGHT : natural := 30);
        port(
            i_clk     : in std_logic;
            i_nrst    : in std_logic;
            i_en      : in  std_logic;
            o_addr    : out natural range 0 to 2400;
            o_data    : out std_logic_vector(15 downto 0);
            o_busy    : out std_logic;
            o_wen     : out std_logic);
    end component;


    component VGA_text
        port(
            vgaClock : in std_logic; -- (25MHz)
            sysClock : in std_logic; -- VGA clock * 2 (50MHz)
            nrst     : in std_logic;
            wen      : in std_logic;
            addr     : in natural range 0 to 2400;
            wdata    : in std_logic_vector(15 downto 0);
            hSync    : out std_logic;
            vSync    : out std_logic;
            hBlank   : out std_logic;
            vBlank   : out std_logic;
            rColor   : out std_logic_vector(4 downto 0);
            gColor   : out std_logic_vector(5 downto 0);
            bColor   : out std_logic_vector(4 downto 0));
    end component;
    
    component Clk_gen
        port ( areset : in std_logic  := '0';
               inclk0 : in std_logic;
               c0     : out std_logic);
    end component;

begin
    write_addr <= fill_vram_addr when fill_vram_busy='1' else addr;
    write_data <= fill_vram_data when fill_vram_busy='1' else data;

    clkGen : Clk_gen port map (
            areset => not rst,
            inclk0 => clk,
            c0 => vgaClk);
            
    fill_vram_inst: component Fill_VRAM
        generic map(
            MAX_WIDTH  => 80,
            MAX_HEIGHT => 30)
        port map(
            i_clk   => q(4),
            i_nrst  => rst,
            i_en    => fill_vram_en,
            o_busy  => fill_vram_busy,
            o_wen   => fill_vram_wen,
            o_addr  => fill_vram_addr ,
            o_data  => fill_vram_data);
            

    vgaText_inst : VGA_text port map (
            vgaClock => vgaClk,
            sysClock => clk,
            nrst  => rst,
            wen   => not q(20),
            addr  => write_addr,
            wdata  => write_data,
            hSync => vgaHs,
            vSync => vgaVs,
            rColor => vgaR,
            gColor => vgaG,
            bColor => vgaB);

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
            x := 0;
            y := 0;
            it:= 0;
            state := fill;
            isDone <= false;
            fill_vram_en <= '1';
        elsif rising_edge(q(21)) then
            case state is
                when fill =>
                    if fill_vram_busy = '1'  then
                        fill_vram_en <= '0';
                        state := fill;
                    else
                        state := xp;
                    end if;    
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
                    if it = 14 then
                        state := fin;
                    else
                        it := it + 1;
                        state := xp;
                    end if;
                when fin =>
                    state := fin;
                    isDone <= true;
            end case;

            updateFifo(x, y);
        end if;
    end process;
    
    process(q(20))
        variable idx : natural range 0 to DONE'length-1 := 0;
    begin
        if rising_edge(q(20)) then
            if isDone then -- show done message
                if idx < DONE'length then
                    idx := idx + 1;
                end if;

                addr <= calcAddr(DONE_X + idx, DONE_Y);
                data <= "00000010" &  std_logic_vector(to_unsigned(character'pos(DONE(idx)),8));
            else -- draw snake
                if q(21) = '1' then
                    addr <= calcAddr(fifo(0).xc, fifo(0).yc);
                    data <= (others=>'1');
                else
                    addr <= calcAddr(fifo(FIFO_SIZE-1).xc, fifo(FIFO_SIZE-1).yc);
                    data <= (others=>'0');
                end if;
            end if;
        end if;
    end process;
    
end architecture behavioral;
