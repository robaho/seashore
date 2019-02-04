#import "UtilitiesManager.h"
#import "PegasusUtility.h"
#import "ToolboxUtility.h"
#import "StatusUtility.h"
#import "OptionsUtility.h"
#import "InfoUtility.h"
#import "SeaController.h"
#import "TextureUtility.h"

@implementation UtilitiesManager

- (id)init
{
	if(![super init])
		return NULL;
	pegasusUtilities = [[NSMutableDictionary alloc] init];
	toolboxUtilities = [[NSMutableDictionary alloc] init];
	brushUtilities = [[NSMutableDictionary alloc] init];
	optionsUtilities = [[NSMutableDictionary alloc] init];
	textureUtilities = [[NSMutableDictionary alloc] init];
	infoUtilities = [[NSMutableDictionary alloc] init];
	statusUtilities = [[NSMutableDictionary alloc] init];
    recentsUtilities = [[NSMutableDictionary alloc] init];
	return self;
}

- (void)awakeFromNib
{	
	// Make sure we are informed when the application shuts down
	[controller registerForTermination:self];
}

- (void)terminate
{
	// Force such information to be written to the hard disk
	[gUserDefaults synchronize];
}

- (void)shutdownFor:(id)doc
{
	NSNumber *key = [NSNumber numberWithLong:(long)doc];

	[pegasusUtilities removeObjectForKey:key];
	[toolboxUtilities  removeObjectForKey:key];
	
	[[self brushUtilityFor:doc] shutdown];
	[brushUtilities  removeObjectForKey:key];
	
	[[self optionsUtilityFor:doc] shutdown];
	[optionsUtilities  removeObjectForKey:key];
	
	[[self textureUtilityFor:doc] shutdown];
	[textureUtilities  removeObjectForKey:key];
	
	[[self infoUtilityFor:doc] shutdown];
	[infoUtilities  removeObjectForKey:key];
    
    [[self statusUtilityFor:doc] shutdown];
    [statusUtilities  removeObjectForKey:key];

    [[self recentsUtilityFor:doc] shutdown];
    [recentsUtilities  removeObjectForKey:key];
    

}

- (void)activate:(id)sender
{
	[(PegasusUtility *)[self pegasusUtilityFor:sender] activate];
	[(ToolboxUtility *)[self toolboxUtilityFor:sender] activate];
	[(OptionsUtility *)[self optionsUtilityFor:sender] activate];
	[(InfoUtility *)[self infoUtilityFor:sender] activate];
}

- (id)pegasusUtilityFor:(id)doc
{
	return [pegasusUtilities objectForKey:[NSNumber numberWithLong:(long)doc]];
}

- (id)transparentUtility
{
	return transparentUtility;
}

- (ToolboxUtility*)toolboxUtilityFor:(id)doc
{
	return [toolboxUtilities objectForKey: [NSNumber numberWithLong:(long)doc]];
}

- (id)brushUtilityFor:(id)doc
{
	return [brushUtilities objectForKey:[NSNumber numberWithLong:(long)doc]];
}

- (TextureUtility*)textureUtilityFor:(id)doc
{
	return [textureUtilities objectForKey:[NSNumber numberWithLong:(long)doc]];
}

- (OptionsUtility*)optionsUtilityFor:(id)doc
{
	return [optionsUtilities objectForKey: [NSNumber numberWithLong:(long)doc]];
}

- (id)infoUtilityFor:(id)doc
{
	return [infoUtilities objectForKey:[NSNumber numberWithLong:(long)doc]];
}

- (StatusUtility*)statusUtilityFor:(id)doc
{
	return [statusUtilities objectForKey:[NSNumber numberWithLong:(long)doc]];
}

- (id)recentsUtilityFor:(id)doc
{
    return [recentsUtilities objectForKey:[NSNumber numberWithLong:(long)doc]];
}


- (void)setPegasusUtility:(id)util for:(id)doc
{
	[pegasusUtilities setObject:util forKey:[NSNumber numberWithLong:(long)doc]];
}

- (void)setToolboxUtility:(id)util for:(id)doc
{
	[toolboxUtilities setObject:util forKey:[NSNumber numberWithLong:(long)doc]];
}

- (void)setBrushUtility:(id)util for:(id)doc
{
	[brushUtilities setObject:util forKey:[NSNumber numberWithLong:(long)doc]];
}

- (void)setTextureUtility:(id)util for:(id)doc
{
	[textureUtilities setObject:util forKey:[NSNumber numberWithLong:(long)doc]];
}

- (void)setOptionsUtility:(id)util for:(id)doc
{
	[optionsUtilities setObject:util forKey:[NSNumber numberWithLong:(long)doc]];
}

- (void)setInfoUtility:(id)util for:(id)doc
{
	[infoUtilities setObject:util forKey:[NSNumber numberWithLong:(long)doc]];
}

- (void)setStatusUtility:(id)util for:(id)doc
{
	[statusUtilities setObject:util forKey:[NSNumber numberWithLong:(long)doc]];
}

- (void)setRecentsUtility:(id)util for:(id)doc
{
    [recentsUtilities setObject:util forKey:[NSNumber numberWithLong:(long)doc]];
}

@end
