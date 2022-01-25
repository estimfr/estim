CXX?=g++
CXXFLAGS?=-O2

estim					:	main.o main_loop.o bundle_signals.o input_midi.o output_midi.o parameters.o sample_step.o global_run.o amplitude_handler.o frequency_handler.o
	$(CXX) $(CXXFLAGS) -o estim main.o main_loop.o bundle_signals.o input_midi.o output_midi.o parameters.o sample_step.o global_run.o amplitude_handler.o frequency_handler.o

main.o					:	main.cpp help_message.hxx
	$(CXX) -c $(CXXFLAGS) -o main.o main.cpp

amplitude_handler.o		:	amplitude_handler.hxx		amplitude_handler.cpp
	$(CXX) -c $(CXXFLAGS) -o amplitude_handler.o amplitude_handler.cpp

frequency_handler.o		:	frequency_handler.hxx		frequency_handler.cpp
	$(CXX) -c $(CXXFLAGS) -o frequency_handler.o frequency_handler.cpp

sample_step.o			:	sample_step.hxx	sample_step.cpp amplitude_handler.hxx frequency_handler.hxx
	$(CXX) -c $(CXXFLAGS) -o sample_step.o sample_step.cpp

bundle_signals.o		:	bundle_signals.hxx	bundle_signals.cpp sample_step.hxx parameters.hxx amplitude_handler.hxx frequency_handler.hxx
	$(CXX) -c $(CXXFLAGS) -o bundle_signals.o bundle_signals.cpp

main_loop.o		:	main_loop.hxx	main_loop.cpp sample_step.hxx parameters.hxx amplitude_handler.hxx frequency_handler.hxx
	$(CXX) -c $(CXXFLAGS) -o main_loop.o main_loop.cpp

global_run.o			:	global_run.hxx	global_run.cpp
	$(CXX) -c $(CXXFLAGS) -o global_run.o global_run.cpp

parameters.o			:	parameters.hxx parameters.cpp amplitude_handler.hxx frequency_handler.hxx
	$(CXX) -c $(CXXFLAGS) -o parameters.o parameters.cpp

input_midi.o			:	input_midi.hxx input_midi.cpp parameters.hxx amplitude_handler.hxx frequency_handler.hxx
	$(CXX) -c $(CXXFLAGS) -o input_midi.o input_midi.cpp

output_midi.o			:	output_midi.hxx output_midi.cpp parameters.hxx amplitude_handler.hxx frequency_handler.hxx
	$(CXX) -c $(CXXFLAGS) -o output_midi.o output_midi.cpp

clean			:
	rm -f *.o

