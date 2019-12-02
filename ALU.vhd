library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ALU is
    generic (
	N : INTEGER := 16
);
    Port ( A,B : in  STD_LOGIC_VECTOR (N-1 downto 0);
           AINVERT, BINVERT : in  STD_LOGIC;
			  OP: in STD_LOGIC_VECTOR( 1 DOWNTO 0 );
           RES : inout  STD_LOGIC_VECTOR (N-1 downto 0);  --RES
           Z, Cn, NE, OV : out  STD_LOGIC);  -- Z, C, N, OV
end ALU;

architecture PROGRAMA of ALU is
--SIGNAL MUXA, MUXB : STD_LOGIC_VECTOR( N-1 DOWNTO 0 ); -- SE NECESITA QUE SEAN VARIABLES
begin

PUA : PROCESS ( A, B, AINVERT, BINVERT, OP)
VARIABLE C : STD_LOGIC_VECTOR(N DOWNTO 0) := "00000000000000000" ; --valor solo para simulacion
VARIABLE EB : STD_LOGIC_VECTOR(N-1 DOWNTO 0); -- := OPERADOR DE ASIGN PARA VARIABLES.
VARIABLE P : STD_LOGIC_VECTOR(N-1 DOWNTO 0);
VARIABLE G : STD_LOGIC_VECTOR(N-1 DOWNTO 0);
VARIABLE PK, T2, T3 : STD_LOGIC;
VARIABLE MUXA, MUXB : STD_LOGIC_VECTOR( N-1 DOWNTO 0 );
VARIABLE PL : STD_LOGIC;
VARIABLE S : STD_LOGIC_VECTOR (N-1 downto 0); --AGREGADA PARA GENERACIÓN DE Z

	BEGIN
      
		P := ( others => '0' );
		G := ( others => '0' );
		C := ( others => '0' );
		
		C(0) := BINVERT;
		
	   FOR I IN 0 TO N-1 LOOP	
				MUXA(I) := A(I) XOR AINVERT; --CHECAR DRIVER DE LA SEÑAL -- VALOR NO ACTUALIZADO
				MUXB(I) := B(I) XOR BINVERT;
				CASE OP IS
					WHEN "00" => 
						S := MUXA AND MUXB; 
					WHEN "01" => 
						S := MUXA OR MUXB;
					WHEN "10" => 
						S := MUXA XOR MUXB;
					WHEN OTHERS => 
					
			--EB(I) := B(I) XOR BINVERT; --SE CONVIERTE EN MUX B
			P(I) := MUXA(I) XOR MUXB(I); -- los necesita el calculo del acarreo C(I+1)
			G(I) := MUXA(I) AND MUXB(I); -- los necesita el calculo del acarreo C(I+1)
			S(I) := MUXA(I) XOR MUXB(I) XOR C(I);
			
			
			--TERMINO T2
			T2 := '0';             -- DEBIDO A LA OR DE LA SUMATORIA PARA NO PERDER EL DATO
			FOR J IN 0 TO I-1 LOOP
				PK := '1';           --INICIAR PK EN 1 PARA NO PERDER EL DATO POR SER AND
				FOR K IN J+1 TO I LOOP
			   	PK := PK AND P(K); --ACUMULANDO 
				END LOOP;
					T2 := T2 OR ( G(J) AND PK );
			END LOOP;
			
			--TERMINO T3
			PL := '1';
			
			FOR L IN 0 TO I LOOP
				PL := PL AND P(L);
			END LOOP;
			T3 := C(0) AND PL;
			
			C(I+1) := G(I) OR T2 OR T3; --ECUACION GENERAL 
			--FALTAN BANDERAS N, OV, Z
			
	END CASE;
	END LOOP;

	RES <= S; --SALIDA 
	
--CALCULO DE BANDERAS:

	OV <= C(N) XOR C(N-1);
	NE <= S(N-1); 
	Cn <= C(N); --c DE LA BANDERA

END PROCESS PUA;
Z <= '1' when (RES = X"0000") else '0';
end PROGRAMA;