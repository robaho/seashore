#import "Globals.h"
#import <sys/sysctl.h>

BOOL globalReadOnlyWarning;

int main(int argc, const char *argv[])
{
	globalReadOnlyWarning = NO;
	return NSApplicationMain(argc, argv);
}
