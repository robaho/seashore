#import "Globals.h"
#import <sys/sysctl.h>

int randomTable[4096];
int globalUniqueDocID;
int tempFileCount;
int diskWarningLevel;
BOOL useAltiVec;
BOOL userWarnedOnDiskSpace;
BOOL globalReadOnlyWarning;

BOOL isAltiVecAvailable()
{
#ifdef __ppc__
	int selectors[2] = { CTL_HW, HW_VECTORUNIT };
	int hasVectorUnit = 0;
	size_t length = sizeof(hasVectorUnit);
	int error = sysctl(selectors, 2, &hasVectorUnit, &length, NULL, 0);
	
	if	(error == 0) return (hasVectorUnit != 0);
#endif
	return NO;
}

int main(int argc, const char *argv[])
{
	userWarnedOnDiskSpace = globalReadOnlyWarning = NO;
	globalUniqueDocID = tempFileCount = 0;
	useAltiVec = isAltiVecAvailable();
	return NSApplicationMain(argc, argv);
}
