#import "BannerView.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaWarning.h"

@implementation BannerView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        bannerText = [[NSString string] retain];
		bannerImportance = kVeryLowImportance;
    }
    return self;
}

- (void)dealloc
{
	[bannerText release];
	[super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect {
    // We use images for the backgrounds
	NSImage *background = NULL;
	switch(bannerImportance){
		case kUIImportance:
			background = [NSImage imageNamed:@"floatbar"];
			break;
		case kHighImportance:
			background = [NSImage imageNamed:@"errorbar"];
			break;
		default:
			background = [NSImage imageNamed:@"warningbar"];
			break;
	}
	
	[background drawInRect:NSMakeRect(0, 0, [self frame].size.width, [self frame].size.height) fromRect: NSZeroRect operation: NSCompositeSourceOver fraction: 1.0]; 
	[NSGraphicsContext saveGraphicsState];
	NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
	[shadow setShadowOffset: NSMakeSize(0, 1)];
	[shadow setShadowBlurRadius:0];
	[shadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.5]];
	[shadow set];
	
	NSDictionary *attrs;
	attrs = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:12] , NSFontAttributeName, [NSColor whiteColor], NSForegroundColorAttributeName, shadow ,NSShadowAttributeName ,nil];
	
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
	[bannerText release];
	bannerText = [text retain];
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
