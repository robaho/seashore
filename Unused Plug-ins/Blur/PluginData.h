/*!
	@header		PluginData
	@abstract	The object shared between Seashore and most plug-ins.
	@discussion	N/A
				<br><br>
				<b>License:</b> Public Domain 2004<br>
				<b>Copyright:</b> N/A
*/

#import <Cocoa/Cocoa.h>
#import "Rects.h"

/*!
	@enum		Overlay behaviours
	@constant	kNormalBehaviour
				Indicates the overlay is to be composited on to the underlying layer.
	@constant	kErasingBehaviour
				Indicates the overlay is to erase the underlying layer.
	@constant	kReplacingBehaviour
				Indicates the overlay is to replace the underling layer where specified.
*/
enum {
	kNormalBehaviour,
	kErasingBehaviour,
	kReplacingBehaviour
};

/*!
	@enum		Channel specifications
	@constant	kAllChannels
				Specifies all channels.
	@constant	kPrimaryChannels
				Specifies the primary RGB channels in a colour image or the
				primary white channel in a greyscale image.
	@constant	kAlphaChannel
				Specifies the alpha channel.
*/
enum {
	kAllChannels,
	kPrimaryChannels,
	kAlphaChannel
};

@interface PluginData : NSObject {

}

/*!
	@method		selection
	@discussion	Returns the rectange bounding the active selection in the
				layer's co-ordinates.
	@result		Returns a IntRect indicating the active selection.
*/
- (IntRect)selection;

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
	@method		spp
	@discussion	Returns the document's samples per pixel (1, 2, 3 or 4).
	@result		Returns an integer indicating the document's sample per pixel.
*/
- (int)spp;

/*!
	@method		channel
	@discussion	Returns the currently selected channel(s).
	@result		Returns an integer representing the currently selected
				channel(s).
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
	@method		window
	@discussion	Returns the window to use for the plug-in's panel.
	@result		Returns the window to use for the plug-in's panel.
*/
- (id)window;

/*!
	@method		setOverlayBehaviour:
	@discussion	Sets the overlay behaviour.
	@param		value
				The new overlay behaviour (see above).
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
	@method		apply
	@discussion	Apply the plug-in changes.
*/
- (void)apply;

/*!
	@method		preview
	@discussion	Preview the plug-in changes.
*/
- (void)preview;

/*!
	@method		cancel
	@discussion	Cancel the plug-in changes.
*/
- (void)cancel;

@end
