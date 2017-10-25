#import "Globals.h"
#import "AbstractOptions.h"

/*!
	@class		GradientOptions
	@abstract	Handles the options pane for the gradient tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface GradientOptions : AbstractOptions
{

	// The pop-up menu indicating the gradient's type
	IBOutlet id typePopup;
	
	// The pop-up menu indicating the repeating style for the gradient
	IBOutlet id repeatPopup;
	
}

/*!
	@method		awakeFromNib
	@discussion	Loads previous options from preferences.
*/
- (void)awakeFromNib;

/*!
	@method		type
	@discussion	Returns the gradient type to be used with the gradient tool.
	@result		Returns an integer representing the gradient type to be used see
				GIMPCore).
*/
- (int)type;

/*!
	@method		repeat
	@discussion	Returns the repeating style to be used with the gradient tool.
	@result		Returns an integer representing the repeating style to be used
				see GIMPCore).
*/
- (int)repeat;

/*!
	@method		supersample
	@discussion Returns whether adaptive supersampling should take place on the
				gradient.
	@result		Returns YES if adaptive supersampling should take place, NO
				otherwise.
*/
- (BOOL)supersample;

/*!
	@method		maximumDepth
	@discussion Returns the maximum depth of the recursive supersampling
				algorithm.
	@result		An integer indicating the maximum depth of the recursive
				supersampling algorithm.
*/
- (int)maximumDepth;

/*!
	@method		threshold
	@discussion The threshold to be used with supersampling.
	@result		A double indicating the threshold to be used with supersampling.
*/
- (double)threshold;

/*!
	@method		shutdown
	@discussion	Saves current options upon shutdown.
*/
- (void)shutdown;

@end
