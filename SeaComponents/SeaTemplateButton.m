//
//  SeaTemplateButton.m
//  SeaComponents
//
//  Created by robert engels on 12/3/22.
//

#import "SeaTemplateButton.h"
#import <SeaLibrary/Bitmap.h>

@implementation SeaTemplateButton

- (void)awakeFromNib
{
    self.alternateImage = getTinted(self.image,[NSColor alternateSelectedControlColor]);
}

@end
