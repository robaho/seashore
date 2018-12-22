#import "Globals.h"
#import <sys/sysctl.h>

int randomTable[4096];
int globalUniqueDocID;
int tempFileCount;
int diskWarningLevel;
BOOL userWarnedOnDiskSpace;
BOOL globalReadOnlyWarning;

int main(int argc, const char *argv[])
{
	userWarnedOnDiskSpace = globalReadOnlyWarning = NO;
	globalUniqueDocID = tempFileCount = 0;
	return NSApplicationMain(argc, argv);
}
