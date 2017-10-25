#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#include <Cocoa/Cocoa.h>

#include "XCFContent.h"
#include "SeaWhiteboard.h"

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
    // Create and read the document file
	XCFContent *contents = [[XCFContent alloc] initWithContentsOfFile: [(NSURL *)url path]];
	SeaWhiteboard *whiteboard = [[SeaWhiteboard alloc] initWithContent:contents];
	[whiteboard update];
	
	QLPreviewRequestSetDataRepresentation(preview, (CFDataRef)[[whiteboard printableImage] TIFFRepresentation], kUTTypeTIFF, NULL);
	
    [pool release];
    return noErr;
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
    // implement only if supported
}
