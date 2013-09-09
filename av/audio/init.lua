
local ffi = require "ffi"
local bit = require "bit"

-- how to find the right binary:
local ext = assert(({ OSX="dylib", Linux="so", Windows="dll" })[ffi.os], "unexpected operating system")
local searchpath = string.format("./lib?.%s;./?/lib?.%s;./av/?/lib?.%s", ext, ext, ext)
local libpath = assert(package.searchpath("audio", searchpath), "could not find binary library")
local lib = ffi.load(libpath)

ffi.cdef [[

	typedef struct SNDFILE_tag SNDFILE;
	typedef int64_t	sf_count_t;

	enum
	{	/* True and false */
		SF_FALSE	= 0,
		SF_TRUE		= 1,

		/* Modes for opening files. */
		SFM_READ	= 0x10,
		SFM_WRITE	= 0x20,
		SFM_RDWR	= 0x30,

		SF_AMBISONIC_NONE		= 0x40,
		SF_AMBISONIC_B_FORMAT	= 0x41
	} ;
	
	enum
	{	/* Major formats. */
		SF_FORMAT_WAV			= 0x010000,		/* Microsoft WAV format (little endian default). */
		SF_FORMAT_AIFF			= 0x020000,		/* Apple/SGI AIFF format (big endian). */
		SF_FORMAT_AU			= 0x030000,		/* Sun/NeXT AU format (big endian). */
		SF_FORMAT_RAW			= 0x040000,		/* RAW PCM data. */
		SF_FORMAT_PAF			= 0x050000,		/* Ensoniq PARIS file format. */
		SF_FORMAT_SVX			= 0x060000,		/* Amiga IFF / SVX8 / SV16 format. */
		SF_FORMAT_NIST			= 0x070000,		/* Sphere NIST format. */
		SF_FORMAT_VOC			= 0x080000,		/* VOC files. */
		SF_FORMAT_IRCAM			= 0x0A0000,		/* Berkeley/IRCAM/CARL */
		SF_FORMAT_W64			= 0x0B0000,		/* Sonic Foundry's 64 bit RIFF/WAV */
		SF_FORMAT_MAT4			= 0x0C0000,		/* Matlab (tm) V4.2 / GNU Octave 2.0 */
		SF_FORMAT_MAT5			= 0x0D0000,		/* Matlab (tm) V5.0 / GNU Octave 2.1 */
		SF_FORMAT_PVF			= 0x0E0000,		/* Portable Voice Format */
		SF_FORMAT_XI			= 0x0F0000,		/* Fasttracker 2 Extended Instrument */
		SF_FORMAT_HTK			= 0x100000,		/* HMM Tool Kit format */
		SF_FORMAT_SDS			= 0x110000,		/* Midi Sample Dump Standard */
		SF_FORMAT_AVR			= 0x120000,		/* Audio Visual Research */
		SF_FORMAT_WAVEX			= 0x130000,		/* MS WAVE with WAVEFORMATEX */
		SF_FORMAT_SD2			= 0x160000,		/* Sound Designer 2 */
		SF_FORMAT_FLAC			= 0x170000,		/* FLAC lossless file format */
		SF_FORMAT_CAF			= 0x180000,		/* Core Audio File format */
		SF_FORMAT_WVE			= 0x190000,		/* Psion WVE format */
		SF_FORMAT_OGG			= 0x200000,		/* Xiph OGG container */
		SF_FORMAT_MPC2K			= 0x210000,		/* Akai MPC 2000 sampler */
		SF_FORMAT_RF64			= 0x220000,		/* RF64 WAV file */

		/* Subtypes from here on. */

		SF_FORMAT_PCM_S8		= 0x0001,		/* Signed 8 bit data */
		SF_FORMAT_PCM_16		= 0x0002,		/* Signed 16 bit data */
		SF_FORMAT_PCM_24		= 0x0003,		/* Signed 24 bit data */
		SF_FORMAT_PCM_32		= 0x0004,		/* Signed 32 bit data */

		SF_FORMAT_PCM_U8		= 0x0005,		/* Unsigned 8 bit data (WAV and RAW only) */

		SF_FORMAT_FLOAT			= 0x0006,		/* 32 bit float data */
		SF_FORMAT_DOUBLE		= 0x0007,		/* 64 bit float data */

		SF_FORMAT_ULAW			= 0x0010,		/* U-Law encoded. */
		SF_FORMAT_ALAW			= 0x0011,		/* A-Law encoded. */
		SF_FORMAT_IMA_ADPCM		= 0x0012,		/* IMA ADPCM. */
		SF_FORMAT_MS_ADPCM		= 0x0013,		/* Microsoft ADPCM. */

		SF_FORMAT_GSM610		= 0x0020,		/* GSM 6.10 encoding. */
		SF_FORMAT_VOX_ADPCM		= 0x0021,		/* OKI / Dialogix ADPCM */

		SF_FORMAT_G721_32		= 0x0030,		/* 32kbs G721 ADPCM encoding. */
		SF_FORMAT_G723_24		= 0x0031,		/* 24kbs G723 ADPCM encoding. */
		SF_FORMAT_G723_40		= 0x0032,		/* 40kbs G723 ADPCM encoding. */

		SF_FORMAT_DWVW_12		= 0x0040, 		/* 12 bit Delta Width Variable Word encoding. */
		SF_FORMAT_DWVW_16		= 0x0041, 		/* 16 bit Delta Width Variable Word encoding. */
		SF_FORMAT_DWVW_24		= 0x0042, 		/* 24 bit Delta Width Variable Word encoding. */
		SF_FORMAT_DWVW_N		= 0x0043, 		/* N bit Delta Width Variable Word encoding. */

		SF_FORMAT_DPCM_8		= 0x0050,		/* 8 bit differential PCM (XI only) */
		SF_FORMAT_DPCM_16		= 0x0051,		/* 16 bit differential PCM (XI only) */

		SF_FORMAT_VORBIS		= 0x0060,		/* Xiph Vorbis encoding. */

		SF_FORMAT_ALAC_16		= 0x0070,		/* Apple Lossless Audio Codec (16 bit). */
		SF_FORMAT_ALAC_20		= 0x0071,		/* Apple Lossless Audio Codec (20 bit). */
		SF_FORMAT_ALAC_24		= 0x0072,		/* Apple Lossless Audio Codec (24 bit). */
		SF_FORMAT_ALAC_32		= 0x0073,		/* Apple Lossless Audio Codec (32 bit). */

		/* Endian-ness options. */

		SF_ENDIAN_FILE			= 0x00000000,	/* Default file endian-ness. */
		SF_ENDIAN_LITTLE		= 0x10000000,	/* Force little endian-ness. */
		SF_ENDIAN_BIG			= 0x20000000,	/* Force big endian-ness. */
		SF_ENDIAN_CPU			= 0x30000000,	/* Force CPU endian-ness. */

		SF_FORMAT_SUBMASK		= 0x0000FFFF,
		SF_FORMAT_TYPEMASK		= 0x0FFF0000,
		SF_FORMAT_ENDMASK		= 0x30000000
	} ;
	
	typedef struct SF_INFO
	{	sf_count_t	frames ;		/* Used to be called samples.  Changed to avoid confusion. */
		int			samplerate ;
		int			channels ;
		int			format ;
		int			sections ;
		int			seekable ;
	} SF_INFO;

	SNDFILE* 	sf_open		(const char *path, int mode, SF_INFO *sfinfo) ;
	
	sf_count_t	sf_read_short	(SNDFILE *sndfile, short *ptr, sf_count_t items) ;
	sf_count_t	sf_write_short	(SNDFILE *sndfile, const short *ptr, sf_count_t items) ;

	sf_count_t	sf_read_int		(SNDFILE *sndfile, int *ptr, sf_count_t items) ;
	sf_count_t	sf_write_int 	(SNDFILE *sndfile, const int *ptr, sf_count_t items) ;

	sf_count_t	sf_read_float	(SNDFILE *sndfile, float *ptr, sf_count_t items) ;
	sf_count_t	sf_write_float	(SNDFILE *sndfile, const float *ptr, sf_count_t items) ;

	sf_count_t	sf_read_double	(SNDFILE *sndfile, double *ptr, sf_count_t items) ;
	sf_count_t	sf_write_double	(SNDFILE *sndfile, const double *ptr, sf_count_t items) ;

	int		sf_close		(SNDFILE *sndfile) ;
	
	SNDFILE * av_sndfile_out(const char * path, int channels, double samplerate);
	void av_sndfile_write(SNDFILE * file, float * buffer, int len);
	void av_sndfile_close(SNDFILE * file);
]]


ffi.metatype("SNDFILE", {
	__gc = lib.sf_close,
	__index = {
		write = function(self, buf, len)
			if ffi.istype(buf, ffi.typeof("float *")) or ffi.istype(buf, ffi.typeof("float []")) then
				lib.sf_write_float(self, buf, len)
			elseif ffi.istype(buf, ffi.typeof("double *")) or ffi.istype(buf, ffi.typeof("double []")) then
				lib.sf_write_double(self, buf, len)
			end
		end,
		close = function(self)
			ffi.gc(self, nil)
			lib.sf_close(self)
		end,
	},
})

local buffer = require "buffer"

local audio = {

	buffer = buffer,

	sndfile = function(path, mode, config)
	
		local info = ffi.new("SF_INFO")
		
		if mode == "w" then
			config = config or {}
			
			local info = ffi.new("SF_INFO")
			info.samplerate = config.samplerate or 44100
			info.channels = config.channels or 1
			info.format = bit.bor(lib.SF_FORMAT_WAV, lib.SF_FORMAT_PCM_16)
			local sf = lib.sf_open(path, lib.SFM_WRITE, info)
			
			if sf == nil then
				error(ffi.string(lib.sf_strerror(nil)))
			end
			
			return ffi.gc(sf, lib.sf_close)
		else
			error("file reading TODO")
		end
	end,
}

return audio