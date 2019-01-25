#import "BannerView.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaWarning.h"

@implementation BannerView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        bannerText = [NSString string];
		bannerImportance = kVeryLowImportance;
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    
    NSColor *background;
    NSColor *foreground;

	switch(bannerImportance){
		case kUIImportance:
            background = [NSColor blueColor];
            foreground = [NSColor whiteColor];
			break;
		case kHighImportance:
            background = [NSColor redColor];
            foreground = [NSColor whiteColor];
			break;
		default:
            background = [NSColor yellowColor];
            foreground = [NSColor blackColor];
			break;
	}
    
    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:background endingColor:[background shadowWithLevel:0.20]];
    [gradient drawInRect:NSMakeRect(0,0,[self frame].size.width, [self frame].size.height) angle:270];
    
    [NSGraphicsContext saveGraphicsState];

	NSDictionary *attrs;
	attrs = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:12] , NSFontAttributeName, foreground, NSForegroundColorAttributeName,nil];
	
	// We need to calculate the width of the text box
	NSRect drawRect = NSMakeRect(10, 8, [self frame].size.width, 18);
	if([alternateButton frame].origin.x < [self frame].size.width){
		drawRect.size.width -= 232;
	}else if ([defaultButton frame].origin.x < [self frame].size.width ){
		drawRect.size.width -= 124;
	}
	
	if(drawRect.size.width < [bannerText sizeWithAttributes:attrs].width){
		[@"..." drawInRect:NSMakeRect(drawRect.size.width + 8, 8, 18, 18) withAttributes:attrs];
	}
	[bannerText drawInRect: drawRect withAttributes:attrs];
	[NSGraphicsContext restoreGraphicsState];
}

- (void)setBannerText:(NSString *)text defaultButtonText:(NSString *)dText alternateButtonText:(NSString *)aText andImportance:(int)importance
{
    bannerText = text;
	bannerImportance = importance;
	
	if(dText){
		[defaultButton setTitle:dText];
		NSRect frame = [defaultButton frame];
		frame.origin.x = [self frame].size.width - 108;
		[defaultButton setFrame:frame];
	}else{
		NSRect frame = [defaultButton frame];
		frame.origin.x = [self frame].size.width;
		[defaultButton setFrame:frame];
	}
		
	if(aText && dText){
		[alternateButton setTitle:aText];
		NSRect frame = [alternateButton frame];
		frame.origin.x = [self frame].size.width - 216;
		[alternateButton setFrame:frame];
	}else {
		NSRect frame = [alternateButton frame];
		frame.origin.x = [self frame].size.width;
		[alternateButton setFrame:frame];
	}
	[self setNeedsDisplay: YES];
}
@end
