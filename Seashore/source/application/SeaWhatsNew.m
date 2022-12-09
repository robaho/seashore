//
//  SeaWhatsNew.m
//  Seashore
//
//  Created by robert engels on 6/21/22.
//

#import "Seashore.h"
#import "SeaWhatsNew.h"
#import "SeaWindowContent.h"

@implementation SeaWhatsNew

#define LATEST @"3.11"

- (void)awakeFromNib
{
    NSBundle *myBundle = [NSBundle mainBundle];
    NSString *sFile= [myBundle pathForResource:@"What's New and Tips" ofType:@"rtf"];
    [self->textView readRTFDFromFile:sFile];
    [self->textView setTextColor:[NSColor textColor]];

    if(![LATEST isEqualTo:[gUserDefaults stringForKey:@"whatsnew"]]){
        [self performSelector:@selector(showWhatsNew:) withObject:self afterDelay:.250];
    }
}

- (IBAction)showWhatsNew:(id)sender
{
    [window setLevel:NSFloatingWindowLevel];
    [window makeKeyAndOrderFront:self];
    [gUserDefaults setValue:LATEST forKey:@"whatsnew"];
}
@end
