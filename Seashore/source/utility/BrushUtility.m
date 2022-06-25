#import "BrushUtility.h"
#import "BrushView.h"
#import "SeaBrush.h"
#import "SeaController.h"
#import "InfoPanel.h"

#ifdef TODO
#warning make brushes shared across all open documents
#endif

@implementation BrushUtility

- (id)init
{		
	// Load the brushes
	[self loadBrushes:NO];
	
	// Determine the currently active brush group
	if ([gUserDefaults objectForKey:@"active brush group"] == NULL)
		activeGroupIndex = 0;
	else
		activeGroupIndex = [gUserDefaults integerForKey:@"active brush group"];
	if (activeGroupIndex < 0 || activeGroupIndex >= [groups count])
		activeGroupIndex = 0;
		
	// Determine the currently active brush 	
	if ([gUserDefaults objectForKey:@"active brush"] == NULL)
		activeBrushIndex = 12;
	else
		activeBrushIndex = [gUserDefaults integerForKey:@"active brush"];
	if (activeBrushIndex < 0 || activeBrushIndex >= [[groups objectAtIndex:activeGroupIndex] count])
		activeBrushIndex = 0;
	
	return self;
}

- (void)awakeFromNib
{
	int yoff, i;

	[super awakeFromNib];
	
	// Configure the view
	[view setHasVerticalScroller:YES];
	[view setDocumentView:[[BrushView alloc] initWithMaster:self]];
	if ([[view documentView] bounds].size.height > 3 * kBrushPreviewSize) {
		yoff = MIN((activeBrushIndex / kBrushesPerRow) * kBrushPreviewSize, ([[self brushes] count] / kBrushesPerRow - 2) * kBrushPreviewSize);
		[[view contentView] scrollToPoint:NSMakePoint(0, yoff)];
	}
	[view reflectScrolledClipView:[view contentView]];
	[view setLineScroll:kBrushPreviewSize];
	
	// Configure the pop-up menu
	[brushGroupPopUp removeAllItems];
	[brushGroupPopUp addItemWithTitle:[groupNames objectAtIndex:0]];
	[[brushGroupPopUp itemAtIndex:0] setTag:0];
	if (customGroups != 0) {
		[[brushGroupPopUp menu] addItem:[NSMenuItem separatorItem]];
		for (i = 1; i < customGroups + 1; i++) {
			[brushGroupPopUp addItemWithTitle:[groupNames objectAtIndex:i]];
			[[brushGroupPopUp itemAtIndex:[[brushGroupPopUp menu] numberOfItems] - 1] setTag:i];
		}
	}
	[[brushGroupPopUp menu] addItem:[NSMenuItem separatorItem]];
	for (i = customGroups + 1; i < [groupNames count]; i++) {
		[brushGroupPopUp addItemWithTitle:[groupNames objectAtIndex:i]];
		[[brushGroupPopUp itemAtIndex:[[brushGroupPopUp menu] numberOfItems] - 1] setTag:i];
	}
	[brushGroupPopUp selectItemAtIndex:[brushGroupPopUp indexOfItemWithTag:activeGroupIndex]];
	
	// Inform the brush that it is active
	[self setActiveBrushIndex:activeBrushIndex];
	
	// Set the window's properties
	[(InfoPanel *)window setPanelStyle:kVerticalPanelStyle];
}

- (void)shutdown
{
	[gUserDefaults setInteger:activeBrushIndex forKey:@"active brush"];
	[gUserDefaults setInteger:activeGroupIndex forKey:@"active brush group"];
}

- (void)update
{
	activeGroupIndex = [[brushGroupPopUp selectedItem] tag];
	if (activeGroupIndex >= [groups count])
		activeGroupIndex = 0;
	if (activeBrushIndex >= [[groups objectAtIndex:activeGroupIndex] count])
		activeBrushIndex = 0;
	[self setActiveBrushIndex:activeBrushIndex];
	[[view documentView] update];
	[view setNeedsDisplay:YES];
}

// Apologies for the bad code in the next method

- (void)loadBrushes:(BOOL)update
{
    brushes = [NSDictionary dictionary];
    [self loadBrushesFromPath:[[gMainBundle resourcePath] stringByAppendingPathComponent:@"/brushes"]];
    [self loadBrushesFromPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Seashore/brushes"]];
    [self createGroups];

}
- (void)loadBrushesFromPath:(NSString*)path
{
    NSArray *files;
    BOOL isDirectory;
    id brush;
    int i;
    
    NSMutableDictionary *temp = [[NSMutableDictionary alloc] init];
    
    // Create a dictionary of all textures
    files = [gFileManager subpathsAtPath:path];
    for (i = 0; i < [files count]; i++) {
        NSString *filepath =[path stringByAppendingPathComponent:files[i]];
        
        [gFileManager fileExistsAtPath:filepath isDirectory:&isDirectory];
        if(isDirectory){
            continue;
        }
        if (![[filepath pathExtension] isEqualToString:@"gbr"]) {
            continue;
        }
        
        brush = [[SeaBrush alloc] initWithContentsOfFile:filepath];
        if (brush) {
            [temp setValue:brush forKey:filepath];
        }
    }
    
    [temp setValuesForKeysWithDictionary:brushes];
    
    brushes = [NSDictionary dictionaryWithDictionary:temp];
}
- (void)createGroups
{
    // Create the all group
    NSArray *array = [[brushes allValues] sortedArrayUsingSelector:@selector(compare:)];
    groups = [NSArray arrayWithObject:array];
    groupNames = [NSArray arrayWithObject:LOCALSTR(@"all group", @"All")];
    
    NSMutableSet *dirs = [[NSMutableSet alloc] init];
    
    for(NSString *filepath in [brushes allKeys]){
        NSArray<NSString *> *comps = [filepath pathComponents];
        // directory is parent component of filename
        NSString *dir = [comps objectAtIndex:([comps count] - 2)];
        [dirs addObject:dir];
    }
    
    NSArray* sorted = [dirs allObjects];
    sorted = [sorted sortedArrayUsingSelector:@selector(compare:)];
    
    for(NSString* dirname in sorted){
        NSArray *groupBrushes = [[NSArray alloc] init];
        for(NSString *filepath in [brushes allKeys]){
            NSArray<NSString *> *comps = [filepath pathComponents];
            // directory is parent component of filename
            NSString *dir = [comps objectAtIndex:([comps count] - 2)];
            if([dirname isEqualToString:dir]){
                groupBrushes = [groupBrushes arrayByAddingObject:[brushes valueForKey:filepath]];
            }
        }
        if([groupBrushes count]>0){
            groupBrushes = [groupBrushes sortedArrayUsingSelector:@selector(compare:)];
            groups = [groups arrayByAddingObject:groupBrushes];
            groupNames = [groupNames arrayByAddingObject:dirname];
        }
    }
}

- (void)addBrushFromPath:(NSString *)path
{
    int i;
    
    SeaBrush *brush = [[SeaBrush alloc] initWithContentsOfFile:path];
    if(!brush){
        return;
    }
    
    NSMutableDictionary *copy = [NSMutableDictionary dictionaryWithDictionary:brushes];
    [copy setValue:brush forKey:path];
    
    brushes = [NSDictionary dictionaryWithDictionary:copy];
    
    [self createGroups];
    
    // Configure the pop-up menu
    [brushGroupPopUp removeAllItems];
    [brushGroupPopUp addItemWithTitle:[groupNames objectAtIndex:0]];
    [[brushGroupPopUp itemAtIndex:0] setTag:0];
    [[brushGroupPopUp menu] addItem:[NSMenuItem separatorItem]];
    for (i = 1; i < [groupNames count]; i++) {
        [brushGroupPopUp addItemWithTitle:[groupNames objectAtIndex:i]];
        [[brushGroupPopUp itemAtIndex:[[brushGroupPopUp menu] numberOfItems] - 1] setTag:i];
    }
    [brushGroupPopUp selectItemAtIndex:[brushGroupPopUp indexOfItemWithTag:activeGroupIndex]];
    
    // Update utility
    [self setActiveBrushIndex:-1];
}

- (IBAction)changeSpacing:(id)sender
{
	[spacingLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"spacing", @"Spacing: %d%%"), [self spacing]]];
}

- (IBAction)changeGroup:(id)sender
{
	[self update];
}

- (int)spacing
{
    int val = [spacingSlider intValue] / 5 * 5;
    return val == 0 ? 1 : val;
}

- (void)setSpacing:(int)spacing
{
    [spacingSlider setIntValue:spacing];
    [self changeSpacing:spacingSlider];
}

- (id)activeBrush
{
	return [[groups objectAtIndex:activeGroupIndex] objectAtIndex:activeBrushIndex];
}

- (int)activeBrushIndex
{
	return activeBrushIndex;
}

- (int)activeGroupIndex
{
    return activeGroupIndex;
}

- (void)setActiveGroupIndex:(int)index
{
    activeBrushIndex=-1;
    activeGroupIndex = index;
    [brushGroupPopUp selectItemAtIndex:[brushGroupPopUp indexOfItemWithTag:activeGroupIndex]];
}

- (void)setActiveBrushIndex:(int)index
{
    activeBrushIndex = index;
    
    if(index!=-1) {
        SeaBrush *newBrush = [[groups objectAtIndex:activeGroupIndex] objectAtIndex:index];
        [brushNameLabel setStringValue:[newBrush name]];
        [self setSpacing:[newBrush spacing]];
    }
    [view setNeedsDisplay:YES];
    [[view documentView] update];
}

- (void)setActiveBrush:(SeaBrush *)brush
{
    for(int group=1;group<[groups count];group++) { // don't search in all {
        NSArray *brushes = [groups objectAtIndex:group];
        for(int index=0;index<[brushes count];index++){
            SeaBrush *sb = [brushes objectAtIndex:index];
            if(sb==brush){
                [self setActiveGroupIndex:group];
                [self setActiveBrushIndex:index];
                [[view documentView] update];
                [view setNeedsDisplay:YES];
                return;
            }
        }
    }
}

- (NSArray *)brushes
{
	return [groups objectAtIndex:activeGroupIndex];
}

- (NSArray *)groupNames
{
    return [groupNames subarrayWithRange:NSMakeRange(1, [groupNames count] - 1)];
}

@end
