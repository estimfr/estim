library ieee;
use ieee.std_logic_1164.all,
  ieee.numeric_std.all;

--! More information is in the files located in the cpp_version folder
package frequency_handler_pac is

  component frequency_handler is
    generic (
      sample_rate_id_pwr2 : integer range 0 to 3;
      division_rate_pwr2 : integer range 0 to 5 );
    port (
      --! master clock
      CLK     :  in std_logic;
      --! Steps forward when is '1'. This is to control the frequency
      EN      :  in std_logic; 
      RST       :  in std_logic;
      parameter :  in std_logic_vector( 15 downto 0 );
      --! writes only one parameter at a time
      --! 001=set frequency, TODO steps and limits
      --! 010=set high hold, 011=set low hold, TODO steps and limits
      --! 100=shift the phase 4 low bits for a shift of N times PI/8 
      write_param :  in std_logic_vector( 2 downto 0 );
      start_cycle : out std_logic;
      angle_out   : out std_logic_vector( 23 downto 0 ));
  end component frequency_handler;
end package frequency_handler_pac;

library ieee;
use ieee.std_logic_1164.all,
  ieee.numeric_std.all;

entity frequency_handler is
  generic (
    sample_rate_id_pwr2 : integer range 0 to 3;
    division_rate_pwr2 : integer range 0 to 5 );
  port (
     --! master clock
    CLK     :  in std_logic;
    --! Steps forward when is '1'. This is to control the frequency
    EN      :  in std_logic; 
    RST       :  in std_logic;
    parameter :  in std_logic_vector( 15 downto 0 );
    --! writes only one parameter at a time
    --! 001=set frequency, TODO steps and limits
    --! 010=set high hold, 011=set low hold, TODO steps and limits
    --! 100=shift the phase 4 low bits for a shift of N times PI/8 
    write_param :  in std_logic_vector( 2 downto 0 );
    start_cycle : out std_logic;
    angle_out   : out std_logic_vector( 23 downto 0 ));
end entity frequency_handler;

architecture arch of frequency_handler is
  signal frequency : std_logic_vector( 23 downto 0 ) := ( others => 'L' );
  signal hold_count : std_logic_vector( 15 + 4 + sample_rate_id_pwr2 + division_rate_pwr2 downto 0 );
  signal high_hold  : std_logic_vector( hold_count'range );
  signal low_hold  : std_logic_vector( hold_count'range );
  signal angle : std_logic_vector( frequency'range );
  constant padding_low_PS : std_logic_vector( angle'high - 2 downto angle'low ) := ( others => '0' );
begin
  assert sample_rate_id_pwr2 /= 3 report "Sample rate is 384, has never been tested" severity warning; 
  angle_out <= angle;
  
  main_proc : process( CLK )
    variable angle_v : std_logic_vector( angle'range );
    variable angle_count_v : boolean;
    variable quadrants : std_logic_vector( 3 downto 0 );
  begin
    if rising_edge( CLK ) then
      RST_IF : if RST = '0' then
        angle_v := angle;
        case write_param is
          when "001" =>
            for ind in parameter'length - 1 downto 0 loop
              if ( ind + 5 - sample_rate_id_pwr2 - division_rate_pwr2 ) > 0 then
                frequency( frequency'low + ind + 5 - sample_rate_id_pwr2 - division_rate_pwr2 ) <=
                  parameter( parameter'low + ind );
              end if;
            end loop;
          when "010" =>
            high_hold( high_hold'high downto high_hold'high + 1 - 4 - sample_rate_id_pwr2 - division_rate_pwr2 ) <=
              parameter;
            null;
          when "011" =>
            low_hold( low_hold'high downto low_hold'high + 1 - 4 - sample_rate_id_pwr2 - division_rate_pwr2 ) <=
              parameter;
          when "100" =>
            angle_v := std_logic_vector( unsigned( angle ) +
                                         unsigned( parameter( parameter'low + 3 downto parameter'low ) & padding_low_PS ));
          when others => null;
        end case;

        if hold_count /= std_logic_vector( to_unsigned ( 0 , hold_count'length )) then
          hold_count <=std_logic_vector( unsigned( hold_count ) - 1 );
        else
          angle_v := std_logic_vector( unsigned( angle_v ) + unsigned( frequency ));
        end if;
          
        quadrants := angle( angle_v'high downto angle_v'high - 1 ) &
                     angle_v( angle_v'high downto angle_v'high - 1 );
        case quadrants is
          when "1100" =>
              start_cycle <= '1';
            when "0001" =>
              hold_count <= high_hold;
              start_cycle <= '0';
            when "0110" =>
              hold_count <= low_hold; 
              start_cycle <= '0';
            when others =>
            start_cycle <= '0';
          end case;
        angle <= angle_v;
      else
        high_hold <= ( others => '0' );
        low_hold <= ( others => '0' );
        hold_count <= ( others => '0' );
        frequency <= ( others => '0' );
        angle <= ( others => '0' );
      end if RST_IF;
    end if;
  end process main_proc;

end architecture arch;
