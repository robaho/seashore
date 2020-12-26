#import "SharpenClass.h"
#import "SharpenFuncs.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation SharpenClass

- (id)initWithManager:(PluginData *)data
{
	pluginData = data;
	[NSBundle loadNibNamed:@"Sharpen" owner:self];
	
	return self;
}

- (int)type
{
	return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Sharpen" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Enhance" table:NULL];
}

- (NSString *)sanity
{
	return @"Seashore Approved (Bobo)";
}

- (void)run
{
	if ([gUserDefaults objectForKey:@"Sharpen.extent"])
		extent = [gUserDefaults integerForKey:@"Sharpen.extent"];
	else
		extent = 15;
	refresh = YES;
	
	if (extent < 0 || extent > 99)
		extent = 15;
	
	[extentLabel setStringValue:[NSString stringWithFormat:@"%d", extent]];
	
	[extentSlider setIntValue:extent];
	
	success = NO;
	[self preview:self];
	if ([pluginData window])
		[NSApp beginSheet:panel modalForWindow:[pluginData window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
	else
		[NSApp runModalForWindow:panel];
	// Nothing to go here
}

- (IBAction)apply:(id)sender
{
	if (refresh) [self sharpen];
	[pluginData apply];
	
	[panel setAlphaValue:1.0];
	
	[NSApp stopModal];
	if ([pluginData window]) [NSApp endSheet:panel];
	[panel orderOut:self];
	success = YES;
	
	[gUserDefaults setInteger:extent forKey:@"Sharpen.extent"];
}

- (void)reapply
{
	[pluginData apply];
}

- (BOOL)canReapply
{
	return success;
}

- (IBAction)preview:(id)sender
{
	if (refresh) [self sharpen];
	[pluginData preview];
	refresh = NO;
}

- (IBAction)cancel:(id)sender
{
	[pluginData cancel];
	
	[panel setAlphaValue:1.0];
	
	[NSApp stopModal];
	[NSApp endSheet:panel];
	[panel orderOut:self];
	success = NO;
}

- (IBAction)update:(id)sender
{
	extent = roundf([extentSlider floatValue]);
	
	[extentLabel setStringValue:[NSString stringWithFormat:@"%d", extent]];
	[panel setAlphaValue:1.0];
	refresh = YES;
	if ([[NSApp currentEvent] type] == NSLeftMouseUp) {
		[self preview:self];
		if ([pluginData window]) [panel setAlphaValue:0.4];
	}
}

static inline get_row(unsigned char *out_row, unsigned char *in_row, int spp, int channel, int width)
{
	int i;
	
	if (channel == kAllChannels || channel == kPrimaryChannels) {
		memcpy(out_row, in_row, width * spp);
	}
	else {
		for (i = 0; i < width; i++)
			out_row[i * 2] = in_row[(i + 1) * spp - 1];
	}
}

static inline set_row(unsigned char *out_row, unsigned char *in_row, int spp, int channel, int width)
{
	int i, j;
	
	if (channel == kAllChannels) {
		memcpy(out_row, in_row, width * spp);
	}
	else if (channel == kPrimaryChannels) {
		memcpy(out_row, in_row, width * spp);
		for (i = 0; i < width; i++)
			out_row[i * spp - 1] = 255;
	}
	else {
		for (i = 0; i < width; i++) {
			for (j = 0; j < spp - 1; j++)
				out_row[i * spp + j] = in_row[i * 2];
			out_row[(i + 1) * spp - 1] = 255;
		}
	}
}

- (void)sharpen
{
	IntRect selection;
	unsigned char *src_rows[4], *dst_row;
	unsigned char *data, *overlay, *replace, *workpad;
	unsigned char *src_ptr;
	intneg *neg_rows[4];
	intneg *neg_ptr;
	int swidth, spp, rspp, row, count, i, y, channel;
	void (*filter)(int, guchar *, guchar *, intneg *, intneg *, intneg *);
	int y1, y2, x1, width;
	
	[pluginData setOverlayOpacity:255];
	[pluginData setOverlayBehaviour:kReplacingBehaviour];
	selection = [pluginData selection];
	y1 = selection.origin.y;
	y2 = selection.origin.y + selection.size.height;
	x1 = selection.origin.x;
	channel = [pluginData channel];
	spp = [pluginData spp];
	if (channel == kAlphaChannel) rspp = 2;
	else rspp = spp;
	swidth = selection.size.width * rspp;
	width = [pluginData width];
	data = [pluginData data];
	overlay = [pluginData overlay];
	replace = [pluginData replace];
	
	compute_luts(extent);
	
	for (row = 0; row < 4; row ++) {
		src_rows[row] = malloc(swidth);
		neg_rows[row] = malloc(swidth * sizeof(intneg));
    }
	dst_row = malloc(swidth);

	get_row(src_rows[0], &(data[(y1 * width + x1) * spp]), spp, channel, selection.size.width);
	
	for (i = swidth, src_ptr = src_rows[0], neg_ptr = neg_rows[0]; i > 0; i--, src_ptr++, neg_ptr++)
		*neg_ptr = neg_lut[*src_ptr];

	row = 1;
	count = 1;

	switch (rspp) {
		case 2 :
			filter = graya_filter;
		break;
		case 4 :
			filter = rgba_filter;
		break;
	}
	
	for (y = y1; y < y2; y++) {

		if ((y + 1) < y2) {

			if (count >= 3)
				count--;

			get_row(src_rows[row], &(data[((y + 1) * width + x1) * spp]), spp, channel, selection.size.width);
	
			for (i = swidth, src_ptr = src_rows[row], neg_ptr = neg_rows[row]; i > 0; i--, src_ptr++, neg_ptr++)
				*neg_ptr = neg_lut[*src_ptr];

			count++;
			row = (row + 1) & 3;
			
		}
		else {
			count--;
		}

		if (count == 3) {
			(* filter) (selection.size.width, src_rows[(row + 2) & 3], dst_row,
				neg_rows[(row + 1) & 3] + rspp,
				neg_rows[(row + 2) & 3] + rspp,
				neg_rows[(row + 3) & 3] + rspp);
			set_row(&(overlay[(y * width + x1) * spp]), dst_row, spp, channel, selection.size.width);
		}
		else if (count == 2) {
			if (y == y1)
				set_row(&(overlay[(y * width + x1) * spp]), src_rows[0], spp, channel, selection.size.width);
			else
				set_row(&(overlay[(y * width + x1) * spp]), src_rows[(selection.size.height - 1) & 3], spp, channel, selection.size.width);
		}
		
	}

	for (row = 0; row < 4; row ++) {
		free(src_rows[row]);
		free(neg_rows[row]);
	}
	free(dst_row);
	
	for (i = y1; i < y2; i++)
		memset(&(replace[i * width + x1]), 255, selection.size.width);
}

+ (BOOL)validatePlugin:(PluginData*)pluginData
{
	return YES;
}

@end
