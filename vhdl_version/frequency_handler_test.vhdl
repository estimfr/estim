--! Use standard library
library ieee;
use ieee.std_logic_1164.all,
  ieee.numeric_std.all,
  ieee.math_real.all,
  work.frequency_handler_pac.all;

--! @brief This module runs a single test of frequency_handler
--!
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
  signal main_counter : std_logic_vector( 7 downto 0 ) := ( others => '0' );
  constant main_counter_max : std_logic_vector( main_counter'range ) := ( others=> '1' );
  signal sub_counter : std_logic_vector( 14 downto 0 ) := ( others => '0' );
  signal sub_counter_max : std_logic_vector( sub_counter'range ) := ( others => '1' );
  signal angle : std_logic_vector( 23 downto 0 );
  signal start_cycle : std_logic;
  signal val_param : std_logic_vector( 15 downto 0);
  signal write_param : std_logic_vector( 2 downto 0 ):= "000";
  signal simul_over_s : std_logic := '0';
  signal display_out_s : std_logic := '0';
  signal writing_parameter : std_logic_vector( 3 downto 0 ) := "0000";
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
            WRITE_PARAM_CASE : case writing_parameter is
              when "0000" =>
                val_param( val_param'high downto val_param'high - 2 ) <= "000";
                val_param( val_param'low + 12 downto val_param'low + 7 ) <=
                  main_counter( main_counter'high downto main_counter'high - 5 );
                val_param( val_param'low + 6 downto val_param'low + 1 ) <=
                  main_counter( main_counter'high downto main_counter'high - 5 );
                val_param( val_param'low ) <= '0';
                writing_parameter <= std_logic_vector( unsigned( writing_parameter ) + 1 );
              when "0011" =>
                val_param( val_param'high downto val_param'high - 8 ) <= "000000000";
                val_param( val_param'low + 6 downto val_param'low + 1 ) <=
                  ( others => main_counter( main_counter'low ));
                val_param( val_param'low ) <= '0';
                writing_parameter <= std_logic_vector( unsigned( writing_parameter ) + 1 );
              when "0110" =>
                val_param( val_param'high downto val_param'high - 8 ) <= "000000000";
                val_param( val_param'low + 6 downto val_param'low + 1 ) <=
                  ( others => main_counter( main_counter'low + 1));
                val_param( val_param'low ) <= '0';
                writing_parameter <= std_logic_vector( unsigned( writing_parameter ) + 1 );
              when "0001" =>
                write_param <= "001";
                writing_parameter <= std_logic_vector( unsigned( writing_parameter ) + 1 );
              when "0100" =>
                write_param <= "010";
                writing_parameter <= std_logic_vector( unsigned( writing_parameter ) + 1 );
              when "0111" =>
                write_param <= "011";
                writing_parameter <= std_logic_vector( unsigned( writing_parameter ) + 1 );
              when "0010" | "0101" | "1000" =>
                write_param <= "000";
                writing_parameter <= std_logic_vector( unsigned( writing_parameter ) + 1 );
              when others =>  
                if sub_counter /= sub_counter_max then
                  sub_counter <= std_logic_vector( unsigned( sub_counter ) + 1 );
                else
                  sub_counter <= ( others => '0' );
                  sub_counter_max( sub_counter_max'high downto sub_counter_max'high + 1 - main_counter'length ) <=
                    not main_counter;
                  main_counter <= std_logic_vector( unsigned( main_counter ) + 1 );
                  writing_parameter <= "0000";
                  report "L " & 
                    integer'image( to_integer( unsigned( main_counter )) + 1 ) & "/256 done";
                end if;
            end case  WRITE_PARAM_CASE;
              if sub_counter( sub_counter'low + 2 downto sub_counter'low ) = "001" then
                EN <= '1';
              else
                EN <= '0';
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
