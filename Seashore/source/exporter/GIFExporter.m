#import "GIFExporter.h"
#import "SeaContent.h"
#import "SeaDocument.h"
#import "SeaWhiteboard.h"

@implementation GIFExporter

- (BOOL) hasOptions
{
	return NO;
}

- (IBAction) showOptions: (id) sender
{
	
}

- (NSString *) title
{
	return @"Graphics Interchange Format (GIF)";
}

- (NSString *) extension
{
	return @"gif";
}

- (BOOL) writeDocument: (id) document toFile: (NSString *) path
{
    NSBitmapImageRep *bm = [[document whiteboard] bitmap];
    
	NSDictionary *gifProperties = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], NSImageDitherTransparency, NULL];
	
	NSData* imageData = [bm representationUsingType: NSGIFFileType properties: gifProperties];
	[imageData writeToFile: path atomically: NO];

	return YES;
}

@end
