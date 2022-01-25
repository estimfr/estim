#ifndef __MIDI_CODES__
#define __MIDI_CODES__

/** \brief Base of the midi input and output method
 *
 * Designed for the documentation tools\n
 * \n
 * Format: e = exponent, m = mantissa, c = constant to exponent\n
 * 0000 0eee 0mmmmmmm c=1 Base frequency             max = 2976.56Hz step = 23.44Hz min = 0.183Hz, 5.46s step = 0.366Hz\n
 * 0000 1eee 0mmmmmmm c=0 Main amplitude slew-rate   max = ??? min step = ? max step = ?\n
 * 0001 000e 0mmmmmmm c=1 Main amplitude             max = 254 min step = 1 max step = 2\n
 * 0001 0010 0xxxxxxx     Abort this parameters input channel, use this for testing\n
 * 0001 0011              Reserved\n
 * 0001 0100 0mmmmmmm c=1 Amplitude modulation depth max = 127 step = 2\n
 * 0001 0101 0mmmmmmm c=1 Pulse depth                max = 127 step = 2\n
 * 0001 0110 0001mmmm c=0 Phase shift of the base signal, use with caution\n
 * 0001 0110 0010mmmm c=0 Phase shift of the pulse signal, use with caution\n
 * 0001 0110 0011mmmm c=0 Phase shift of the amplitude modulation signal, use with caution\n
 * 0001 0111 0xxxxxxx     NOP\n

 * 0001 1eee 0mmmmmmm c=0 Amplitude modulation freq  max = 186.035Hz step = 1.465Hz min = 0.01144Hz, 87.38s step 43.69s\n

 * Obsolete
 * 0001 1100 0mmmmmmm c=1 Amplitude modulation depth max = 127 step = 2
 * 0001 1101 0mmmmmmm c=1 Pulse depth                max = 127 step = 2
 * 0001 1110 0001mmmm c=0 Phase shift of the base signal, use with caution
 * 0001 1110 0010mmmm c=0 Phase shift of the pulse signal, use with caution
 * 0001 1110 0011mmmm c=0 Phase shift of the amplitude modulation signal, use with caution
 * 0001 1111 0xxxxxxx     NOP

 * 0010 00ee 0mmmmmmm c=0 Pulse frequency\n
 * 0010 01ee 0mmmmmmm c=6 High hold time\n
 * 0010 10ee 0mmmmmmm c=6 Low hold time\n
 * 0010 11ee 0mmmmmmm     Reserved\n
 * \n
 * 1xxx xxxx xxxxxxxx     Can not be used as it is not a midi note code
 */ 

class midi_codes
{};


#endif
