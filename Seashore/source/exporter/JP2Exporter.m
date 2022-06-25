#import "JP2Exporter.h"
#import "SeaContent.h"
#import "SeaLayer.h"
#import "SeaDocument.h"
#import "SeaWhiteboard.h"

@implementation JP2Exporter

- (id)init
{
    int value;
    
    if ([gUserDefaults objectForKey:@"jp2 target"] == NULL)
        targetWeb = YES;
    else
        targetWeb = [gUserDefaults boolForKey:@"jp2 target"];
    
    if ([gUserDefaults objectForKey:@"jp2 web compression"] == NULL) {
        value = 26;
    }
    else {
        value = [gUserDefaults integerForKey:@"jp2 web compression"];
        if (value < 0 || value > kMaxCompression)
            value = 26;
    }
    webCompression = value;
    
    if ([gUserDefaults objectForKey:@"jp2 print compression"] == NULL) {
        value = 30;
    }
    else {
        value = [gUserDefaults integerForKey:@"jp2 print compression"];
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
    NSBitmapImageRep *sample = [(SeaWhiteboard *)[document whiteboard] sampleImage];

    // Now make an image for the view
    realImage = [[NSImage alloc] initWithSize:NSMakeSize(160, 160)];
    [realImage addRepresentation:sample];
    [realImageView setImage:realImage];
    compressImage = [[NSImage alloc] initWithData:[sample representationUsingType:NSJPEG2000FileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:[self reviseCompression]] forKey:NSImageCompressionFactor]]];
    [compressImage setSize:NSMakeSize(160, 160)];
    [compressImageView setImage:compressImage];
    
    // Display the options dialog
    [panel center];
    [NSApp runModalForWindow:panel];
    [panel orderOut:self];
    
    // Clean-up
    [gUserDefaults setObject:(targetWeb ? @"YES" : @"NO") forKey:@"jp2 target"];
    if (targetWeb)
        [gUserDefaults setInteger:webCompression forKey:@"jp2 web compression"];
    else
        [gUserDefaults setInteger:printCompression forKey:@"jp2 print compression"];
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
    return @"JPEG 2000 image";
}

- (NSString *)extension
{
    return @"jp2";
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
    int xres = [[document contents] xres];
    int yres = [[document contents] yres];

    // Make an image representation from the data
    NSBitmapImageRep *imageRep = [[document whiteboard] bitmap];

    if (!targetWeb) {
        // use color space of display device where the window is
        NSColorSpace *cs = [[[[document docView] window] screen] colorSpace];
        imageRep = [imageRep bitmapImageRepByConvertingToColorSpace:cs renderingIntent:NSColorRenderingIntentDefault];
    }
    
    NSSize newSize;
    newSize.width = [imageRep pixelsWide] * 72.0 / xres;  // x-resolution
    newSize.height = [imageRep pixelsHigh] * 72.0 / yres;  // y-resolution
    
    [imageRep setSize:newSize];

    // Finally build the JPEG 2000 data
    NSData *imageData = [imageRep representationUsingType:NSJPEG2000FileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:[self reviseCompression]] forKey:NSImageCompressionFactor]];
    
    // Save our file and let's go
    [imageData writeToFile:path atomically:YES];

    return YES;
}

@end
