--! Use standard library
library ieee;
use ieee.std_logic_1164.all,
  ieee.numeric_std.all,
  ieee.math_real.all,
work.signal_gene.all;

--! @brief Batches the test of the sample_step_sine_test with many value
--!
--! This is an early version
entity sample_step_sine_generic_test is
end entity sample_step_sine_generic_test;

architecture arch of sample_step_sine_generic_test is
  signal simul_over : std_logic_vector( 1 downto 0 );
  signal display_io : std_logic_vector( 0 downto 0 );
  signal simul_over_and_reduce : std_logic;
  component sample_step_sine_test is
    generic (
      sub_counter_size : integer range 2 to 20 := 8;
      limit_calc : std_logic_vector( 4 downto 0 ) := "00111" );
    port (
      simul_over : out std_logic;
      display_in :  in std_logic;
      display_out: out std_logic);
  end component sample_step_sine_test;
  signal last_wait : boolean := false;
begin
  simul_over_and_reduce <= simul_over( 0 ) and simul_over( 1 );

  xxx : process
    begin
      if simul_over_and_reduce = '0' then
        wait for 1 mS;
      elsif last_wait = false then
        last_wait <= true;
        wait for 1 mS;
      else
        wait;
      end if;
    end process;
      
  sample_step_sine_test_L7 : sample_step_sine_test generic map (
    sub_counter_size => 8,
    limit_calc => "00111" )
    port map (
      simul_over => simul_over( 0 ),
      display_in => simul_over_and_reduce ,
      display_out => display_io( 0 ) );
  sample_step_sine_test_Lmax : sample_step_sine_test generic map (
    sub_counter_size => 6,
    limit_calc => "11111" )
    port map (
      simul_over => simul_over( 1 ),
      display_in => display_io( 0 ) ,
      display_out => open );
end architecture arch;
