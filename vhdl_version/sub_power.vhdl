--! Use standard library
library ieee;
use ieee.std_logic_1164.all,
  ieee.numeric_std.all,
  ieee.math_real.all;

package sub_power_pac is
  component sub_power is
    port (
      CLK :  in std_logic; --! System clock
      RST :  in std_logic;
      EN  :  in std_logic; --! Steps forward when is '1'. This is to control
                           --! the frequency
      the_out : out std_logic_vector --! Signed value that goes as rail to rail
                                     --! as possible. *** Should be proofed for
                                     --! a particular size ***
      );
  end component sub_power;
  procedure cnv_angle_2_sin( angle : in std_logic_vector( 4 downto 0 ); result : out std_logic_vector );
end package sub_power_pac;

package body sub_power_pac is
  procedure cnv_angle_2_sin( angle : in std_logic_vector( 4 downto 0 ); result : out std_logic_vector ) is
    constant pi_1_32 : signed( result'range ) := to_signed(
      integer(round( 1.34 * sin(      math_pi/32.0) * real(2**(result'length-2)))), result'length );
    constant pi_3_32 : signed( result'range ) := to_signed(
      integer(round( 1.34 * sin(3.0 * math_pi/32.0) * real(2**(result'length-2)))), result'length );
    constant pi_5_32 : signed( result'range ) := to_signed(
      integer(round( 1.34 * sin(5.0 * math_pi/32.0) * real(2**(result'length-2)))), result'length );
    constant pi_7_32 : signed( result'range ) := to_signed(
      integer(round( 1.34 * sin(7.0 * math_pi/32.0) * real(2**(result'length-2)))), result'length );
    constant pi_9_32 : signed( result'range ) := to_signed(
      integer(round( 1.34 * sin(9.0 * math_pi/32.0) * real(2**(result'length-2)))), result'length );
    constant pi_11_32 : signed( result'range ) := to_signed(
      integer(round( 1.34 * sin(11.0 * math_pi/32.0) * real(2**(result'length-2)))), result'length );
    constant pi_13_32 : signed( result'range ) := to_signed(
      integer(round( 1.34 * sin(13.0 * math_pi/32.0) * real(2**(result'length-2)))), result'length );
    constant pi_15_32 : signed( result'range ) := to_signed(
      integer(round( 1.34 * sin(15.0 * math_pi/32.0) * real(2**(result'length-2)))), result'length );
    variable interm_result : signed( result'range );
  begin
    case angle( angle'high - 1 downto angle'low ) is
      when "0000" | "1111" => interm_result := pi_1_32;
      when "0001" | "1110" => interm_result := pi_3_32;
      when "0010" | "1101" => interm_result := pi_5_32;
      when "0011" | "1100" => interm_result := pi_7_32;
      when "0100" | "1011" => interm_result := pi_9_32;
      when "0101" | "1010" => interm_result := pi_11_32;
      when "0110" | "1001" => interm_result := pi_13_32;
      when "0111" | "1000" => interm_result := pi_15_32;
      when others => interm_result := pi_1_32;
    end case;
    if angle( angle'high ) = '1' then
      result := std_logic_vector( - interm_result );
    else
      result := std_logic_vector( interm_result );
    end if;
  end procedure cnv_angle_2_sin;

end package body sub_power_pac;

library ieee;
use ieee.std_logic_1164.all,
  ieee.numeric_std.all,
  work.sub_power_pac.all;

--! @brief For auxiliary powers supplies, this module generates the relevant signal
--!
--! The signal is intended to pass through a transformer\n
--! Its frequency is any value, let's say, as a power of 2 division ratio
--!   of the system clock\n
--! Its third harmonic is generated and added to the main signal\n
--! By this way i) the bandwidth is under control ii) the output amplitude is
--! a little bit more controlled
entity sub_power is
  port (
    --! System clock
    CLK :  in std_logic;
    RST :  in std_logic;
     --! Steps forward when is '1'. This is to control the frequency
    EN  :  in std_logic;
    --! signed value that goes as rail to rail as possible.\n
    --! *** Should be proofed for a particular size ***
    the_out : out std_logic_vector
    );
end entity sub_power;

architecture arch of sub_power is
  signal angle : std_logic_vector( 6 downto 0 );
  signal display_1, display_3 : std_logic_vector( the_out'high + 1 downto the_out'low );
begin
  assert the_out'length >= 5 report "Length of the_out vector should be at least 5" severity failure;

  main_proc : process( CLK ) is
    variable angle_1, angle_3 : std_logic_vector( 4 downto 0 );
    variable angle_build : unsigned( angle'high + 1 downto angle'low );
    variable result_cnv : std_logic_vector( the_out'high + 1 downto the_out'low );
    variable result_3_1 : std_logic_vector( the_out'high + 2 downto the_out'low );
    constant padding_1 : std_logic_vector( 1 downto 1 ) := "0";
    variable padding_sgn : std_logic_vector( 1 downto 1 );
    begin
      if rising_edge( CLK ) then
        RST_IF : if RST = '0' then
          EN_IF : if EN = '1' then
            if angle = "11111111" then
              angle <= ( others => '0' );
            else
              angle <= std_logic_vector( unsigned ( angle ) + 1 );
            end if;
            -- Yes we are taking the last value of angle, but the phase is irrelevant
            --   as long as it is the same for both 1 and 3
            angle_1 := angle( angle'high downto angle'high - 4 );
            cnv_angle_2_sin( angle_1, result_cnv );
            display_1( display_1'high ) <= not result_cnv( result_cnv'high );
            display_1( display_1'high - 1 downto display_1'low ) <=
              result_cnv( result_cnv'high - 1 downto result_cnv'low );
            padding_sgn( padding_sgn'high ) := result_cnv( result_cnv'high );
            result_3_1 := std_logic_vector( signed( result_cnv & padding_sgn ) +
                                          signed( padding_sgn & result_cnv ));

            angle_build := unsigned( angle & padding_1 ) + unsigned( padding_1 & angle );
            angle_3 := std_logic_vector( angle_build( angle_build'high - 1 downto angle_build'high - 5 ));
            cnv_angle_2_sin( angle_3, result_cnv );
            display_3( display_3'high ) <= not result_cnv( result_cnv'high );
            display_3( display_3'high - 1 downto display_3'low ) <=
              result_cnv( result_cnv'high - 1 downto result_cnv'low );
            padding_sgn( padding_sgn'high ) := result_cnv( result_cnv'high );
            result_3_1 := std_logic_vector( signed( result_3_1 ) +
                                            signed( padding_sgn & result_cnv ));
            the_out <= result_3_1( result_3_1'high downto result_3_1'low + 2 );
          end if EN_IF;
        else
          angle <= ( others => '0' );
          display_1 <= ( others => '0' );
          display_3 <= ( others => '0' );
        end if RST_IF;
      end if;
    end process main_proc;
end architecture arch;
