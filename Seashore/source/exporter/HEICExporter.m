#import "HEICExporter.h"
#import "SeaContent.h"
#import "SeaLayer.h"
#import "SeaDocument.h"
#import "SeaWhiteboard.h"
#import "Bitmap.h"
#import "SeaDocument.h"
#import "Bitmap.h"
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

/*
    if (spp == 4) {
        for (k = 0; k < 3; k++)
            sampleData[(j * 40 + i) * 4 + k + 1] = data[(y * width + x) * 4 + k];
        sampleData[(j * 40 + i) * 4] = data[(y * width + x) * 4 + 3];
    }
    else {
        for (k = 0; k < 3; k++)
            sampleData[(j * 40 + i) * 4 + k + 1] = data[(y * width + x) * 2];
        sampleData[(j * 40 + i) * 4] = data[(y * width + x) * 2 + 1];
    }
*/

- (void)showOptions:(id)document
{
    unsigned char *data;
    int width = [(SeaContent *)[document contents] width], height = [(SeaContent *)[document contents] height], spp = [[document contents] spp];
    int i, j, k, x, y;
    id realImage, compressImage;
    float value;
    
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
    value = [self reviseCompression];
    
    // Set-up the sample data
    data = [(SeaWhiteboard *)[document whiteboard] data];
    sampleData = malloc(40 * 40 * 4);
    memset(sampleData, 0x00, 40 * 40 * 4);
    for (j = 0; j < 40; j++) {
        for (i = 0; i < 40; i++) {
            x = width / 2 - 20 + i;
            y = height / 2 - 20 + j;
            if (x >= 0 && x < width && y >= 0 && y < height) {
                if (spp == 4) {
                    for (k = 0; k < 4; k++)
                        sampleData[(j * 40 + i) * 4 + k] = data[(y * width + x) * 4 + k];
                }
                else {
                    for (k = 0; k < 3; k++)
                        sampleData[(j * 40 + i) * 4 + k] = data[(y * width + x) * 2];
                    sampleData[(j * 40 + i) * 4 + 3] = data[(y * width + x) * 2 + 1];
                }
            }
        }
    }
    premultiplyBitmap(4, sampleData, sampleData, 40 * 40);
    
    // Now make an image for the view
    realImageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&sampleData pixelsWide:40 pixelsHigh:40 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:40 * 4 bitsPerPixel:8 * 4];
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
    free(sampleData);
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
    int width, height, spp, xres, yres;
    unsigned char *srcData, *destData;
    NSBitmapImageRep *imageRep;
    BOOL hasAlpha = true;
    
    // Get the data to write
    srcData = [(SeaWhiteboard *)[document whiteboard] data];
    width = [(SeaContent *)[document contents] width];
    height = [(SeaContent *)[document contents] height];
    spp = [(SeaContent *)[document contents] spp];
    xres = [[document contents] xres];
    yres = [[document contents] yres];

//    // Strip the alpha channel if necessary
//    destData = stripAlpha(srcData,width,height,spp);
//    if (destData!=srcData) {
//        spp--;
//        hasAlpha=false;
//    }
    
    destData = srcData;
    
    // Make an image representation from the data
    imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&destData pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:spp hasAlpha:hasAlpha isPlanar:NO colorSpaceName:(spp > 2) ? MyRGBSpace : MyGraySpace bytesPerRow:width * spp bitsPerPixel:8 * spp];
    
    if (!targetWeb) {
        // use color space of display device where the window is
        NSColorSpace *cs = [[[[document docView] window] screen] colorSpace];
        imageRep = [imageRep bitmapImageRepByConvertingToColorSpace:cs renderingIntent:NSColorRenderingIntentDefault];
    }
    
    CIFormat ciFormat = (spp == 4 ? kCIFormatRGBA8 : kCIFormatLA8);
    
    CGColorSpaceRef ciCS = [[imageRep colorSpace] CGColorSpace];
    
    NSSize newSize;
    newSize.width = [imageRep pixelsWide] * 72.0 / xres;  // x-resolution
    newSize.height = [imageRep pixelsHigh] * 72.0 / yres;  // y-resolution
    
    [imageRep setSize:newSize];
    
    CIImage *ciImage = [[CIImage alloc] initWithBitmapImageRep:imageRep];
    
//    CGColorSpaceRef csp = (spp == 4 ? CGColorSpaceCreateDeviceRGB() : CGColorSpaceCreateDeviceGray());
    
    CIContext *ctx = [CIContext context];
    
    NSURL *url = [NSURL fileURLWithPath:path];
    
    NSDictionary *options = @{(__bridge id)kCGImageDestinationLossyCompressionQuality:[NSNumber numberWithFloat:[self reviseCompression]]};
    
    if (@available(macOS 10.13.4, *)) {
        [ctx writeHEIFRepresentationOfImage:ciImage toURL:url format:ciFormat colorSpace:ciCS options:options error:nil];
    }
//    // Finally build the JPEG 2000 data
//    imageData = [imageRep representationUsingType:NSJPEG2000FileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:[self reviseCompression]] forKey:NSImageCompressionFactor]];
//
//    // Save our file and let's go
//    [imageData writeToFile:path atomically:YES];
//
    // If the destination data is not equivalent to the source data free the former
    if (destData != srcData)
        free(destData);
    
    return YES;
}

@end
