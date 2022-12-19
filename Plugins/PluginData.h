#import <SeaLibrary/SeaLibrary.h>

/*!
	@protocol		PluginData
	@abstract   	The object shared between Seashore and most plug-ins.
*/

@protocol PluginData

/*!
	@method		selection
	@discussion	Returns the rectange bounding the active selection in the
				layer's co-ordinates.
	@result		Returns a IntRect indicating the active selection.
*/
- (IntRect)selection;

/*!
 @method        inSelection
 @result        Returnstrue if the point is in the selection or no selection is active
 */
- (bool)inSelection:(IntPoint)local;

/*!
 @method        bitmap
 @discussion    Returns the bitmap data of the layer. Caller must release.
 @result        Returns a bitmap of the layer.
 */
- (CGImageRef)bitmap;

/*!
	@method		data
	@discussion	Returns the bitmap data of the layer.
	@result		Returns a pointer to the bitmap data of the layer.
*/
- (unsigned char *)data;

/*!
	@method		replace
	@discussion	Returns the replace mask of the overlay.
	@result		Returns a pointer to the 8 bits per pixel replace mask of the
				overlay.
*/
- (unsigned char *)replace;

/*!
	@method		overlay
	@discussion	Returns the bitmap data of the overlay.
	@result		Returns a pointer to the bitmap data of the overlay.
*/
- (unsigned char *)overlay;

/*!
	@method		channel
	@discussion	Returns the currently selected channel.
	@result		Returns an integer representing the currently selected channel.
*/
- (int)channel;

/*!
	@method		width
	@discussion	Returns the layer's width in pixels.
	@result		Returns an integer indicating the layer's width in pixels.
*/
- (int)width;

/*!
	@method		height
	@discussion	Returns the layer's height in pixels.
	@result		Returns an integer indicating the layer's height in pixels.
*/
- (int)height;

/*!
	@method		hasAlpha
	@discussion	Returns if the layer's alpha channel is enabled.
	@result		Returns YES if the layer's alpha channel is enabled, NO
				otherwise.
*/
- (BOOL)hasAlpha;

- (BOOL)isGrayscale;

/*!
	@method		point:
	@discussion	Returns the given point from the effect tool. Only valid
				for plug-ins with type one.
	@param		index
				An integer from zero to less than the plug-in's specified
				value.
	@result		The corresponding point from the effect tool.
*/
- (IntPoint)point:(int)index;

/*!
	@method		foreColor
	@discussion	Return the active foreground colour.
	@result		Returns an NSColor representing the active foreground
				colour.
*/
- (NSColor *)foreColor;

/*!
	@method		backColor
	@discussion	Return the active background colour.
	@result		Returns an NSColor representing the active background
				colour.
*/
- (NSColor *)backColor;

/*!
	@method		setOverlayBehaviour:
	@discussion	Sets the overlay behaviour.
	@param		value
				The new overlay behaviour (see SeaWhiteboard).
*/
- (void)setOverlayBehaviour:(int)value;

/*!
	@method		setOverlayOpacity:
	@discussion	Sets the opacity of the overlay.
	@param		value
				An integer from 0 to 255 representing the revised opacity of the
				overlay.
*/
- (void)setOverlayOpacity:(int)value;

/*!
    @discussion callback to let tool know the plugin settings changed
 */
- (void)settingsChanged;

@end
