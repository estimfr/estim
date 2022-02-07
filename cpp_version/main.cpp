#include <getopt.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include "global_run.hxx"
#include "bundle_signals.hxx"
#include "output_midi.hxx"
#include "input_midi.hxx"
#include "help_message.hxx"

#include <deque>
#include <string>
#include <iostream>
#include <fstream>
#include <sstream>
using namespace std;


extern char *optarg;

unsigned char debug_level;

int main(int argc,char *argv[] )
{
  int opt;
  deque<string>file_inputs;
  deque<string>file_outputs;
  bool run_dummy( false );
  bool has_input( false );
  bool has_output( false );
  bool has_hv( false );
  bool has_cin;
  bool has_cout;

  string filename;
  char sample_rate_id = 1;
  char channels_number = 0;

  debug_level = 0;

  while (( opt= getopt( argc, argv, "d:o:i:f:c:tj:r:hv" )) != EOF ) 
	{
	  switch ( opt )
		{
		case 'd':
		  debug_level = atoi( optarg );
		  break;
		case 'o':
		  file_outputs.push_back( string( optarg ));
		  has_output = true;
		  break;
		case 'i':
		  file_inputs.push_back( string( optarg ));
		  has_input = true;
		  break;
		case 'f':
		  filename = string( optarg );
		  has_output = true;
		  break;
		case 'c':
		  channels_number = atoi( optarg );
		  break;
		case 't':
		  run_dummy = true;
		  cout << "Dummy -d OPTON IS NOT YET DONE" << endl;
		  break;
		case 'j':
		  has_output = true;
		  cout << "Jackaudio -j OPTION IS NOT YET DONE" << endl;
		  break;
		case 'r':
		  switch ( atoi( optarg ) )
			{
			case 48000: sample_rate_id = 1; break;
			case 96000: sample_rate_id = 2; break;
			case 192000: sample_rate_id = 4; break;
			default: cout << "Only 48, 96, 192KHz are allowed sample rates" << endl; break;
			}		  
		  break;
		case 'h':
		  cout << help();
		  has_hv = true;
		  break;
		case 'v':
		  cout << "estim v0.1" << endl;
		  has_hv = true;
		  break;
		}
	}
  if ( (has_input == false) && (has_output == false) )
	{
	  if ( has_hv )
		exit( EXIT_SUCCESS );
	  else {
		cout << "Both input commands channel and output should be provided" << endl;
		exit( EXIT_FAILURE );
	  }
	}
  if ( has_input == false )
	{
	  cout << "Input commands channel should be provided" << endl;
	  exit( EXIT_FAILURE );
	}
  if ( has_output == false )
	{
	  cout << "Output commands channel, output audio or raw data filename should be provided" << endl;
	  exit( EXIT_FAILURE );
	}

  if( debug_level != 0 )
	{
  	  cout << "Debug set to: " << dec << (unsigned short)debug_level << endl;
	}

  if ( filename.empty() )
	{
	  channels_number = 0;
	}
  else
	{
	  cout << "Opening raw file " << filename.c_str() << " for writing" << endl;
	}

  main_loop signals(sample_rate_id,'s',channels_number);

  for( deque<string>::iterator it= file_inputs.begin(); it != file_inputs.end(); it++ )
	// Check here for pipes and other pckeyboard style files
	if ( (*it).compare( "-" ) != 0 )
	  {
		cout << "Opening midi file " << *it << endl; 
		signals += new input_params_midi_file( *it );
	  } else {
	  cout << "Opening midi input keyboard" << endl;
	  signals += new input_params_midi_pckeyboard( cin );
	}
  // signals+=new output_params_txt;
  for( deque<string>::iterator it= file_outputs.begin(); it != file_outputs.end(); it++ )
	if ( (*it).compare( "-" ))
	  {
		cout << "Opening text output parameters file " << *it << endl;
		signals += new output_params_txt_file( *it );
	  } else {
	  cout << "Opening text output parameters console output " << endl;
	  signals += new output_params_txt( cout );
	}
  
  global_run_file grf( signals, filename.c_str() );
  //  global_run_single ers(signals);

  cout << "Initializing " << (unsigned short)channels_number << " channels" << endl;
  
  clock_t ticks( clock() );
  while( signals.is_all_ready() == false )
	{
	  cout << "waiting for some input parameters channels" << endl;
	  sleep( 1 );
	}

  unsigned short jalon( 0 );
  while( signals.exec_actions())
	{
	  grf();
	}
  
  cout << endl << signals.get_clearing() << endl;
  
  return 0;
}




