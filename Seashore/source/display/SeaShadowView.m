#import "SeaShadowView.h"
#import "SeaController.h"
#import "SeaPrefs.h"

#import "Globals.h"

@implementation SeaShadowView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        areRulersVisible = NO;
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
	[[(SeaPrefs *)[SeaController seaPrefs] windowBack] set];
	[[NSBezierPath bezierPathWithRect:rect] fill];

	NSRect scrollRect = [[scrollView contentView] bounds];

	NSRect shadowRect = NSMakeRect(-scrollRect.origin.x + areRulersVisible * 22, -scrollRect.origin.y + [scrollView hasHorizontalScroller] * 15, scrollRect.size.width + 2 * scrollRect.origin.x , scrollRect.size.height + 2 * scrollRect.origin.y);
	
	NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
	
	[shadow setShadowOffset: NSMakeSize(3, -3)];
	[shadow setShadowBlurRadius: 5];
	[shadow setShadowColor:[NSColor blackColor]];
	[shadow set];

	[[NSBezierPath bezierPathWithRect:shadowRect] fill];
}

- (void)setRulersVisible:(BOOL)isVisible
{
	if(isVisible != areRulersVisible){
		areRulersVisible = isVisible;
		[self setNeedsDisplay:YES];
	}
}

@end
