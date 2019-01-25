//
//  Alpha2GrayClass.h
//  Alpha2Gray
//
//  Created by robert engels on 1/23/19.
//  Copyright © 2019 robert engels. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Plugins/PluginClass.h>

NS_ASSUME_NONNULL_BEGIN

@interface Alpha2GrayClass : NSObject <PluginClass>
{
    // The plug-in's manager
    SeaPlugins *seaPlugins;
}

@end

NS_ASSUME_NONNULL_END
