// This class handles the final amplitude
//
// For safety reasons, there is always a volume control
// The programs sets the amplitude as a percent of the maximum
//   (means the volume value) set by the user
//
// This class hold the volume and calculate the output amplitude
//
// char, short, long24 are used because this is a PoC of the VHDL version

#ifndef __AMPLITUDE_HANDLER__
#define __AMPLITUDE_HANDLER__

class amplitude_handler
{
  unsigned char volume;
  // slew-rate uses 14 bits value plus 2 bits padding on the right
  unsigned long slewrate;
  // amplitude24 is the same range as slewrate plus one bit on the left for overflow detection
  unsigned long amplitude24;
  unsigned char requested_ampl;
  // sample_rate_id should be 1 = 48KHz 2 = 96KHz 4 = 192KHz
  const unsigned sample_rate_id;
  amplitude_handler();
 public:
  amplitude_handler(const unsigned char&sample_rate_id);
  void set_volume(const unsigned char& );
  void set_slewrate(const unsigned short& );
  void set_amplitude(const unsigned char& );
  unsigned short operator()();
};

#endif
