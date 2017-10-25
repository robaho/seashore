#import "SeaWarning.h"
#import "SeaController.h"
#import "SeaPrefs.h"
#import "SeaWindowContent.h"
#import "SeaDocument.h"
#import "WarningsUtility.h"

@implementation SeaWarning

- (id)init
{
	self = [super init];
	if(self){
		documentQueues = [[NSMutableDictionary dictionary] retain];
		appQueue = [[NSMutableArray array] retain];
	}
	return self;
}

- (void)dealloc
{
	[documentQueues release];
	[appQueue release];
	[super dealloc];
}

- (void)addMessage:(NSString *)message level:(int)level
{
	[appQueue addObject: [NSDictionary dictionaryWithObjectsAndKeys: message, @"message", [NSNumber numberWithInt:level], @"importance", nil]];
	[self triggerQueue: NULL];
}

- (void)triggerQueue:(id)key
{
	NSMutableArray* queue;
	if(!key){
		queue = appQueue;
	}else{
		queue = [documentQueues objectForKey:[NSNumber numberWithLong:(long)key]];
	}
	// First check to see if we have any messages
	if(queue && [queue count] > 0){
		// This is the app modal queue
		if(!key){
			while([queue count] > 0){
				NSDictionary *thisWarning = [queue objectAtIndex:0];
				if([[thisWarning objectForKey:@"importance"] intValue] <= [[SeaController seaPrefs] warningLevel]){
					NSRunAlertPanel(NULL, [thisWarning objectForKey:@"message"], NULL, NULL, NULL);
				}
				[queue removeObjectAtIndex:0];
			}
		}else {
			// First we need to see if the app has a warning object that
			// is ready to be used (at init it's not all hooked up)
			if([(SeaDocument *)key warnings] && [[key warnings] activeWarningImportance] == -1){
				// Next, pop the object out of the queue and pass to the warnings
				NSDictionary *thisWarning = [queue objectAtIndex:0];
				[[key warnings] setWarning: [thisWarning objectForKey:@"message"] ofImportance: [[thisWarning objectForKey:@"importance"] intValue]];
				 [queue removeObjectAtIndex:0];
			}
		}
	}
}

- (void)addMessage:(NSString *)message forDocument:(id)document level:(int)level
{	
	NSMutableArray* thisDocQueue = [documentQueues objectForKey:[NSNumber numberWithLong:(long)document]];
	if(!thisDocQueue){
		thisDocQueue = [NSMutableArray array];
		[documentQueues setObject: thisDocQueue forKey: [NSNumber numberWithLong:(long)document]];
	}
	[thisDocQueue addObject: [NSDictionary dictionaryWithObjectsAndKeys: message, @"message", [NSNumber numberWithInt: level], @"importance", nil]];
	[self triggerQueue: document];
}

@end
