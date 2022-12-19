#import <Cocoa/Cocoa.h>
#import "PluginData.h"
#import "PluginClass.h"

#define MyRGBSpace NSDeviceRGBColorSpace
#define MyGraySpace NSDeviceWhiteColorSpace

#define MyRGBCS NSColorSpace.deviceRGBColorSpace
#define MyGrayCS NSColorSpace.deviceGrayColorSpace

#define gOurBundle [NSBundle bundleForClass:[self class]]
#define gUserDefaults [NSUserDefaults standardUserDefaults]

#define UserIntDefault(key,def) ([gUserDefaults objectForKey:key] ? [gUserDefaults integerForKey:key] : def)
#define UserFloatDefault(key,def) ([gUserDefaults objectForKey:key] ? [gUserDefaults floatForKey:key] : def)

enum {
    kNormalBehaviour,
    kErasingBehaviour,
    kReplacingBehaviour
};

/*!
	@protocol	PluginClass
	@abstract	required methods of a plugin with Seashore
	@discussion	This class is in the public domain allowing plug-ins of any
				license to be made compatible with Seashore.
				<br><br>
				<b>License:</b> Public Domain 2004<br>
				<b>Copyright:</b> N/A
*/

@interface PluginClassImpl : NSObject
{
    id<PluginData> pluginData;
}

/*!
 @method		initWithManager:
 @discussion	Initializes an instance of this class with the given manager.
 @param		data
 The Plugin services callback.
 @result		Returns instance upon success (or NULL otherwise).
 */
- (id)initWithManager:(id<PluginData>)data;

- (int)points;
- (NSString*)name;
- (NSString*)groupName;
- (NSString*)instruction;

/*!
 @discussion apply a core image filter to the current plugin data - modifies the overlay and replace entries. Do not set the image on the filter.
 */
-(void)applyFilter:(CIFilter *)filter;

/*!
 @discussion apply a core image filter to the current plugin data - modifies the overlay for source compositing
 */
-(void)applyFilterAsOverlay:(CIFilter *)filter;

/*!
 @discussion apply a core image filter to the current plugin data - modifies the overlay and replace entries. Do not set the image on the filter. Must end list
 with NULL filter.
 */
-(void) applyFilters:(CIFilter *)filterA,...;

/*!
 @discussion apply a core image filter with a constant background to the current plugin data - modifies the overlay and replace entries. Do not set the image on the filter.
 */
-(void) applyFilterFG:(CIFilter *)filter;

/*!
 @discussion apply a core image filter with a constant background to the current plugin data - modifies the overlay and replace entries. Do not set the image on the filter.
 */
-(void) applyFilterBG:(CIFilter *)filter;

/*!
 @discussion apply a core image filter with a using foreground and background to colorize the current plugin data - modifies the overlay and replace entries. Do not set the image on the filter.
 */
-(void) applyFilterFGBG:(CIFilter *)filter;

/*!
 @discussion create a CIImage that represents the source plugin data
 */
-(CIImage *)createCIImage;

/*!
 @discussion render a CIImage into the plugin overlay, and set the replace mask
 */
-(void)renderCIImage:(CIImage *)image;

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

float calculateAngle(IntPoint point,IntPoint apoint);
int calculateRadius(IntPoint point,IntPoint apoint);

CGRect determineContentBorders(id<PluginData> pluginData);

/*!
 @discussion return a possibly cropped CIImage, the image is already marked autorelease
 */
-(CIImage *)croppedCIImage:(CGRect)bounds;

CIColor *createCIColor(NSColor *color);

@end

