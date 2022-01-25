library ieee;
use ieee.std_logic_1164.all,
  ieee.numeric_std.all,
  ieee.math_real.all,
work.signal_gene.all;

entity sample_step_test is
  generic (
    sub_counter_size : integer range 2 to 20 := 8 );
end entity sample_step_test;

architecture arch of sample_step_test is
  signal CLK : std_logic := '0';
  signal RST : std_logic_vector( 5 downto 0 ) := ( others => '1' );
  signal main_counter : std_logic_vector( 4 downto 0 ) := ( others => '0' );
  constant main_counter_max : std_logic_vector( main_counter'range ) := "10010";
  signal sub_counter : std_logic_vector( sub_counter_size - 1 downto 0 ) := ( others => '0' );
  constant sub_counter_max : std_logic_vector( sub_counter'range ) := ( others => '1' );
  signal angle : std_logic_vector( 23 downto 0 ) := ( others => '0' );
  signal completed,start : std_logic;
  signal started : std_logic := '0';
  signal sin_out, cos_out : std_logic_vector( 15 downto 0 ); -- := "0100000000000000";
  signal sin_latched, cos_latched : std_logic_vector( sin_out'range );
  signal z_out : std_logic_vector( 23 downto 0 );
  signal z_latched : std_logic_vector( z_out'range );
  signal min_square_sc : natural := natural'high;
  signal max_square_sc : natural := 0;
begin
  main_proc : process
    variable square_s, square_c : integer;
    variable square_sc : natural;
    begin
      if main_counter /= main_counter_max then
        CLK_1 : if CLK = '1' then
          RST( RST'high - 1 downto RST'low ) <= RST( RST'high downto RST'low + 1 );
          RST( RST'high ) <= '0';
          if RST = std_logic_vector( to_unsigned( 0 , RST'length )) then
          --        counter <= std_logic_vector( unsigned( counter ) + 1 );
            if started = '0' then
              start <= '1';
              started <= '1';
            elsif completed = '1' then
              -- respawn imediately after a computation is over
              start <= '1';
              if sub_counter /= sub_counter_max then
                sub_counter <= std_logic_vector( unsigned( sub_counter ) + 1 );
              else
                sub_counter <= ( others => '0' );
                main_counter <= std_logic_vector( unsigned( main_counter ) + 1 );
                report integer'image( to_integer( unsigned( main_counter ))) & "/17";
              end if;
            else
              start <= '0';
            end if;
            -- Temporary loop to test the test architecture
            -- completed <= start;
            angle( angle'high downto angle'high + 1 - ( main_counter'length - 1 )) <=
              main_counter( main_counter'high - 1 downto main_counter'low );
            angle( angle'high + 1 - ( main_counter'length - 1 ) - 1 downto
                   angle'high + 1 - ( main_counter'length - 1 ) - 1 + 1 - sub_counter'length ) <=
              sub_counter;
            
            square_s := to_integer( signed( sin_out )) ** 2;
            square_c := to_integer( signed( cos_out )) ** 2;
            square_sc := square_s + square_c;

            if completed = '1' then
              sin_latched( sin_latched'high - 1 downto sin_latched'low ) <=
                sin_out( sin_out'high - 1 downto sin_out'low );
              sin_latched( sin_latched'high ) <= not sin_out( sin_out'high );
              cos_latched( cos_latched'high - 1 downto cos_latched'low ) <=
                cos_out( cos_out'high - 1 downto cos_out'low );
              cos_latched( cos_latched'high ) <= not cos_out( cos_out'high );
              z_latched( z_latched'high - 1 downto z_latched'low ) <=
                z_out( z_out'high - 1 downto z_out'low );
              z_latched( z_latched'high ) <= not z_out( z_out'high );

              if square_sc > max_square_sc then
                max_square_sc <= square_sc;
              end if;
              if square_sc < min_square_sc then
                min_square_sc <= square_sc;
              end if;
            end if;
          end if;
        end if CLK_1;
        CLK <= not CLK;
        wait for 40 nS;
      else
        report "end of simulation" severity note;
        report "Verification sin2 + cos2 is 1: min=" &
          real'image( real( min_square_sc ) / real( 2 ** 30 )) &
          ", max = " & real'image( real( max_square_sc ) / real( 2 ** 30 )) severity note;
        
        wait;
      end if;
    end process main_proc;

    sample_step_sine_instanc : sample_step_sine port map (
      CLK => CLK,
      RST => RST( RST'low ),
      start_calc => start,
      limit_calc => "11111",
      amplitude => x"ffff",
      angle => angle,
      completed => completed,
      out_z => z_out,
      out_s => sin_out,
      out_c => cos_out );
        
end architecture arch;
