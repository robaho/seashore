#import "SeaContent.h"
#import "SeaLayer.h"
#import "SeaWhiteboard.h"
#import "Bitmap.h"
#import "SeaCompositor.h"

@implementation SeaContent

- (id)init
{
	// Set the data members to reasonable values
	xres = yres = 72;
	height = width = type = 0;
	lostprops = NULL; lostprops_len = 0;
	parasites = NULL; parasites_count = 0;
	exifData = NULL;
	layers = NULL; activeLayerIndex = 0;
	layersToUndo = [[NSMutableArray array] retain];
	layersToRedo = [[NSMutableArray array] retain];
	orderings = [[NSMutableArray array] retain];
	deletedLayers = [[NSArray alloc] init];
	selectedChannel = kAllChannels; trueView = NO;
	cmykSave = NO;
	gScreenResolution = IntMakePoint(1024, 768);

	return self;
}

- (void)dealloc
{
	int i;
	
	if (parasites) {
		for (i = 0; i < parasites_count; i++) {
			[parasites[i].name autorelease];
			free(parasites[i].data);
		}
		free(parasites);
	}
	if (exifData) [exifData autorelease];
	if (lostprops) free(lostprops);
	if (layers) {
		for (i = 0; i < [layers count]; i++) {
			[[layers objectAtIndex:i] autorelease];
		}
		[layers autorelease];
	}
	if (layersToUndo) {
		for (i = 0; i < [layersToUndo count]; i++) {
			[[layersToUndo objectAtIndex:i] autorelease];
		}
		[layersToUndo autorelease];
	}
	if (layersToRedo) {
		for (i = 0; i < [layersToRedo count]; i++) {
			[[layersToRedo objectAtIndex:i] autorelease];
		}
		[layersToRedo autorelease];
	}
	if (deletedLayers) {
		for (i = 0; i < [deletedLayers count]; i++) {
			[[deletedLayers objectAtIndex:i] autorelease];
		}
		[deletedLayers autorelease];
	}
	if(orderings){
		for (i = 0; i < [orderings count]; i++) {
			[[orderings objectAtIndex:i] autorelease];
		}
		[orderings autorelease];
	}
	[super dealloc];
}

- (int)type
{
	return type;
}

- (int)spp
{
	int result = 0;
	
	switch (type) {
		case XCF_RGB_IMAGE:
			result = 4;
		break;
		case XCF_GRAY_IMAGE:
			result = 2;
		break;
		default:
			NSLog(@"Document type not recognised by spp");
		break;
	}
	
	return result;
}

- (int)xres
{
	return xres;
}

- (int)yres
{
	return yres;
}

- (float)xscale
{
	float xscale = 1.0;
	
	if (gScreenResolution.x != 0 && xres != gScreenResolution.x)
		xscale /= ((float)xres / (float)gScreenResolution.x);
	
	return xscale;
}

- (float)yscale
{
	float yscale = 1.0;
	
	if (gScreenResolution.y != 0 && yres != gScreenResolution.y)
		yscale /= ((float)yres / (float)gScreenResolution.y);
	
	return yscale;
}

- (int)height
{
	return height;
}

- (int)width
{
	return width;
}

- (int)selectedChannel
{
	return selectedChannel;
}

- (char *)lostprops
{
	return lostprops;
}

- (int)lostprops_len
{
	return lostprops_len;
}

- (ParasiteData *)parasites
{
	return parasites;
}

- (int)parasites_count
{
	return parasites_count;
}

- (ParasiteData *)parasiteWithName:(NSString *)name
{
	int i;
	
	for (i = 0; i < parasites_count; i++) {
		if ([name isEqualToString:parasites[i].name])
			return &(parasites[i]);
	}
	
	return NULL;
}

- (void)deleteParasiteWithName:(NSString *)name
{
	int i, x;
	
	// Find the parasite to delete
	x = -1;
	for (i = 0; i < parasites_count && x == -1; i++) {
		if ([name isEqualToString:parasites[i].name])
			x = i;
	}
	
	if (x != -1) {
		
		// Destroy it
		[parasites[x].name autorelease];
		free(parasites[x].data);
	
		// Update the parasites list
		parasites_count--;
		if (parasites_count > 0) {
			for (i = x; i < parasites_count; i++) {
				parasites[i] = parasites[i + 1];
			}
			parasites = realloc(parasites, sizeof(ParasiteData) * parasites_count);
		}
		else {
			free(parasites);
			parasites = NULL;
		}
	
	}
}

- (void)addParasite:(ParasiteData)parasite
{
	// Delete existing parasite with the same name (if any)
	[self deleteParasiteWithName:parasite.name];
	
	// Add parasite
	parasites_count++;
	if (parasites_count == 1) parasites = malloc(sizeof(ParasiteData) * parasites_count);
	else parasites = realloc(parasites, sizeof(ParasiteData) * parasites_count);
	parasites[parasites_count - 1] = parasite;
}

- (BOOL)trueView
{
	return trueView;
}

- (void)setTrueView:(BOOL)value
{
	trueView = value;
}

- (void)setCMYKSave:(BOOL)value
{
	cmykSave = value;
}

- (BOOL)cmykSave
{
	return cmykSave;
}

- (NSDictionary *)exifData
{
	return exifData;
}

- (id)layer:(int)index
{
	return [layers objectAtIndex:index];
}

- (int)layerCount
{
	return [layers count];
}

- (id)activeLayer
{
	return (activeLayerIndex < 0) ? NULL : [layers objectAtIndex:activeLayerIndex];
}

- (int)activeLayerIndex
{
	return activeLayerIndex;
}

- (unsigned char *)bitmapUnderneath:(IntRect)rect forWhiteboard:(SeaWhiteboard *)whiteboard
{
	CompositorOptions options;
	unsigned char *data;
	SeaLayer *layer;
	int i, spp = [self spp];
	
	// Create the replacement flat layer
	data = malloc(make_128(rect.size.width * rect.size.height * spp));
	memset(data, 0, rect.size.width * rect.size.height * spp);

	// Set the composting options
	options.forceNormal = 0;
	options.rect = rect;
	options.destRect = rect;
	options.insertOverlay = NO;
	options.useSelection = NO;
	options.overlayOpacity = 255;
	options.overlayBehaviour = kNormalBehaviour;
	options.spp = spp;

	// Composite the layers underneath
	for (i = [layers count] - 1; i >= activeLayerIndex; i--) {
		layer = [layers objectAtIndex:i];
		if ([layer visible]) {
			[[whiteboard compositor] compositeLayer:layer withOptions:options andData:data];
		}
	}
	
	return data;
}


@end
