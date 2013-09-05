
// to compile this program:
// cc -I/usr/local/include soundfile.c -L/usr/local/lib -lsndfile -o soundfile
// to run it:
// ./soundfile

// #include directives tell the compiler to load in additional "header" files
// these files declare additional functions we can use
// we need <stdio.h> in order to use printf() below
#include <stdio.h>
// for sin()
#include <math.h>

// bring in libsndfile definitions:
#include <sndfile.h>

// the "main" function is where the program starts running
int main() {
	// declare a variable of type "int" which we will use in this function:
	int i;
    
    // printf puts text onto the output console
	// we need to add \n so that it outputs the line break at the end
    printf("hello, world\n");
    
    // define a sample format to write:
    SF_INFO info;
    info.samplerate = 44100;		// at 44.1 kHz
    info.channels = 1;				// monophonic
    info.format = SF_FORMAT_WAV | SF_FORMAT_PCM_16;	// use Microsoft WAV format
    
    // now open a sound file for writing:
    // pass in a pointer to our "info", so that it can be 
    SNDFILE* file = sf_open("mysound.wav", SFM_WRITE, &info); 
    
    // now start writing some data
    // loop the following section 44100 times
    for (i=0; i<44100; i++) {
    
    	// create a new sample value:
		// using a 32-bit floating point number:
		float value = sin(3.141592653589793 * 2. * i * 440. / 44100.);
    
    	// write one sample into the file
    	// (pass a pointer to the new sample value):
    	sf_write_float(file, &value, 1);
    }
    
    // now close the file:
    sf_close(file);
    
    // main must return an integer
    // (the value indicates whether the program succeeded or had an error)
    // (returning zero means no error occurred)
    return 0;
}
