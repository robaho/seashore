//
//  PluginClass.m
//  Plugins
//
//  Created by robert engels on 12/30/18.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Accelerate/Accelerate.h>

#import "PluginClass.h"
#import "PluginData.h"

inline void premultiplyBitmap(int spp, unsigned char *output, unsigned char *input, int length)
{
    if(spp==4) {
        vImage_Buffer obuf = {.data=output,.height=1,.width=length,.rowBytes=length*spp};
        vImage_Buffer ibuf = {.data=input,.height=1,.width=length,.rowBytes=length*spp};

        vImagePremultiplyData_RGBA8888(&ibuf,&obuf,0);
    } else { // spp==2 which is grayscale with alpha
        int temp;
        for(int i=0;i<length;i++) {
            *output = int_mult(*input,*(input+1), temp);
            output+=2;
            input+=2;
        }
    }
}

inline void unpremultiplyBitmap(int spp, unsigned char *output, unsigned char *input, int length)
{
    if(spp==4) {
        vImage_Buffer obuf = {.data=output,.height=1,.width=length,.rowBytes=length*spp};
        vImage_Buffer ibuf = {.data=input,.height=1,.width=length,.rowBytes=length*spp};

        vImageUnpremultiplyData_RGBA8888(&ibuf,&obuf,0);
    } else {
        for(int i=0;i<length;i++) {
            *output = MIN((*input * 255 + 128)/ *(input+1),255);
            output+=2;
            input+=2;
        }
    }
}

/*
 convert NSImageRep to a format Seashore can work with, which is RGBA, or GrayA. If spp is 4, then RGBA, if 2, the GrayA
 */
void convertImageRepWithData(NSImageRep *imageRep,unsigned char *dest,int width,int height,int spp) {
    
    NSColorSpaceName csname = MyRGBSpace;
    if (spp==2) {
        csname = MyGraySpace;
    }
    
    memset(dest,0,width*height*spp);
    
    NSBitmapImageRep *bitmapWhoseFormatIKnow = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&dest pixelsWide:width pixelsHigh:height
                                                                                    bitsPerSample:8 samplesPerPixel:spp hasAlpha:YES isPlanar:NO
                                                                                   colorSpaceName:csname bytesPerRow:width*spp
                                                                                     bitsPerPixel:8*spp];
    
    NSRect rect = NSMakeRect(0,0,width,height);
    
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext *ctx = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmapWhoseFormatIKnow];
    [NSGraphicsContext setCurrentContext:ctx];
    [imageRep drawInRect:rect fromRect:rect operation:NSCompositingOperationCopy fraction:1.0 respectFlipped:NO hints:NULL];
    [NSGraphicsContext restoreGraphicsState];
}

CIImage *createCIImage(PluginData *pluginData){
    CGImageRef bitmap = [pluginData bitmap];
    CIImage *inputImage = [CIImage imageWithCGImage:bitmap];
    CGImageRelease(bitmap);

    return inputImage;
}

void renderCIImage(PluginData *pluginData,CIImage *image){
    int spp = [pluginData spp];
    int width = [pluginData width];
    int height = [pluginData height];
    IntRect selection = [pluginData selection];
    
    [pluginData setOverlayOpacity:255];
    [pluginData setOverlayBehaviour:kReplacingBehaviour];
    
    unsigned char *overlay = [pluginData overlay];

    NSCIImageRep *imageRep = [NSCIImageRep imageRepWithCIImage:image];
    
    convertImageRepWithData(imageRep,overlay,width,height,spp);
    
    unsigned char *replace = [pluginData replace];
    int i;
    
    // set the replace mask
    if ((selection.size.width > 0 && selection.size.width < width) || (selection.size.height > 0 && selection.size.height < height)) {
        for (i = 0; i < selection.size.height; i++) {
            memset(&(replace[width * (selection.origin.y + i) + selection.origin.x]), 0xFF, selection.size.width);
        }
    }
    else {
        memset(replace, 0xFF, width * height);
    }
}

void applyFilter(PluginData *pluginData,CIFilter *filter) {
    CIImage *inputImage = createCIImage(pluginData);

    if([[filter inputKeys] containsObject:@"inputImage"]){
        [filter setValue:inputImage forKey:@"inputImage"];
    }

    CIImage *outputImage = [filter valueForKey: @"outputImage"];
    
    renderCIImage(pluginData,outputImage);
}

void applyFilterAsOverlay(PluginData *pluginData,CIFilter *filter) {
    CIImage *outputImage = [filter valueForKey: @"outputImage"];

    [pluginData setOverlayOpacity:255];
    [pluginData setOverlayBehaviour:kNormalBehaviour];
    int width = [pluginData width];
    int height = [pluginData height];
    int spp = [pluginData spp];

    unsigned char *overlay = [pluginData overlay];

    NSCIImageRep *imageRep = [NSCIImageRep imageRepWithCIImage:outputImage];

    convertImageRepWithData(imageRep,overlay,width,height,spp);
}


void applyFilters(PluginData *pluginData,CIFilter *filterA,CIFilter *filterB) {
    CIImage *inputImage = createCIImage(pluginData);
    
    [filterA setValue:inputImage forKey:@"inputImage"];
    CIImage *outputImage = [filterA valueForKey: @"outputImage"];
    [filterB setValue:outputImage forKey:@"inputImage"];
    outputImage = [filterB valueForKey: @"outputImage"];

    renderCIImage(pluginData,outputImage);
}

void applyFilterBG(PluginData *pluginData,CIFilter *filter) {
    CIImage *inputImage = createCIImage(pluginData);
    
    CIColor *backColor = createCIColor([pluginData backColor]);

    if([[filter inputKeys] containsObject:@"inputImage"]){
        [filter setValue:inputImage forKey:@"inputImage"];
    }
    CIImage *outputImage = [filter valueForKey: @"outputImage"];
    
    filter = [CIFilter filterWithName:@"CIConstantColorGenerator"];
    [filter setDefaults];
    [filter setValue:backColor forKey:@"inputColor"];
    CIImage *background = [filter valueForKey: @"outputImage"];
    filter = [CIFilter filterWithName:@"CISourceOverCompositing"];
    [filter setDefaults];
    [filter setValue:background forKey:@"inputBackgroundImage"];
    [filter setValue:outputImage forKey:@"inputImage"];
    outputImage = [filter valueForKey:@"outputImage"];
    
    renderCIImage(pluginData,outputImage);
}

void applyFilterFG(PluginData *pluginData,CIFilter *filter) {
    CIImage *inputImage = createCIImage(pluginData);
    
    CIColor *foreColor = createCIColor([pluginData foreColor]);

    if([[filter inputKeys] containsObject:@"inputImage"]){
        [filter setValue:inputImage forKey:@"inputImage"];
    }
    CIImage *outputImage = [filter valueForKey: @"outputImage"];
    
    filter = [CIFilter filterWithName:@"CIConstantColorGenerator"];
    [filter setDefaults];
    [filter setValue:foreColor forKey:@"inputColor"];
    CIImage *foreground = [filter valueForKey: @"outputImage"];
    filter = [CIFilter filterWithName:@"CISourceInCompositing"];
    [filter setDefaults];
    [filter setValue:outputImage forKey:@"inputBackgroundImage"];
    [filter setValue:foreground forKey:@"inputImage"];
    outputImage = [filter valueForKey:@"outputImage"];
    
    renderCIImage(pluginData,outputImage);
}


void applyFilterFGBG(PluginData *pluginData,CIFilter *filter) {
    CIImage *inputImage = createCIImage(pluginData);
    
    CIColor *foreColor = createCIColor([pluginData foreColor]);
    CIColor *backColor = createCIColor([pluginData backColor]);
    
    [filter setValue:inputImage forKey:@"inputImage"];
    CIImage *outputImage = [filter valueForKey: @"outputImage"];
    
    filter = [CIFilter filterWithName:@"CIConstantColorGenerator"];
    [filter setDefaults];
    [filter setValue:foreColor forKey:@"inputColor"];
    CIImage *foreground = [filter valueForKey: @"outputImage"];
    filter = [CIFilter filterWithName:@"CISourceInCompositing"];
    [filter setDefaults];
    [filter setValue:outputImage forKey:@"inputBackgroundImage"];
    [filter setValue:foreground forKey:@"inputImage"];
    outputImage = [filter valueForKey:@"outputImage"];
    
    filter = [CIFilter filterWithName:@"CIConstantColorGenerator"];
    [filter setDefaults];
    [filter setValue:backColor forKey:@"inputColor"];
    CIImage *background = [filter valueForKey: @"outputImage"];
    filter = [CIFilter filterWithName:@"CISourceOverCompositing"];
    [filter setDefaults];
    [filter setValue:background forKey:@"inputBackgroundImage"];
    [filter setValue:outputImage forKey:@"inputImage"];
    outputImage = [filter valueForKey:@"outputImage"];
    
    renderCIImage(pluginData,outputImage);
}

float calculateAngle(IntPoint point,IntPoint apoint){
    float angle;
    if (apoint.x - point.x == 0)
        angle = PI / 2.0;
    else if (apoint.x - point.x > 0)
        angle = atanf((float)(point.y - apoint.y) / fabsf((float)(apoint.x - point.x)));
    else if (apoint.x - point.x < 0 && point.y - apoint.y > 0)
        angle = PI - atanf((float)(point.y - apoint.y) / fabsf((float)(apoint.x - point.x)));
    else
        angle = -PI - atanf((float)(point.y - apoint.y) / fabsf((float)(apoint.x - point.x)));
    return angle;
}

int calculateRadius(IntPoint point,IntPoint apoint) {
    int radius = (apoint.x - point.x) * (apoint.x - point.x) + (apoint.y - point.y) * (apoint.y - point.y);
    radius = sqrt(radius);
    return radius;
}

CGRect determineContentBorders(PluginData *pluginData) {
    int contentLeft, contentRight, contentTop, contentBottom;
    int width, height;
    int spp;
    unsigned char *data;
    int i, j;
    
    // Start out with invalid content borders
    contentLeft = contentRight = contentTop = contentBottom =  -1;
    
    // Select the appropriate data for working out the content borders
    data = [pluginData data];
    width = [pluginData width];
    height = [pluginData height];
    spp = [pluginData spp];
    
    // Determine left content margin
    for (i = 0; i < width && contentLeft == -1; i++) {
        for (j = 0; j < height && contentLeft == -1; j++) {
            if (data[j * width * spp + i * spp + (spp - 1)] != 0) {
                contentLeft = i;
            }
        }
    }
    
    // Determine right content margin
    for (i = width - 1; i >= 0 && contentRight == -1; i--) {
        for (j = 0; j < height && contentRight == -1; j++) {
            if (data[j * width * spp + i * spp + (spp - 1)] != 0) {
                contentRight = i;
            }
        }
    }
    
    // Determine top content margin
    for (j = 0; j < height && contentTop == -1; j++) {
        for (i = 0; i < width && contentTop == -1; i++) {
            if (data[j * width * spp + i * spp + (spp - 1)] != 0) {
                contentTop = j;
            }
        }
    }
    
    // Determine bottom content margin
    for (j = height - 1; j >= 0 && contentBottom == -1; j--) {
        for (i = 0; i < width && contentBottom == -1; i++) {
            if (data[j * width * spp + i * spp + (spp - 1)] != 0) {
                contentBottom = j;
            }
        }
    }
    
    if (contentLeft != -1 && contentTop != -1 && contentRight != -1 && contentBottom != -1) {
        CGRect bounds;
        
        bounds.origin.x = contentLeft;
        bounds.origin.y = contentTop;
        bounds.size.width = contentRight - contentLeft + 1;
        bounds.size.height = contentBottom - contentTop + 1;
        
        return bounds;
    }
    else {
        return CGRectNull;
    }
}

CIImage *croppedCIImage(PluginData *pluginData,CGRect bounds) {
    CIImage *image = createCIImage(pluginData);
    
    if(CGRectIsNull(bounds)){
        return image;
    }
    
    int height = [pluginData height];
    
    CIFilter *filter = [CIFilter filterWithName:@"CICrop"];
    [filter setDefaults];
    [filter setValue:image forKey:@"inputImage"];
    [filter setValue:[CIVector vectorWithX:bounds.origin.x Y:height - bounds.size.height - bounds.origin.y Z:bounds.size.width W:bounds.size.height] forKey:@"inputRectangle"];
    CIImage *output = [filter valueForKey:@"outputImage"];
    
    // Offset properly
    filter = [CIFilter filterWithName:@"CIAffineTransform"];
    [filter setDefaults];
    [filter setValue:output forKey:@"inputImage"];
    NSAffineTransform *offsetTransform = [NSAffineTransform transform];
    [offsetTransform translateXBy:-bounds.origin.x yBy:-height + bounds.origin.y + bounds.size.height];
    [filter setValue:offsetTransform forKey:@"inputTransform"];
    return [filter valueForKey:@"outputImage"];
}

CIColor *createCIColor(NSColor *color) {
    CIColor *ci = [ [CIColor alloc] initWithColor:color];
    if(ci==NULL){
        // some conversions cannot work, so convert to rgb
        NSColor *rgb = [color colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
        ci = [[CIColor alloc] initWithColor:rgb];
    }
    return ci;
}


