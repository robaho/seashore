#import "Seashore.h"
#import "WandOptions.h"
#import "AbstractTool.h"
#import "AbstractTool+FillExtensions.h"
#import "AbstractSelectTool.h"

/*!
	@class		WandTool
	@abstract	The wand tool allows selections to be made based upon colour
				that are confined to a given tolerance range.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface WandTool : AbstractSelectTool {
    IntPoint startPoint,currentPoint;
    IntRect previewRect;
    
    WandOptions *options;

    unsigned char lastTolerance;
    NSOperationQueue *queue;
}
@end
