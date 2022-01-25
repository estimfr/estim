#include "input_midi.hxx"

midi_event::midi_event(ostream&os,const bool&with_time_stamp ):
  info_out_str(os),with_time_stamp( with_time_stamp ),
  status( warming_up ), timestamp( 0 ),
  code( 0 ), key( 0 ), value( 0 ), track_tellg( 0 ),
  state( state_end ), header( 0 )
{}
bool midi_event::get_event(istream&i_str,input_params_base::clearing_t&clearing)
{
  unsigned char val_read;
  
  if( state == state_end )
	{
	  if( with_time_stamp == true )
		state = state_ts;
	  else
		state = state_code;
	}
  timestamp = 0;
  user_str = string();

  while( (i_str.eof() == false) && (status != end_track) && (state != state_end) )
	{
	  i_str.read( (char*)(&val_read) , 1 );
	  // info_out_str << hex << (unsigned short)val_read << '\t';
	  switch( state ){
		// Totally done here as the TS is always provided
	  case state_ts:
		if ( val_read > 127 )
		  {
			timestamp += val_read;
			timestamp -= 128;
			timestamp *= 128;
		  } else {
		  timestamp += val_read;
		  state = state_code;
		}
		break;
		// Totally done here as the midi code is always provided
	  case state_code:
		code = val_read;
		state = state_key;
		if ( code < 128 )
		  {
			cerr << "Error reading midi smf/mid file: position " << track_tellg << ": code "<< hex << key << " shoud have its high bit set to one" << endl;
		  }
		break;
		// Some codes may not expect parameters, they should not be in the file
		// TODO fix that
	  case state_key:
		key = val_read;
		state = state_val;
		break;
	  case state_val:
		value = val_read;
		if ( code != 0xff )
		  {
			state = state_end;
		  }
		else {
		  switch ( key )
			{
			case 03:
			  if ( value > 0 )
				{
				  state = state_string;
				  str_length = value - 1;
				}
			  else
				{
				  state = state_end;
				}
			  // end of track
			  break;
			case 0x2f:
			  status = end_track;
			  clearing = input_params_midi::c_end_of_data;
			  state = state_end;
			  break;
			default:
			  cerr << "Error reading midi smf/mid file: position " << track_tellg << ": unknown FF "<< hex << key << endl;
			  break;
			}
		}
		track_tellg += 1;
		break;
	  case state_string:
		  user_str += (string::value_type)val_read;
		if ( str_length > 0 )
		  {
			str_length -= 1;
		  }
		else
		  {
			state = state_end;
		  }
	  }	
	}
  if ((state == state_end) && (status != end_track))
	{
	  return true;
	}
  else
	{
	  return false;
	}
}

ostream& operator<<( ostream&the_out , const midi_event&me )
{
  the_out << "Timestamp: " << hex << me.timestamp << ", code: " << (unsigned short)me.code;
  the_out << ", key/note: " << (unsigned short)me.key;
  the_out << ", value: " << (unsigned short)me.value << ", optional str: " << me.user_str;
  return the_out;
}

unsigned long midi_event::get_value( const unsigned char&exponent_size, const unsigned char&exponent_const )const{
  unsigned long val( value );

  if ( exponent_const > 0 )
	{
	  val <<= exponent_const;
	}
  unsigned char expo_ind( exponent_size );
  unsigned short expo_mask( 1 );
  while( expo_ind > 0 )
	{
	  expo_ind -= 1;
	  expo_mask *= 2;
	}
  expo_mask -= 1;
  
  // info_out_str << "  ___ " << (unsigned short)exponent_size << " _ " << (unsigned short)expo_mask << " _ ";
  // info_out_str << (unsigned short)exponent_const << " ___  ";
  val <<= (expo_mask & key); 
 
  return val;
}


input_params_midi::input_params_midi(const bool&with_time_stamp):
  midi_event( info_out_stream, with_time_stamp ),input_params_base( 4800 )
{}



void input_params_midi::exec_next_event(vector<signals_param_action>&actions)
{
  // float val_float;
  unsigned long long_value;
  // info_out_stream << "TS cumul: " << dec << cumul_time_stamp / 10 << '\t';
  signals_param_action action;
  
  action.channel_id = code & 0x0f;
  switch( code & 0xf0 )
	{
	case 0x80:
	  // info_out_stream << "Note off, only for handling the time stamp" << endl;
	  break;
	case 0x90:
	  switch( key & 0xf8 )
		{
		case 0x00:
		  long_value = get_value( 3, 1 );
		  // val_float = (float)long_value * 48000.0 * 4.0 * 8.0 / 16777216.0;
		  // info_out_stream << "Set base frequency " << hex << long_value << ", means: " << val_float;
		  // info_out_stream << "Hz (step: " << 2.0 * 48000.0 * 4.0 * 8.0 / 16777216.0 << ')' << endl;
		  action.action = signals_param_action::base_freq;
		  action.value = long_value;
		  break;
		case 0x08:
		  long_value = get_value( 3, 0 );
		  // val_float = 16777216.0 / ( (float)long_value * 48000 * 4.0 );
		  // info_out_stream << "Set global amplitude slewrate " << hex << long_value;
		  // info_out_stream << ", means " << val_float;
		  // info_out_stream << "s 0-255 (step: 1/" << 16777216.0 /( 48000.0 * 4.0 ) << ')' << endl;
		  action.action = signals_param_action::main_ampl_slewrate;
		  action.value = long_value;
		  break;
		case 0x10:
		  switch( key & 0x7 )
			{
			case 0x00:
			case 0x01:
			  long_value = get_value( 1, 0 );
			  // info_out_stream << "Sets the amplitude " << hex << long_value << ", dec: " << dec << long_value << endl;
			  action.action = signals_param_action::main_ampl_val;
			  action.value = long_value;
			  break;
			case 0x02:
			  // Abort
			  status = end_track;
			  clearing = c_abort;
			  break;
			case 0x04:
			  long_value = get_value( 0, 1 );
			  // info_out_stream << "Sets the amplitude modulation depth " << hex << long_value;
			  // info_out_stream << ", means: " << dec << long_value << " (0-255)"<<endl;
			  action.action = signals_param_action::ampl_modul_depth;
			  action.value = long_value;
			  break;
			case 0x05:
			  long_value = get_value( 0, 1 );
			  // info_out_stream << "Sets the pulse depth " << hex << long_value;
			  // info_out_stream << ", means: " << dec << long_value << " (0-255)"<<endl;
			  action.action = signals_param_action::pulse_depth;
			  action.value = long_value;
			  break;
			case 0x06:
			  // info_out_stream << "Sets phase shift " << hex << long_value;
			  // 
			  action.value = get_value( 0, 0 );
			  switch( action.value & 0x70 )
				{
				case 0x10:  action.action = signals_param_action::base_phase_shift;  break;
				case 0x20:  action.action = signals_param_action::pulse_phase_shift;  break;
				case 0x30:  action.action = signals_param_action::ampl_modul_phase_shift;  break;
				}
			  action.value &= 0x0f;
			  break;
			case 0x03:
			  action.action = signals_param_action::nop;
			  break;
			}
		  break;
		case 0x18:
		  long_value = get_value( 3, 0 );
		  // val_float = (float)long_value * 48000.0 * 4.0 * 4.0 / 16777216.0;
		  // info_out_stream << "Sets the amplitude modulation frequency " << hex << long_value;
		  // info_out_stream << ", means: " << val_float;
		  // info_out_stream << "Hz (step: " << 48000.0 * 4.0 * 4.0 / 16777216.0 << ')' << endl;
		  action.action = signals_param_action::ampl_modul_freq;
		  action.value = long_value;
		  break;
		case 0x20:
		  if ( key == 0x20 )
			{
			  long_value = get_value( 2, 0 );
			  // info_out_stream << "Sets the pulse data " << hex << long_value;
			  // info_out_stream << ", means: " << dec << long_value << " (0-255)"<<endl;
			  action.action = signals_param_action::pulse_freq;
			  action.value = long_value;
			} else {  // key == 0x24
			long_value = get_value( 2, 6 );
			// info_out_stream << "Sets the pulse data " << hex << long_value;
			// info_out_stream << ", means: " << dec << long_value << " (0-255)"<<endl;
			action.action = signals_param_action::pulse_high_hold;
			action.value = long_value;
		  }
		  break;		  
		case 0x28:
		  if ( key == 0x28 )
			{
			  long_value = get_value( 2, 6 );
			  // info_out_stream << "Sets the pulse data " << hex << long_value;
			  // info_out_stream << ", means: " << dec << long_value << " (0-255)"<<endl;
			  action.action = signals_param_action::pulse_low_hold;
			  action.value = long_value;
			} else {
			long_value = get_value( 2, 6 );
			// info_out_stream << "Sets the pulse data " << hex << long_value;
			// info_out_stream << ", means: " << dec << long_value << " (0-255)"<<endl;
			action.action = signals_param_action::nop;
			action.value = long_value;
		  }
		  break;		  
		default:
		  // info_out_stream << "Unknown action" << endl;
		  break;
		}
	  actions.push_back( action );
	  break;
	case 0xf0:
	  if ( code == 0xff )
		{
		  switch ( key )
			{
			case 0x03:
			  // info_out_stream << "Name of track: " << user_str << endl;
			  action.action = signals_param_action::track_name;
			  actions.push_back( action );
			  break;
			case 0x2f:
			  // info_out_stream << "Explicit end of track" << endl;
			  break;
			default:
			  // info_out_stream << "Unknown control code" << endl;
			  break;
			}
		}// else
		// info_out_stream << "Unknown midi code" << endl;
	}			  
}

ostream&operator<<(ostream&the_out,const input_params_midi&)
{
  

  return the_out;
}


input_params_midi_file::input_params_midi_file( const string&filename ):
  input_params_midi( true )
{
  //  unsigned long midi_header( 22 );
  if_str.open( filename.c_str(), ios_base::binary );
  // if_str.seekg( midi_header );
  if ( if_str.is_open() == false )
	{
	  status = end_track;
	  clearing = c_file_err;
	}
}
input_params_midi_file::~input_params_midi_file()
{
  // TODO check here if the length is the declared length. if not report a warning
  if_str.close();
}


unsigned long input_params_midi_file::check_next_time_stamp()
{
  if ( get_event( if_str, clearing ) )
	{
	  //	  info_out_stream<< (*this);
	  return timestamp;
	}else
	return 0xffffffff;
}
bool input_params_midi_file::eot()const
{
  return status == end_track;
}
bool input_params_midi_file::is_ready()
{
  unsigned char val_read;

  while( (if_str.eof() == false) && (status == warming_up) )
	{
	  if_str.read( (char*)(&val_read) , 1 );
	  switch( header )
		{
		case 0 : if ( val_read != 'M' ) status = end_track;  clearing = c_data_err;  break;
		case 1 : if ( val_read != 'T' ) status = end_track;  clearing = c_data_err;  break;
		case 2 : if ( val_read != 'h' ) status = end_track;  clearing = c_data_err;  break;
		case 3 : if ( val_read != 'd' ) status = end_track;  clearing = c_data_err;  break;
		case 14 : if ( val_read != 'M' ) status = end_track;  clearing = c_data_err;  break;
		case 15 : if ( val_read != 'T' ) status = end_track;  clearing = c_data_err;  break;
		case 16 : if ( val_read != 'r' ) status = end_track;  clearing = c_data_err;  break;
		case 17 : if ( val_read != 'k' ) status = end_track;  clearing = c_data_err;  break;
		  // TODO complete the header checking
		  // In order to run with beats others than code 6
		}
	  header += 1;
	  if ( header == 22 )
		{
		  status = running;
		}
	}

  return status != warming_up;
}


input_params_midi_pckeyboard::input_params_midi_pckeyboard( istream&i_str ):
  input_params_midi( true ), i_str( i_str )
{

}


unsigned long input_params_midi_pckeyboard::check_next_time_stamp()
{
  // TODO read and convert here
	return 0xffffffff;
}

bool input_params_midi_pckeyboard::eot()const
{
  return status == end_track;
}
bool input_params_midi_pckeyboard::is_ready()
{
  return status != warming_up;
}

input_params_midi_pckeyboard_file::input_params_midi_pckeyboard_file( const string&filename ):
  input_params_midi_pckeyboard( if_str )
{
  if_str.open( filename.c_str(), ios_base::binary );
}
input_params_midi_pckeyboard_file::~input_params_midi_pckeyboard_file()
{
  if_str.close();
}

	
input_params_midi_connec::input_params_midi_connec():
  input_params_midi( false )
{
}
unsigned long input_params_midi_connec::check_next_time_stamp()
{
  return 0xffffffff;
}
bool input_params_midi_connec::eot()const
{
  return true;
}

unsigned long input_params_UI::check_next_time_stamp(){}
void input_params_UI::export_next_event(const unsigned long&absolute_TS,
										const unsigned long&diff_TS,
										const signals_param_action&)
{}
