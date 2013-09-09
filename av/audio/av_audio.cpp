#include "RtAudio.h"
#include <sndfile.h>

extern "C" {

	//typedef struct SNDFILE SNDFILE;
	
	SNDFILE * av_sndfile_out(const char * path, int channels, double samplerate);
	void av_sndfile_write(SNDFILE * file, float * buffer, int len);
	
}

void av_sndfile_write(SNDFILE * file, float * buffer, int len) {
	sf_write_float(file, buffer, len);
}