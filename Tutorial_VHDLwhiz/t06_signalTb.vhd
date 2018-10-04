entity t06_signalTb is
end entity;

architecture sim of t06_signalTb is
    signal mySignal : integer := 0;
begin

    process is
        variable myVariable : integer := 0;
    begin
        report "**** Process begin ******";

        myVariable := myVariable + 1;
        mySignal   <= mySignal + 1;

        report "myVariable=" & integer'image(myVariable) &
            ", mySignal=" & integer'image(mySignal);

        myVariable := myVariable + 1;
        mySignal   <= mySignal + 1;

        report "myVariable=" & integer'image(myVariable) &
            ", mySignal=" & integer'image(mySignal);
    
        wait for 10 ns;

        report "myVariable=" & integer'image(myVariable) &
            ", mySignal=" & integer'image(mySignal);

    end process;
	
end architecture;