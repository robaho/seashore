#import "Seashore.h"
#import "SmudgeOptions.h"
#import "AbstractBrushTool.h"
#import <Accelerate/Accelerate.h>

/*!
	@class		SmudgeTool
	@abstract	The smudge tool allows the user to smudge certain parts of a
				picutre, removing unwanted figures or edges.
	@discussion	The implementation of smudging is not complete.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface SmudgeTool : AbstractBrushTool {
    SmudgeOptions *options;
    unsigned char *accumData, *tempData;
    int rate;
    bool noMoreBlur;
}
@end
