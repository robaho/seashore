#import <Cocoa/Cocoa.h>
#import <SeaComponents/SeaComponents.h>

NS_ASSUME_NONNULL_BEGIN

@interface SeaFileChooser : NSView
{
    SeaButton *button;
    NSString *directory;
    NSString *path;
    NSString *title;
    id<Listener> listener;
    NSArray *fileTypes;
}

-(NSString*)path;
+ (SeaFileChooser*)chooserWithTitle:(NSString*)title types:(NSArray*)fileTypes directory:(NSString*) directory Listener:(id<Listener>)listener;

@end

NS_ASSUME_NONNULL_END
