#import "PNGExporter.h"
#import "SeaContent.h"
#import "SeaLayer.h"
#import "SeaDocument.h"
#import "SeaWhiteboard.h"

@implementation PNGExporter

- (BOOL)hasOptions
{
	return NO;
}

- (IBAction)showOptions:(id)sender
{
}

- (NSString *)title
{
	return @"Portable Network Graphics image";
}

- (NSString *)extension
{
	return @"png";
}

- (BOOL)writeDocument:(id)document toFile:(NSString *)path
{
    int xres = [[document contents] xres];
    int yres = [[document contents] yres];
	
    NSBitmapImageRep *imageRep = [[document whiteboard] bitmap];

    NSSize newSize;
    newSize.width = [imageRep pixelsWide] * 72.0 / xres;  // x-resolution
    newSize.height = [imageRep pixelsHigh] * 72.0 / yres;  // y-resolution
    
    [imageRep setSize:newSize];
    
	NSData *imageData = [imageRep representationUsingType:NSPNGFileType properties:[NSDictionary dictionary]];
		
    NSError *error;
	// Save our file and let's go
    if([imageData writeToFile:path options:0 error:&error]==NO) {
        NSLog(@"unable to write file %@",error);
    }
	
	return YES;
}

@end
