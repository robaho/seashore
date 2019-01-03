//
//  SeaColorProfiles.m
//  Seashore
//
//  Created by robert engels on 1/2/19.
//

#import <Foundation/Foundation.h>
#import "SeaColorProfiles.h"
#import "SeaDocument.h"
#import "SeaHelpers.h"

@implementation SeaColorProfile
@end
@implementation SeaColorMenuItem
@end

@implementation SeaColorProfiles

// Callback routine with a description of a profile that is
// called during an iteration through the available profiles.
//
static bool profileIterate (CFDictionaryRef profileInfo, void *refCon)
{
    NSDictionary *dict = (__bridge NSDictionary*)profileInfo;
    
//    NSLog(@"%@",dict);
    
    NSMutableArray* array = (__bridge NSMutableArray*) refCon;
    
    NSString *class =[dict valueForKey:@"com.apple.ColorSync.ProfileClass"];
    if (![class isEqualToString:@"mntr"] && ![class isEqualToString:@"prtr"]) {
        return true;
    }
    
    SeaColorProfile *p = [SeaColorProfile alloc];
    p.url = [dict valueForKey:@"com.apple.ColorSync.ProfileURL"];
    p.desc = [dict valueForKey:@"com.apple.ColorSync.ProfileDescription"];

    [array addObject:p];
    
    return true;
}

- (id)init
{
    profiles=[NSMutableArray arrayWithCapacity:0];
    CFErrorRef error;
    uint32_t seed = 0;
    
    ColorSyncIterateInstalledProfiles(profileIterate,&seed,(__bridge void*)profiles,&error);
    
    return self;
}

- (void)awakeFromNib
{
    
    int index = 0;
    
    SeaColorMenuItem *none = [[SeaColorMenuItem alloc] initWithTitle:@"None" action:@selector(run:) keyEquivalent:@""];
    [none setProfile:NULL];
    [none setEnabled:TRUE];
    [none setTarget:self];
    [proofMenu insertItem:none atIndex:(index)];
    index++;

    [proofMenu insertItem:[NSMenuItem separatorItem] atIndex:(index)];
    index++;
    
    for (SeaColorProfile *p in profiles){
        SeaColorMenuItem *item = [[SeaColorMenuItem alloc] initWithTitle:[p desc] action:@selector(run:) keyEquivalent:@""];
        [item setTarget:self];
        [item setProfile:p];
        [item setEnabled:TRUE];
        [proofMenu insertItem:item atIndex:index];
        index++;
    }
}

- (BOOL)validateMenuItem:(SeaColorMenuItem*)menuItem
{
    SeaDocument *document = gCurrentDocument;
    
    // Never when there is no document
    if (document == NULL)
        return NO;
    
    [[document helpers] endLineDrawing];
    
    if ([document locked])
        return NO;
    
    SeaColorProfile *current = [[document whiteboard] proofProfile];
    SeaColorProfile *cp = [menuItem profile];
    if (cp==NULL && current==NULL){
        [menuItem setState:NSOnState];
    } else {
        [menuItem setState:NSOffState];
    }
    
    if(cp!=NULL) {
        if (cp==current) {
            [menuItem setState:NSOnState];
        } else {
            [menuItem setState:NSOffState];
        }
    }
    
    return YES;
}

- (IBAction)run:(SeaColorMenuItem*)menuItem
{
    SeaColorProfile *cp = menuItem.profile;
    
    if(cp!=NULL) {
        if(cp.profile==NULL){
            cp.profile = ColorSyncProfileCreateWithURL((__bridge CFURLRef)cp.url,NULL);
            if (cp.profile) {
                cp.cs = [[NSColorSpace alloc] initWithColorSyncProfile:(void*)cp.profile];
            }
        }
        [[gCurrentDocument whiteboard] toggleSoftProof:cp];
    } else {
        [[gCurrentDocument whiteboard] toggleSoftProof:NULL];
    }
    
}

@end


