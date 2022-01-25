// char, short, long24 are used because this is a PoC of the VHDL version

#include <deque>
#include <map>
#include <vector>
#include <string>
#include <fstream>
#include <iostream>
#include <iomanip>
#include <sstream>
using namespace std;


#ifndef __OUTPUT_MIDI__
#define __OUTPUT_MIDI__

#include "midi_codes.hxx"
#include "parameters.hxx"

class output_params_txt : public output_params_base, private midi_codes
{
  void cnv_2_note_velocity( const unsigned char&nbre_bits_expo,const unsigned short&value,
					   unsigned char&note, unsigned char&velocity);
  ostream&o_str;
  output_params_txt();
 public:
  output_params_txt( ostream&o_str );
  void export_next_event(const unsigned long&absolute_TS,
						 const unsigned long&diff_TS,
						 const signals_param_action&);
  friend ostream&operator<<(ostream&,const output_params_txt&);
};
class output_params_txt_file : public output_params_txt
{
  ofstream of_str;
  output_params_txt_file();
 public:
  output_params_txt_file( const string& );
  ~output_params_txt_file();
};





#endif
