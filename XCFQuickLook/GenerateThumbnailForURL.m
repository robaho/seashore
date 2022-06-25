#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#include <Cocoa/Cocoa.h>

#include <SeaMinimal/XCFContent.h>
#include <SeaMinimal/SeaRenderer.h>

/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
{
    XCFContent *contents = [[XCFContent alloc] initWithDocument:NULL contentsOfFile: [(__bridge NSURL *)url path]];
    SeaRenderer *renderer = [[SeaRenderer alloc] init];

    CGImageRef cgimg = [renderer render:contents];
    CGSize size = CGSizeMake(CGImageGetWidth(cgimg), CGImageGetHeight(cgimg));
    NSImage *image = [[NSImage alloc] initWithCGImage:cgimg size:size];
    NSData* tiff = image.TIFFRepresentation;
    CGImageRelease(cgimg);
	
	QLThumbnailRequestSetImageWithData(thumbnail,(__bridge CFDataRef)tiff, NULL);
    return noErr;
}

void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail)
{
    // implement only if supported
}
