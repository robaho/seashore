#import "Seashore.h"
#import <sys/sysctl.h>

int main(int argc, const char *argv[])
{
    rgbCS = CGColorSpaceCreateDeviceRGB();
    grayCS = CGColorSpaceCreateDeviceGray();

    [gColorPanel setShowsAlpha:FALSE];


    return NSApplicationMain(argc, argv);
}
