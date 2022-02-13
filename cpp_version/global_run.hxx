// char, short, long24 are used because this is a PoC of the VHDL version

#include <deque>
#include <vector>
#include <fstream>
using namespace std;

#include "sample_step.hxx"
#include "main_loop.hxx"

#ifndef __GLOBAL_RUN__
#define __GLOBAL_RUN__

class global_run_base {
  global_run_base(void);
 public:
  main_loop&signals;
 public:
  explicit global_run_base(main_loop&signals);
};
class global_run_single : public global_run_base
{
  global_run_single(void);
public:
  explicit global_run_single(main_loop&signals );
  bool run_single(vector<signed short>&);

};
class global_run_buffer : public global_run_base
{
  global_run_buffer(void);
public:
  explicit global_run_buffer(main_loop&signals);
  unsigned short run_buffer( signed short*const& val_list, const unsigned short&length );
};
class global_run_file : public global_run_buffer
{
  ofstream outputfile_stream;
  signed short values[20000];
  global_run_file(void);
 public:
  global_run_file( main_loop&signals, const char*const&filename );
  ~global_run_file(void);
  void operator()(void);
};


#endif
