#import "TIFFExporter.h"
#import "SeaContent.h"
#import "SeaLayer.h"
#import "SeaDocument.h"
#import "SeaWhiteboard.h"

@implementation TIFFExporter

- (id)init
{
	return self;
}

- (BOOL)hasOptions
{
	return YES;
}

- (IBAction)showOptions:(id)sender
{
	// Display the options dialog
	[panel center];
	[NSApp runModalForWindow:panel];
	[panel orderOut:self];
}

- (IBAction)targetChanged:(id)sender
{
}

- (IBAction)endPanel:(id)sender
{
	[NSApp stopModal];
}

- (NSString *)title
{
	return @"TIFF image";
}

- (NSString *)extension
{
	return @"tiff";
}

- (NSString *)optionsString
{
    SeaColorProfile *proof = [[idocument whiteboard] proofProfile];
    NSColorSpace *monitor = [[[[idocument docView] window] screen] colorSpace];
    NSString *csname = (__bridge NSString*)ColorSyncProfileCopyDescriptionString((ColorSyncProfileRef)[monitor colorSyncProfile]);
                           
    switch ([targetRadios selectedRow]) {
        case 0:
            return @"RGB/RGBA";
        case 1:
            return @"CMYK";
        case 2:
            if(proof!=NULL && proof.cs!=NULL){
                return proof.desc;
            }
            // fall through to monitor if proof is none, yet selected
        case 3:
            return csname;
    }
    return @"Unknown";
}

- (BOOL)writeDocument:(id)document toFile:(NSString *)path
{
	int xres = [[document contents] xres];
	int yres = [[document contents] yres];
    
    NSBitmapImageRep* imageRep = [[document whiteboard] bitmap];

    switch([targetRadios selectedRow]) {
        case 1: {
                NSColorSpace* cs = [NSColorSpace deviceCMYKColorSpace];
                imageRep = [imageRep bitmapImageRepByConvertingToColorSpace:cs renderingIntent:NSColorRenderingIntentDefault];
            }
            break;
        case 2:{
                SeaColorProfile *cp = [[document whiteboard] proofProfile];
                if(cp!=NULL && cp.cs!=NULL){
                    imageRep = [imageRep bitmapImageRepByConvertingToColorSpace:cp.cs renderingIntent:NSColorRenderingIntentDefault];
                }
            }
            break;
        case 3: {
            NSColorSpace *cs = [[[[idocument docView] window] screen] colorSpace];
            imageRep = [imageRep bitmapImageRepByConvertingToColorSpace:cs renderingIntent:NSColorRenderingIntentDefault];
        }
    }
    
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:NSTIFFCompressionLZW] forKey:NSImageCompressionMethod];
    
    NSSize newSize;
    newSize.width = [imageRep pixelsWide] * 72.0 / xres;
    newSize.height = [imageRep pixelsHigh] * 72.0 / yres;

    [imageRep setSize:newSize];
    
    NSDictionary *exifData = [[document contents] exifData];
    if (exifData) [imageRep setProperty:@"NSImageEXIFData" withValue:exifData];
    
    NSData *imageData = [imageRep representationUsingType:NSBitmapImageFileTypeTIFF properties:imageProps];

    [imageData writeToFile:path atomically:NO];

    return YES;
}

@end
