#import "HSVClass.h"
#import <SeaLibrary/SeaLibrary.h>

@implementation HSVClass

static inline void RGBtoHSV(int *ir, int *ig, int *ib)
{
	double max, min, delta;
	double h, s, v;
	double r, g, b;
	
	r = (double)*ir / 255.0;
	g = (double)*ig / 255.0;
	b = (double)*ib / 255.0;
	
	if (r > g) {
		max = MAX (r, b);
		min = MIN (g, b);
	}
	else {
		max = MAX (g, b);
		min = MIN (r, b);
    }

	v = max;
	delta = max - min;

	if (delta > 0.0001) {
		s = delta / max;

		if (r == max) {
			h = (g - b) / delta;
        }
		else if (g == max) {
			h = 2.0 + (b - r) / delta;
        }
		else if (b == max) {
			h = 4.0 + (r - g) / delta;
        }

		h /= 6.0;

		if (h < 0.0)
			h += 1.0;
		else if (h > 1.0)
			h -= 1.0;
	}
	else {
		s = 0.0;
		h = 0.0;
	}
	
	*ir = h * 255.0;
	*ig = s * 255.0;
	*ib = v * 255.0;
}

static inline void HSVtoRGB(int *ih, int *is, int *iv)
{
	int		i;
	double	r, g, b;
	double	f, w, q, t;
	double	h, s, v;

	h = (double)*ih / 255.0;
	s = (double)*is / 255.0;
	v = (double)*iv / 255.0;

	if (s == 0.0) {
		r = v;
		g = v;
		b = v;
	}
	else {
		if (h == 1.0)
			h = 0.0;

		h *= 6.0;

		i = (int)h;
		f = h - i;
		w = v * (1.0 - s);
		q = v * (1.0 - (s * f));
		t = v * (1.0 - (s * (1.0 - f)));

		switch (i) {
			case 0:
				r = v;
				g = t;
				b = w;
			break;
			case 1:
				r = q;
				g = v;
				b = w;
			break;
			case 2:
				r = w;
				g = v;
				b = t;
			break;
			case 3:
				r = w;
				g = q;
				b = v;
			break;
			case 4:
				r = t;
				g = w;
				b = v;
			break;
			case 5:
				r = v;
				g = w;
				b = q;
			break;
		}
	}
	
	*ih = r * 255.0;
	*is = g * 255.0;
	*iv = b * 255.0;
}

- (id)initWithManager:(id<PluginData>)data
{
    self = [super initWithManager:data];

    panel = [VerticalView view];
    hue = [SeaSlider sliderWithTitle:@"Hue" Min:-1 Max:1 Listener:self];
    saturation = [SeaSlider sliderWithTitle:@"Saturation" Min:-1 Max:1 Listener:self];
    value = [SeaSlider sliderWithTitle:@"Value" Min:-1 Max:1 Listener:self];

    [panel addSubviews:hue,saturation,value,nil];

	return self;
}

- (NSView*)initialize
{
    [hue setFloatValue:UserFloatDefault(@"HSV.hue",0.0)];
    [saturation setFloatValue:UserFloatDefault(@"HSV.saturation",0.0)];
    [value setFloatValue:UserFloatDefault(@"HSV.value",0.0)];

    return panel;
}

- (IBAction)apply:(id)sender
{
    [gUserDefaults setFloat:[hue floatValue] forKey:@"HSV.hue"];
    [gUserDefaults setFloat:[saturation floatValue] forKey:@"HSV.saturation"];
    [gUserDefaults setFloat:[value floatValue] forKey:@"HSV.intensity"];
}

- (IBAction)componentChanged:(id)sender
{
    [pluginData settingsChanged];
}

static inline unsigned char CLAMP(int x) { return (x < 0) ? 0 : ((x > 255) ? 255 : x); }
static inline unsigned char WRAPAROUND(int x) { return (x < 0) ? (255 + ((x + 1) % 255)) : ((x > 255) ? (x % 255) : x); }

- (void)execute
{
	IntRect selection;
	int i, j, width, channel, pos;
	unsigned char *data, *overlay, *replace;
	int r, g, b;
	
	[pluginData setOverlayOpacity:255];
	[pluginData setOverlayBehaviour:kReplacingBehaviour];
	selection = [pluginData selection];
	channel = [pluginData channel];
	width = [pluginData width];
	data = [pluginData data];
	overlay = [pluginData overlay];
	replace = [pluginData replace];

    float h = [hue floatValue];
    float s = [saturation floatValue];
    float v = [value floatValue];

	for (j = selection.origin.y; j < selection.origin.y + selection.size.height; j++) {
		for (i = selection.origin.x; i < selection.origin.x + selection.size.width; i++) {
			pos = (j * width + i) * SPP;
			r = data[pos + CR] ;
			g = data[pos + CG];
			b = data[pos + CB];
			overlay[pos + alphaPos] = data[pos + alphaPos];
			RGBtoHSV(&r, &g, &b);
			r = WRAPAROUND(r + (int)(h * 255.0));
			g = CLAMP(g + (int)(s * 255.0));
			b = CLAMP(b + (int)(v * 255.0));
			HSVtoRGB(&r, &g, &b);
			overlay[pos + CR] = (unsigned char)r;
			overlay[pos + CG] = (unsigned char)g;
			overlay[pos + CB] = (unsigned char)b;
            premultiplyBitmap(4,overlay+pos,overlay+pos,1);
			replace[j * width + i] = 255;
		}
	}
}

+ (BOOL)validatePlugin:(id<PluginData>)pluginData
{
    if ([pluginData channel] == kAlphaChannel)
        return NO;
	
	return YES;
}

@end
