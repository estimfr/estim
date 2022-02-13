--! Use standard library
library ieee;
use ieee.std_logic_1164.all,
  ieee.numeric_std.all,
  ieee.math_real.all,
work.signal_gene.all;

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
entity sample_step_sine_test is
  generic (
    --! 32 points from 0 to 2.PI minus epsilon are performed. 2 power this
    --! parameter ( - 1 ) additional points are added in each interval 
    sub_counter_size : integer range 4 to 20 := 8;
    limit_calc : std_logic_vector( 4 downto 0 ) := "00111" );
  port (
    --! Tells the simulation is over. It is used (with an and-reduce) in batch mode to start all the reporting
    simul_over : out std_logic;
    --! Controls the report. 0 = wait, 1 = do it, U = do it after the simulation is completed (stand alone)
    display_in :  in std_logic;
    --! Pass the event to the next instantiation after the report is completed (batch mode)
    display_out: out std_logic);
end entity sample_step_sine_test;

architecture arch of sample_step_sine_test is
  signal CLK : std_logic := '0';
  signal RST : std_logic_vector( 5 downto 0 ) := ( others => '1' );
  signal main_counter : std_logic_vector( 5 downto 0 ) := ( others => '0' );
  constant main_counter_max : std_logic_vector( main_counter'range ) := "100010";
  signal sub_counter : std_logic_vector( sub_counter_size - 1 downto 0 ) := ( others => '0' );
  constant sub_counter_max : std_logic_vector( sub_counter'range ) := ( others => '1' );
  signal angle : std_logic_vector( 23 downto 0 );
  signal completed,start : std_logic;
  signal started : std_logic := '0';
  signal sin_out, sin_viewer : std_logic_vector( 15 downto 0 );
  signal cos_out, cos_viewer : std_logic_vector( sin_out'range );
  signal z_out : std_logic_vector( 23 downto 0 );
  signal z_viewer : std_logic_vector( z_out'range );
  signal last_s, last_c : integer := integer'high;
  signal min_square_sc : natural := natural'high;
  signal max_square_sc : natural := natural'low;
  signal min_square_der_sc : natural := natural'high;
  signal max_square_der_sc : natural := natural'low;
  signal min_residual_z : integer := integer'high;
  signal max_residual_z : integer := integer'low;
  constant amplitude : std_logic_vector( 15 downto 0 ) := x"ffff";
  signal simul_over_s : std_logic := '0';
  signal display_out_s : std_logic := '0';
  signal debug_der_c, debug_der_s : integer;
  signal derivate_started : boolean := false;
  signal derivate_count : integer := 1;
  type quadrant_trans_t is array( 0 to 15 ) of natural;
  signal quadrant_trans : quadrant_trans_t := ( others => 0 );
  signal last_quadrant : std_logic_vector( 1 downto 0 );
begin
  simul_over <= simul_over_s;
  display_out <= display_out_s;
  
  main_proc : process
    variable int_val_s, int_val_c : integer;
    variable square_sc, square_der_sc : natural;
    variable residual_z : integer;
    variable is_main : boolean;
    variable ind_count : integer;
    variable quadrant_v : std_logic_vector( last_quadrant'range );
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
                report "L " & integer'image( to_integer( unsigned( limit_calc ))) & ", " &
                  "SCS " & integer'image( sub_counter_size ) & ", " &
                  integer'image( to_integer( unsigned( main_counter ))) & "/33 done";
              end if;
            else
              start <= '0';
            end if;
            is_main := true;
            ind_count := main_counter'high - 1;
            for ind in angle'high downto angle'low loop
              if is_main then
                angle( ind ) <= main_counter( ind_count );
                if ind_count /= main_counter'low then
                  ind_count := ind_count - 1;
                else
                  ind_count := sub_counter'high;
                  is_main := false;
                end if;
              else
                angle( ind ) <= sub_counter( ind_count );
                if ind_count /= sub_counter'low then
                  ind_count := ind_count - 1;
                else
                  ind_count := main_counter'high - 1;
                  is_main := true;
                end if;

              end if;
            end loop;

            if completed = '1' then
              quadrant_v := sin_out( sin_out'high downto sin_out'high ) &
                               cos_out( cos_out'high downto cos_out'high );
              last_quadrant <= quadrant_v;
              if derivate_started then
                if quadrant_v /= last_quadrant then
                  quadrant_trans( to_integer( unsigned( last_quadrant & quadrant_v ))) <=
                    quadrant_trans( to_integer( unsigned( last_quadrant & quadrant_v ))) + 1;
                end if;
              end if;

              sin_viewer( sin_viewer'high - 1 downto sin_viewer'low ) <=
                sin_out( sin_out'high - 1 downto sin_out'low );
              sin_viewer( sin_viewer'high ) <= not sin_out( sin_out'high );
              cos_viewer( cos_viewer'high - 1 downto cos_viewer'low ) <=
                cos_out( cos_out'high - 1 downto cos_out'low );
              cos_viewer( cos_viewer'high ) <= not cos_out( cos_out'high );
              z_viewer( z_viewer'high - 1 downto z_viewer'low ) <=
                z_out( z_out'high - 1 downto z_out'low );
              z_viewer( z_viewer'high ) <= not z_out( z_out'high );
              
              int_val_s := to_integer( signed( sin_out ));
              int_val_c := to_integer( signed( cos_out ));
              square_sc := int_val_s ** 2 + int_val_c ** 2;
              if square_sc > max_square_sc then
                max_square_sc <= square_sc;
              end if;
              if square_sc < min_square_sc then
                min_square_sc <= square_sc;
              end if;

--              if last_s /= integer'high and last_c /= integer'high then
              derivate : if sub_counter( sub_counter'high - 3 downto sub_counter'low ) =
                 std_logic_vector( to_unsigned( 0 , sub_counter'length - 3 )) then
                last_c <= int_val_c;
                last_s <= int_val_s;
                derivate_started <= true;
                if derivate_started then
                  if last_c /= int_val_c or last_s /= int_val_s then
                    -- keep the values low in order to avoid overflows in case:
                    -- * High steps (small angle sub counter)
                    -- * aborts at low iterations
                    square_der_sc := (( int_val_s - last_s ) * ( 16 / derivate_count )) ** 2 +
                                     (( int_val_c - last_c ) * ( 16 / derivate_count ) ) ** 2;
                    debug_der_s <= ( int_val_s - last_s ) ** 2;
                    debug_der_c <= ( int_val_c - last_c ) ** 2;
                    if square_der_sc > max_square_der_sc then
                      max_square_der_sc <= square_der_sc;
                    end if;
                    if square_der_sc < min_square_der_sc then
                      min_square_der_sc <= square_der_sc;
                    end if;
                    derivate_count <= 1;
                  else
                    derivate_count <= derivate_count + 1;
                  end if;
                end if;
              end if derivate;
              
              residual_z := to_integer( signed( z_out ));            
              if residual_z > max_residual_z then
                max_residual_z <= residual_z;
              end if;
              if residual_z < min_residual_z then
                min_residual_z <= residual_z;
              end if;
              
            end if;
          end if;
        end if CLK_1;
        CLK <= not CLK;
        wait for 20 nS;
      else
        report "Limit: " & integer'image( to_integer( unsigned( limit_calc ))) & ", " &
          "sub counter size: " & integer'image( sub_counter_size ) & ", " &
          "Simulation is over" severity note;
        simul_over_s <= '1';
        wait;
      end if;
    end process main_proc;

    display : process
    begin
      wait until ( display_in = '1' or ( display_in = 'U' and simul_over_s = '1' ));
      report "Limit: " & integer'image( to_integer( unsigned( limit_calc ))) & ", " &
          "sub counter size: " & integer'image( sub_counter_size ) & ", " &
          "********** Verifications **********" severity note;
      report "Quadrants 00->01: " & integer'image( quadrant_trans( 1 )) &
        ", 00->10: " & integer'image( quadrant_trans( 2 )) &
        ", 00->11: " & integer'image( quadrant_trans( 3 )) &
        ", 01->00: " & integer'image( quadrant_trans( 4 )) &
        ", 01->10: " & integer'image( quadrant_trans( 6 )) &
        ", 01->11: " & integer'image( quadrant_trans( 7 )) &
        ", 10->00: " & integer'image( quadrant_trans( 8 )) &
        ", 10->01: " & integer'image( quadrant_trans( 9 )) &
        ", 10->11: " & integer'image( quadrant_trans( 11 )) &
        ", 11->00: " & integer'image( quadrant_trans( 12 )) &
        ", 11->01: " & integer'image( quadrant_trans( 13 )) &
        ", 11->10: " & integer'image( quadrant_trans( 14 ))
       severity note;
      -- Since the values are received signed, they are in fact coded on 15 bits
      -- Then the square is coded on 30 bits
      report "Sin2 + cos2 is 1: min=" &
        real'image( real( min_square_sc ) * 1.046 / real( 2 ** 30 )) &
        ", max = " & real'image( real( max_square_sc ) * 1.046 / real( 2 ** 30 )) severity note;
      -- Balance the low values of the derivates, see above
      report "Sin'2 + cos'2 is 1: min=" &
        real'image( real( min_square_der_sc ) * 1.046 / real( 2 ** 27 )) &
        ", max = " & real'image( real( max_square_der_sc ) * 1.046 / real( 2 ** 27 )) severity note;
      -- Angle is unsigned but z is signed. the we receive it as a 23 bits vlue
      report "Residual z is close to 0: " &
        real'image( real( min_residual_z ) / real( 2 ** 23 )) &
        ", max = " & real'image( real( max_residual_z ) / real( 2 ** 23 )) severity note;
      report "Residual z as min = 1/" &
        integer'image( integer( round( real( 2 ** 23 ) / real( min_residual_z )))) &
        ", max = 1/" & integer'image( integer( round( real( 2 ** 23 ) / real( max_residual_z ))) ) severity note;
      display_out_s <= '1';
    end process display;

    sample_step_sine_instanc : sample_step_sine port map (
      CLK => CLK,
      RST => RST( RST'low ),
      start_calc => start,
      limit_calc => limit_calc,
      amplitude => amplitude,
      angle => angle,
      completed => completed,
      out_z => z_out,
      out_s => sin_out,
      out_c => cos_out );
        
end architecture arch;
