#import <Cocoa/Cocoa.h>
#import "PluginData.h"

#define MyRGBSpace NSDeviceRGBColorSpace
#define MyGraySpace NSDeviceWhiteColorSpace

#define MyRGBCS NSColorSpace.deviceRGBColorSpace
#define MyGrayCS NSColorSpace.deviceGrayColorSpace

#define gOurBundle [NSBundle bundleForClass:[self class]]
#define gUserDefaults [NSUserDefaults standardUserDefaults]

#define UserIntDefault(key,def) ([gUserDefaults objectForKey:key] ? [gUserDefaults integerForKey:key] : def)
#define UserFloatDefault(key,def) ([gUserDefaults objectForKey:key] ? [gUserDefaults floatForKey:key] : def)

/*!
	@protocol	PluginClass
	@abstract	required methods of a plugin with Seashore
	@discussion	This class is in the public domain allowing plug-ins of any
				license to be made compatible with Seashore.
				<br><br>
				<b>License:</b> Public Domain 2004<br>
				<b>Copyright:</b> N/A
*/

@protocol PluginClass

/*!
	@method		initWithManager:
	@discussion	Initializes an instance of this class with the given manager.
	@param		data
				The Plugin services callback.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)initWithManager:(PluginData *)data;

/*!
	@method		name
	@discussion	Returns the plug-in's name.
	@result		Returns an NSString indicating the plug-in's name.
*/
- (NSString *)name;

/*!
	@method		groupName
	@discussion	Returns the plug-in's group name.
	@result		Returns an NSString indicating the plug-in's group name.
*/
- (NSString *)groupName;

/*!
 @method        instruction
 @discussion    Returns the plug-in's instructions.
 @result        Returns a NSString indicating the plug-in's instructions
 (127 chars max).
 */
- (NSString *)instruction;

/*!
 @method        sanity
 @discussion    Returns a string to indicate this is a Seashore plug-in.
 @result        Returns the NSString "Seashore Approved (Bobo)".
 */
- (NSString *)sanity;

- (NSView*)initialize;

- (void)execute;

/*!
 @method        validateMenuItem
 @discussion    return YES if the plugin can be run given the current layer conditions - obtained from the SeaPlugins reference
 @result        return YES if it can be run, else NO
 */
+ (BOOL)validatePugin:(PluginData*)pluginData;

@end

/*!
 @discussion apply a core image filter to the current plugin data - modifies the overlay and replace entries. Do not set the image on the filter.
 */
void applyFilter(PluginData *pluginData,CIFilter *filter);

/*!
 @discussion apply a core image filter to the current plugin data - modifies the overlay for source compositing
 */
void applyFilterAsOverlay(PluginData *pluginData,CIFilter *filter);

/*!
 @discussion apply a core image filter to the current plugin data - modifies the overlay and replace entries. Do not set the image on the filter. Must end list
 with NULL filter.
 */
void applyFilters(PluginData *pluginData,CIFilter *filterA,...);

/*!
 @discussion apply a core image filter with a constant background to the current plugin data - modifies the overlay and replace entries. Do not set the image on the filter.
 */
void applyFilterFG(PluginData *pluginData,CIFilter *filter);

/*!
 @discussion apply a core image filter with a constant background to the current plugin data - modifies the overlay and replace entries. Do not set the image on the filter.
 */
void applyFilterBG(PluginData *pluginData,CIFilter *filter);

/*!
 @discussion apply a core image filter with a using foreground and background to colorize the current plugin data - modifies the overlay and replace entries. Do not set the image on the filter.
 */
void applyFilterFGBG(PluginData *pluginData,CIFilter *filter);


/*!
 @discussion create a CIImage that represents the source plugin data
 */
CIImage *createCIImage(PluginData *plugin);

/*!
 @discussion render a CIImage into the plugin overlay, and set the replace mask
 */
void renderCIImage(PluginData *plugin,CIImage *image);

/*!
 @defined    int_mult(a, b, t)
 @discussion    A macro that when given two unsigned characters (bytes)
 determines the product of the two. The returned value is scaled
 so it is between 0 and 255. A third argument,  a temporary
 integer, must also be passed to allow the calculation to
 complete.
 */
#define int_mult(a,b,t)  ((t) = (a) * (b) + 0x80, ((((t) >> 8) + (t)) >> 8))

#define PI 3.14159265

/*!
 @function    premultiplyBitmap
 @discussion    Given a bitmap this function premultiplies the primary channels
 and places the result in the output. The output and input can
 both point to the same block of memory.
 @param        spp
 The samples per pixel of the original bitmap.
 @param        destPtr
 The block of memory in which to place the premultiplied bitmap.
 @param        srcPtr
 The block of memory containing the original bitmap.
 @param        length
 The length of the bitmap in terms of pixels (not bytes).
 */
void premultiplyBitmap(int spp, unsigned char *destPtr, unsigned char *srcPtr, int length);

/*!
 @function    unpremultiplyBitmap
 @discussion    Given a bitmap this function tries to reverse the
 premultiplication of the primary channels and places the result
 in the output. The output and input can  both point to the same
 block of memory.
 @param        spp
 The samples per pixel of the original bitmap.
 @param        destPtr
 The block of memory in which to place the premultiplied bitmap.
 @param        srcPtr
 The block of memory containing the original bitmap.
 @param        length
 The length of the bitmap in terms of pixels (not bytes).
 */
void unpremultiplyBitmap(int spp, unsigned char *destPtr, unsigned char *srcPtr, int length);

float calculateAngle(IntPoint point,IntPoint apoint);
int calculateRadius(IntPoint point,IntPoint apoint);

CGRect determineContentBorders(PluginData *pluginData);

/*!
 @discussion return a possibly cropped CIImage, the image is already marked autorelease
 */
CIImage *croppedCIImage(PluginData *pluginData,CGRect bounds);

CIColor *createCIColor(NSColor *color);
