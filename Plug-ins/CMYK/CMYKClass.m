#import "CMYKClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

@implementation CMYKClass

- (id)initWithManager:(SeaPlugins *)manager
{
	seaPlugins = manager;
	
	return self;
}

- (int)type
{
	return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Convert to CMYK" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Color Effect" table:NULL];
}

- (NSString *)sanity
{
	return @"Seashore Approved (Bobo)";
}

- (void)run
{
	PluginData *pluginData;
	IntRect selection;
	unsigned char *data, *overlay, *replace;
	int pos, i, j, k, width, spp, channel;
	CMBitmap srcBitmap, destBitmap;
	CMProfileRef srcProf, destProf;
	CMDeviceID device;
	CMDeviceProfileID deviceID;
	CMProfileLocation profileLoc;
	CMProfileRef *profile;
	CMWorldRef cw, scw;
	
	pluginData = [(SeaPlugins *)seaPlugins data];
	[pluginData setOverlayOpacity:255];
	[pluginData setOverlayBehaviour:kReplacingBehaviour];
	selection = [pluginData selection];
	spp = [pluginData spp];
	width = [pluginData width];
	data = [pluginData data];
	overlay = [pluginData overlay];
	replace = [pluginData replace];
	
	CMGetDefaultDevice(cmDisplayDeviceClass, &device);
	CMGetDeviceDefaultProfileID(cmDisplayDeviceClass, device, &deviceID);
	CMGetDeviceProfile(cmDisplayDeviceClass, device, deviceID, &profileLoc);
	CMOpenProfile(&srcProf, &profileLoc);
	CMGetDefaultProfileBySpace(cmCMYKData, &destProf);
	NCWNewColorWorld(&cw, srcProf, destProf);
	NCWNewColorWorld(&scw, destProf, srcProf);
	
	for (j = selection.origin.y; j < selection.origin.y + selection.size.height; j++) {

		pos = j * width + selection.origin.x;

		if (channel == kPrimaryChannels) {
			srcBitmap.image = (char *)&(data[pos * 3]);
			srcBitmap.width = selection.size.width;
			srcBitmap.height = 1;
			srcBitmap.rowBytes = selection.size.width * 3;
			srcBitmap.pixelSize = 8 * 3;
			srcBitmap.space = cmRGB24Space;
		}
		else {
			srcBitmap.image = (char *)&(data[pos * 4]);
			srcBitmap.width = selection.size.width;
			srcBitmap.height = 1;
			srcBitmap.rowBytes = selection.size.width * 4;
			srcBitmap.pixelSize = 8 * 4;
			srcBitmap.space = cmRGBA32Space;
		}

		destBitmap.image = (char *)&(overlay[pos * 4]);
		destBitmap.width = selection.size.width;
		destBitmap.height = 1;
		destBitmap.rowBytes = selection.size.width * 4;
		destBitmap.pixelSize = 8 * 4;
		destBitmap.space = cmCMYK32Space;
		
		CWMatchBitmap(cw, &srcBitmap, NULL, 0, &destBitmap);
		
		srcBitmap.image = (char *)&(overlay[pos * 4]);
		srcBitmap.width = selection.size.width;
		srcBitmap.height = 1;
		srcBitmap.rowBytes = selection.size.width * 4;
		srcBitmap.pixelSize = 8 * 4;
		srcBitmap.space = cmCMYK32Space;
		
		destBitmap.image = (char *)&(overlay[pos * 4]);
		destBitmap.width = selection.size.width;
		srcBitmap.height = 1;
		destBitmap.rowBytes = selection.size.width * 4;
		destBitmap.pixelSize = 8 * 4;
		destBitmap.space = cmRGBA32Space;
		
		CWMatchBitmap(scw, &srcBitmap, NULL, 0, &destBitmap);
		
		for (i = selection.size.width; i >= 0; i--) {
			if (channel == kPrimaryChannels)
				overlay[(pos + i) * 4 + 3] = 255;
			else
				overlay[(pos + i) * 4 + 3] = data[(pos + i) * 4 + 3];
			replace[pos + i] = 255;
		}
		
	}
	
	CWDisposeColorWorld(cw);
	CWDisposeColorWorld(scw);
	CMCloseProfile(srcProf);
	
	[pluginData apply];
}

- (void)reapply
{
	[self run];
}

- (BOOL)canReapply
{
	return YES;
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
