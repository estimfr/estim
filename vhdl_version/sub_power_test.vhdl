--! Use standard library
library ieee;
use ieee.std_logic_1164.all,
  ieee.numeric_std.all,
  ieee.math_real.all,
work.sub_power_pac.all;

--! @brief This test only runs the sub_power entity.
--!
--! One has to check the output waves
--! There is nothing more to do as it is a cyclic signal generation
--! without any other option

entity sub_power_test is
  generic (
    sub_counter_size : integer range 1 to 10 := 4 );
end entity sub_power_test;

architecture arch of sub_power_test is
  signal CLK : std_logic := '0';
  signal RST : std_logic_vector( 5 downto 0 ) := ( others => '1' );
  signal main_counter : std_logic_vector( 5 downto 0 ) := ( others => '0' );
  constant main_counter_max : std_logic_vector( main_counter'range ) := ( others => '1' );
  signal sub_counter : std_logic_vector( sub_counter_size - 1 downto 0 ) := ( others => '0' );
  constant sub_counter_max : std_logic_vector( sub_counter'range ) := ( others => '1' );
  signal EN : std_logic;
  signal the_out : std_logic_vector( 11 downto 0 );
  signal display_out : std_logic_vector( the_out'range );

begin
  main_proc : process
    variable square_s, square_c : integer;
    variable square_sc : natural;
    variable residual_z : integer;
    begin
      if main_counter /= main_counter_max then
        CLK_1 : if CLK = '1' then
          RST( RST'high - 1 downto RST'low ) <= RST( RST'high downto RST'low + 1 );
          RST( RST'high ) <= '0';

          if sub_counter = sub_counter_max then
            sub_counter <= ( others => '0' );
            EN <= '1';
            main_counter <= std_logic_vector( unsigned( main_counter ) + 1 );

          else
            EN <= '0';
            sub_counter <= std_logic_vector( unsigned( sub_counter ) + 1 );
          end if;
        end if CLK_1;

        display_out( display_out'high ) <= not the_out( the_out'high );
        display_out( display_out'high - 1 downto display_out'low ) <=
          the_out( the_out'high - 1 downto the_out'low );
        
        CLK <= not CLK;
        wait for 20 nS;
      else
        report "end of simulation, there is no (yet) report, see the waves" severity note;
        wait;
      end if;
    end process main_proc;

    sub_power_instanc : sub_power port map (
      CLK => CLK,
      RST => RST( RST'low ),
      EN => '1',
      the_out => the_out );
        
end architecture arch;
