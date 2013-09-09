#include "RtAudio.h"
#include <sndfile.h>

#ifdef _WIN32
#define AV_EXPORT __declspec(dllexport)
#else
#define AV_EXPORT extern "C"
#endif

AV_EXPORT void av_sndfile_write(SNDFILE * file, float * buffer, int len);

void av_sndfile_write(SNDFILE * file, float * buffer, int len) {
	sf_write_float(file, buffer, len);
}