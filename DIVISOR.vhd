
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity DIVISOR is
    Port ( OSC_CLK, CLR : in  STD_LOGIC;
           CLK : inout  STD_LOGIC);
end DIVISOR;

architecture PROGRAMA of DIVISOR is
--SIGNAL CONT : STD_LOGIC_VECTOR( 25 DOWNTO 0 );
SIGNAL CONT : INTEGER RANGE 0 TO 50000000-1;
begin
		PDIV : PROCESS( OSC_CLK , CLR)
		BEGIN
				IF ( CLR = '1' ) THEN
						CONT <= 0;
						CLK <= '0';
				ELSIF(RISING_EDGE(OSC_CLK)) THEN 
							CONT <= CONT + 1;
--							IF ( CONT = "10" & X"FAF080" ) THEN
--							IF ( CONT = 50000000-1 ) THEN
							IF ( CONT = 0 ) THEN
									CLK <= NOT CLK;
--									CONT <= ( OTHERS => '0' );
						END IF;
				END IF;
			END PROCESS PDIV;
end PROGRAMA;

