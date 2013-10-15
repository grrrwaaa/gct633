#include "av.h"

// the main update routine (high priority)
void av_update_once();
// the main rendering routine (medium priority)
// (put swapbuffers in here)
void av_draw_once();
// an idle task to call when neither update or render is due (low priority)
void av_idle_once();

int quit = 0;

// maximum no. of updates per render
// also maximum possible pending before skipping updates
int64_t update_bail_threshold = 40;	

const int64_t updates_per_second = 120;
const double update_period = 1./updates_per_second;
// the base number of updates already run:
// at 100Hz a 64-bit double / long combo can accommodate a million years...
int64_t updated = 0;	
// how many update cycles are due to run:
int64_t pending_updates = 0;

// we could move this into a separate thread and just read pending_updates
// (make it volatile if so)
inline void pending() {
	pending_updates = av_now()*updates_per_second - updated;
	return pending_updates;
}


// must call this before first call to av_run_once()
void av_run_init() {
	// initialize counters:
	updated = av_now()*updates_per_second;
	pending_updates = 0;
}

// this run loop has update priority
// it runs the risk of low frame rates if the update_once() function takes update_period or more to complete
// to give more preference to rendering, move work from update_once() into idle_once()
void av_run_once() {
	
	// idle check:
	// this occurs when rendering took less than one update interval to complete
	while (pending() <= 0) {
		// try any idle calls:
		av_idle_once();
		// if time still hasn't passed, sleep:
		if (pending() <= 0) {
			av_sleep(update_period);	
		}
	}
	
	// this loop occurs when time has moved on but updates have not caught up
	// the idle check above should ensure that pending_updates is at least 1 initially
	// pending_updates now shows how many updates were missed during rendering/idle
	// we need to run update_once() for each of them
	// we also need a bail condition in case the updates take update_period or more to complete; max_pending takes care of this condition
	int64_t max_pending = update_bail_threshold;
	do {
		// run an update:
		av_update_once();
		
		// risk here is that we never catch up and exit the loop
		// bail when our pending() has exceeded an ever-decreasing limit:
		// (handles both runaway pending counts as well as steady saturation)
		if (pending_updates > --max_pending) {
			// avoid accumulated pending updates by skipping:
			// (post a 'update underrun' message?)
			updated = av_now()*updates_per_second;
			break;
		}
		
		// one less update to run:
		updated++;
		
	} while (pending() > 0);
	
	// no more updates due, so render:
	av_draw_once();
}