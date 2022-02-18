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
    limit_calc : std_logic_vector( 4 downto 0 ) := "00111";
    amplitude : integer range 0 to 65535 := 65535);
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
  signal sin_out, sin_viewer : std_logic_vector( 23 downto 0 );
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
  constant amplitude_vector : std_logic_vector( 15 downto 0 ) :=
    std_logic_vector( to_unsigned( amplitude, 16 ));
  signal amplitude_coeff : real;
  signal simul_over_s : std_logic := '0';
  signal display_out_s : std_logic := '0';
  signal debug_der_c, debug_der_s : integer;
  signal derivate_started : boolean := false;
  signal derivate_count : integer := 1;
  type quadrant_trans_t is array( 0 to 15 ) of natural;
  signal quadrant_trans : quadrant_trans_t := ( others => 0 );
  signal last_quadrant : std_logic_vector( 1 downto 0 );
begin
  amp_ne: if amplitude /= 0 generate
    amplitude_coeff <= 65535.0 / real( amplitude );
  end generate amp_ne;
  amp_eq: if amplitude = 0 generate
    amplitude_coeff <= 1.0;
  end generate amp_eq;

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
                  "A " & integer'image( amplitude ) & ", " &
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
              square_sc := ( int_val_s / 256 ) ** 2 + ( int_val_c / 256 ) ** 2;
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
                  -- Limit to only real differences for an accurate result
                  if abs( last_c - int_val_c ) > 16 or
                    abs( last_s - int_val_s ) > 16 then
                    -- keep the values low in order to avoid overflows in case:
                    -- * High steps (small angle sub counter)
                    -- * aborts at low iterations
                    square_der_sc := (( int_val_s - last_s ) / ( 8 * derivate_count )) ** 2 +
                                     (( int_val_c - last_c ) / ( 8 * derivate_count )) ** 2;
                    debug_der_s <= (( int_val_s - last_s ) / ( 8 * derivate_count )) ** 2;
                    debug_der_c <= (( int_val_c - last_c ) / ( 8 * derivate_count )) ** 2;
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
          "Amplitude: " & integer'image( amplitude ) &
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
      report "Quadrants CCW correct 00->01: " & integer'image( quadrant_trans( 1 )) &
        ", 01->11: " & integer'image( quadrant_trans( 7 )) &
        ", 11->10: " & integer'image( quadrant_trans( 14 )) &
        ", 10->00: " & integer'image( quadrant_trans( 8 )) &
        ", CW wrong 00->10->11->01->00: " & integer'image( quadrant_trans( 2 ) + quadrant_trans( 11 ) + quadrant_trans( 13 ) + quadrant_trans( 4 )) &
        ", neg wrong 00->11, ~, 01->10, ~: " & integer'image( quadrant_trans( 3 ) + quadrant_trans( 12 ) + quadrant_trans( 6 ) + quadrant_trans( 9 )) &
        ", Bad xy->xy: " & integer'image( quadrant_trans( 0 ) + quadrant_trans( 5 ) + quadrant_trans( 10 ) + quadrant_trans( 15 )) 
       severity note;
      -- Since the values are received signed, they are in fact coded on 15 bits
      -- Then the square is coded on 30 bits
      report "Sin2 + cos2 is 1: min=" &
        real'image( real( min_square_sc ) * amplitude_coeff ** 2 / real( 2 ** 30 )) &
        ", max = " & real'image( real( max_square_sc ) * amplitude_coeff ** 2 / real( 2 ** 30 )) severity note;
      -- Balance the low values of the derivates, see above
      report "Sin'2 + cos'2 is 1: min=" &
        real'image( real( min_square_der_sc ) * amplitude_coeff ** 2 / real( 2 ** 29 )) &
        ", max = " & real'image( real( max_square_der_sc ) * amplitude_coeff ** 2 / real( 2 ** 29 )) severity note;
      -- Angle is unsigned but z is signed. the we receive it as a 23 bits vlue
      report "Residual z is close to 0: " &
        real'image( real( min_residual_z ) / real( 2 ** 23 )) &
        ", max = " & real'image( real( max_residual_z ) / real( 2 ** 23 )) &
        ", zesidual z as min = 1/" &
        integer'image( integer( round( real( 2 ** 23 ) / real( min_residual_z )))) &
        ", max = 1/" & integer'image( integer( round( real( 2 ** 23 ) / real( max_residual_z ))) ) severity note;
      display_out_s <= '1';
    end process display;

    sample_step_sine_instanc : sample_step_sine port map (
      CLK => CLK,
      RST => RST( RST'low ),
      start_calc => start,
      limit_calc => limit_calc,
      amplitude => amplitude_vector,
      angle => angle,
      completed => completed,
      out_z => z_out,
      out_s => sin_out,
      out_c => cos_out );
        
end architecture arch;


--! Use standard library
library ieee;
use ieee.std_logic_1164.all,
  ieee.numeric_std.all,
  ieee.math_real.all,
work.signal_gene.all;

--! @brief This module runs a single test of sample_step_pulse
--!
--! It runs a full pulse with some residual points.
--! The number of points is fixed to around 40 points to get a full pulse
--! \n
--! Four verifications are done\n
--! * the integration of the cycle is close to zero
--! * some counting of the signess change.
--! The pulse should change only one time from 0 to +1, from +1 to 0,
--! from 0 to -1 and from -1 to 0
--! * the integration of x ** 2 .sgn( x ) is close to 0\n
--! \n
--! For long simulation a progress data is sent regularly\n
--! \n
--! It can be used in batch mode or in stand alone.
--! The batch mode provides signal to publish the reports after all the
--! instantiations has terminated. This is to avoid to mix the progress with the
--! reported data.
entity sample_step_pulse_test is
  generic (
    amplitude : integer range 0 to 65535 := 65535);
  port (
    --! Tells the simulation is over. It is used (with an and-reduce) in batch mode to start all the reporting
    simul_over : out std_logic;
    --! Controls the report. 0 = wait, 1 = do it, U = do it after the simulation is completed (stand alone)
    display_in :  in std_logic;
    --! Pass the event to the next instantiation after the report is completed (batch mode)
    display_out: out std_logic);
end entity sample_step_pulse_test;

architecture arch of sample_step_pulse_test is
  signal CLK : std_logic := '0';
  signal RST : std_logic_vector( 5 downto 0 ) := ( others => '1' );
  signal main_counter : std_logic_vector( 7 downto 0 ) := ( others => '0' );
  constant main_counter_max : std_logic_vector( main_counter'range ) := "11111111";
  signal start_cycle : std_logic;
  signal completed,start : std_logic;
  signal started : std_logic := '0';
  signal pulse_out, pulse_viewer : std_logic_vector( 16 downto 0 );
  constant amplitude_vector : std_logic_vector( 15 downto 0 ) :=
    std_logic_vector( to_unsigned( amplitude, 16 ));
  signal amplitude_coeff : real;
  signal simul_over_s : std_logic := '0';
  signal display_out_s : std_logic := '0';
  signal integr_pulse, integr_sq : integer := 0;
  type quadrant_trans_t is array( 0 to 15 ) of natural;
  signal quadrant_trans : quadrant_trans_t := ( others => 0 );
  signal last_quadrant : std_logic_vector( 1 downto 0 );
begin
  amp_ne: if amplitude /= 0 generate
    amplitude_coeff <= 65535.0 / real( amplitude );
  end generate amp_ne;
  amp_eq: if amplitude = 0 generate
    amplitude_coeff <= 1.0;
  end generate amp_eq;

  simul_over <= simul_over_s;
  display_out <= display_out_s;
  
  main_proc : process
    variable int_val_out : integer;
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
                main_counter <= std_logic_vector( unsigned( main_counter ) + 1 );
              report "A " & integer'image( amplitude ) & ", " &
                integer'image( to_integer( unsigned( main_counter ))) & "/33 done";
            else
              start <= '0';
            end if;
            is_main := true;
            ind_count := main_counter'high - 1;

            if main_counter( main_counter'low + 1 downto main_counter'low ) = "01" then
              start <= '1';
              start_cycle <= '0';
            elsif main_counter = "00000100" then
              start_cycle <= '1';
              start <= '0';
            else
              start_cycle <= '0';
              start <= '0';
            end if;

            if completed = '1' and main_counter( main_counter'low + 1 downto main_counter'low ) = "11" then
              int_val_out := to_integer( signed( pulse_out ));
              integr_pulse <= integr_pulse + int_val_out;

              if to_integer( signed( pulse_out )) > 0 then
                integr_sq <= integr_sq + ( int_val_out / 8 )** 2;
                quadrant_v := "01";
              elsif to_integer( signed( pulse_out )) < 0 then
                integr_sq <= integr_sq - ( int_val_out / 8 ) ** 2;
                quadrant_v := "10";
              else
                quadrant_v := "00";
              end if;
                
              last_quadrant <= quadrant_v;
              if main_counter( main_counter'low + 1 downto main_counter'low ) = "11" then
                if quadrant_v /= last_quadrant then
                  quadrant_trans( to_integer( unsigned( last_quadrant & quadrant_v ))) <=
                    quadrant_trans( to_integer( unsigned( last_quadrant & quadrant_v ))) + 1;
                end if;
              end if;

              pulse_viewer( pulse_viewer'high - 1 downto pulse_viewer'low ) <=
                pulse_out( pulse_out'high - 1 downto pulse_out'low );
              pulse_viewer( pulse_viewer'high ) <= not pulse_out( pulse_out'high );
            end if;
          end if;
        end if CLK_1;
        CLK <= not CLK;
        wait for 20 nS;
      else
        report 
          "Amplitude: " & integer'image( amplitude ) &
          "Simulation is over" severity note;
        simul_over_s <= '1';
        wait;
      end if;
    end process main_proc;

    display : process
    begin
      wait until ( display_in = '1' or ( display_in = 'U' and simul_over_s = '1' ));
      report "********** Verifications **********" severity note;
      report "Quadrants correct 00->01: " & integer'image( quadrant_trans( 1 )) &
        ", 10->00: " & integer'image( quadrant_trans( 8 )) &
        ", 00->10: " & integer'image( quadrant_trans( 2 )) &
        ", 01->00: " & integer'image( quadrant_trans( 4 )) &
        ", Bad 01->10, ~: " & integer'image( quadrant_trans( 6 ) + quadrant_trans( 9 )) &
        ", Bad xy->xy: " & integer'image( quadrant_trans( 0 ) + quadrant_trans( 5 ) + quadrant_trans( 10 ) + quadrant_trans( 15 )) & 
        ", Bad 11: " & integer'image( quadrant_trans( 3 ) + quadrant_trans( 7 ) + quadrant_trans( 11 ) + quadrant_trans( 12 ) + quadrant_trans( 13 ) + quadrant_trans( 14 )  )
       severity note;
      report "Average=" &
        integer'image( integr_pulse ) severity note;
      report "Average sgn(x).x**2=" &
        integer'image( integr_sq ) severity note;
      display_out_s <= '1';
    end process display;

    sample_step_sine_instanc : sample_step_pulse port map (
      CLK => CLK,
      RST => RST( RST'low ),
      start_calc => start,
      amplitude => amplitude_vector,
      width => x"000e",
      start_pulse => start_cycle,
      completed => completed,
      out_p => pulse_out );
        
end architecture arch;
