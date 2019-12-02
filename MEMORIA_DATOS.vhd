library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity MEMORIA_DATOS is
	GENERIC(
			N_ADDR : INTEGER := 8; --15 BITS PARA LA MEMORIA DE DATOS
			N_DATA : INTEGER := 16 --16 BITS PARA LA MEMORIA DE DATOS
	);
    Port ( ADDR : in  STD_LOGIC_VECTOR (N_ADDR-1 downto 0);
           DIN : in  STD_LOGIC_VECTOR (N_DATA-1 downto 0);
           DOUT : out  STD_LOGIC_VECTOR (N_DATA-1 downto 0);
           WEN : in  STD_LOGIC;
           CLK : in  STD_LOGIC);
end MEMORIA_DATOS;

architecture PROGRAMA of MEMORIA_DATOS is
TYPE MEMORIA IS ARRAY ( 0 TO 2**N_ADDR-1 ) --direcciones
				OF STD_LOGIC_VECTOR( DIN'RANGE ); --long registro
SIGNAL RAM_DIST : MEMORIA;
begin
	
	PRAM : PROCESS (CLK)
	BEGIN
		IF ( RISING_EDGE(CLK) ) THEN
			IF( WEN = '1' ) THEN 
				RAM_DIST( CONV_INTEGER(ADDR) ) <= DIN;  --ESCRITURA SINCRONA
			END IF;
		END IF;
--REVISAR: MEMORIA RAM DE 1 SOLO PUERTO

	END PROCESS PRAM;
	
	--LECTURA ASINCRONA
	
	DOUT <= RAM_DIST( CONV_INTEGER(ADDR) );

end PROGRAMA;