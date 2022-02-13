#include "parameters.hxx"

signals_param_action::signals_param_action( const unsigned short&channel_id,
											const action_list&action,
											const unsigned short&value):
  channel_id(channel_id),action(action),value(value)
{}

signals_param_action::signals_param_action():
  action(nop)
{}


input_params_base::input_params_base(const unsigned short&samples_per_TS):
  wait_for_next_TS( false ), cumul_time_stamp( 0 ),
  current_samples( 0 ),
  samples_per_TS( samples_per_TS ),
  clearing( c_unknown )
{}
input_params_base::~input_params_base()
{}
bool input_params_base::check_next_event( const unsigned short&elapsed_samples, vector<signals_param_action>&actions)
{
  bool do_leave( false );
  current_samples += elapsed_samples;
  while( do_leave == false )
	{
	  // Think to respawn the function immediately in case of a ts = 0
	  // In order to avoid awaiting for some output
	  // The function is left only if 1) it is too early against the next event
	  // 2) There are actually no event
	  if( wait_for_next_TS )
		{
		  if( current_samples >= requested_samples )
			{
			  // Something to do now
			  exec_next_event(actions);
			  current_samples -= requested_samples;
			  wait_for_next_TS = false;
			  cout << info_out_stream.str();
			  info_out_stream.str("");
			} else
			// Too early
			do_leave = true;
		} else {
		unsigned long requested_time_stamp = check_next_time_stamp();
		if( requested_time_stamp != 0xffffffff )
		  {
			// An event has been received. Computer the waiting time
			requested_samples = samples_per_TS * requested_time_stamp; 
			cumul_time_stamp += requested_time_stamp;
			wait_for_next_TS = true;
		  }
		else
		  {
			// No event or event not fully received
			do_leave = true;
			requested_samples = 0xffffffff;
			if ( eot() )
			  return false;
		  }
	  }
	}
  return true;
}

output_params_base::output_params_base(const unsigned short&samples_per_TS):
  cumul_time_stamp( 0 ), current_samples( 0 ), samples_per_TS( 4800 )
{}
output_params_base::~output_params_base()
{}
bool output_params_base::check_next_event( const unsigned short&elapsed_samples,
										   const vector<signals_param_action>&actions)
{
  current_samples += elapsed_samples;
  if ( actions.size() > 0 )
	{
	    unsigned long diff_TS;
		diff_TS = current_samples / samples_per_TS;
		cumul_time_stamp += diff_TS;
		current_samples -= diff_TS * samples_per_TS;
		for( vector<signals_param_action>::const_iterator it=actions.begin(); it!=actions.end(); ++it )
		  {
			export_next_event( cumul_time_stamp, diff_TS, *it );
			diff_TS = 0;
		  }
	}
  return true;
}

