//
//  SeaPrintOptionsContoller.m
//  Seashore
//
//  Created by robert engels on 1/12/19.
//

#import "SeaPrintOptionsController.h"

@interface SeaPrintOptionsController ()

@end

@implementation SeaPrintOptionsController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    // We override the designated initializer, ignoring the nib since we need our own
    return [super initWithNibName:@"PrintPanelAccessory" bundle:nibBundleOrNil];
}

- (id)initWithDocument:(SeaDocument*)doc
{
    document = doc;
    return [super init];
}

- (void)awakeFromNib
{
    self.scaleByAmount = true;
    self.scaleEntireImage = true;
}

/* The first time the printInfo is supplied, initialize the value of the pageNumbering setting from defaults
 */
- (void)setRepresentedObject:(id)printInfo {
    [super setRepresentedObject:printInfo];
    NSPrintInfo *pi = (NSPrintInfo*)printInfo;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateScale) name:@"NSPrintInfoDidChange" object:nil];
    [self setValue:[NSNumber numberWithFloat:[pi scalingFactor]] forKeyPath:@"scaleAmount"];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"NSPrintInfoDidChange" object:NULL];
}

- (void)setScaleAmount:(float)amount {
    NSPrintInfo *printInfo = [self representedObject];
    [[printInfo dictionary] setObject:[NSNumber numberWithFloat:amount] forKey:NSPrintScalingFactor];
}

- (float)scaleAmount {
    NSPrintInfo *printInfo = [self representedObject];
    return [[[printInfo dictionary] objectForKey:NSPrintScalingFactor] floatValue];
}

- (NSSet *)keyPathsForValuesAffectingPreview {
    return [NSSet setWithObjects:@"scaleAmount", @"scaleByAmount", @"scaleToFit", nil];
}

/* This enables Seahore-specific settings to be displayed in the Summary pane of the print panel.
 */
- (NSArray *)localizedSummaryItems {
    NSMutableArray *items = [NSMutableArray array];
    NSString *on = NSLocalizedString(@"On",@"On");
    if([self scaleToFit]){
        if([self scaleEntireImage]) {
            [items addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                              NSLocalizedString(@"Fit Entire Image",@"scale to fit entire image"),NSPrintPanelAccessorySummaryItemNameKey,
                              on,NSPrintPanelAccessorySummaryItemDescriptionKey,
                              nil]];
        }
        if([self scaleFillPaper]){
            [items addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                              NSLocalizedString(@"Fill Entire Paper",@"scale to fill entire paper"),NSPrintPanelAccessorySummaryItemNameKey,
                              on,NSPrintPanelAccessorySummaryItemDescriptionKey,
                              nil]];
        }
    }
    return items;
}

- (IBAction)scaleTypeChange:(id)sender {
    // these should not be needed but binding Value with radio buttons doesn't seem to work on set
    [self setScaleByAmount:([sender tag]==1)];
    [self setScaleToFit:([sender tag]==2)];
    [self updateScale];
}

- (IBAction)scaleFitTypeChange:(id)sender {
    // these should not be needed but binding Value with radio buttons doesn't seem to work on set
    [self setScaleEntireImage:([sender tag]==1)];
    [self setScaleFillPaper:([sender tag]==2)];
    [self updateScale];
}

-(void)updateScale
{
    NSPrintInfo *pi = [self representedObject];
    
    int xres = [[document contents] xres], yres = [[document contents] yres];
    
    NSRect bounds = [pi imageablePageBounds];

    float width = ([[document contents] width] * (72.0/xres));
    float height = ([[document contents] height] * (72.0/yres));

    float scaleh = bounds.size.height / (float)height;
    float scalew = bounds.size.width / (float)width;
    
    NSLog(@"scaleByAmount %d, scaleToFit %d",_scaleByAmount,_scaleToFit);
    NSLog(@"scaleh %f, scalew %f",scaleh,scalew);
    
    if(_scaleToFit){
        if(_scaleEntireImage) {
            float scale = MIN(scaleh,scalew);
            [self setScaleAmount:scale];
        } else {
            float scale = MAX(scaleh,scalew);
            [self setScaleAmount:scale];
        }
    }
}

@end
