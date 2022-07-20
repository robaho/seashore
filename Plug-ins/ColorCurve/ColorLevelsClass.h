/*!
	@header	    ColorCurveClass
	@abstract	    Basic color levels adjustments
*/
#import <Plugins/CoreImagePlugin.h>

@interface ColorLevelsClass : CoreImagePlugin {
    SeaSlider *redShadow,*greenShadow,*blueShadow;
    SeaSlider *redMid,*greenMid,*blueMid;
    SeaSlider *redHighlight,*greenHighlight,*blueHighlight;
}

@end
