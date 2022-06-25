#import "TextureUtility.h"
#import "TextureView.h"
#import "SeaTexture.h"
#import "SeaController.h"
#import "ToolboxUtility.h"
#import "SeaPrefs.h"
#import "SeaProxy.h"
#import "InfoPanel.h"
#import "TextTool.h"
#import "SeaDocument.h"
#import "SeaTools.h"

#ifdef TODO
#warning Make textures shared across all open documents
#endif

@implementation TextureUtility

- (id)init
{		
	// Load the textures
	[self loadTextures:NO];
	
	// Determine the currently active texture group
	if ([gUserDefaults objectForKey:@"active texture group"] == NULL)
		activeGroupIndex = 0;
	else
		activeGroupIndex = [gUserDefaults integerForKey:@"active texture group"];
	if (activeGroupIndex < 0 || activeGroupIndex >= [groups count])
		activeGroupIndex = 0;
		
	// Determine the currently active texture 	
	if ([gUserDefaults objectForKey:@"active texture"] == NULL)
		activeTextureIndex = 0;
	else
		activeTextureIndex = [gUserDefaults integerForKey:@"active texture"];
	if (activeTextureIndex < 0 || activeTextureIndex >= [[groups objectAtIndex:activeGroupIndex] count])
		activeTextureIndex = 0;
		
	// Set the opacity
	[opacitySlider setIntValue:100];
	[opacityLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"opacity", @"Opacity: %d%%"), [opacitySlider intValue]]];
	opacity = 255;
	
	return self;
}

- (void)awakeFromNib
{
	int yoff, i;
	
	[super awakeFromNib];

	// Configure the view
	[view setHasVerticalScroller:YES];
	[view setDocumentView:[[TextureView alloc] initWithMaster:self]];
	if ([[view documentView] bounds].size.height > 3 * kTexturePreviewSize) {
		yoff = MIN((activeTextureIndex / kTexturesPerRow) * kTexturePreviewSize, ([[self textures] count] / kTexturesPerRow - 2) * kTexturePreviewSize);
		[[view contentView] scrollToPoint:NSMakePoint(0, yoff)];
	}
	[view reflectScrolledClipView:[view contentView]];
	[view setLineScroll:kTexturePreviewSize];
	
	// Configure the pop-up menu
	[textureGroupPopUp removeAllItems];
	[textureGroupPopUp addItemWithTitle:[groupNames objectAtIndex:0]];
	[[textureGroupPopUp itemAtIndex:0] setTag:0];
	[[textureGroupPopUp menu] addItem:[NSMenuItem separatorItem]];
	for (i = 1; i < [groupNames count]; i++) {
		[textureGroupPopUp addItemWithTitle:[groupNames objectAtIndex:i]];
		[[textureGroupPopUp itemAtIndex:[[textureGroupPopUp menu] numberOfItems] - 1] setTag:i];
	}
	[textureGroupPopUp selectItemAtIndex:[textureGroupPopUp indexOfItemWithTag:activeGroupIndex]];
	
	// Inform the texture that it is active
	[self setActiveTextureIndex:-1];
}

- (void)shutdown
{
	[gUserDefaults setInteger:activeTextureIndex forKey:@"active texture"];
	[gUserDefaults setInteger:activeGroupIndex forKey:@"active texture group"];
}

- (void)update
{
	activeGroupIndex = [[textureGroupPopUp selectedItem] tag];
	if (activeGroupIndex >= [groups count])
		activeGroupIndex = 0;
	if (activeTextureIndex >= [[groups objectAtIndex:activeGroupIndex] count])
		activeTextureIndex = 0;
	[self setActiveTextureIndex:activeTextureIndex];
}

- (void)loadTextures:(BOOL)update
{
	// Create a dictionary of all textures
	textures = [NSDictionary dictionary];
    [self loadTexturesFromPath:[[gMainBundle resourcePath] stringByAppendingPathComponent:@"/textures"]];
    [self loadTexturesFromPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Seashore/textures"]];
    [self createGroups];
	
	// Update utility if requested
	if (update) [self update];
}

- (void)loadTexturesFromPath:(NSString*)path
{
    NSArray *files;
    BOOL isDirectory;
    id texture;
    int i;
    
    NSMutableDictionary *temp = [[NSMutableDictionary alloc] init];
                               
    // Create a dictionary of all textures
    files = [gFileManager subpathsAtPath:path];
    for (i = 0; i < [files count]; i++) {
        NSString *filepath =[path stringByAppendingPathComponent:files[i]];
        
        [gFileManager fileExistsAtPath:filepath isDirectory:&isDirectory];
        if(isDirectory || ![[filepath pathExtension] isEqualToString:@"png"]){
            continue;
        }

        texture = [[SeaTexture alloc] initWithContentsOfFile:filepath];
        if (texture) {
            [temp setValue:texture forKey:filepath];
        }
    }
    
    [temp setValuesForKeysWithDictionary:textures];
    
    textures = [NSDictionary dictionaryWithDictionary:temp];
    
}

- (void)createGroups
{
    // Create the all group
    NSArray *array = [[textures allValues] sortedArrayUsingSelector:@selector(compare:)];
    groups = [NSArray arrayWithObject:array];
    groupNames = [NSArray arrayWithObject:LOCALSTR(@"all group", @"All")];
    
    NSMutableSet *dirs = [[NSMutableSet alloc] init];
    
    for(NSString *filepath in [textures allKeys]){
        NSArray<NSString *> *comps = [filepath pathComponents];
        // directory is parent component of filename
        NSString *dir = [comps objectAtIndex:([comps count] - 2)];
        [dirs addObject:dir];
    }
    
    NSArray* sorted = [dirs allObjects];
    sorted = [sorted sortedArrayUsingSelector:@selector(compare:)];
    
    for(NSString* dirname in sorted){
        NSArray *groupTextures = [[NSArray alloc] init];
        for(NSString *filepath in [textures allKeys]){
            NSArray<NSString *> *comps = [filepath pathComponents];
            // directory is parent component of filename
            NSString *dir = [comps objectAtIndex:([comps count] - 2)];
            if([dirname isEqualToString:dir]){
                groupTextures = [groupTextures arrayByAddingObject:[textures valueForKey:filepath]];
            }
        }
        if([groupTextures count]>0){
            groupTextures = [groupTextures sortedArrayUsingSelector:@selector(compare:)];
            groups = [groups arrayByAddingObject:groupTextures];
            groupNames = [groupNames arrayByAddingObject:dirname];
        }
    }

}


- (void)addTextureFromPath:(NSString *)path
{
	int i;
    
    SeaTexture *texture = [[SeaTexture alloc] initWithContentsOfFile:path];
    if(!texture){
        return;
    }
    
    NSMutableDictionary *copy = [NSMutableDictionary dictionaryWithDictionary:textures];
    [copy setValue:texture forKey:path];
    
    textures = [NSDictionary dictionaryWithDictionary:copy];
    
    [self createGroups];

	// Configure the pop-up menu
	[textureGroupPopUp removeAllItems];
	[textureGroupPopUp addItemWithTitle:[groupNames objectAtIndex:0]];
	[[textureGroupPopUp itemAtIndex:0] setTag:0];
	[[textureGroupPopUp menu] addItem:[NSMenuItem separatorItem]];
	for (i = 1; i < [groupNames count]; i++) {
		[textureGroupPopUp addItemWithTitle:[groupNames objectAtIndex:i]];
		[[textureGroupPopUp itemAtIndex:[[textureGroupPopUp menu] numberOfItems] - 1] setTag:i];
	}
	[textureGroupPopUp selectItemAtIndex:[textureGroupPopUp indexOfItemWithTag:activeGroupIndex]];
	
	// Update utility
	[self setActiveTextureIndex:-1];
}

- (IBAction)changeGroup:(id)sender
{
	[self update];
}

- (IBAction)changeOpacity:(id)sender
{
	[opacityLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"opacity", @"Opacity: %d%%"), [opacitySlider intValue]]];
	opacity = (int)([opacitySlider intValue] * 2.55 +.5);
}

- (int)opacity
{
	return opacity;
}

- (float)opacity_float
{
    return opacity/255.0;
}
- (void)setOpacity:(int)value
{
    if(value<0 || value>255)
        return;
    [opacitySlider setIntValue:(int)((value/255.0)*100 +0.5)];
    [self changeOpacity:opacitySlider];
}

- (id)activeTexture
{
    if(activeTextureIndex==-1)
        return NULL;
	return [[groups objectAtIndex:activeGroupIndex] objectAtIndex:activeTextureIndex];
}

- (int)activeTextureIndex
{
    return activeTextureIndex;
}

- (void)setActiveTexture:(SeaTexture*)texture
{
    if(texture==NULL){
        [self setActiveTextureIndex:-1];
    } else {
        for(int group=1;group<[groups count];group++){ // don't check all group
            NSArray *textures = [groups objectAtIndex:group];
            for(int index=0;index<[textures count];index++){
                if([textures objectAtIndex:index]==texture){
                    [self setActiveTextureIndex:index];
                    return;
                }
            }
        }
    }
}

- (void)setActiveTextureIndex:(int)index
{
	if (index == -1) {
        activeTextureIndex=-1;
		[textureNameLabel setStringValue:@""];
		[opacitySlider setEnabled:NO];
	}
	else {
		id newTexture = [[groups objectAtIndex:activeGroupIndex] objectAtIndex:index];
		activeTextureIndex = index;
		[textureNameLabel setStringValue:[newTexture name]];
		[opacitySlider setEnabled:YES];
	}

    [view setNeedsDisplay:YES];
    [colorSelectView setNeedsDisplay:YES];
    [[document docView] setNeedsDisplay:YES];
}

- (NSArray *)textures
{
	return [groups objectAtIndex:activeGroupIndex];
}

- (NSArray *)groupNames
{
	return [groupNames subarrayWithRange:NSMakeRange(1, [groupNames count] - 1)];
}

@end
