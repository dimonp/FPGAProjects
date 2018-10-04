entity t01_helloWorld is
end entity;

architecture sim of t01_helloWorld is
begin

    process is
    begin
        report "Hello World";
        wait;
    end process;
	
end architecture;