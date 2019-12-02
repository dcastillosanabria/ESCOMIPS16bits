  LIBRARY ieee;
  USE ieee.std_logic_1164.ALL;
  USE ieee.numeric_std.ALL;

  ENTITY testbench IS
  END testbench;

  ARCHITECTURE behavior OF testbench IS 

  -- Component Declaration
          COMPONENT PRINCIPAL
          PORT(
                  CLK, CLR : in  STD_LOGIC;
						DI_MEM_DAT : out  STD_LOGIC_VECTOR (15 downto 0)
               );
          END COMPONENT;

         --Inputs
   signal CLK : std_logic := '0';
   signal CLR : std_logic := '0';

 	--Outputs
   signal DI_MEM_DAT : std_logic_vector(15 downto 0);
          
	-- Clock period definitions
   constant CLK_period : time := 10 ns;

  BEGIN

  -- Component Instantiation
          uut: PRINCIPAL PORT MAP(
                  CLK => CLK,
						CLR => CLR,
						DI_MEM_DAT => DI_MEM_DAT
          );

	   -- Clock process definitions
   CLK_process :process
   begin
		CLK <= '0';
		wait for CLK_period/2;
		CLK <= '1';
		wait for CLK_period/2;
   end process;
	
-- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	
		CLR <= '1';
      wait for CLK_period*10;

      CLR <= '0';
		wait for 100 ns;	
				
      wait;
   end process;


  END;