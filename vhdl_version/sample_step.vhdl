--! Use standard library
library ieee;
use ieee.std_logic_1164.all,
  ieee.numeric_std.all;

--! @brief This module computes the sine ( and cosine)\n
--!
--! It does not know anything about the frequency\n
--! It takes an unsigned 24 bits as the angle,
--! low 0 = angle 0, high $ffffff = angle 2.PI - epsilon\n
--! It returns the sine as a 16 bits signed\n
--! More values are returned for debug purposes and should left open in real world\n
--! More information is in the files located in the cpp_version folder
package signal_gene is
component sample_step_sine is
  port (
    CLK        : in  std_logic; --! Component runs on each clock cycle (if it
                                --is in the running state)
    RST         : in  std_logic;
    start_calc : in  std_logic;
    limit_calc : in  std_logic_vector( 4 downto 0 ); --! Send (others=>'1') for
                                                     --! full computation, or an
                                                     --! unsigned limit for fast one
    amplitude  : in  std_logic_vector;               --! Unsigned amplitude value
    angle      : in  std_logic_vector(23 downto 0);  --! Unsigned 0 to 2.PI value
    completed  : out std_logic;
    out_z      : out std_logic_vector(23 downto 0);  --! Signed truncated z
                                                     --! (mostly used to test the
                                                     --! residual value is close
                                                     --! to 0)
    out_s      : out std_logic_vector(15 downto 0);  --! Signed sine output;
    out_c      : out std_logic_vector(15 downto 0)); --! Signed cosine output
                                                     --! (mostly used for test purposes)
end component sample_step_sine;


end package signal_gene;




library ieee;
use ieee.std_logic_1164.all,
  ieee.numeric_std.all;

entity sample_step_sine is
  port (
    CLK        : in  std_logic; --! Component runs on each clock cycle (if it
                                --is in the running state)
    RST         : in  std_logic;
    start_calc : in  std_logic;
    limit_calc : in  std_logic_vector( 4 downto 0 ); --! Send (others=>'1') for
                                                     --! full computation, or an
                                                     --! unsigned limit for fast one
    amplitude  : in  std_logic_vector;               --! Unsigned amplitude value
    angle      : in  std_logic_vector(23 downto 0);  --! Unsigned 0 to 2.PI value
    completed  : out std_logic;
    out_z      : out std_logic_vector(23 downto 0);  --! Signed truncated z
                                                     --! (mostly used to test the
                                                     --! residual value is close
                                                     --! to 0)
    out_s      : out std_logic_vector(15 downto 0);  --! Signed sine output;
    out_c      : out std_logic_vector(15 downto 0)); --! Signed cosine output
                                                     --! (mostly used for test purposes)
end entity sample_step_sine;

architecture arch of sample_step_sine is
  -- a 23rd bit is need for the sign in the calculation for the sign
  -- (2's complement). The coefficients below are 22 bits number with the high
  -- bit always 0
  subtype z_range is integer range 23 downto 0;
  subtype amplitude_range is integer range 23 downto 0;
  subtype a_range_input is integer range amplitude_range'high - 2 downto amplitude_range'low;  
  type cor_angle_list_t is array(integer range<>) of std_logic_vector(z_range);
  constant cor_angle_list : cor_angle_list_t( 0 to 19 ) := (x"200000", x"12E405", x"09FB38", x"051112", x"028B0D", x"0145D8", x"00A2F6", x"00517C", x"0028BE", x"00145F", x"000A30", x"000518", x"00028C", x"000146", x"0000A3", x"000051", x"000029", x"000014", x"00000A", x"000005");
-- List of the angles for which their tangent is the inverse of a power of 2 
  signal the_sin : std_logic_vector( amplitude_range  );
  signal the_cos : std_logic_vector( amplitude_range );
  signal the_z   : std_logic_vector( z_range );
  signal cordic_iter : std_logic_vector( 4 downto 0 );
  signal cordic_iter_last : std_logic_vector( cordic_iter'range );
begin
  assert cor_angle_list'length < 30 report "Size of cordic_iter is too small" severity failure;
  assert amplitude'length <= the_z'length report "Size of the amplitude (" & integer'image( amplitude'length ) & ") should be lower of equal of the size of z " & integer'image( the_z'length ) & ")" severity failure;
  
  out_z <= the_z;
  out_s <= the_sin(the_sin'high downto the_sin'high + 1 - out_s'length );
  out_c <= the_cos(the_cos'high downto the_cos'high + 1 - out_c'length );
      
main_proc : process ( CLK )
  variable v_cos : std_logic_vector( amplitude_range );
  variable shifted_cos, shifted_cos_2 : std_logic_vector( amplitude_range );
  variable v_sin : std_logic_vector( amplitude_range );
  variable shifted_sin, shifted_sin_2 : std_logic_vector( amplitude_range );
  variable v_z   : std_logic_vector( z_range );
  variable delta_z : std_logic_vector( z_range );
  variable shifted_sin_padding : std_logic_vector( amplitude_range );
  variable shifted_cos_padding : std_logic_vector( amplitude_range );
  variable input_amplitude : std_logic_vector( a_range_input );
  variable ind_a : integer;
  begin
    if rising_edge( CLK ) then
      RST_IF : if RST = '0' then
        -- Index is up to N - 1, process the cordic algo
        RUN_IF : if to_integer( unsigned( cordic_iter )) < to_integer( unsigned( cordic_iter_last )) then
          if to_integer( unsigned( cordic_iter )) < cor_angle_list'length then
            delta_z := cor_angle_list( to_integer( unsigned( cordic_iter )));
          else
            delta_z := ( others => '0' );
          end if;
          shifted_sin := the_sin;
          shifted_cos := the_cos;
          -- Computes the sine and cosine multiplied by the tangent
          if cordic_iter /= std_logic_vector( to_unsigned ( 0, cordic_iter'length )) then
				shifted_sin_padding := ( others => the_sin( the_sin'high ) );
				shifted_sin( shifted_sin'high downto shifted_sin'high + 1 - to_integer ( unsigned( cordic_iter )) - 1 ) :=
					shifted_sin_padding( shifted_sin_padding'high downto shifted_sin_padding'high + 1 - to_integer ( unsigned( cordic_iter )) - 1 );
                shifted_sin( shifted_sin'high - to_integer ( unsigned( cordic_iter )) - 1 downto shifted_sin'low ) :=
					the_sin( the_sin'high - 1 downto the_sin'low + to_integer ( unsigned( cordic_iter )) );

			    shifted_cos_padding := ( others => the_cos( the_cos'high ) );
                shifted_cos( shifted_cos'high downto shifted_cos'high + 1 - to_integer ( unsigned( cordic_iter )) - 1 ) :=
                  shifted_cos_padding( shifted_cos_padding'high downto shifted_cos_padding'high + 1 - to_integer ( unsigned( cordic_iter )) - 1 );
                shifted_cos( shifted_cos'high - to_integer ( unsigned( cordic_iter )) - 1 downto shifted_cos'low ) :=
					the_cos( the_cos'high - 1 downto the_cos'low + to_integer ( unsigned( cordic_iter )) );
          end if;
          -- Run the algo a, y anhd z
          if signed( the_z ) > to_signed( 0 , the_z'length ) then
            the_sin <= std_logic_vector( signed( the_sin ) + signed( shifted_cos )); 
            the_cos <= std_logic_vector( signed( the_cos ) - signed( shifted_sin )); 
            the_z <= std_logic_vector( signed( the_z ) - signed( delta_z )); 
          else
            the_sin <= std_logic_vector( signed( the_sin ) - signed( shifted_cos )); 
            the_cos <= std_logic_vector( signed( the_cos ) + signed( shifted_sin )); 
            the_z <= std_logic_vector( signed( the_z ) + signed( delta_z ));
          end if;
          cordic_iter <= std_logic_vector( unsigned( cordic_iter ) + 1 );
        elsif cordic_iter = cordic_iter_last then
          -- Index is N then final processing is processed
          -- The algo lefts a cosine( h ) at every step
          -- The multiplication is done at the end with the product of all of them
          -- See in the tek_and_gene folder for more information
          -- TODO improve the rail to rail with more additions
          shifted_sin( shifted_sin'high downto shifted_sin'high - 2 ) := ( others => the_sin( the_sin'high ));
          shifted_sin( shifted_sin'high - 3 downto shifted_sin'low ) :=
            the_sin( the_sin'high downto the_sin'low + 3 );
          shifted_sin_2( shifted_sin_2'high downto shifted_sin_2'high - 3 ) := ( others => the_sin( the_sin'high ));
          shifted_sin_2( shifted_sin_2'high - 4 downto shifted_sin_2'low ) :=
            the_sin( the_sin'high downto the_sin'low + 4 );
          the_sin <= std_logic_vector( signed( the_sin ) + signed( shifted_sin ) + signed( shifted_sin_2 ));

          shifted_cos( shifted_cos'high downto shifted_cos'high - 2 ) := ( others => the_cos( the_cos'high ));
          shifted_cos( shifted_cos'high - 3 downto shifted_cos'low ) :=
            the_cos( the_cos'high downto the_cos'low + 3 );
          shifted_cos_2( shifted_cos_2'high downto shifted_cos_2'high - 3 ) := ( others => the_cos( the_cos'high ));
          shifted_cos_2( shifted_cos_2'high - 4 downto shifted_cos_2'low ) :=
            the_cos( the_cos'high downto the_cos'low + 4 );
          the_cos <= std_logic_vector( signed( the_cos ) + signed( shifted_cos ) + signed( shifted_cos_2 ));

          completed <= '1';
          cordic_iter <= ( others => '1' );
        -- If on hold, starting now
        elsif start_calc = '1' then
          cordic_iter <= ( others => '0' );
          v_cos := ( others => '0' );
          v_sin := ( others => '0' );

          -- Fill up the amplitude with a barrel shifting of the given amplitude
          -- This improves the rail to rail in case the precision of the input
          -- is limited
          ind_a := amplitude'length - 1;
          build_input_amplitude: for ind_ia in input_amplitude'high downto input_amplitude'low loop
            input_amplitude( ind_ia ) := amplitude( amplitude'low + ind_a );
            if ind_a /= 0 then
              ind_a := ind_a - 1;
            else
              ind_a := amplitude'length - 1;
            end if;
          end loop build_input_amplitude;
			 
          
          -- Execute the 2 first step by hand while placing the value into 
          case angle( angle'high downto angle'high - 1 ) is
            when "00" =>
              v_cos( the_cos'high - 2 downto the_cos'low ) := input_amplitude;				  
            when "01" =>
              v_sin( the_sin'high - 2 downto the_sin'low ) := input_amplitude;
            when "10" =>
              v_cos( the_cos'high - 2 downto the_cos'low ) := input_amplitude;
              v_cos := std_logic_vector( - signed( v_cos ));
            when "11" =>
              v_sin( the_sin'high - 2 downto the_sin'low ) := input_amplitude;
              v_sin := std_logic_vector( - signed( v_sin ));
            when others =>
              NULL;
          end case;
          v_z := ( others => '0' );
          v_z( v_z'high - 2 downto v_z'high + 1 - angle'length ) := angle( angle'high - 2 downto angle'low );
          the_z <= v_z;
          the_sin <= v_sin;
          the_cos <= v_cos;
          completed <= '0';
          -- Initiate the termination if all the list was computed or if an
          -- abort is reached
          if to_integer( unsigned( limit_calc )) < to_integer( unsigned( cordic_iter )) then
            cordic_iter_last <= limit_calc;
          else
            cordic_iter_last <= std_logic_vector( to_unsigned( cor_angle_list'length, cordic_iter'length ));
          end if;
          -- no else as there is nothing to do, waiting for the start
        end if RUN_IF;
      else
        -- This is always greater than the limit calc
        -- cordic_iter is a 5 bits vector as the list contains about 20 elements
        cordic_iter <= ( others => '1' );
        completed <= '0';
      end if RST_IF;
    end if;
  end process main_proc;  
      
end architecture arch;
    
