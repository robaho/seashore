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
    // Create and read the document file
	XCFContent *contents = [[XCFContent alloc] initWithContentsOfFile: [(__bridge NSURL *)url path]];
	SeaWhiteboard *whiteboard = [[SeaWhiteboard alloc] initWithContent:contents];
	[whiteboard update];
    
    NSImage* rimage = [whiteboard printableImage];
    NSRect imageRect = NSMakeRect(0, 0, rimage.size.width, rimage.size.height);
    CGImageRef image = [rimage CGImageForProposedRect:&imageRect context:NULL hints:nil];
    
//    QLPreviewRequestSetDataRepresentation(preview, (CFDataRef)tiff, kUTTypeTIFF, NULL);
    
    CGSize size = CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
    CGContextRef ctxt = QLPreviewRequestCreateContext(preview, size, YES, nil);
    CGContextDrawImage(ctxt, CGRectMake(0, 0, size.width, size.height), image);
    QLPreviewRequestFlushContext(preview, ctxt);
    CGContextRelease(ctxt);
	
    return noErr;
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
    // implement only if supported
}
