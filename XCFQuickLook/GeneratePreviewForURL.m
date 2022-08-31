#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#include <Cocoa/Cocoa.h>

#include "SeaMinimal/XCFContent.h"
#include "SeaMinimal/SeaRenderer.h"

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
    // Create and read the document file
	XCFContent *contents = [[XCFContent alloc] initWithDocument:NULL contentsOfFile: [(__bridge NSURL *)url path]];
	SeaRenderer *renderer = [[SeaRenderer alloc] init];

    CGImageRef image = [renderer render:contents];
    
    CGSize size = CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
    CGContextRef ctxt = QLPreviewRequestCreateContext(preview, size, YES, nil);
    CGContextDrawImage(ctxt, CGRectMake(0, 0, size.width, size.height), image);
    QLPreviewRequestFlushContext(preview, ctxt);
    CGImageRelease(image);
    CGContextRelease(ctxt);

    return noErr;
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
    // implement only if supported
}
