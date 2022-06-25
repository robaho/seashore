/*!
	@header		ThresholdView
	@abstract	Adjusts the Threshold and contrast of the selection.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2005 Mark Pazolli
*/

#import <Cocoa/Cocoa.h>
#import <Plugins/PluginData.h>


@interface ThresholdView : NSView
{
	int histogram[256];
	
	id thresholdClass;
}

- (ThresholdView*)initWithClass:(id)class;

- (void)calculateHistogram:(PluginData *)pluginData; 

/*!
	@method		drawRect:
	@discussion	Draws the view within the given rectangle.
	@param		rect
				The rectangle containing the part of the view to be drawn.
*/
- (void)drawRect:(NSRect)rect;

@end
