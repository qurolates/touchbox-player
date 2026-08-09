#import <Foundation/Foundation.h>

#ifndef TB_DEBUG_PERFORMANCE
#define TB_DEBUG_PERFORMANCE 0
#endif

#if TB_DEBUG_PERFORMANCE
#define TBPerformanceLog(...) NSLog(__VA_ARGS__)
#else
#define TBPerformanceLog(...) do { if (0) NSLog(__VA_ARGS__); } while (0)
#endif
