//
//  PluginClass.h
//  Plugins
//
//  Created by robert engels on 12/11/22.
//

#import "PluginData.h"

#ifndef PluginClass_h
#define PluginClass_h

@protocol PluginClass <NSObject>

/*!
 @method        initWithManager:
 @discussion    Initializes an instance of this class with the given manager.
 @param        data
 The Plugin services callback.
 @result        Returns instance upon success (or NULL otherwise).
 */
- (id)initWithManager:(id<PluginData>)data;

/*!
 @method        points
 @discussion    Returns the number of points that the plug-in requires from the
 effect tool to operate.
 @result        Returns an integer indicating the number of points the plug-in
 requires to operate.
 */
- (int)points;

/*!
 @method        name
 @discussion    Returns the plug-in's name.
 @result        Returns an NSString indicating the plug-in's name.
 */
- (NSString *)name;

/*!
 @method        groupName
 @discussion    Returns the plug-in's group name.
 @result        Returns an NSString indicating the plug-in's group name.
 */
- (NSString *)groupName;

/*!
 @method        execute
 @discussion    Runs the plug-in.
 */
- (void)execute;

/*!
 @method        validatePlugin:
 @discussion    Determines whether a given plugin should be enabled or
 disabled.
 @param         data The plugin services callback.
 @result        YES if the plugin should be enabled, NO otherwise.
 */
+ (BOOL)validatePlugin:(id<PluginData>)data;

@optional

/*!
 @method        instruction
 @discussion    Returns the plug-in's instructions.
 @result        Returns a NSString indicating the plug-in's instructions
 (127 chars max).
 */
- (NSString *)instruction;

/*!
 @method        initialize
 @discussion    Initializes the plugin from any saved defaults.
 @result        Returns the NSView to be used for options, or NULL.
 */
- (NSView *)initialize;

/*!
 @method        detectRectangle
 @discussion    if the plugin implements this method, and asks for 4 points or more, then Seashore
 will add a button to auto-detect the primary rectangle in the image, settings the first four point
 to the rectangle
 */
- (void)detectRectangle;

@end

#endif /* PluginClass_h */

