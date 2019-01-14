#import "TextureExporter.h"
#import "SeaController.h"
#import "UtilitiesManager.h"
#import "TextureUtility.h"

enum {
	kExistingCategoryButton,
	kNewCategoryButton
};

@implementation TextureExporter

- (void)awakeFromNib
{
	[self selectButton:kExistingCategoryButton];
}

- (IBAction)exportAsTexture:(id)sender
{
	[NSApp beginSheet:sheet modalForWindow:[document window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)apply:(id)sender
{
	NSArray *groupNames = [[[SeaController utilitiesManager] textureUtilityFor:document] groupNames];

    if ([existingCategoryRadio state] == NSOnState && [categoryTable selectedRow]==-1) {
        return;
    }
	// End the sheet
	[NSApp stopModal];
	[NSApp endSheet:sheet];
	[sheet orderOut:self];
    
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Seashore/textures/"];

	// Determine the path
	if ([existingCategoryRadio state] == NSOnState) {
		path = [path stringByAppendingPathComponent:[groupNames objectAtIndex:[categoryTable selectedRow]]];
	}
	else {
		path = [path stringByAppendingPathComponent:[categoryTextbox stringValue]];
	}
    [gFileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:0 error:NULL];
	path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", [nameTextbox stringValue]]];
	
	// Write document
	[document writeToFile:path ofType:@"Portable Network Graphics Image"];
	
	// Refresh textures
	[[[SeaController utilitiesManager] textureUtilityFor:document] addTextureFromPath:path];
}

- (IBAction)cancel:(id)sender
{
	[NSApp stopModal];
	[NSApp endSheet:sheet];
	[sheet orderOut:self];
}

- (IBAction)existingCategoryClick:(id)sender
{
	[self selectButton:kExistingCategoryButton];
}

- (IBAction)newCategoryClick:(id)sender
{
	[self selectButton:kNewCategoryButton];
}

- (void)selectButton:(int)button
{
	switch (button) {
		case kExistingCategoryButton:
			[existingCategoryRadio setState:NSOnState];
			[newCategoryRadio setState:NSOffState];
			[categoryTable setEnabled:YES];
			[categoryTextbox setEnabled:NO];
		break;
		case kNewCategoryButton:
			[existingCategoryRadio setState:NSOffState];
			[newCategoryRadio setState:NSOnState];
			[categoryTable setEnabled:NO];
			[categoryTextbox setEnabled:YES];
		break;
	}
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(int)row
{
	NSArray *groupNames = [[[SeaController utilitiesManager] textureUtilityFor:document] groupNames];

	return [groupNames objectAtIndex:row];
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	NSArray *groupNames = [[[SeaController utilitiesManager] textureUtilityFor:document] groupNames];

	return [groupNames count];
}

@end
