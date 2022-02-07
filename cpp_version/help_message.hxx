#include <iostream>
#include <fstream>
#include <sstream>


string help()
{
  ostringstream ostrstm;

  ostrstm << "Usage: estim <options>. Returns when no input parameters channel are active anymore (or on error)" << endl;
  ostrstm << "At least one output parameters channel OR one raw file OR one audio output is compulsory" << endl;
  ostrstm << "COMMAND LINE OPTIONS" << endl;
  ostrstm << "The option order is not significant unless otherwyse" << endl;
  ostrstm << "Details the options with concurrency and with multiple invocation (MI) behavior:" << endl;
  ostrstm << endl << "-h" << endl;
  ostrstm << "\tDisplays this help. Quit if no other options (other than -v) are specified" << endl;
  ostrstm << "\tMI: The help is displayed multiple times" << endl;
  ostrstm << endl << "-v" << endl;
  ostrstm << "\tDisplays the version. Quit if no other options (other than -h) are specified" << endl;
  ostrstm << "\tMI: The version is displayed multiple times" << endl;
  ostrstm << endl << "-d" << endl;
  ostrstm << "\tSet the debug level" << endl;
  ostrstm << "\tThe default is 0: no debug messages sent to the std output. MI: Only the last usage is considered" << endl;
  ostrstm << endl << "-M" << endl;
  ostrstm << "\tSwitch the format of the input or output parameters into midi mapped notes" << endl;
  ostrstm << "\tShould be placed before a -o or a -i option" << endl;
  ostrstm << "\tIt is the defult one for the -i option. MI: Only the last usage is considered" << endl;
  ostrstm << endl << "-o filename" << endl;
  ostrstm << "\tSpecifies an output parameters channel to export text data about the values and the midi code"<< endl;
  ostrstm << "\tA filename can be given, use - for the console output" << endl;
  ostrstm << "\t0..N MI: They all run in parallel, be careful when specifying two times the same one" << endl;
  ostrstm << endl << "-i filename" << endl;
  ostrstm << "\tSpecifies an input parameters channel using midi mapped commands" << endl;
  ostrstm << "\tIf a filename is specified and the .mid is recognized, The format is the notes mapped midi" << endl;
  ostrstm << "\tIf a filename is specified and the .mid is not recognized, the format is some text formatted TODO" << endl;
  ostrstm << "\tIf - is involved, the format is some text formatted coming from the console TODO" << endl;
  ostrstm << "\t1..N MI: They all run in parallel, be careful when specifying two times the same one" << endl;
  ostrstm << endl << "-f filename" << endl;
  ostrstm << "\tSpecifies a raw signal file. Format is PCM 16 bits as many channels as defined by the -n option" << endl;  
  ostrstm << "\t0..1 MI: Only the last usage is considered" << endl;
  ostrstm << endl << "-c number" << endl;
  ostrstm << "\tSpecifies the number of audio or raw file channels." << endl;
  ostrstm << "\tThe value can be 0. In such case at least one output parameters channel should be defined" << endl;
  ostrstm << "\tThis option is mostly used to convert a parameter format into another one" << endl; 
  ostrstm << "\tIf not involved, 0 is the default MI: Only the last usage is considered" << endl;
  ostrstm << endl << "-t" << endl;
  ostrstm << "\tFollow the time beat, even if no audio output is selected" << endl;
  ostrstm << "\tIf no option to define an audio output is defined, the software computes as fast as the machine can do" << endl;
  ostrstm << "\tThis option execute the time stamps and plays as an audio output would have do TODO" << endl;
  ostrstm << endl << "-j peer-name" << endl;
  ostrstm << "\tUse jackaudio as audio channel TODO" << endl;
  ostrstm << endl << "-r"; ostrstm << endl;
  ostrstm << "\tSpecifies the sample rate" << endl;
  ostrstm << "\tOnly 1= 48KHz, 2= 96KHz and 4=192KHz are valid" << endl;
  ostrstm << "\tIf not involved, 1 is the default MI: Only the last usage is considered" << endl;
  return ostrstm.str();
}

