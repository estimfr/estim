#ifndef __SAMPLE_STEP_H__
#define __SAMPLE_STEP_H__

#include "amplitude_handler.hxx"
#include "frequency_handler.hxx"

#include<vector>
#include <iostream>
using namespace std;

/** \brief Base of all the wave generators
 *
 * Stores the common parameters used by all the modules
 * Returns a 16bits signed value on each call of the run operator
 */
class sample_step
{
protected:
  frequency_handler&frequency;
  sample_step();
public:
  sample_step( frequency_handler&frequency );
  virtual signed short operator()(const unsigned short&)=0;
  void set_frequency( unsigned short &frequency );
  friend class signal_channel;
};
/** \brief Inherited classes that are suitable
 *         for the final output
 */
class sample_step_output {};
/** \brief Regular sinus generator
 *
 * Generates the sinus wave until the parameters are modified
 *   according with the amplitude and the frequency
 */
class sample_step_sine : public sample_step, private sample_step_output
{
  sample_step_sine();
public:
  sample_step_sine( frequency_handler&frequency );
  signed short operator()(const unsigned short&);
};
/** \brief Regular pulse generator
 *
 * Generates bi-phase pulses until the parameters are modified
 * The amplitude is the top of the pulse
 * The frequency is the space between the starting points
 * The additional parameter width is the width of the positive and of the negative pulses
 */
class sample_step_pulse : public sample_step, private sample_step_output
{
  unsigned short state;
  unsigned short length;
  unsigned short length_count;
  sample_step_pulse();
public:
  sample_step_pulse( frequency_handler&frequency, const unsigned short& length );
  signed short operator()(const unsigned short&);
};
/** \brief Debug text generator
 *
 * Returns only one "Dirac" pulse of the amplitude
 *   at the beginning of each period (defined by the frequency)
 * Uncomment or comment to also get a cout version
 *   ... as long as one knows what he is doing!!!!!!
 */
class sample_step_txt : public sample_step, private sample_step_output
{
  ostream&out_str;
  sample_step_txt();
public:
  sample_step_txt( frequency_handler&frequency );
  signed short operator()(const unsigned short&);
};

#endif
