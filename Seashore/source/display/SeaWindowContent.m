#import "SeaWindowContent.h"


@implementation SeaWindowContent

-(void)awakeFromNib
{
	dict = [[NSDictionary dictionaryWithObjectsAndKeys:
			 [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], @"visibility", optionsBar, @"view", nonOptionsBar, @"nonView", @"above", @"side", [NSNumber numberWithFloat: 0], @"oldValue", nil], [NSNumber numberWithInt:kOptionsBar],
			 [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], @"visibility", sidebar, @"view", nonSidebar, @"nonView", @"left", @"side", [NSNumber numberWithFloat: 0], @"oldValue", nil], [NSNumber numberWithInt:kSidebar],
			 [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], @"visibility", pointInformation, @"view", layers, @"nonView", @"below", @"side", [NSNumber numberWithFloat: 0], @"oldValue", nil], [NSNumber numberWithInt:kPointInformation],
			 [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], @"visibility", warningsBar, @"view", mainDocumentView, @"nonView", @"above", @"side", [NSNumber numberWithFloat: 0], @"oldValue", nil], [NSNumber numberWithInt:kWarningsBar],
			 [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], @"visibility", statusBar, @"view", mainDocumentView, @"nonView", @"below", @"side", [NSNumber numberWithFloat: 0], @"oldValue", nil], [NSNumber numberWithInt:kStatusBar],
			 nil] retain];
	
	int i;
	for(i = kOptionsBar; i <= kStatusBar; i++){
		NSString *key = [NSString stringWithFormat:@"region%dvisibility", i];
		if([gUserDefaults objectForKey: key] && ![gUserDefaults boolForKey:key]){
			// We need to hide it
			[self setVisibility: NO forRegion: i];
		}
	}
	
	// by default, the warning bar should be hidden. we will only show it iff we need it
	[self setVisibility:NO forRegion:kWarningsBar];
}

-(BOOL)visibilityForRegion:(int)region
{
	return [[[dict objectForKey:[NSNumber numberWithInt:region]] objectForKey:@"visibility"] boolValue];
}

-(void)setVisibility:(BOOL)visibility forRegion:(int)region
{
	NSMutableDictionary *thisDict = [dict objectForKey:[NSNumber numberWithInt:region]];
	BOOL currentVisibility = [[thisDict objectForKey:@"visibility"] boolValue];
	
	// Check to see if we are already in the proper state
	if(currentVisibility == visibility){
		return;
	}
	
	float oldValue = [[thisDict objectForKey:@"oldValue"] floatValue];
	NSView *view = [thisDict objectForKey:@"view"];
	NSView *nonView = [thisDict objectForKey:@"nonView"];
	NSString *side = [thisDict objectForKey:@"side"];
	if(!visibility){
		
		if([side isEqual:@"above"] || [side isEqual:@"below"]){
			oldValue = [view frame].size.height;
		}else {
			oldValue = [view frame].size.width;
		}

		NSRect oldRect = [view frame];
		
		
		if([side isEqual:@"above"] || [side isEqual:@"below"]){
			oldRect.size.height = 0;
		}else {
			oldRect.size.width = 0;
		}
		
		[view setFrame:oldRect];
		
		oldRect = [nonView frame];
		
		if([side isEqual:@"above"]){
			oldRect.size.height += oldValue;
		}else if([side isEqual:@"below"]){
			oldRect.origin.y = [view frame].origin.y;
			oldRect.size.height += oldValue;
		}else if([side isEqual:@"left"]){
			oldRect.origin.x = [view frame].origin.x;
			oldRect.size.width += oldValue;
		}else if([side isEqual:@"right"]){
			oldRect.size.width += oldValue;
		}
		
		[nonView setFrame:oldRect];
				
		[nonView setNeedsDisplay:YES];
		
		[thisDict setObject:[NSNumber numberWithFloat:oldValue] forKey:@"oldValue"];
		[gUserDefaults setObject: @"NO" forKey:[NSString stringWithFormat:@"region%dvisibility", region]];		
	}else{
		NSRect newRect = [view frame];
		if([side isEqual:@"above"] || [side isEqual:@"below"]){
			newRect.size.height = oldValue;
		}else{
			newRect.size.width = oldValue;
		}
		
		[view setFrame:newRect];
		
		newRect = [nonView frame];

		if([side isEqual:@"above"]){
			newRect.size.height -= oldValue;
		}else if([side isEqual:@"below"]){
			newRect.origin.y += oldValue;
			newRect.size.height -= oldValue;
		}else if([side isEqual:@"left"]){
			newRect.origin.x += oldValue;
			newRect.size.width -= oldValue;
		}else if([side isEqual:@"right"]){
			newRect.size.width -= oldValue;
		}
		
		[nonView setFrame:newRect];
				
		[nonView setNeedsDisplay:YES];
		
		[gUserDefaults setObject: @"YES" forKey:[NSString stringWithFormat:@"region%dvisibility", region]];
	}
	[thisDict setObject:[NSNumber numberWithBool:visibility] forKey:@"visibility"];
}

-(float)sizeForRegion:(int)region
{
	if([self visibilityForRegion:region]){
		NSMutableDictionary *thisDict = [dict objectForKey:[NSNumber numberWithInt:region]];
		NSString *side = [thisDict objectForKey:@"side"];
		NSView *view = [thisDict objectForKey: @"view"];
		if([side isEqual: @"above"] || [side isEqual: @"below"]){
			return [view frame].size.height;
		}else{
			return [view frame].size.width;
		}
	}
	return 0.0;
}

@end
