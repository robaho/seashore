#import "GaussianClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation GaussianClass

- (id)initWithManager:(SeaPlugins *)manager
{
	seaPlugins = manager;
	[NSBundle loadNibNamed:@"Gaussian" owner:self];
	
	return self;
}

- (int)type
{
	return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Gaussian Blur" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Blur" table:NULL];
}

- (NSString *)sanity
{
	return @"Seashore Approved (Bobo)";
}

- (void)run
{
	PluginData *pluginData;
	
	if ([gUserDefaults objectForKey:@"Gaussian.radius"])
		radius = [gUserDefaults integerForKey:@"Gaussian.radius"];
	else
		radius = 1;
	refresh = YES;
	
	if (radius < 0 || radius > 100)
		radius = 1;
	
	[radiusLabel setStringValue:[NSString stringWithFormat:@"%d", radius]];
	
	[radiusSlider setIntValue:radius];
	
	success = NO;
	pluginData = [(SeaPlugins *)seaPlugins data];
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
	if (refresh) [self gauss:BLUR_RLE];
	[pluginData apply];
	
	[panel setAlphaValue:1.0];
	
	[NSApp stopModal];
	if ([pluginData window]) [NSApp endSheet:panel];
	[panel orderOut:self];
	success = YES;
	
	[gUserDefaults setInteger:radius forKey:@"Gaussian.radius"];
}

- (void)reapply
{
	PluginData *pluginData;
	
	pluginData = [(SeaPlugins *)seaPlugins data];
	[self gauss:BLUR_RLE];
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
	if (refresh) [self gauss:BLUR_RLE];
	[pluginData preview];
	if ([pluginData window]) [panel setAlphaValue:0.4];
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
	radius = roundf([radiusSlider floatValue]);
	
	[radiusLabel setStringValue:[NSString stringWithFormat:@"%d", radius]];
	[panel setAlphaValue:1.0];
	refresh = YES;
}

- (void)gauss:(BlurMethod)method
{
	PluginData *pluginData;
	IntRect selection;
	int i, j, k, l, spp, fspp, width, height, fwidth, channel;
	unsigned char *data, *overlay, *replace, *workpad;
	int numerator, denominator, t;
	double vert, horz;
	double n_p[5], n_m[5];
	double d_p[5], d_m[5];
	double bd_p[5], bd_m[5];
	double std_dev;
	int length;
	int *curve;
	int *sum = NULL;
	int total = 1;
	unsigned char *dest, *dp;
	unsigned char *src, *sp, *sp_p, *sp_m;
	int *buf = NULL;
	int *bb;
	double *val_p = NULL;
	double *val_m = NULL;
	double *vp, *vm;
	int x1, y1;
	int row, col, b;
	int terms;
	int initial_p[4];
	int initial_m[4];
	int pixels;
	int start, end;
	int val;
	int initial_pp, initial_mm;

	pluginData = [(SeaPlugins *)seaPlugins data];
	[pluginData setOverlayOpacity:255];
	[pluginData setOverlayBehaviour:kReplacingBehaviour];
	selection = [pluginData selection];
	fspp = spp = [pluginData spp];
	fwidth = [pluginData width];
	data = [pluginData data];
	overlay = [pluginData overlay];
	replace = [pluginData replace];
	channel = [pluginData channel];
	
	x1 = selection.origin.x;
	y1 = selection.origin.y;

	switch (channel) {
		case kPrimaryChannels:
			spp = 3;
		break;
		case kAlphaChannel:
			spp = 1;
		break;
	}
	
	width  = selection.size.width;
	height = selection.size.height;
	vert = (double)radius;
	horz = (double)radius;

	switch (method) {
		case BLUR_IIR:
			val_p = malloc(MAX(width, height) * spp * sizeof(double));
			val_m = malloc(MAX(width, height) * spp * sizeof(double));
		break;
		case BLUR_RLE:
			buf = malloc(MAX (width, height) * 2 * sizeof(int));
		break;
	}

	src = malloc(MAX (width, height) * spp);
	dest = malloc(MAX (width, height) * spp);
						   
	// First the vertical pass
	if (vert > 0.0) {
		vert = fabs(vert) + 1.0;
		std_dev = sqrt(-(vert * vert) / (2 * log(1.0 / 255.0)));

		switch (method) {
			case BLUR_IIR:
				find_constants (n_p, n_m, d_p, d_m, bd_p, bd_m, std_dev);
			break;
			case BLUR_RLE:
				curve = make_curve (std_dev, &length);
				sum = malloc((2 * length + 1) * sizeof(int));

				sum[0] = 0;

				for (i = 1; i <= length*2; i++)
					sum[i] = curve[i-length-1] + sum[i-1];
				sum += length;

				total = sum[length] - sum[-length];
			break;
        }

		for (col = 0; col < width; col++) {
		
			switch (method) {
				case BLUR_IIR:
					memset (val_p, 0, height * spp * sizeof (double));
					memset (val_m, 0, height * spp * sizeof (double));
				break;
				case BLUR_RLE:
				break;
			}

			switch (channel) {
				case kAllChannels:
					for (k = 0; k < height; k++) {
						memcpy(&(src[k * spp]), &(data[((y1 + k) * fwidth + x1 + col) * spp]), spp);
					}
				break;
				case kPrimaryChannels:
					for (k = 0; k < height; k++) {
						memcpy(&(src[k * spp]), &(data[((y1 + k) * fwidth + x1 + col) * fspp]), spp);
					}
				break;
				case kAlphaChannel:
					for (k = 0; k < height; k++) {
						src[k * spp] = data[((y1 + k) * fwidth + x1 + col + 1) * fspp - 1];
					}
				break;
			}

			switch (method) {
				case BLUR_IIR:
					sp_p = src;
					sp_m = src + (height - 1) * spp;
					vp = val_p;
					vm = val_m + (height - 1) * spp;

					/*  Set up the first vals  */
					for (i = 0; i < spp; i++) {
						initial_p[i] = sp_p[i];
						initial_m[i] = sp_m[i];
					}

					for (row = 0; row < height; row++) {
						double *vpptr, *vmptr;
						terms = (row < 4) ? row : 4;

						for (b = 0; b < spp; b++) {
							vpptr = vp + b; vmptr = vm + b;
							for (i = 0; i <= terms; i++) {
								*vpptr += n_p[i] * sp_p[(-i * spp) + b] -
								d_p[i] * vp[(-i * spp) + b];
								*vmptr += n_m[i] * sp_m[(i * spp) + b] -
								d_m[i] * vm[(i * spp) + b];
							}
							for (j = i; j <= 4; j++) {
								*vpptr += (n_p[j] - bd_p[j]) * initial_p[b];
								*vmptr += (n_m[j] - bd_m[j]) * initial_m[b];
							}
						}

						sp_p += spp;
						sp_m -= spp;
						vp += spp;
						vm -= spp;
					}

					transfer_pixels (val_p, val_m, dest, spp, height);
				break;

				case BLUR_RLE:
					sp = src;
					dp = dest;

					for (b = 0; b < spp; b++) {
						initial_pp = sp[b];
						initial_mm = sp[(height-1) * spp + b];

						/*  Determine a run-length encoded version of the row  */
						run_length_encode (sp + b, buf, spp, height);

						for (row = 0; row < height; row++) {
							start = (row < length) ? -row : -length;
							end = (height <= (row + length) ?
							(height - row - 1) : length);

							val = 0;
							i = start;
							bb = buf + (row + i) * 2;

							if (start != -length)
								val += initial_pp * (sum[start] - sum[-length]);

							while (i < end) {
								pixels = bb[0];
								i += pixels;
								if (i > end)
								i = end;
								val += bb[1] * (sum[i] - sum[start]);
								bb += (pixels * 2);
								start = i;
							}

							if (end != length)
								val += initial_mm * (sum[length] - sum[end]);

							dp[row * spp + b] = val / total;
						}
					}
				break;
            }
		
			switch (channel) {
				case kAllChannels:
					for (k = 0; k < height; k++) {
						memcpy(&(overlay[((y1 + k) * fwidth + x1 + col) * fspp]), &(dest[k * spp]), spp);
					}
				break;
				case kPrimaryChannels:
					for (k = 0; k < height; k++) {
						memcpy(&(overlay[((y1 + k) * fwidth + x1 + col) * fspp]), &(dest[k * spp]), spp);
						overlay[((y1 + k) * fwidth + x1 + col + 1) * fspp - 1] = 255;
					}
				break;
				case kAlphaChannel:
					for (k = 0; k < height; k++) {
						for (l = 0; l < spp; l++)
							overlay[((y1 + k) * fwidth + x1 + col) * fspp + l] = dest[k * spp];
						overlay[((y1 + k) * fwidth + x1 + col + 1) * fspp - 1] = 255;
					}
				break;
			}

        }
		
	}

	/*  Now the horizontal pass  */
	if (horz > 0.0) {
		horz = fabs (horz) + 1.0;

		if (horz != vert) {
			std_dev = sqrt (-(horz * horz) / (2 * log (1.0 / 255.0)));

			switch (method) {
				case BLUR_IIR:
					/*  derive the constants for calculating the gaussian
					*  from the std dev
					*/
					find_constants (n_p, n_m, d_p, d_m, bd_p, bd_m, std_dev);
				break;

				case BLUR_RLE:
					curve = make_curve (std_dev, &length);
					sum = malloc ((2 * length + 1) * sizeof(int));

					sum[0] = 0;

					for (i = 1; i <= length*2; i++)
					sum[i] = curve[i-length-1] + sum[i-1];
					sum += length;

					total = sum[length] - sum[-length];
				break;
			}
		}

		for (row = 0; row < height; row++) {
			  
			switch (method) {
				case BLUR_IIR:
					memset (val_p, 0, width * spp * sizeof (double));
					memset (val_m, 0, width * spp * sizeof (double));
				break;

				case BLUR_RLE:
				break;
			}

			switch (channel) {
				case kAllChannels:
					for (k = 0; k < width; k++) {
						memcpy(&(src[k * spp]), &(overlay[((y1 + row) * fwidth + x1 + k) * spp]), spp);
					}
				break;
				case kPrimaryChannels:
					for (k = 0; k < width; k++) {
						memcpy(&(src[k * spp]), &(overlay[((y1 + row) * fwidth + x1 + k) * fspp]), spp);
					}
				break;
				case kAlphaChannel:
					for (k = 0; k < width; k++) {
						src[k * spp] = overlay[((y1 + row) * fwidth + x1 + k) * fspp];
					}
				break;
			}

			switch (method) {
				case BLUR_IIR:
					sp_p = src;
					sp_m = src + (width - 1) * spp;
					vp = val_p;
					vm = val_m + (width - 1) * spp;

					/*  Set up the first vals  */
					for (i = 0; i < spp; i++) {
						initial_p[i] = sp_p[i];
						initial_m[i] = sp_m[i];
					}

					for (col = 0; col < width; col++) {
						double *vpptr, *vmptr;
						terms = (col < 4) ? col : 4;

						for (b = 0; b < spp; b++) {
							vpptr = vp + b; vmptr = vm + b;
							for (i = 0; i <= terms; i++) {
								*vpptr += n_p[i] * sp_p[(-i * spp) + b] -
								d_p[i] * vp[(-i * spp) + b];
								*vmptr += n_m[i] * sp_m[(i * spp) + b] -
								d_m[i] * vm[(i * spp) + b];
							}
							for (j = i; j <= 4; j++) {
								*vpptr += (n_p[j] - bd_p[j]) * initial_p[b];
								*vmptr += (n_m[j] - bd_m[j]) * initial_m[b];
							}
						}

						sp_p += spp;
						sp_m -= spp;
						vp += spp;
						vm -= spp;
					}

					transfer_pixels (val_p, val_m, dest, spp, width);
				break;

				case BLUR_RLE:
					sp = src;
					dp = dest;

					for (b = 0; b < spp; b++) {
						initial_pp = sp[b];
						initial_mm = sp[(width-1) * spp + b];

						/*  Determine a run-length encoded version of the row  */
						run_length_encode (sp + b, buf, spp, width);

						for (col = 0; col < width; col++) {
							start = (col < length) ? -col : -length;
							end = (width <= (col + length)) ? (width - col - 1) : length;

							val = 0;
							i = start;
							bb = buf + (col + i) * 2;

							if (start != -length)
							val += initial_pp * (sum[start] - sum[-length]);

							while (i < end)
							{
								pixels = bb[0];
								i += pixels;
								if (i > end)
									i = end;
								val += bb[1] * (sum[i] - sum[start]);
								bb += (pixels * 2);
								start = i;
							}

							if (end != length)
								val += initial_mm * (sum[length] - sum[end]);

							dp[col * spp + b] = val / total;
						}
					}
				break;
			}

			switch (channel) {
				case kAllChannels:
					for (k = 0; k < width; k++) {
						memcpy(&(overlay[((y1 + row) * fwidth + x1 + k) * spp]), &(dest[k * spp]), spp);
						replace[(y1 + row) * fwidth + x1 + k] = 255;
					}
				break;
				case kPrimaryChannels:
					for (k = 0; k < width; k++) {
						memcpy(&(overlay[((y1 + row) * fwidth + x1 + k) * fspp]), &(dest[k * spp]), spp);
						replace[(y1 + row) * fwidth + x1 + k] = 255;
					}
				break;
				case kAlphaChannel:
					for (k = 0; k < width; k++) {
						for (l = 0; l < spp; l++)
							overlay[((y1 + row) * fwidth + x1 + k) * fspp + l] = dest[k * spp];
						overlay[((y1 + row) * fwidth + x1 + k + 1) * fspp - 1] = 255;
						replace[(y1 + row) * fwidth + x1 + k] = 255;
					}
				break;
			}

		}
	}

	/*  free up buffers  */
	switch (method) {
		case BLUR_IIR:
			free(val_p);
			free(val_m);
		break;
		case BLUR_RLE:
			free(buf);
		break;
	}

	free(src);
	free(dest);
}

- (BOOL)validateMenuItem:(id)menuItem
{
	return YES;
}

@end
