#include "amplitude_handler.hxx"
#include <iostream>
using namespace std;

amplitude_handler::amplitude_handler(const unsigned char&sample_rate_id):
  volume( 255 ), requested_ampl( 0 ), amplitude24( 0 ), slewrate( 2048 ), sample_rate_id( sample_rate_id )
{}
void amplitude_handler::set_volume( const unsigned char&volume )
{
  this->volume = volume;
}
void amplitude_handler::set_amplitude( const unsigned char&amplitude )
{
  requested_ampl = amplitude;
}
void amplitude_handler::set_slewrate( const unsigned short&slewrate )
{
  this->slewrate = slewrate;
  this->slewrate *= 4;
  this->slewrate /= sample_rate_id;
}

unsigned short amplitude_handler::operator()()
{
  if( ((unsigned char)(amplitude24>>16)) > requested_ampl )
	{
	  amplitude24 -= slewrate;
	  if ( (( amplitude24 & 0x10000000 ) == 0x10000000 ) ||
		   (((unsigned char)(amplitude24>>16)) < requested_ampl ) )
		amplitude24 = ((unsigned long)requested_ampl) << 16;
	}
  else if (((unsigned char)(amplitude24>>16)) < requested_ampl )
	{
	  amplitude24 += slewrate;
	  if (( ( amplitude24 & 0x01000000 ) == 0x01000000 ) ||
		  (((unsigned char)(amplitude24>>16)) > requested_ampl ) )
		amplitude24 = ((unsigned long)requested_ampl) << 16;
	}
  //    cout << hex << ((unsigned short)volume) * ((unsigned short)(amplitude24>>16)) << "  ";

  return ((unsigned short)volume) * ((unsigned short)(amplitude24>>16));
}


