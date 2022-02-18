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
  signal simul_over : std_logic_vector( 5 downto 0 );
  signal display_io : std_logic_vector( 4 downto 0 );
  signal simul_over_and_reduce : std_logic;
  component sample_step_sine_test is
    generic (
      sub_counter_size : integer range 2 to 20 := 8;
      limit_calc : std_logic_vector( 4 downto 0 ) := "00111";
      amplitude : integer range 0 to 65535 := 65535);
    port (
      simul_over : out std_logic;
      display_in :  in std_logic;
      display_out: out std_logic);
  end component sample_step_sine_test;
  signal last_wait : boolean := false;
begin
  and_reduc_over : process is
    variable reduced : std_logic;
    begin
      reduced := '1';
      for ind in simul_over'high downto simul_over'low loop
        reduced := reduced and simul_over( ind );
      end loop;
      simul_over_and_reduce <= reduced;
      wait on simul_over;
  end process and_reduc_over;


  xxx : process is
    begin
      if simul_over_and_reduce = '0' then
        wait for 1 mS;
      elsif last_wait = false then
        last_wait <= true;
        wait for 1 mS;
      else
        wait;
      end if;
    end process xxx;
      
  sample_step_sine_test_L7 : sample_step_sine_test generic map (
    sub_counter_size => 8,
    limit_calc => "00111")
    port map (
      simul_over => simul_over( 0 ),
      display_in => simul_over_and_reduce ,
      display_out => display_io( 0 ) );
  sample_step_sine_test_Lmax : sample_step_sine_test generic map (
    sub_counter_size => 4,
    limit_calc => "11111")
    port map (
      simul_over => simul_over( 1 ),
      display_in => display_io( 0 ) ,
      display_out => display_io( 1 ) );
  sample_step_sine_test_fine_Lmax : sample_step_sine_test generic map (
    sub_counter_size => 9,
    limit_calc => "11111")
    port map (
      simul_over => simul_over( 2 ),
      display_in => display_io( 1 ) ,
      display_out => display_io( 2 ));
  sample_step_sine_test_low_amp : sample_step_sine_test generic map (
    sub_counter_size => 4,
    limit_calc => "11111",
    amplitude => 255)
    port map (
      simul_over => simul_over( 3 ),
      display_in => display_io( 2 ) ,
      display_out => display_io( 3 ) );
  sample_step_sine_test_amp_close_0 : sample_step_sine_test generic map (
    sub_counter_size => 4,
    limit_calc => "11111",
    amplitude => 20)
    port map (
      simul_over => simul_over( 4 ),
      display_in => display_io( 3 ) ,
      display_out => display_io( 4 ) );
  sample_step_sine_test_amp_0 : sample_step_sine_test generic map (
    sub_counter_size => 4,
    limit_calc => "11111",
    amplitude => 0)
    port map (
      simul_over => simul_over( 5 ),
      display_in => display_io( 4 ) ,
      display_out => open );
end architecture arch;
