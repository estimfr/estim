#include "frequency_handler.hxx"
#include<iostream>
using namespace std;

frequency_handler::frequency_handler( const unsigned char&sample_rate_id,
									  const unsigned char&division_rate):
  global_rate( (unsigned short)sample_rate_id * (unsigned short)division_rate ),
  angle( 0 ), startCycle(false),
  high_hold( 0 ), low_hold( 0 ),
  high_hold_count( 0 ), low_hold_count( 0 ),
  lastQuadrant( 0 )
{
  // put something non null to initialise
  frequency = 1;
}
void frequency_handler::set_frequency(const unsigned short&frequency )
{
  if ( frequency < 1 )
    throw;
  this->frequency = frequency; 
  this->frequency *= 32;
  this->frequency /= global_rate;
  //cout << "Frequency settings " << this->frequency << endl;
}
/** \brief Set the high hold time
 *
 * It gets the requested value and apply the coeficient
 * according with the division rate and the sample rate used
 * The result is stored to initialize the counter if so.
 * Since the hold time terminates when the counter reaches 0
 * the DR and the SR are multiplied to the requested value
 */
void frequency_handler::set_high_hold(const unsigned short&high_hold)
{
  this->high_hold = high_hold;
  this->high_hold *= 16;
  this->high_hold *= global_rate;
  //cout << "val high_hold " << 16 * high_hold * global_rate << endl;
}
/** \brief Set the low hold time
 *
 * It gets the requested value and apply the coeficient
 * according with the division rate and the sample rate used
 * The result is stored to initialize the counter if so.
 * Since the hold time terminates when the counter reaches 0
 * the DR and the SR are multiplied to the requested value
 */
void frequency_handler::set_low_hold(const unsigned short&low_hold)
{
  this->low_hold = low_hold;
  this->low_hold *= 16;
  this->low_hold *= global_rate;
  //  cout << "val low_hold " << 16 * low_hold * global_rate << endl;
}
/** \breif Shift the phase
 *
 * Since the value is a shift between 0 and (excluded) 2.PI
 * and it is coded using 4 bits unsigned,
 * A shift is performed to move into a 24 bits value
 */ 
void frequency_handler::shift_phase(const unsigned char&shift)
{
  unsigned long shift_shifted( ((unsigned long)( 0x0f & shift )) << 20 );
  // cout << hex << angle << "  ";
  angle += shift_shifted;
  // cout << "shift of " << dec << (unsigned short)shift << ", means: " << shift_shifted << "  ";
  CheckHold();
  // cout << hex << angle << endl;
}
/** \brief Computes when the sine reached the min or the max
 *
 * The sine is checked if it passes the min or the max.
 * If 24th and 23rd bits are 01 as it was 00, the max is just passed
 * if they are 11 as they was 10, the min is just passed
 *
 * If none, the angle is checked for the overflow against 24 bits in oder
 * to clear the 25th bit (and higher)
 *
 * If just passed, the relevant counter is loaded
 */
void frequency_handler::CheckHold()
{
  unsigned char newQuadrant = angle >> 22; 
  if ( ( newQuadrant & 0x04 ) == 0x04 )
	{
	  angle &= 0x00ffffff;
	  newQuadrant = 0;
	  startCycle = true;
	}
  else if (( newQuadrant == 0x01) && (lastQuadrant == 0x00) )
	{
	  high_hold_count = high_hold;
	}
  else if (( newQuadrant == 0x03) && (lastQuadrant == 0x02) )
	{
	  low_hold_count = low_hold;
	}
  lastQuadrant = newQuadrant;
}
void frequency_handler::operator()()
{
  startCycle = false;
  if ( high_hold_count != 0 )
	{
	  high_hold_count -= 1;
	}
  else if ( low_hold_count != 0 )
	{
	  low_hold_count -= 1;
	}
  else
	{
	  angle += frequency;
	  CheckHold();
	}
};
unsigned long frequency_handler::GetAngle()const
{
  return angle;
}
bool frequency_handler::GetStartCycle()const
{
  return startCycle;
}

