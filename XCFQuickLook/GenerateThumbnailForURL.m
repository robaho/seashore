#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#include <Cocoa/Cocoa.h>

#include "XCFContent.h"
#include "SeaWhiteboard.h"

/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

	XCFContent *contents = [[XCFContent alloc] initWithContentsOfFile: [(NSURL *)url path]];
	 SeaWhiteboard *whiteboard = [[SeaWhiteboard alloc] initWithContent:contents];
	[whiteboard update];
	
	QLThumbnailRequestSetImageWithData(thumbnail,(CFDataRef)[[whiteboard printableImage] TIFFRepresentation], NULL);
	
	[pool release];
    return noErr;
}

void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail)
{
    // implement only if supported
}
