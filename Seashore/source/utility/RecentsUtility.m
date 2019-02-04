//
//  RecentsUtility.m
//  Seashore
//
//  Created by robert engels on 2/4/19.
//
#import "SeaController.h"
#import "UtilitiesManager.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaHelpers.h"
#import "Units.h"
#import "LayerControlView.h"
#import "ToolboxUtility.h"
#import "SeaView.h"
#import "SeaWindowContent.h"

#import "RecentsUtility.h"

@implementation RecentsUtility

- (void)awakeFromNib
{
    [[SeaController utilitiesManager] setRecentsUtility: self for:document];
}

- (IBAction)show:(id)sender
{
    [[[document window] contentView] setVisibility: YES forRegion: kRecentsBar];
    [self update];
}

- (IBAction)hide:(id)sender
{
    [[[document window] contentView] setVisibility: NO forRegion: kRecentsBar];
}

- (IBAction)toggle:(id)sender
{
    if([[[document window] contentView] visibilityForRegion: kRecentsBar]) {
        [self hide:sender];
    }else{
        [self show:sender];
    }
}
- (void)update
{
}

- (BOOL)visible
{
    return [[[document window] contentView] visibilityForRegion: kRecentsBar];
}


@end
