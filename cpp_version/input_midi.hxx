// char, short, long24 are used because this is a PoC of the VHDL version

#include <string>
#include <deque>
#include <vector>
#include <fstream>
#include <iostream>
#include <sstream>
using namespace std;

#ifndef __INPUT_MIDI__
#define __INPUT_MIDI__

#include "parameters.hxx"
#include "midi_codes.hxx"

class midi_event {
  enum state_t{ state_ts, state_code, state_key, state_val, state_string, state_end } state;
  ostream&info_out_str;
 protected:
  enum status_t{ warming_up, running, end_track } status;
  unsigned long timestamp;
  unsigned char code;
  unsigned char key;
  unsigned char value;
  unsigned short str_length;
  string user_str;
  unsigned long track_tellg;
  const bool with_time_stamp;
  unsigned char header;
  midi_event();
 public:
  midi_event(ostream&,const bool&with_time_stamp );
  bool get_event(istream&,input_params_base::clearing_t&clearing);
  bool eot() const;
  // For debug purposes, sends the content of a midi message
  friend ostream&operator<<( ostream&, const midi_event& );
  // Get the value mantissa + exponent compiled into an unsigned long used as 24 bits
  // Format is: velocity is always, full 7 bits the mantissa,
  // exponent_size of the right bits of the key (note code) is the exponent
  // a constant is the additional exponent
  unsigned long get_value( const unsigned char&exponent_size, const unsigned char&exponent_const )const;
  //  friend class parameters_midi;
  //friend class parameters_midi_file;
  //friend class parameters_midi_connec;
};

/** \brief Base of the midi method to set the parameters
 *
 * Decodes the midi messages and sets the parameters.
 * It is involved when something has to be done,
 * regardless on the fly or on schedule
 * In case of a multi track smf or midd file, instances as many as tracks
 * should be created
 * 
 */
class input_params_midi : public input_params_base, public midi_event, private midi_codes {
 public:
  input_params_midi(const bool&);
  void exec_next_event(vector<signals_param_action>&actions);
  friend ostream&operator<<(ostream&,const input_params_midi&);
};
/** \brief Midi file control
 *
 * Handles the midi files containing events and timestamps
 */
class input_params_midi_file : public input_params_midi{
  ifstream if_str;
 public:
  input_params_midi_file(const string&);
  ~input_params_midi_file();
  unsigned long check_next_time_stamp();
  bool eot() const;
  bool is_ready();
};
/** \brief Midi pc keyboard control
 *
 * Handles the midi event coming on the fly from a pc keyboard
 * The data is given as notes or text commands
 */
class input_params_midi_pckeyboard : public input_params_midi{
  istream&i_str;
 public:
  // relevant connection parameter here
  input_params_midi_pckeyboard(istream&i_str);
  unsigned long check_next_time_stamp();
  bool eot() const;
  bool is_ready();
};
/** \brief Midi pc keyboard style control
 *
 * Handles the midi event coming on the fly as the pc keyboard style
 * The data is given as notes or text commands
 * This class is intended mostly for file style connections such as pipes
 */
class input_params_midi_pckeyboard_file : public input_params_midi_pckeyboard{
  ifstream if_str;
 public:
  // relevant connection parameter here
  input_params_midi_pckeyboard_file(const string&);
  ~input_params_midi_pckeyboard_file();
};
/** \brief Midi connection control
 *
 * Handles the midi event coming on the fly from a connection
 * (electronic or network)
 */
class input_params_midi_connec : public input_params_midi{
  stringstream i_str;
 public:
  // relevant connection parameter here
  input_params_midi_connec();
  unsigned long check_next_time_stamp();
  bool eot() const;
};
// Inherit from midi_connec all the midi connections: jackaudio alsa etc...


/** \brief Receive parameters, on the fly from an UI
 *
 */
class input_params_UI : public input_params_base
{
 public:
  input_params_UI();
  unsigned long check_next_time_stamp();
  void export_next_event(const unsigned long&absolute_TS,
						 const unsigned long&diff_TS,
						 const signals_param_action&);
};


#endif
