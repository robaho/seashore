//
//  Configure.h
//  SeaComponents
//
//  Created by robert engels on 12/2/22.
//

#ifndef Configure_h
#define Configure_h

#undef LOG_LAYOUT

#ifdef LOG_LAYOUT
#define VLOG(...) NSLog(__VA_ARGS__)
#else
#define VLOG(...)
#endif

#endif /* Configure_h */
