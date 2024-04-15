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
#import <CoreImage/CoreImage.h>
#import <Accelerate/Accelerate.h>

#import "PluginClassImpl.h"

/*
 convert CIImage to the ARGB8888 format used by Seashore
 */
void rasterizeCIImage(CIImage *image,unsigned char *dest,int width,int height) {
    
    memset(dest,0,width*height*4);

    CGRect extent = [image extent];
    if(CGRectEqualToRect(CGRectInfinite, extent)) {
        extent = CGRectMake(0,0,width,height);
    }

    CGContextRef cg = CGBitmapContextCreate(dest, width,height,8,width*4,rgbCS,kCGImageAlphaPremultipliedFirst);
    CIContext *ci = [CIContext contextWithCGContext:cg options:NULL];
    CGRect r = CGRectMake(0,0,width,height);
    [ci drawImage:image inRect:r fromRect:extent];
    CGContextRelease(cg);
    unpremultiplyBitmap(4,dest,dest,width*height);
}

@implementation PluginClassImpl

- (id)initWithManager:(id<PluginData>)data
{
    self->pluginData = data;
    return self;
}

-(CIImage *)createCIImage
{
    CGImageRef bitmap = [pluginData bitmap];
    CIImage *inputImage = [CIImage imageWithCGImage:bitmap];
    CGImageRelease(bitmap);

    return inputImage;
}

-(void)renderCIImage:(CIImage *)image
{
    int width = [pluginData width];
    int height = [pluginData height];
    IntRect selection = [pluginData selection];
    
    [pluginData setOverlayOpacity:255];
    [pluginData setOverlayBehaviour:kReplacingBehaviour];
    
    unsigned char *overlay = [pluginData overlay];

    if(overlay==NULL) {
        [NSException raise:@"IllegalStateException" format:@"Overlay data reference is nil."];
    }

    if([pluginData isGrayscale]) {
        // need to ensure grayscale output
        CIFilter *filter = [CIFilter filterWithName:@"CIColorMatrix"];
        if (filter == NULL) {
            @throw [NSException exceptionWithName:@"CIColorMatrix" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIAffineTile"] userInfo:NULL];
        }
        [filter setDefaults];
        [filter setValue:image forKey:@"inputImage"];

        [filter setValue:[CIVector vectorWithX:0.2125 Y:0.7154 Z:0.7154 W:0] forKey:@"inputRVector"];
        [filter setValue:[CIVector vectorWithX:0.2125 Y:0.7154 Z:0.7154 W:0] forKey:@"inputGVector"];
        [filter setValue:[CIVector vectorWithX:0.2125 Y:0.7154 Z:0.7154 W:0] forKey:@"inputBVector"];
        image = [filter valueForKey: @"outputImage"];
    }

    rasterizeCIImage(image,overlay,width,height);
    
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

- (void) applyFilter:(CIFilter *)filter
{
    CIImage *inputImage = [self createCIImage];

    if([[filter inputKeys] containsObject:@"inputImage"]){
        [filter setValue:inputImage forKey:@"inputImage"];
    }

    CIImage *outputImage = [filter valueForKey: @"outputImage"];
    
    [self renderCIImage:outputImage];
}

- (void) applyFilterAsOverlay:(CIFilter *)filter
{
    CIImage *outputImage = [filter valueForKey: @"outputImage"];

    [pluginData setOverlayOpacity:255];
    [pluginData setOverlayBehaviour:kNormalBehaviour];
    int width = [pluginData width];
    int height = [pluginData height];

    unsigned char *overlay = [pluginData overlay];

    rasterizeCIImage(outputImage,overlay,width,height);
}

- (void) applyFilters:(CIFilter*) filter,...
{
    va_list args;
    va_start(args, filter);

    CIImage *inputImage = [self createCIImage];

    [filter setValue:inputImage forKey:@"inputImage"];
    CIImage *outputImage = [filter valueForKey: @"outputImage"];

    CIFilter* next;
    while (next = va_arg(args, id))
    {
        [next setValue:outputImage forKey:@"inputImage"];
        outputImage = [next valueForKey: @"outputImage"];
    }
    va_end(args);

    [self renderCIImage:outputImage];
}

- (void) applyFilterBG:(CIFilter *)filter
{
    CIImage *inputImage = [self createCIImage];
    
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
    
    [self renderCIImage:outputImage];
}

- (void) applyFilterFG:(CIFilter *)filter
{
    CIImage *inputImage = [self createCIImage];
    
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
    
    [self renderCIImage:outputImage];
}


- (void) applyFilterFGBG:(CIFilter *)filter
{
    CIImage *inputImage = [self createCIImage];
    
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
    
    [self renderCIImage:outputImage];
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

CGRect determineContentBorders(id<PluginData> pluginData) {
    Margins m = determineContentMargins([pluginData data],[pluginData width],[pluginData height]);

    if (!MarginsIsEmpty(m)) {
        CGRect bounds;

        bounds.origin.x = m.left;
        bounds.origin.y = m.right;
        bounds.size.width = [pluginData width] - m.right - m.left;
        bounds.size.height = [pluginData height] - m.bottom - m.top;

        return bounds;
    }
    else {
        return CGRectNull;
    }
}

- (CIImage *)croppedCIImage:(CGRect)bounds
{
    CIImage *image = [self createCIImage];

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


- (NSString *)name
{
    return [gOurBundle localizedStringForKey:@"name" value:@"Missing Name" table:NULL];
}

- (NSString *)groupName
{
    return [gOurBundle localizedStringForKey:@"groupName" value:@"Missing Group" table:NULL];
}

- (NSString *)instruction
{
    return [gOurBundle localizedStringForKey:@"instruction" value:@"No instructions." table:NULL];
}

- (int)points
{
    return 0;
}

+(BOOL)validatePlugin:(id<PluginData>)data
{
    return YES;
}

@end
