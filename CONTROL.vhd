-- BLOQUE DE LA UNIDAD DE CONTROL
--EL PAQUETE DEBE CONTENER TODAS LAS CONSTANTES, COMPONENTES Y FUNCIONES DE CORRIMIENTO 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use WORK.PKG_ESCOMIPS.ALL;

entity CONTROL is
	GENERIC ( BC : INTEGER := 20;
				 ADR_F : INTEGER := 4;
				 ADR_OP: INTEGER := 5 );
    Port ( FUNCODE : in  STD_LOGIC_VECTOR (ADR_F-1 downto 0);
           OPCODE : in  STD_LOGIC_VECTOR (ADR_OP-1 downto 0);
           Z, C, N, OV : in STD_LOGIC;
           LF, CLK, CLR : in  STD_LOGIC;
           BCTRL : out  STD_LOGIC_VECTOR (BC-1 downto 0));
end CONTROL;

architecture PROGRAMA of CONTROL is
--SIGNAL TIPOR, BEQI, BNEI, BLETI, BGTI, BGETI : STD_LOGIC;
SIGNAL TIPOR, BEQI, BNEQI, BLTI, BLETI, BGTI, BGETI : STD_LOGIC;
SIGNAL EQ, NE, LTI, LETI, GTI, GETI : STD_LOGIC; --SEÑALES BINARIAS PARA LAS CONDICIONES DE IGUALDAD
SIGNAL RZ :  STD_LOGIC; --BANDERAS DEL REGISTRO
SIGNAL RC :  STD_LOGIC;
SIGNAL RN :  STD_LOGIC;
SIGNAL ROV : STD_LOGIC;

TYPE MEM_FUN IS ARRAY ( 0 TO 2**ADR_F-1 ) OF STD_LOGIC_VECTOR ( BCTRL'RANGE );
TYPE MEM_OPC IS ARRAY ( 0 TO 2**ADR_OP-1 ) OF STD_LOGIC_VECTOR ( BCTRL'RANGE );

TYPE ESTADOS IS ( A ); --UNICO ESTADO
SIGNAL EDO_ACT, EDO_SGTE : ESTADOS;

--SELECTOR DE DATOS DE OPCODE Y SELECTOR MICROINSTRUCCION
SIGNAL SM, SDOPC : STD_LOGIC;

CONSTANT MICRO_COD_FU : MEM_FUN := (
	"00000100110000011001", --0 ADD
	"00000100110000111001", --1 SUB
	"00000100110000000001", --2 AND
	"00000100110000001001", --3 OR
	"00000100110000010001", --4 XOR
	"00000100110001101001", --5 NAND
	"00000100110001100001", --6 NOR
	"00000100110001010001", --7 XNOR
	"00000100110001101001", --8 NOT
	"00000011100000000000", --9 SLL
	"00000010100000000000", --10 SRL
	OTHERS => ( OTHERS => '0' )
);

CONSTANT MICRO_COD_OP : MEM_OPC := (
	"00001000010000111000", -- 0 Bcond
	"00000000100000000000", -- 1 LI
	"00000100100000000100", -- 2 LWI
	"00001000000000000110", -- 3 SWI
	"00001000000000000110", -- 4 SW
	"00000100110010011001", -- 5 ADDI
	"00000100110010111001", --6 SUBI
	"00000100111010000001", --7 ANDI
	"00000100111010001001", --8 ORI
	"00000100111010010001", --9 XORI
	"00000100111011101001", --10 NANDI
	"00000100111011100001", --11 NORI
	"00000100111011010001", --12 XNORI
	"00110000010110011001", -- 13 BEQI
	"00110000010110011001", -- 14 BNEI	
	"00110000010110011001", -- 15 BLTI
	"00110000010110011001", --16 BLETI
	"00110000010110011001", --17 BGTI
	"00110000010110011001", --18 BGETI
	"00100000000000000000", --19 B
	"10100000000000000000", --20 CALL
	"01000000000000000000", --21 RET
	"00000000000000000000", --22 NOP
	"00000100100000011000", --23 LW
	OTHERS => ( OTHERS => '0' )
);


SIGNAL DF : STD_LOGIC_VECTOR ( BCTRL'RANGE );
SIGNAL D : STD_LOGIC_VECTOR ( BCTRL'RANGE );
--SEÑAL DE ENTRADA A LA MEMORIA DE MICROCODIGO DE OPCODE:
SIGNAL A_MOPCODE : STD_LOGIC_VECTOR ( OPCODE'RANGE );

begin
	
	--MUX PEQUEÑO
	A_MOPCODE <= OPCODE WHEN ( SDOPC = '1' ) ELSE (OTHERS => '0' ); -- CAMBIAR CEROS POR RANGO DE ARREGLO EN CEROS

	--LECTURA ASINCRONA DE LA MEMORIA DE MICROCODIGO DE FUNCION
	DF <= MICRO_COD_FU ( CONV_INTEGER(FUNCODE) );
	
	--LECTURA ASINCRONA DE LA MEMORIA DE MICROCODIGO DE OPERACION
	D  <= MICRO_COD_OP ( CONV_INTEGER(A_MOPCODE) );
	
	--MUX GRANDE
	BCTRL <= DF WHEN ( SM = '0' ) ELSE D;
	
	--DECODIFICADOR DE INSTRUCCION
	TIPOR <= '1' WHEN ( OPCODE = OPCODE_TIPOR ) ELSE '0';
	BEQI  <= '1' WHEN ( OPCODE = OPCODE_BEQI )  ELSE '0';
	BNEQI <= '1' WHEN ( OPCODE = OPCODE_BNEI )  ELSE '0';
	BLTI  <= '1' WHEN ( OPCODE = OPCODE_BLTI )  ELSE '0';
	BLETI <= '1' WHEN ( OPCODE = OPCODE_BLETI ) ELSE '0';
	BGTI  <= '1' WHEN ( OPCODE = OPCODE_BGTI )  ELSE '0';
	BGETI <= '1' WHEN ( OPCODE = OPCODE_BGETI ) ELSE '0';
	
	
	--UNICA PARTE DEL PROCESADOR DONDE LA CARGA SE HACE EN FLANCO DE BAJADA:
	--REGISTRO DE ESTADO DE BANDERAS:
	RFLAGS : PROCESS ( CLK, CLR )
	BEGIN
		IF ( CLR = '1' ) THEN
			RZ  <= '0'; 
			RC  <= '0';
			RN  <= '0';
			ROV <= '0';
		ELSIF ( FALLING_EDGE(CLK) ) THEN --FLANCO DE BAJADA SE GUARDAN BANDERAS
			IF ( LF = '1' ) THEN --SI NO SE QUEDA EN RETENCION
				RZ  <= Z; 
				RC  <= C;
				RN  <= N;
				ROV <= OV;
			END IF;
		END IF;		
	END PROCESS RFLAGS;
	
-- CONDICIONES PARA NUMEROS CON SIGNO

	EQ   <= RZ;                       			  -- A  = B
	NE   <= NOT RZ;                         	  -- A != B 
	LTI  <= (NOT RZ) AND (RN XOR ROV);			  -- A <  B
	LETI <= RZ OR (RN XOR ROV);      			  -- A <= B
	GTI  <= (NOT (RN XOR ROV)) AND (NOT RZ);	  -- A >  B
	GETI <= (NOT (RN XOR ROV)) OR RZ;			  -- A >= B

-- UNIDAD DE CONTROL

	TRANSICION : PROCESS ( CLK, CLR )
	BEGIN
		IF ( CLR = '1' ) THEN
			EDO_ACT <= A;
		ELSIF ( RISING_EDGE(CLK) ) THEN
			EDO_ACT <= EDO_SGTE;
		END IF;
	END PROCESS TRANSICION;
	
	AUTOMATA : PROCESS ( CLK, EDO_ACT, TIPOR, BEQI, BNEQI, BLTI, BLETI, BGTI, BGETI, EQ, NE, LTI, LETI, GTI, GETI   )
	BEGIN
		
		SM	   <= '0';
		SDOPC <= '0';
		--EQ, NE, LTI, LETI, GTI, GETI 
		
		CASE EDO_ACT IS
			WHEN A => 
				IF ( TIPOR = '1' ) THEN
					EDO_SGTE <= A;
				ELSE 
					IF ( BEQI = '1' ) THEN 
						IF ( CLK = '1' ) THEN 
							--SDOPC <= '0'; --YA ESTA EN 0
							SM <= '1';
						ELSE -- NIVEL BAJO
							IF ( EQ = '0' ) THEN
							--SDOPC <= '0'; --YA ESTA EN 0
								SM <= '1';
							END IF;
						END IF;
					ELSIF ( BNEQI = '1' ) THEN
						IF ( CLK = '1' ) THEN 
							--SDOPC <= '0'; --YA ESTA EN 0
							SM <= '1';
						ELSE -- NIVEL BAJO
							IF ( NE = '0' ) THEN
							 --SDOPC <= '0'; --YA ESTA EN 0
								SM <= '1';
							END IF;
						END IF;
					ELSIF ( BLTI = '1' ) THEN
						IF ( CLK = '1' ) THEN 
							--SDOPC <= '0'; --YA ESTA EN 0
							SM <= '1';
						ELSE -- NIVEL BAJO
							IF ( LTI = '0' ) THEN
							--SDOPC <= '0'; --YA ESTA EN 0
								SM <= '1';
							END IF;
						END IF;
					ELSIF ( BLETI = '1' ) THEN
						IF ( CLK = '1' ) THEN 
							--SDOPC <= '0'; --YA ESTA EN 0
							SM <= '1';
						ELSE -- NIVEL BAJO
							IF ( LETI = '0' ) THEN
							--SDOPC <= '0'; --YA ESTA EN 0
								SM <= '1';
							END IF;
						END IF;
					ELSIF ( BGTI = '1' ) THEN
						IF ( CLK = '1' ) THEN 
							--SDOPC <= '0'; --YA ESTA EN 0
							SM <= '1';
						ELSE -- NIVEL BAJO
							IF ( GTI = '0' ) THEN
							--SDOPC <= '0'; --YA ESTA EN 0
								SM <= '1';
							END IF;
						END IF;
					ELSIF ( BGETI = '1' ) THEN
						IF ( CLK = '1' ) THEN 
							--SDOPC <= '0'; --YA ESTA EN 0
							SM <= '1';
						ELSE -- NIVEL BAJO
							IF ( GETI = '0' ) THEN
							--SDOPC <= '0'; --YA ESTA EN 0
								SM <= '1';
							END IF;
						END IF;
					ELSE
						SDOPC <= '1';
						SM <= '1';
					END IF;
				END IF;
		END CASE;
	END PROCESS AUTOMATA;
	
end PROGRAMA;


--       MEMORIA DE MICROCODIGO DE FUNCION
-- UP DW WPC SDMP SR2 SWD SHE DIR WR LF SEXT SOP1 SOP2 ALUOP SDMD WD SR
--	"0 0 0 0 0 1 0 0 1 1 0 0 0 0011 0 0 1", --0 ADD
--	"0 0 0 0 0 1 0 0 1 1 0 0 0 0111 0 0 1", --1 SUB
--	"0 0 0 0 0 1 0 0 1 1 0 0 0 0000 0 0 1", --2 AND
--	"0 0 0 0 0 1 0 0 1 1 0 0 0 0001 0 0 1", --3 OR
--	"0 0 0 0 0 1 0 0 1 1 0 0 0 0010 0 0 1", --4 XOR
--	"0 0 0 0 0 1 0 0 1 1 0 0 0 1101 0 0 1", --5 NAND
--	"0 0 0 0 0 1 0 0 1 1 0 0 0 1100 0 0 1", --6 NOR
--	"0 0 0 0 0 1 0 0 1 1 0 0 0 1010 0 0 1", --7 XNOR
--	"0 0 0 0 0 1 0 0 1 1 0 0 0 1101 0 0 1", --8 NOT
--	"0 0 0 0 0 0 1 1 1 0 0 0 0 0000 0 0 0", --9 SLL
--	"0 0 0 0 0 0 1 0 1 0 0 0 0 0000 0 0 0", --10 SRL
--
--      MEMORIA DE MICROCODIGO DE OPERACION
-- UP DW WPC SDMP SR2 SWD SHE DIR WR LF SEXT SOP1 SOP2 ALUOP SDMD WD SR
--	"0 0 0 0 1 0 0 0 0 1 0 0 0 0111 0 0 0", -- 0 Bcond
--	"0 0 0 0 0 0 0 0 1 0 0 0 0 0000 0 0 0", -- 1 LI
--	"0 0 0 0 0 1 0 0 1 0 0 0 0 0000 1 0 0", -- 2 LWI
--	"0 0 0 0 1 0 0 0 0 0 0 0 0 0000 1 1 0", -- 3 SWI
--	"0 0 0 0 1 0 0 0 0 0 0 0 0 0000 1 1 0", -- 4 SW
--	"0 0 0 0 0 1 0 0 1 1 0 0 1 0011 0 0 1", -- 5 ADDI
--	"0 0 0 0 0 1 0 0 1 1 0 0 1 0111 0 0 1", --6 SUBI
--	"0 0 0 0 0 1 0 0 1 1 1 0 1 0000 0 0 1", --7 ANDI
--	"0 0 0 0 0 1 0 0 1 1 1 0 1 0001 0 0 1", --8 ORI
--	"0 0 0 0 0 1 0 0 1 1 1 0 1 0010 0 0 1", --9 XORI
--	"0 0 0 0 0 1 0 0 1 1 1 0 1 1101 0 0 1", --10 NANDI
--	"0 0 0 0 0 1 0 0 1 1 1 0 1 1100 0 0 1", --11 NORI
--	"0 0 0 0 0 1 0 0 1 1 1 0 1 1010 0 0 1", --12 XNORI
--	"0 0 1 1 0 0 0 0 0 1 0 1 1 0011 0 0 1", -- 13 BEQI
--	"0 0 1 1 0 0 0 0 0 1 0 1 1 0011 0 0 1", -- 14 BNEI	
--	"0 0 1 1 0 0 0 0 0 1 0 1 1 0011 0 0 1", -- 15 BLTI
--	"0 0 1 1 0 0 0 0 0 1 0 1 1 0011 0 0 1", --16 BLETI
--	"0 0 1 1 0 0 0 0 0 1 0 1 1 0011 0 0 1", --17 BGTI
--	"0 0 1 1 0 0 0 0 0 1 0 1 1 0011 0 0 1", --18 BGETI
--	"0 0 1 0 0 0 0 0 0 0 0 0 0 0000 0 0 0", --19 B
--	"1 0 1 0 0 0 0 0 0 0 0 0 0 0000 0 0 0", --20 CALL
--	"0 1 0 0 0 0 0 0 0 0 0 0 0 0000 0 0 0", --21 RET
--	"0 0 0 0 0 0 0 0 0 0 0 0 0 0000 0 0 0", --22 NOP
--	"0 0 0 0 0 1 0 0 1 0 0 0 0 0011 0 0 0", --23 LW