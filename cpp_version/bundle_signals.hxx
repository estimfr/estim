// char, short, long24 are used because this is a PoC of the VHDL version

#include "amplitude_handler.hxx"
#include "frequency_handler.hxx"
#include "parameters.hxx"
#include "sample_step.hxx"

#ifndef __BUNDLE_SIGNALS__
#define __BUNDLE_SIGNALS__

#include <deque>
#include <map>
using namespace std;

/** \brief Bundles all the primitives of one signal
 *
 * This class as to be implemented as many as output channels
 * It holds all the parameters and the primitives of one signal
 */
class signal_channel{
  sample_step*the_step;
  sample_step_sine ampl_modul_step;
  sample_step_sine pulse_step;
  unsigned short channel_id;
 public:
  signal_channel( const unsigned short&channel_id,
				  const unsigned char&sample_rate_id,
				  const unsigned char&mode );
  ~signal_channel();
  void exec_next_event( const vector<signals_param_action>& );
  amplitude_handler amplitude;
  frequency_handler frequency;
  amplitude_handler ampl_modul_depth;
  frequency_handler ampl_modul_freq;
  amplitude_handler pulse_depth;
  frequency_handler pulse_freq;
  signed short operator()();
};


#endif
