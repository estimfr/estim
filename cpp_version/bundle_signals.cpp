#include "global_run.hxx"


extern unsigned char debug_level;

signal_channel::signal_channel( const unsigned short&channel_id,
								const unsigned char&sample_rate_id,
								const unsigned char&mode):
  channel_id( channel_id ),
  frequency(sample_rate_id,1), amplitude(1),
  ampl_modul_depth( 1 ), ampl_modul_freq(sample_rate_id,8),
  pulse_depth( 1 ), pulse_freq(sample_rate_id,2),
  ampl_modul_step( ampl_modul_freq ), 
  pulse_step( pulse_freq )
{
  switch( mode )
	{
	case 's':
	case 'S':
	  the_step = new sample_step_sine( frequency );
	  break;
	case 'p':
	case 'P':
	  the_step = new sample_step_pulse( frequency, 10 );
	  break;
	case 't':
	case 'T':
	  the_step = new sample_step_txt( frequency );
	  break;
	case 'd':
	case 'D':
	  return;
	default:
	  cerr<< "Bad mode"<<endl;
	  throw;
	  break;
	}
}
signal_channel::~signal_channel()
{
    delete the_step;
}
signed short signal_channel::operator()()
{
  // Primitive 1 the amplitude
  unsigned long base_amplitude( amplitude() );
  unsigned long pulse_amplitude = base_amplitude * pulse_depth();
  // return to short
  pulse_amplitude /= 65536;
  if ( pulse_amplitude >= 65536 )
	cerr << "Problems 1 in signal_channel::operator() PA:" << dec << pulse_amplitude << " BA:" << base_amplitude << endl;

  // Primitive 2 pulse
  // Get the sin of the pulse and divide by 2 for a range of signed -1/2 to +1/2
  signed short pulse_run = pulse_step( (unsigned short)pulse_amplitude );
  if ( pulse_run == -32768 )
	cerr << "Problems 2 in signal_channel::operator()" << endl;
  // Compute the pulse in a range of signed 0 +1
  signed long pulse_run_0_1 = (signed long)pulse_amplitude / 2 - (signed long)pulse_run;
  if ( pulse_run_0_1 < 0 )
	{
	  if ( pulse_run_0_1 < -3 )
	  	cerr << "Problems 3 in signal_channel::operator()" << endl;
	  pulse_run_0_1 = 0;
	}
  if ( (unsigned short)pulse_run_0_1 > base_amplitude )
	cerr << "Problems 4 in signal_channel::operator()" << endl;
  unsigned short pulse_output = base_amplitude - (unsigned short)pulse_run_0_1;

  // Primitive 3 amplitude modulation
  // Get the sin of the amplitude modulation and divide by 2 for a range of signed -1/2 to +1/2
  signed short ampl_modul_run = ampl_modul_step( (unsigned short)pulse_output );
  if ( ampl_modul_run == -32768 )
	cerr << "Problems 5 in signal_channel::operator()" << endl;
  // Compute the amplitude modulation in a range of signed 0 +1
  signed long ampl_modul_run_0_1 = (signed long)pulse_output / 2 - (signed long)ampl_modul_run;
  if ( ampl_modul_run_0_1 < 0 )
	{
	  if ( ampl_modul_run_0_1 < -3 )
	  	cerr << "Problems 6 in signal_channel::operator()" << endl;
	  ampl_modul_run_0_1 = 0;
	}
  if ( (unsigned short)ampl_modul_run_0_1 > pulse_output )
	{
	  if ( debug_level >= 3 || ( debug_level >= 1 && (unsigned short)ampl_modul_run_0_1 > ( pulse_output + 1 )))
		{
		  cerr << "Problems 7 in signal_channel::operator()" << dec << (unsigned short)ampl_modul_run_0_1 << "  " << pulse_output << "\t" << endl;
		}
	  ampl_modul_run_0_1 = pulse_output;
	}
  unsigned short ampl_modul_output = pulse_output - (unsigned short)ampl_modul_run_0_1;
  

  return (*the_step)(ampl_modul_output);
}


void signal_channel::exec_next_event( const vector<signals_param_action>&spa )
{
  for( vector<signals_param_action>::const_iterator it = spa.begin(); it != spa.end(); it++ )
	if( (it->channel_id == 0) || (it->channel_id == channel_id) )
	  switch( it->action )
		{
		case signals_param_action::base_freq:
		  frequency.set_frequency( (unsigned short)it->value );
		  break;
 		case signals_param_action::base_phase_shift:
		  frequency.shift_phase( (unsigned char)it->value );
		  break;
		case signals_param_action::main_ampl_val:
		  amplitude.set_amplitude( (unsigned char)it->value);
		  break;
		case signals_param_action::main_ampl_slewrate:
		  amplitude.set_slewrate( it->value );
		  break;
		case signals_param_action::ampl_modul_freq:
		  ampl_modul_freq.set_frequency( (unsigned short)it->value );
		  break;
		case signals_param_action::ampl_modul_depth:
		  ampl_modul_depth.set_amplitude( (unsigned char)it->value );
		  break;
 		case signals_param_action::ampl_modul_phase_shift:
		  ampl_modul_freq.shift_phase( (unsigned char)it->value );
		  break;
		case signals_param_action::pulse_freq:
		  pulse_freq.set_frequency( (unsigned short)it->value );
		  break;
		case signals_param_action::pulse_depth:
		  pulse_depth.set_amplitude( (unsigned char)it->value );
		  break;
 		case signals_param_action::pulse_high_hold:
		  pulse_freq.set_high_hold( (unsigned short)it->value );
		  break;
 		case signals_param_action::pulse_low_hold:
		  pulse_freq.set_low_hold( (unsigned short)it->value );
		  break;
 		case signals_param_action::pulse_phase_shift:
		  pulse_freq.shift_phase( (unsigned char)it->value );
		  break;

		}
}

ostream&operator<<(ostream&os,const signals_param_action&a){
  switch( a.action )
	{
	case signals_param_action::base_freq:  os<<"Base frequency";  break;
	case signals_param_action::main_ampl_val:  os<<"Main amplitude";  break;
	case signals_param_action::main_ampl_slewrate:  os<<"Amplitude slewrate";  break;
	case signals_param_action::ampl_modul_freq:  os<<"Ampl_Modul frequency";  break;
	case signals_param_action::ampl_modul_depth:  os<<"Ampl_Modul depth";  break;
	}
  return os;
}


