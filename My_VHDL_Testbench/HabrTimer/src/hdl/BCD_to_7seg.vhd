library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity BCD_to_7seg is
    port(
        clk         : in std_logic; 
        BCDM1       : in std_logic_vector(3 downto 0); 
        BCDM10      : in std_logic_vector(3 downto 0); 
        BCDH1       : in std_logic_vector(3 downto 0); 
        BCDH10      : in std_logic_vector(3 downto 0); 
        dataout       : out std_logic_vector(6 downto 0);
        U2_138_select : out std_logic;
        U3_138_select : out std_logic;
        U2_138_A      : out std_logic_vector(2 downto 0));

end BCD_to_7seg;

architecture Behavioral of BCD_to_7seg is
    signal cnt_scan         : std_logic_vector(26 downto 0 );
    signal dataout_xhdl1    : std_logic_vector(6 downto 0);
    signal en_xhdl          : std_logic_vector(2 downto 0);
    signal BCD              : std_logic_vector(3 downto 0); 
begin
    dataout <= dataout_xhdl1;
    U2_138_A <= en_xhdl;
    U2_138_select <= '1';
    U3_138_select <= '0';

    process(clk)
    begin
        if rising_edge(clk) then
            cnt_scan <= cnt_scan+1;
        end if;  
    end process;

    process(cnt_scan(26 downto 24))
    begin
        case cnt_scan(26 downto 24) is
          when"000"=> en_xhdl<="000";
          when"001"=> en_xhdl<="001";
          when"010"=> en_xhdl<="010";
          when"011"=> en_xhdl<="011";
          when"100"=> en_xhdl<="000";
          when"101"=> en_xhdl<="001";
          when"110"=> en_xhdl<="010";
          when"111"=> en_xhdl<="011";
          when others=> en_xhdl<="XXX";
        end case;
    end process;

    process(en_xhdl, BCDM1, BCDM10, BCDH1, BCDH10)
    begin
        case en_xhdl is
          when"000"=> 
				BCD <= BCDM1;
          when"001"=> 
				BCD <= BCDM10;
          when"010"=> 
				BCD <= BCDH1;
          when"011"=> 
				BCD <= BCDH10;
          when others=> 
				BCD <= "XXXX";
        end case;
    end process;
    
    process(BCD)
    begin
        case BCD is 
            when "0000" =>
                dataout_xhdl1 <= "1000000"; --0
            when "0001" =>
                dataout_xhdl1 <= "1111001"; --1 
            when "0010" =>
                dataout_xhdl1 <= "0100100"; --2 
            when "0011" =>
                dataout_xhdl1 <= "0110000"; --3 
            when "0100" =>
                dataout_xhdl1 <= "0011001"; --4 
            when "0101" =>
                dataout_xhdl1 <= "0010010"; --5 
            when "0110" =>
                dataout_xhdl1 <= "0000010"; --6 
            when "0111" =>
                dataout_xhdl1 <= "1111000"; --7 
            when "1000" =>
                dataout_xhdl1 <= "0000000"; --8 
            when "1001" =>
                dataout_xhdl1 <= "0010000"; --9
            when others=>null; 
        end case; 
    end process;
end Behavioral;