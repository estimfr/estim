--! Use standard library
library ieee;
use ieee.std_logic_1164.all,
  ieee.numeric_std.all,
  ieee.math_real.all,
  work.frequency_handler_pac.all;

--! @brief This module runs a single test of sample_step_sine
--!
--! It runs a full sine with some residual points
--! * The abort/calculation limitation is a parameter
--! * The number of points is a parameter\n
--! \n
--! Four verifications are done
--! * the residual angle (z) is close to zero
--! * the sum sine2 plus cosine2 is close to 1
--! * some counting of the quadrant change of the sine and cosine
--! Since the test is supposed to generate one period plus a residual,
--! only one change clockwyse should be seen.
--! * the sum of the squares of the derivatives is close to 1\n
--! The 2 first ones should give a result as close as the requested precision
--! is high.
--! The 2 last ones are more tricky if the precisions is low and/or
--! the sharpness is low\n
--! \n
--! For long simulation a progress data is sent regularly\n
--! \n
--! It can be used in batch mode or in stand alone.
--! The batch mode provides signal to publish the reports after all the
--! instantiations has terminated. This is to avoid to mix the progress with the
--! reported data.
entity frequency_handler_test is
  generic (
    sample_rate_id_pwr2 : integer range 0 to 3 := 0;
    division_rate_pwr2 : integer range 0 to 5 );
  port (
    --! Tells the simulation is over. It is used (with an and-reduce) in batch mode to start all the reporting
    simul_over : out std_logic;
    --! Controls the report. 0 = wait, 1 = do it, U = do it after the simulation is completed (stand alone)
    display_in :  in std_logic;
    --! Pass the event to the next instantiation after the report is completed (batch mode)
    display_out: out std_logic);
end entity frequency_handler_test;

architecture arch of frequency_handler_test is
  signal CLK : std_logic := '0';
  signal EN : std_logic;
  signal RST : std_logic_vector( 5 downto 0 ) := ( others => '1' );
  signal main_counter : std_logic_vector( 5 downto 0 ) := ( others => '0' );
  constant main_counter_max : std_logic_vector( main_counter'range ) := "100010";
  signal sub_counter : std_logic_vector( 5 downto 0 ) := ( others => '0' );
  constant sub_counter_max : std_logic_vector( sub_counter'range ) := ( others => '1' );
  signal angle : std_logic_vector( 23 downto 0 );
  signal start_cycle : std_logic;
  signal val_param : std_logic_vector( 15 downto 0);
  signal write_param : std_logic_vector( 2 downto 0 ):= "000";
  signal simul_over_s : std_logic := '0';
  signal display_out_s : std_logic := '0';
begin
  simul_over <= simul_over_s;
  
  main_proc : process
  begin
      if main_counter /= main_counter_max then
        CLK_1 : if CLK = '1' then
          RST( RST'high - 1 downto RST'low ) <= RST( RST'high downto RST'low + 1 );
          RST( RST'high ) <= '0';
          if RST = std_logic_vector( to_unsigned( 0 , RST'length )) then
          --        counter <= std_logic_vector( unsigned( counter ) + 1 );
              if sub_counter /= sub_counter_max then
                sub_counter <= std_logic_vector( unsigned( sub_counter ) + 1 );
              else
                sub_counter <= ( others => '0' );
                main_counter <= std_logic_vector( unsigned( main_counter ) + 1 );
                report "L " & 
                  integer'image( to_integer( unsigned( main_counter ))) & "/33 done";
              end if;
              
            end if;
        end if CLK_1;
        CLK <= not CLK;
        wait for 20 nS;
      else
        report "Simulation is over" severity note;
        simul_over_s <= '1';
        wait;
      end if;
    end process main_proc;

    display : process
    begin
      wait until ( display_in = '1' or ( display_in = 'U' and simul_over_s = '1' ));
      display_out_s <= '1';
    end process display;

    frequency_handler_instanc : frequency_handler generic map (
      sample_rate_id_pwr2 => sample_rate_id_pwr2,
      division_rate_pwr2 => division_rate_pwr2
      )
      port map (
      CLK => CLK,
      EN => EN,
      RST => RST( RST'low ),
      parameter => val_param,
      write_param => write_param,
      start_cycle => start_cycle,
      angle_out => angle);
        
end architecture arch;
