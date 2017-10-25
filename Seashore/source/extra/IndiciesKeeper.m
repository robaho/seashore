#include "IndiciesKeeper.h"

#define kNumberOfIndiciesRecordsPerMalloc 10

IndiciesKeeper allocKeeper()
{
	IndiciesKeeper result;
	
	result.length = 0;
	result.stack = malloc(kNumberOfIndiciesRecordsPerMalloc * sizeof(IndiciesRecord));
	
	return result;
}

void freeKeeper(IndiciesKeeper *keeper)
{
	int i;
	
	if (keeper->stack) {
		for (i = 0; i < keeper->length; i++)
			free(keeper->stack[i].indicies);
		free(keeper->stack);
		keeper->stack = NULL;
	}
}

void addToKeeper(IndiciesKeeper *keeper, IndiciesRecord record)
{
	if (keeper->stack == NULL)
		return;
	
	if (keeper->length != 0 && keeper->length % kNumberOfIndiciesRecordsPerMalloc == 0)
		keeper->stack = realloc(keeper->stack, (keeper->length + kNumberOfIndiciesRecordsPerMalloc) * sizeof(IndiciesRecord));
	
	keeper->stack[keeper->length] = record;
	keeper->length++;
}

