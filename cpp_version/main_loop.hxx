// char, short, long24 are used because this is a PoC of the VHDL version


#include "amplitude_handler.hxx"
#include "frequency_handler.hxx"
#include "parameters.hxx"
#include "bundle_signals.hxx"

#ifndef __MAIN_LOOP__
#define __MAIN_LOOP__

#include <deque>
#include <map>
#include <vector>
using namespace std;


/** \brief General bundle of an entire set
 *
 * Bundles:
 *   All the signals
 *   All the parameters inputs, one instance per input control
 *   All the parameters outputs, one instance per output
 */
class main_loop {
  main_loop(void);
 public:
  /** \brief Main actions list
	  It is built by all the parameters input modules
	  It is sent to all the output parameters modules
	  It is sent to the bundleler for all the output channels
  */
  vector<signals_param_action>actions;
 private:
  const unsigned char&sample_rate_id;
  //! Samples counter for the parameters set update
  unsigned short samples_count;
  //! Number of samples ran between 2 parameters updates (always based on 48KHz)
  const unsigned short samples_per_param_check;
  //! Number of samples to run for one parameter set according with the sample rate
  unsigned short samples_per_TS_unit;
  //! Not yet implemented
  const unsigned long shutdown_start;
  //! Not yet implemented 
  unsigned long shutdown_count;
  unsigned short div_debug;
  map<unsigned short, signal_channel*>signal_list;
  deque<input_params_base*>params_input_list;
  deque<output_params_base*>params_output_list;
 public:
  /** \brief Constructor
	  \param sample_rate_id Sample rate 1=48KHz, 2=96KHz and 4 =192KHz
	  \param mode Output wave (or debug text), see the generator
	  \param n_channels How many output channels
	  \param samples_per_param_check Number of samples to run for one parameter set (in or out) update
	  \param shutdown_length Not yet implemented
  */
  main_loop( const unsigned char&sample_rate_id,
			 const unsigned char&mode,
			 const unsigned short&n_channels,
			 const unsigned short samples_per_param_check = 50,
			 const unsigned long shutdown_length = 1000);
  ~main_loop(void);
  //! Adds an input parameters interface
  main_loop&operator+=(input_params_base*const);
  //! Adds an output parameters interface
  main_loop&operator+=(output_params_base*const);
  /** Get the size of a sample output
	  \return The size unit is the number of signed short elements
  */
  unsigned short GetSamplesSize(void)const;
  /** \brief Main run operator
	  This is the operator that has to be run for every output sample set
	  Indeed the scheduling is done by the output
	  \return A small array of signed short, one per channel
  */
  bool operator()(vector<signed short>&output);
  bool exec_actions(void);
  //  void exec_actions(vector<signals_param_action>actions);
  bool is_all_ready(void)const;
  string get_clearing(void)const;
};

#endif
