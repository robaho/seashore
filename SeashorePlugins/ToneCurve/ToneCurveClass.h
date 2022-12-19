/*!
	@header		ToneCurveClass
	@abstract	     Basic tone adjustments
*/
#import <Plugins/CoreImagePlugin.h>

@interface ToneCurveClass : CoreImagePlugin {
    CurveWithHistogram *view;
}

@end
