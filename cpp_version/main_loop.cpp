#include "main_loop.hxx"


main_loop::main_loop( const unsigned char&sample_rate_id,
					  const unsigned char&mode,
					  const unsigned short&n_channels,
					  const unsigned short samples_per_param_check,
					  const unsigned long shutdown_length):
  sample_rate_id( sample_rate_id ),
  samples_count( 0 ),
  samples_per_param_check( samples_per_param_check ),
  shutdown_start( shutdown_length ),
  shutdown_count( 0 )
{
  samples_per_TS_unit = sample_rate_id * samples_per_param_check;
  //  cout << "SPTU " <<samples_per_TS_unit << endl;

  for( unsigned short ind= 0 ; ind < n_channels; ind++ )
	{
	  unsigned char actual_mode;
	  signal_channel*sc;
	  if ( mode == 'b' || mode == 'B' )
		{
		  if ((( ind / 2 ) * 2) == ind )
			actual_mode = 's';
		  else
			actual_mode = 'p';
		}
	  else
		actual_mode = mode;

	  sc = new signal_channel( ind + 1, sample_rate_id, actual_mode );
	  signal_list.insert( pair<unsigned short,signal_channel*>( ind, sc ));
	}
}
main_loop::~main_loop()
{
  signal_channel*sc;
  for( map<unsigned short, signal_channel*>::const_iterator it=signal_list.begin(); it!=signal_list.end(); ++it)
	delete it->second;
  for( deque<input_params_base*>::const_iterator it=params_input_list.begin(); it!=params_input_list.end(); ++it)
	delete *it;
  for( deque<output_params_base*>::const_iterator it=params_output_list.begin(); it!=params_output_list.end(); ++it)
	delete *it;
}
main_loop&main_loop::operator+=(input_params_base*const the_input)
{
  params_input_list.push_back( the_input );
  return*this;
};
main_loop&main_loop::operator+=(output_params_base*const the_output)
{
  params_output_list.push_back( the_output );
  return*this;
};
unsigned short main_loop::GetSamplesSize()const
{
  return (short)signal_list.size();
}
bool main_loop::operator()(vector<signed short>&the_out)
{
  // First execute the parameters changes if so
  // Since there are more samples (48, 96 or 192KHz) than events
  //   don't laos the system for nothing
  if ( samples_count != 0 )
	samples_count -= 1;
  else
	{
	  if( shutdown_count > 0 )
		{
		  if ( shutdown_count != shutdown_start )
			shutdown_count += 1;
		}else{
		if ( exec_actions() == false )
		  shutdown_count = 1;
		samples_count = samples_per_TS_unit;
	  }
	}
  // Second compute the samples
  for( struct { map<unsigned short, signal_channel*>::const_iterator its;
	vector<signed short>::iterator it_out; } s =
	{ signal_list.begin(), the_out.begin() };
	   s.its != signal_list.end() && s.it_out != the_out.end();
	   ++s.its,++s.it_out)
	*s.it_out = (*s.its->second)();
  return true;
};

bool main_loop::exec_actions()
{
  bool more_input_params( false );
  bool more_output_params( false );
  // Check if at least one of them has not yet reached the eot. If so true is returned
  for( deque<input_params_base*>::iterator it=params_input_list.begin(); it!=params_input_list.end(); ++it)
	if ((*it)->check_next_event( samples_per_param_check, actions ) )
	  more_input_params = true;
  for( deque<output_params_base*>::iterator it=params_output_list.begin(); it!=params_output_list.end(); ++it)
	if ((*it)->check_next_event( samples_per_param_check, actions ) )
	  more_output_params = true;
  for( map<unsigned short,signal_channel*>::iterator it=signal_list.begin(); it!=signal_list.end(); ++it)
  	(it->second)->exec_next_event( actions );
  actions.clear();

  return more_input_params;
}
/*void main_loop::exec_actions(vector<signals_param_action>actions)
{
  for( vector<signals_param_action>::const_iterator ita=actions.begin(); ita!=actions.end(); ita++)
	  for( map<unsigned short, signal_channel*>::const_iterator its=signal_list.begin();
		   its != signal_list.end();
		   its++)
		if( ita->channel_id == 0 || ita-> channel_id == its->first )
		  switch( ita->action )
			{
			case signals_param_action::base_freq: (*its->second).frequency.set_frequency( ita->value );break;
			case signals_param_action::main_ampl_val: (*its->second).amplitude.set_amplitude( ita->value );break;
			case signals_param_action::main_ampl_slewrate: (*its->second).amplitude.set_slewrate( ita->value );break;
			case signals_param_action::ampl_modul_freq: break;
			case signals_param_action::ampl_modul_depth: break;
			case signals_param_action::user_volume: (*its->second).amplitude.set_volume( ita->value );break;
			}
}
*/
bool main_loop::is_all_ready()const
{
  bool all_ready( true );

  for( deque<input_params_base*>::const_iterator it=params_input_list.begin(); it!=params_input_list.end(); ++it)
	if ((*it)->is_ready() == false )
	  all_ready = false;

  return all_ready;
}
string main_loop::get_clearing()const
{
  ostringstream oss;
  bool all_ready( true );

  for( deque<input_params_base*>::const_iterator it=params_input_list.begin(); it!=params_input_list.end(); ++it)
	{
	  oss << "Exit input parameyters channel: ";
	  switch ((*it)->clearing )
		{
		case input_params_base::c_unknown: oss << "Unknown reason";  break;
		case input_params_base::c_end_of_data: oss << "Data reached the end";  break;
		case input_params_base::c_abort: oss << "Abort instruction";  break;
		case input_params_base::c_file_err: oss << "File err (may not found)";  break;
		case input_params_base::c_net_err: oss << "Network error";  break;
		case input_params_base::c_data_err: oss << "Data error (maybe header corrupted)";  break;
		  }
	  oss << endl;
	}

  return oss.str();
}

