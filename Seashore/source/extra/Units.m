#import "Units.h"

NSString *StringFromPixels(int pixels, int units, int resolution)
{
	NSString *result;
	
	switch (units) {
		case kInchUnits:
			result = [NSString stringWithFormat:@"%.2f", (float)pixels / resolution];
		break;
		case kMillimeterUnits:
			result = [NSString stringWithFormat:@"%.0f", (float)pixels / resolution * 25.4];
		break;
		default:
			result = [NSString stringWithFormat:@"%d", pixels];
		break;
	}
	return result;
}

int PixelsFromFloat(float measure, int units, int resolution)
{
	int result;
	
	switch (units) {
		case kInchUnits:
			result = roundf(measure * (float)resolution);
		break;
		case kMillimeterUnits:
			result = roundf(measure * (float)resolution / 25.4);
		break;
		default:
			result = measure;
		break;
	}
	
	return result;
}

NSString *UnitsString(int units)
{
	switch (units) {
		case kPixelUnits:
			return @"px";
		break;
		case kInchUnits:
			return @"in";
		break;
		case kMillimeterUnits:
			return @"mm";
		break;
	}
	return @"";
}