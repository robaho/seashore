/*!
	@header		Constants
	@abstract	Defines various constants use by Seashore and the XCF file
				format.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli and
				Copyright (c) 1995 Spencer Kimball and Peter Mattis
*/

typedef enum
{
	PROP_END                   =  0,
	PROP_COLORMAP              =  1,
	PROP_ACTIVE_LAYER          =  2,
	PROP_ACTIVE_CHANNEL        =  3,
	PROP_SELECTION             =  4,
	PROP_FLOATING_SELECTION    =  5,
	PROP_OPACITY               =  6,
	PROP_MODE                  =  7,
	PROP_VISIBLE               =  8,
	PROP_LINKED                =  9,
	PROP_PRESERVE_TRANSPARENCY = 10,
	PROP_APPLY_MASK            = 11,
	PROP_EDIT_MASK             = 12,
	PROP_SHOW_MASK             = 13,
	PROP_SHOW_MASKED           = 14,
	PROP_OFFSETS               = 15,
	PROP_COLOR                 = 16,
	PROP_COMPRESSION           = 17,
	PROP_GUIDES                = 18,
	PROP_RESOLUTION            = 19,
	PROP_TATTOO                = 20,
	PROP_PARASITES             = 21,
	PROP_UNIT                  = 22,
	PROP_PATHS                 = 23,
	PROP_USER_UNIT             = 24
} PropType;

/*!
	@enum		XcfCompressionType
	@constant	COMPRESS_NONE
				Indicates no compression is used.
	@constant	COMPRESS_RLE
				Indicates compression through run-length encoding is used.
*/
typedef enum
{
	COMPRESS_NONE              =  0,
	COMPRESS_RLE               =  1,
	COMPRESS_ZLIB              =  2,  /* unused */
	COMPRESS_FRACTAL           =  3   /* unused */
} XcfCompressionType;


/*!
	@enum       XcfLayerMode
    @discussion These are the layer modes defined in GIMP.
*/
typedef enum
{
    GIMP_LAYER_MODE_NORMAL_LEGACY,
    GIMP_LAYER_MODE_DISSOLVE,
    GIMP_LAYER_MODE_BEHIND_LEGACY,
    GIMP_LAYER_MODE_MULTIPLY_LEGACY,
    GIMP_LAYER_MODE_SCREEN_LEGACY,
    GIMP_LAYER_MODE_OVERLAY_LEGACY,
    GIMP_LAYER_MODE_DIFFERENCE_LEGACY,
    GIMP_LAYER_MODE_ADDITION_LEGACY,
    GIMP_LAYER_MODE_SUBTRACT_LEGACY,
    GIMP_LAYER_MODE_DARKEN_ONLY_LEGACY,
    GIMP_LAYER_MODE_LIGHTEN_ONLY_LEGACY,
    GIMP_LAYER_MODE_HSV_HUE_LEGACY,
    GIMP_LAYER_MODE_HSV_SATURATION_LEGACY,
    GIMP_LAYER_MODE_HSL_COLOR_LEGACY,
    GIMP_LAYER_MODE_HSV_VALUE_LEGACY,
    GIMP_LAYER_MODE_DIVIDE_LEGACY,
    GIMP_LAYER_MODE_DODGE_LEGACY,
    GIMP_LAYER_MODE_BURN_LEGACY,
    GIMP_LAYER_MODE_HARDLIGHT_LEGACY,
    GIMP_LAYER_MODE_SOFTLIGHT_LEGACY,
    GIMP_LAYER_MODE_GRAIN_EXTRACT_LEGACY,
    GIMP_LAYER_MODE_GRAIN_MERGE_LEGACY,
    GIMP_LAYER_MODE_COLOR_ERASE_LEGACY,
    GIMP_LAYER_MODE_OVERLAY,
    GIMP_LAYER_MODE_LCH_HUE,
    GIMP_LAYER_MODE_LCH_CHROMA,
    GIMP_LAYER_MODE_LCH_COLOR,
    GIMP_LAYER_MODE_LCH_LIGHTNESS,
    GIMP_LAYER_MODE_NORMAL,
    GIMP_LAYER_MODE_BEHIND,
    GIMP_LAYER_MODE_MULTIPLY,
    GIMP_LAYER_MODE_SCREEN,
    GIMP_LAYER_MODE_DIFFERENCE,
    GIMP_LAYER_MODE_ADDITION,
    GIMP_LAYER_MODE_SUBTRACT,
    GIMP_LAYER_MODE_DARKEN_ONLY,
    GIMP_LAYER_MODE_LIGHTEN_ONLY,
    GIMP_LAYER_MODE_HSV_HUE,
    GIMP_LAYER_MODE_HSV_SATURATION,
    GIMP_LAYER_MODE_HSL_COLOR,
    GIMP_LAYER_MODE_HSV_VALUE,
    GIMP_LAYER_MODE_DIVIDE,
    GIMP_LAYER_MODE_DODGE,
    GIMP_LAYER_MODE_BURN,
    GIMP_LAYER_MODE_HARDLIGHT,
    GIMP_LAYER_MODE_SOFTLIGHT,
    GIMP_LAYER_MODE_GRAIN_EXTRACT,
    GIMP_LAYER_MODE_GRAIN_MERGE,
    GIMP_LAYER_MODE_VIVID_LIGHT,
    GIMP_LAYER_MODE_PIN_LIGHT,
    GIMP_LAYER_MODE_LINEAR_LIGHT,
    GIMP_LAYER_MODE_HARD_MIX,
    GIMP_LAYER_MODE_EXCLUSION,
    GIMP_LAYER_MODE_LINEAR_BURN,
    GIMP_LAYER_MODE_LUMA_DARKEN_ONLY,
    GIMP_LAYER_MODE_LUMA_LIGHTEN_ONLY,
    GIMP_LAYER_MODE_LUMINANCE,
    GIMP_LAYER_MODE_COLOR_ERASE,
    GIMP_LAYER_MODE_ERASE,
    GIMP_LAYER_MODE_MERGE,
    GIMP_LAYER_MODE_SPLIT,
    GIMP_LAYER_MODE_PASS_THROUGH
} XcfLayerMode;

typedef struct
{
    CGBlendMode blendMode;
} ModeMap;
/*!
 @enum       XcfLayerModeMap
 @discussion These map the GIMP Layer modes to Core Graphics blend modes.
 */
static ModeMap XcfLayerModeMap[] = {
    { kCGBlendModeNormal }, // GIMP_LAYER_MODE_NORMAL
    { -1 }, // GIMP_LAYER_MODE_DISSOLVE,
    { -1 }, // GIMP_LAYER_MODE_BEHIND_LEGACY,
    { kCGBlendModeMultiply }, // GIMP_LAYER_MODE_MULTIPLY_LEGACY,
    { kCGBlendModeScreen }, //  GIMP_LAYER_MODE_SCREEN_LEGACY,
    { kCGBlendModeOverlay },  // GIMP_LAYER_MODE_OVERLAY_LEGACY,
    { kCGBlendModeDifference }, // GIMP_LAYER_MODE_DIFFERENCE_LEGACY,
    { kCGBlendModePlusLighter }, // GIMP_LAYER_MODE_ADDITION_LEGACY,
    { -1}, // GIMP_LAYER_MODE_SUBTRACT_LEGACY,
    { kCGBlendModeDifference }, // GIMP_LAYER_MODE_DARKEN_ONLY_LEGACY,
    { kCGBlendModeLighten }, // GIMP_LAYER_MODE_LIGHTEN_ONLY_LEGACY,
    { kCGBlendModeHue }, //  GIMP_LAYER_MODE_HSV_HUE_LEGACY,
    { kCGBlendModeSaturation }, // GIMP_LAYER_MODE_HSV_SATURATION_LEGACY,
    { kCGBlendModeColor }, // GIMP_LAYER_MODE_HSL_COLOR_LEGACY,
    { kCGBlendModeLuminosity }, // GIMP_LAYER_MODE_HSV_VALUE_LEGACY,
    { -1 },  // GIMP_LAYER_MODE_DIVIDE_LEGACY,
    { kCGBlendModeColorDodge }, // GIMP_LAYER_MODE_DODGE_LEGACY,
    { kCGBlendModeColorBurn }, // GIMP_LAYER_MODE_BURN_LEGACY,
    { kCGBlendModeHardLight }, // GIMP_LAYER_MODE_HARDLIGHT_LEGACY,
    { kCGBlendModeSoftLight }, // GIMP_LAYER_MODE_SOFTLIGHT_LEGACY,
    {-1}, // GIMP_LAYER_MODE_GRAIN_EXTRACT_LEGACY,
    {-1}, // GIMP_LAYER_MODE_GRAIN_MERGE_LEGACY,
    {-1}, // GIMP_LAYER_MODE_COLOR_ERASE_LEGACY,
    {kCGBlendModeOverlay },// GIMP_LAYER_MODE_OVERLAY,
    {-1}, // GIMP_LAYER_MODE_LCH_HUE,
    {-1}, // GIMP_LAYER_MODE_LCH_CHROMA,
    {kCGBlendModeColor}, // GIMP_LAYER_MODE_LCH_COLOR,
    {kCGBlendModeLuminosity }, // GIMP_LAYER_MODE_LCH_LIGHTNESS,
    {kCGBlendModeNormal }, // GIMP_LAYER_MODE_NORMAL,
    {-1}, // GIMP_LAYER_MODE_BEHIND,
    {kCGBlendModeMultiply}, // GIMP_LAYER_MODE_MULTIPLY,
    {kCGBlendModeScreen},// GIMP_LAYER_MODE_SCREEN,
    {kCGBlendModeDifference}, // GIMP_LAYER_MODE_DIFFERENCE,
    {kCGBlendModePlusLighter}, // GIMP_LAYER_MODE_ADDITION,
    {kCGBlendModePlusDarker}, // GIMP_LAYER_MODE_SUBTRACT,
    {kCGBlendModeDarken}, // GIMP_LAYER_MODE_DARKEN_ONLY,
    {kCGBlendModeLighten},// GIMP_LAYER_MODE_LIGHTEN_ONLY,
    {kCGBlendModeHue},// GIMP_LAYER_MODE_HSV_HUE,
    {kCGBlendModeSaturation},// GIMP_LAYER_MODE_HSV_SATURATION,
    {kCGBlendModeColor},// GIMP_LAYER_MODE_HSL_COLOR,
    {kCGBlendModeLuminosity},// GIMP_LAYER_MODE_HSV_VALUE,
    {-1},  // GIMP_LAYER_MODE_DIVIDE,
    {kCGBlendModeColorDodge}, // GIMP_LAYER_MODE_DODGE,
    {kCGBlendModeColorBurn}, // GIMP_LAYER_MODE_BURN,
    {kCGBlendModeHardLight},// GIMP_LAYER_MODE_HARDLIGHT,
    {kCGBlendModeSoftLight},// GIMP_LAYER_MODE_SOFTLIGHT,
    {-1}, // GIMP_LAYER_MODE_GRAIN_EXTRACT,
    {-1}, // GIMP_LAYER_MODE_GRAIN_MERGE,
    {-1}, // GIMP_LAYER_MODE_VIVID_LIGHT,
    {-1}, // GIMP_LAYER_MODE_PIN_LIGHT,
    {-1}, // GIMP_LAYER_MODE_LINEAR_LIGHT,
    {-1}, // GIMP_LAYER_MODE_HARD_MIX,
    {kCGBlendModeExclusion}, // GIMP_LAYER_MODE_EXCLUSION,
    {-1}, // GIMP_LAYER_MODE_LINEAR_BURN,
    {-1}, // GIMP_LAYER_MODE_LUMA_DARKEN_ONLY,
    {-1}, // GIMP_LAYER_MODE_LUMA_LIGHTEN_ONLY,
    {-1}, // GIMP_LAYER_MODE_LUMINANCE,
    {-1}, // GIMP_LAYER_MODE_COLOR_ERASE,
    {-1}, // GIMP_LAYER_MODE_ERASE,
    {-1}, // GIMP_LAYER_MODE_MERGE,
    {-1}, // GIMP_LAYER_MODE_SPLIT,
    {-1}, // GIMP_LAYER_MODE_PASS_THROUGH
};

#define XCF_TILE_WIDTH 64
#define XCF_TILE_HEIGHT 64

/*!
	@enum		XcfImageType
	@constant	XCF_RGB_IMAGE
				A document with three colour channels (red, green and blue).
	@constant	XCF_GRAY_IMAGE
				A document with a single colour channel (white).
	@constant	XCF_INDEXED_IMAGE
				A document with an indexed colour channel (all such
				documents are converted to one of the above types after
				loading, as such elsewhere you do not need to account for
				this document type).
*/
typedef enum
{
	XCF_RGB_IMAGE,
	XCF_GRAY_IMAGE,
	XCF_INDEXED_IMAGE
} XcfImageType;

/*!
	@enum		GimpImageType
	@constant   GIMP_RGB_IMAGE
				Specifies the layer's data is in the RGB format.
	@constant   GIMP_RGBA_IMAGE
				Specifies the layer's data is in the RGBA format.
	@constant   GIMP_GRAY_IMAGE
				Specifies the layer's data is in the GRAY format.
	@constant   GIMP_GRAYA_IMAGE
				Specifies the layer's data is in the GRAYA format.
	@constant   GIMP_INDEXED_IMAGE
				Specifies the layer's data is in the INDEXED format.
	@constant   GIMP_INDEXEDA_IMAGE
				Specifies the layer's data is in the INDEXEDA format.
*/
typedef enum
{
  GIMP_RGB_IMAGE,
  GIMP_RGBA_IMAGE,
  GIMP_GRAY_IMAGE,
  GIMP_GRAYA_IMAGE,
  GIMP_INDEXED_IMAGE,
  GIMP_INDEXEDA_IMAGE
} GimpImageType;


/*!
	@enum		k...Channels
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

/*!
	@enum		k...Layer
	@constant	kActiveLayer
				Specifies the active layer.
	@constant	kAllLayers
				Specifies all layers.
	@constant	kLinkedLayers
				Specifies all linked layers.
*/
enum {
	kActiveLayer = -1,
	kAllLayers = -2,
	kLinkedLayers = -3
};

/*!
	@enum		k...Format
	@constant	kAlphaFirstFormat
				Specifies the alpha channel is first.
	@constant	kAlphaNonPremultipliedFormat
				Specifies the alpha is not premultiplied.
	@constant	kFloatingFormat
				Specifies the colour components are specified as floating point values.
*/
enum {
	kAlphaFirstFormat = 1 << 0,
	kAlphaNonPremultipliedFormat = 1 << 1,
	kFloatingFormat = 1 << 2
};

/*!
	@defined	kMaxImageSize
	@discussion	Specifies the maximum size of an image, this restricts images to
				256 MB.
*/
#define kMaxImageSize 8192*2

/*!
	@defined	kMinImageSize
	@discussion	Specifies the minimum size of an image.
*/
#define kMinImageSize 1

/*!
	@defined	kMaxResolution
	@discussion	Specifies the maximum resolution of an image.
*/
#define kMaxResolution 3000

/*!
	@defined	kMinResolution
	@discussion	Specifies the minimum resolution of an image.
*/
#define kMinResolution 18

#define MyRGBSpace NSDeviceRGBColorSpace
#define MyGraySpace NSDeviceWhiteColorSpace

#define MyRGBCS NSColorSpace.deviceRGBColorSpace
#define MyGrayCS NSColorSpace.deviceGrayColorSpace

extern CGColorSpaceRef rgbCS;
extern CGColorSpaceRef grayCS;

#define COLOR_SPACE (spp==4?rgbCS:grayCS)
