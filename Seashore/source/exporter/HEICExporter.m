#import "HEICExporter.h"
#import "SeaContent.h"
#import "SeaLayer.h"
#import "SeaDocument.h"
#import "SeaWhiteboard.h"
#import "SeaDocument.h"
#import <CoreImage/CoreImage.h>

@implementation HEICExporter

- (id)init
{
    int value;
    
    if ([gUserDefaults objectForKey:@"heic target"] == NULL)
        targetWeb = YES;
    else
        targetWeb = [gUserDefaults boolForKey:@"heic target"];
    
    if ([gUserDefaults objectForKey:@"heic web compression"] == NULL) {
        value = 26;
    }
    else {
        value = [gUserDefaults integerForKey:@"heic web compression"];
        if (value < 0 || value > kMaxCompression)
            value = 26;
    }
    webCompression = value;
    
    if ([gUserDefaults objectForKey:@"heic print compression"] == NULL) {
        value = 30;
    }
    else {
        value = [gUserDefaults integerForKey:@"heic print compression"];
        if (value < 0 || value > kMaxCompression)
            value = 30;
    }
    printCompression = value;
    
    return self;
}


- (BOOL)hasOptions
{
    return YES;
}

- (float)reviseCompression
{
    float result;
    
    if (targetWeb) {
        if (webCompression < 5) {
            result = 0.1 + 0.08 * (float)webCompression;
        }
        else if (webCompression < 10) {
            result = 0.3 + 0.04 * (float)webCompression;
        }
        else if (webCompression < 20) {
            result = 0.5 + 0.02 * (float)webCompression;
        }
        else {
            result = 0.7 + 0.01 * (float)webCompression;
        }
    }
    else {
        if (printCompression < 5) {
            result = 0.1 + 0.08 * (float)printCompression;
        }
        else if (printCompression < 10) {
            result = 0.3 + 0.04 * (float)printCompression;
        }
        else if (printCompression < 20) {
            result = 0.5 + 0.02 * (float)printCompression;
        }
        else {
            result = 0.7 + 0.01 * (float)printCompression;
        }
    }
    [compressLabel setStringValue:[NSString stringWithFormat:@"Compressed - %d%%", (int)roundf(result * 100.0)]];
    
    return result;
}

- (void)showOptions:(id)document
{
    id realImage, compressImage;

    // Work things out
    if (targetWeb)
        [targetRadios selectCellAtRow:0 column:0];
    else
        [targetRadios selectCellAtRow:0 column:1];
    
    // Revise the compression
    if (targetWeb)
        [compressSlider setIntValue:webCompression];
    else
        [compressSlider setIntValue:printCompression];

    realImageRep = [[document whiteboard] sampleImage];
    realImage = [[NSImage alloc] initWithSize:NSMakeSize(160, 160)];
    [realImage addRepresentation:realImageRep];
    [realImageView setImage:realImage];
    compressImage = [[NSImage alloc] initWithData:[realImageRep representationUsingType:NSJPEG2000FileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:[self reviseCompression]] forKey:NSImageCompressionFactor]]];
    [compressImage setSize:NSMakeSize(160, 160)];
    [compressImageView setImage:compressImage];
    
    // Display the options dialog
    [panel center];
    [NSApp runModalForWindow:panel];
    [panel orderOut:self];
    
    // Clean-up
    [gUserDefaults setObject:(targetWeb ? @"YES" : @"NO") forKey:@"heic target"];
    if (targetWeb)
        [gUserDefaults setInteger:webCompression forKey:@"heic web compression"];
    else
        [gUserDefaults setInteger:printCompression forKey:@"heic print compression"];
}

- (IBAction)compressionChanged:(id)sender
{
    id compressImage;
    float value;
    
    if (targetWeb)
        webCompression = [compressSlider intValue];
    else
        printCompression = [compressSlider intValue];
    value = [self reviseCompression];
    compressImage = [[NSImage alloc] initWithData:[realImageRep representationUsingType:NSJPEG2000FileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:[self reviseCompression]] forKey:NSImageCompressionFactor]]];
    [compressImage setSize:NSMakeSize(160, 160)];
    [compressImageView setImage:compressImage];
    [compressImageView display];
}

- (IBAction)targetChanged:(id)sender
{
    id compressImage;
    float value;
    
    // Determine the target
    if ([targetRadios selectedColumn] == 0)
        targetWeb = YES;
    else
        targetWeb = NO;
    
    // Revise the compression
    if (targetWeb)
        [compressSlider setIntValue:webCompression];
    else
        [compressSlider setIntValue:printCompression];
    value = [self reviseCompression];
    compressImage = [[NSImage alloc] initWithData:[realImageRep representationUsingType:NSJPEG2000FileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:[self reviseCompression]] forKey:NSImageCompressionFactor]]];
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
    return @"HEIC image";
}

- (NSString *)extension
{
    return @"heic";
}

- (NSString *)optionsString
{
    if (targetWeb)
        return [NSString stringWithFormat:@"Web %.0f%%", [self reviseCompression] * 100.0];
    else
        return [NSString stringWithFormat:@"Print %.0f%%", [self reviseCompression] * 100.0];
}

- (BOOL)writeDocument:(id)document toFile:(NSString *)path
{
    int xres, yres;

    if (@available(macOS 10.13.4, *)) {
        //
    } else {
        return NO;
    }
    // Get the data to write
    xres = [[document contents] xres];
    yres = [[document contents] yres];

    NSBitmapImageRep *imageRep = [[document whiteboard] image];

    if (!targetWeb) {
        // use color space of display device where the window is
        NSColorSpace *cs = [[[[document docView] window] screen] colorSpace];
        imageRep = [imageRep bitmapImageRepByConvertingToColorSpace:cs renderingIntent:NSColorRenderingIntentDefault];
    }

    CIFormat ciFormat;
    if (@available(macOS 10.13.4, *)) {
        // make compiler happy by guarding even though this cannot be reached
        ciFormat = [[document contents] isRGB] ? kCIFormatRGBA8 : kCIFormatLA8;
    }
    
    CGColorSpaceRef ciCS = [[imageRep colorSpace] CGColorSpace];
    
    NSSize newSize;
    newSize.width = [imageRep pixelsWide] * 72.0 / xres;  // x-resolution
    newSize.height = [imageRep pixelsHigh] * 72.0 / yres;  // y-resolution
    
    [imageRep setSize:newSize];
    
    CIImage *ciImage = [[CIImage alloc] initWithBitmapImageRep:imageRep];
    
    CIContext *ctx = [CIContext context];
    
    NSURL *url = [NSURL fileURLWithPath:path];
    
    NSDictionary *options = @{(__bridge id)kCGImageDestinationLossyCompressionQuality:[NSNumber numberWithFloat:[self reviseCompression]]};
    
    if (@available(macOS 10.13.4, *)) {
        [ctx writeHEIFRepresentationOfImage:ciImage toURL:url format:ciFormat colorSpace:ciCS options:options error:nil];
    }

    return YES;
}

@end
