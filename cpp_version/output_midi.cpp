#include "output_midi.hxx"


output_params_txt::output_params_txt( ostream& o_str ):
  o_str( o_str ),
  output_params_base( 4800 )
{}
void output_params_txt::cnv_2_note_velocity( const unsigned char&nbre_bits_expo,
											 const unsigned short&value,
											 unsigned char&note,
											 unsigned char&velocity)
{

}

void output_params_txt::export_next_event(const unsigned long&absolute_TS,
										  const unsigned long&diff_TS,
										  const signals_param_action&action)
{
  unsigned char note;
  unsigned char velocity;

  info_out_stream << right << setw(6) << dec << cumul_time_stamp;
  if ( action.channel_id == 0 )
	{
	  info_out_stream << "\tChannel: all\t";
	}
  else
	{
	  info_out_stream << "\tChannel: " << right << setw( 3 ) << action.channel_id << "\t";
	}
  float val_float;
  switch( action.action )
	{
	case signals_param_action::track_name:
	  info_out_stream << "Set track name to " << endl;
	  break;
	case signals_param_action::base_freq:
	  val_float = (float)action.value * 48000.0 * 4.0 * 8.0 / 16777216.0;
	  info_out_stream << "Set base frequency " << hex << action.value << ", means: " << val_float;
	  info_out_stream << "Hz (step: " << (2.0 * 48000.0 * 4.0 * 8.0 / 16777216.0) << ")" << endl;
	  break;
	case signals_param_action::main_ampl_val:
	  info_out_stream << "Sets the amplitude " << hex << action.value << ", dec: " << dec << action.value << endl;
	  break;
	case signals_param_action::main_ampl_slewrate:
	  val_float = 16777216.0 / ( (float)action.value * 48000 * 4.0 );
	  info_out_stream << "Set global amplitude slewrate " << hex << action.value;
	  info_out_stream << ", means " << val_float;
	  info_out_stream << "s 0-255 (step: 1/" << (16777216.0 /( 48000.0 * 4.0 )) << ")" << endl;
	  break;
	case signals_param_action::ampl_modul_freq:
	  val_float = (float)action.value * 48000.0 * 4.0 / 16777216.0;
	  info_out_stream << "Sets the amplitude modulation frequency " << hex << action.value;
	  info_out_stream << ", means: " << val_float;
	  info_out_stream << "Hz (step: " << (48000.0 * 4.0 / 16777216.0) << ")" << endl;
	  break;
	case signals_param_action::ampl_modul_depth:
	  info_out_stream << "Sets the amplitude modulation depth " << hex << action.value;
	  info_out_stream << ", means: " << dec << action.value << " (0-255)"<<endl;
	  break;
	case signals_param_action::pulse_freq:
	  val_float = (float)action.value * 48000.0 * 4.0 * 4.0 / 16777216.0;
	  info_out_stream << "Set pulse frequency " << hex << action.value << ", means: " << val_float;
	  info_out_stream << "Hz (step: " << (2.0 * 48000.0 * 4.0 * 4.0 / 16777216.0) << ")" << endl;
	  break;
	case signals_param_action::pulse_high_hold:
	  val_float = (float)action.value * 16.0 * 2.0 / 48000.0;
	  info_out_stream << "Set high hold time " << hex << action.value << ", means: " << val_float;
	  info_out_stream << "S (step: " << (16.0 * 2.0 / 48000.0) << ")" << endl;
	  break;
	case signals_param_action::pulse_low_hold:
	  val_float = (float)action.value * 16.0 * 2.0 / 48000.0;
	  info_out_stream << "Set low hold time " << hex << action.value << ", means: " << val_float;
	  info_out_stream << "S (step: " << (16.0 * 2.0 / 48000.0) << ")" << endl;
	  break;
	case signals_param_action::pulse_depth:
	  info_out_stream << "Sets the pulse depth " << hex << action.value << ", dec: " << dec << action.value << endl;
	  break;
	case signals_param_action::base_phase_shift:
	  info_out_stream << "Shift the phase of the base " << dec << action.value << " PI/8" << endl;
	  break;
	case signals_param_action::ampl_modul_phase_shift:
	  info_out_stream << "Shift the phase of the amplitude modulation " << dec << action.value << " PI/8" << endl;
	  break;
	case signals_param_action::pulse_phase_shift:
	  info_out_stream << "Shift the phase of the pulse " << dec << action.value << " PI/8" << endl;
	  break;
	case signals_param_action::user_volume:
	  info_out_stream << "Sets the user_volume " << hex << action.value << ", dec: " << dec << action.value << endl;
	  break;
	case signals_param_action::nop:
	  info_out_stream << "No operation " << endl;
	  break;
	default:
	  info_out_stream << endl;
	  break;
	}
  o_str << info_out_stream.str();
  info_out_stream.str("");
  o_str.flush();
}


output_params_txt_file::output_params_txt_file( const string&filename ):
  output_params_txt( of_str )
{
  of_str.open( filename.c_str(), ios_base::out );
}
output_params_txt_file::~output_params_txt_file()
{
  of_str.close();
}

