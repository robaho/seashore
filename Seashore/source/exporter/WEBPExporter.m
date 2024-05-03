#import "WEBPExporter.h"
#import "WEBPImporter.h"
#import "SeaContent.h"
#import "SeaLayer.h"
#import "SeaDocument.h"
#import "SeaWhiteboard.h"
#import "SeaDocument.h"

#include "encode.h"

@implementation WEBPExporter

- (id)init
{
	int value;
	
	if ([gUserDefaults objectForKey:@"webp compression"] == NULL) {
		value = 50;
	}
	else {
		value = [gUserDefaults integerForKey:@"webp compression"];
		if (value < 0 || value > kMaxWEBPCompression)
			value = 50;
	}
	webCompression = value;
    lossless = [gUserDefaults boolForKey:@"webp lossless"];

	return self;
}

- (BOOL)hasOptions
{
	return YES;
}

- (void)showOptions:(id)document
{
	id realImage;

	// Revise the compression
    [compressSlider setIntValue:webCompression];
    [losslessCheckbox setState:lossless];

    realImageRep = [[document whiteboard] sampleImage];

	realImage = [[NSImage alloc] initWithSize:NSMakeSize(160, 160)];
	[realImage addRepresentation:realImageRep];
    [realImageView setImage:realImage];

    [self compressionChanged:document];

	[panel center];
	[NSApp runModalForWindow:panel];
	[panel orderOut:self];
	
	// Clean-up
    [gUserDefaults setInteger:webCompression forKey:@"webp compression"];
    [gUserDefaults setBool:lossless forKey:@"webp lossless"];
}

- (IBAction)compressionChanged:(id)sender
{
	id compressImage;

    webCompression = [compressSlider intValue];
    lossless = [losslessCheckbox state];

    [compressLabel setStringValue:[self optionsString]];

    [compressSlider setEnabled:![losslessCheckbox state]];

	compressImage = [self compressImage:realImageRep];
	[compressImage setSize:NSMakeSize(160, 160)];
	[compressImageView setImage:compressImage];
	[compressImageView display];
}

- (IBAction)endPanel:(id)sender
{
	[NSApp stopModal];
}

- (NSString *)title
{
	return @"WEBP image";
}

- (NSString *)extension
{
	return @"webp";
}

- (NSString *)optionsString
{
    if(lossless) {
        return @"Lossless";
    } else {
        return [NSString stringWithFormat:@"Compression %d%%", webCompression];
    }
}

- (BOOL)writeDocument:(id)document toFile:(NSString *)path
{
    NSBitmapImageRep *imageRep = [[document whiteboard] image];
    NSData* data = [self convertRepToData:imageRep];
    [data writeToFile:path atomically:true];

	return YES;
}

- (NSImage*)compressImage:(NSImageRep*)uncompressed
{
    NSData *data = [self convertRepToData:uncompressed];
    return [WEBPImporter loadImage:data];
}

- (NSData*)convertRepToData:(NSImageRep*)rep
{
    unsigned char *rgba = convertRepToARGB(rep);
    int width = [rep pixelsWide];
    int height = [rep pixelsHigh];
    convertARGBtoRGBA(rgba,width*height);

    unsigned char *output;
    size_t nbytes;
    if([losslessCheckbox state]==NSControlStateValueOn) {
        nbytes = WebPEncodeLosslessRGBA(rgba, width, height,width*4, &output);
    } else {
        nbytes = WebPEncodeRGBA(rgba, width, height,width*4, (float)(100-webCompression), &output);
    }
    if(nbytes<=0) return NULL;

    NSData *data = [NSData dataWithBytes:output length:nbytes];
    WebPFree(output);

    return data;
}

@end
