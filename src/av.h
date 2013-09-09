
typedef struct av_Audio {
	unsigned int blocksize;
	unsigned int frames;	
	unsigned int indevice, outdevice;
	unsigned int inchannels, outchannels;		
	
	double time;		// in seconds
	double samplerate;
	double lag;			// in seconds
	
	// a big buffer for main-thread audio generation
	float * buffer;
	// the buffer alternates between channels at blocksize periods:
	int blocks, blockread, blockwrite, blockstep;
	
	// only access from audio thread:
	float * input;
	float * output;	
	void (*onframes)(struct av_Audio * self, double sampletime, float * inputs, float * outputs, int frames);
	
} av_Audio;

av_Audio * av_audio_get();

// only use from main thread:
void av_audio_start(); 
