#include "global_run.hxx"

global_run_base::global_run_base(main_loop&signals):
  signals(signals)
{}

global_run_single::global_run_single(main_loop&signals):
  global_run_base(signals)
{}
bool global_run_single::run_single(vector<signed short>&the_out)
{
  signals(the_out);
  return true;
}


global_run_buffer::global_run_buffer(main_loop&signals):
  global_run_base(signals)
{}

unsigned short global_run_buffer::run_buffer( signed short*const& val_list, const unsigned short&length )
{
  unsigned short samplesSize( signals.GetSamplesSize() );
  vector<signed short>the_out(samplesSize);
  unsigned short actual_length( 0 );
  vector<signed short>::const_iterator the_out_it;
  signed short*buffer_iter = val_list;
  if ( samplesSize > 0 )
	while( ( actual_length + 2 * samplesSize ) <= length )
	{
	  signals(the_out);
	  for( the_out_it = the_out.begin(); the_out_it!= the_out.end(); ++the_out_it )
		*buffer_iter++ = *the_out_it;
	  actual_length += 2 * samplesSize;
	}
  return actual_length;
}


global_run_file::global_run_file( main_loop&signals, const char*const&filename ):
  global_run_buffer(signals), outputfile_stream( filename, ostream::binary | ostream::trunc )
{}
global_run_file::~global_run_file()
{
  outputfile_stream.flush();
  outputfile_stream.close();
}

void global_run_file::operator()()
{
  unsigned short actual_size;
  actual_size = run_buffer( values, sizeof(values) );
  outputfile_stream.write( (const char*)values, actual_size );
  outputfile_stream.flush();
};




