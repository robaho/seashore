#import "HSVClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

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
	double	hue;
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

- (id)initWithManager:(SeaPlugins *)manager
{
	seaPlugins = manager;
	[NSBundle loadNibNamed:@"HSV" owner:self];
	
	return self;
}

- (int)type
{
	return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Hue, Saturation and Value" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Color Adjust" table:NULL];
}

- (NSString *)sanity
{
	return @"Seashore Approved (Bobo)";
}

- (void)run
{
	PluginData *pluginData;

	refresh = NO;
	
	hue = saturation = value = 0.0;
	
	[hueLabel setStringValue:[NSString stringWithFormat:@"%.2f", hue]];
	[saturationLabel setStringValue:[NSString stringWithFormat:@"%.2f", saturation]];
	[valueLabel setStringValue:[NSString stringWithFormat:@"%.2f", value]];
	
	[hueSlider setFloatValue:hue];
	[saturationSlider setFloatValue:saturation];
	[valueSlider setFloatValue:value];
	
	success = NO;
	pluginData = [(SeaPlugins *)seaPlugins data];
	[self preview:self];
	if ([pluginData window])
		[NSApp beginSheet:panel modalForWindow:[pluginData window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
	else
		[NSApp runModalForWindow:panel];
	// Nothing to go here
}

- (IBAction)apply:(id)sender
{
	PluginData *pluginData;
	
	pluginData = [(SeaPlugins *)seaPlugins data];
	if (refresh) [self adjust];
	[pluginData apply];
	
	[panel setAlphaValue:1.0];
	
	[NSApp stopModal];
	if ([pluginData window]) [NSApp endSheet:panel];
	[panel orderOut:self];
	success = YES;
}

- (void)reapply
{
	PluginData *pluginData;
	
	pluginData = [(SeaPlugins *)seaPlugins data];
	[self adjust];
	[pluginData apply];
}

- (BOOL)canReapply
{
	return success;
}

- (IBAction)preview:(id)sender
{
	PluginData *pluginData;
	
	pluginData = [(SeaPlugins *)seaPlugins data];
	if (refresh) [self adjust];
	[pluginData preview];
	refresh = NO;
}

- (IBAction)cancel:(id)sender
{
	PluginData *pluginData;
	
	pluginData = [(SeaPlugins *)seaPlugins data];
	[pluginData cancel];
	
	[panel setAlphaValue:1.0];
	
	[NSApp stopModal];
	[NSApp endSheet:panel];
	[panel orderOut:self];
	success = NO;
}

- (IBAction)update:(id)sender
{
	PluginData *pluginData;
	
	pluginData = [(SeaPlugins *)seaPlugins data];
	hue = [hueSlider floatValue];
	saturation = [saturationSlider floatValue];
	value = [valueSlider floatValue];
	
	[hueLabel setStringValue:[NSString stringWithFormat:@"%.2f", hue]];
	[saturationLabel setStringValue:[NSString stringWithFormat:@"%.2f", saturation]];
	[valueLabel setStringValue:[NSString stringWithFormat:@"%.2f", value]];
	
	[panel setAlphaValue:1.0];
	refresh = YES;
	if ([[NSApp currentEvent] type] == NSLeftMouseUp) {
		[self preview:self];
		pluginData = [(SeaPlugins *)seaPlugins data];
		if ([pluginData window]) [panel setAlphaValue:0.4];
	}
}

static inline unsigned char CLAMP(int x) { return (x < 0) ? 0 : ((x > 255) ? 255 : x); }
static inline unsigned char WRAPAROUND(int x) { return (x < 0) ? (255 + ((x + 1) % 255)) : ((x > 255) ? (x % 255) : x); }

- (void)adjust
{
	PluginData *pluginData;
	IntRect selection;
	int spp, i, j, k, width, channel, pos;
	unsigned char *data, *overlay, *replace;
	double power;
	int r, g, b;
	
	pluginData = [(SeaPlugins *)seaPlugins data];
	[pluginData setOverlayOpacity:255];
	[pluginData setOverlayBehaviour:kReplacingBehaviour];
	selection = [pluginData selection];
	channel = [pluginData channel];
	spp = [pluginData spp];
	width = [pluginData width];
	data = [pluginData data];
	overlay = [pluginData overlay];
	replace = [pluginData replace];
	
	for (j = selection.origin.y; j < selection.origin.y + selection.size.height; j++) {
		for (i = selection.origin.x; i < selection.origin.x + selection.size.width; i++) {
		
			pos = (j * width + i) * spp;
			r = data[pos];
			g = data[pos + 1];
			b = data[pos + 2];
			overlay[pos + 3] = data[pos + 3];
			RGBtoHSV(&r, &g, &b);
			r = WRAPAROUND(r + (int)(hue * 255.0));
			g = CLAMP(g + (int)(saturation * 255.0));
			b = CLAMP(b + (int)(value * 255.0));
			HSVtoRGB(&r, &g, &b);
			overlay[pos] = (unsigned char)r;
			overlay[pos + 1] = (unsigned char)g;
			overlay[pos + 2] = (unsigned char)b;
			replace[j * width + i] = 255;

		}
	}
}

- (BOOL)validateMenuItem:(id)menuItem
{
	PluginData *pluginData;
	
	pluginData = [(SeaPlugins *)seaPlugins data];
	
	if (pluginData != NULL) {

		if ([pluginData channel] == kAlphaChannel)
			return NO;
		
		if ([pluginData spp] == 2)
			return NO;
	
	}
	
	return YES;
}

@end
