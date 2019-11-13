#include "Bucket.h"

#define kStackSizeIncrement 2500

inline BOOL shouldFill(unsigned char *overlay, unsigned char *data, IntPoint seeds[], int numSeeds, IntPoint point, int width, int spp, int tolerance, int channel)
{
	int seedIndex;
	
	for(seedIndex = 0; seedIndex < numSeeds; seedIndex++){
		
		IntPoint seed = seeds[seedIndex];
		BOOL outsideTolerance = NO;
		int i, j, k, temp;
		
		i = point.x;
		j = point.y;
		
		if (overlay[(width * j + i + 1) * spp - 1] > 0){
			outsideTolerance = YES;
			continue;
		}
		
		if (channel == kAllChannels) {
			
			for (k = spp - 1; k >= 0; k--) {
				temp = abs((int)data[(width * j + i) * spp + k] - (int)data[(width * seed.y + seed.x) * spp + k]);
				if (temp > tolerance){
					outsideTolerance = YES;
					break;
				}
				if (k == spp - 1 && data[(width * j + i) * spp + k] == 0)
					return YES;
			}
		
		} else if (channel == kPrimaryChannels) {
		
			for (k = 0; k < spp - 1; k++) {
				temp = abs((int)data[(width * j + i) * spp + k] - (int)data[(width * seed.y + seed.x) * spp + k]);
				if (temp > tolerance){
					outsideTolerance = YES;
					break;
				}
			}
		
		} else if (channel == kAlphaChannel) {
		
			temp = abs((int)data[(width * j + i + 1) * spp - 1] - (int)data[(width * seed.y + seed.x + 1) * spp - 1]);
			if (temp > tolerance){
				outsideTolerance = YES;
			}
		
		}
		
		if(!outsideTolerance){
			return YES;
		}
	}
	
	return NO;
}

IntRect bucketFill(int spp, IntRect rect, unsigned char *overlay, unsigned char *data, int width, int height, IntPoint seeds[], int numSeeds, unsigned char *fillColor, int tolerance, int channel)
{
	int seedIndex;
	// We know at the very least that this point is in the rect
	IntRect result = IntMakeRect(seeds[0].x, seeds[0].y, 1, 1);

	for(seedIndex = 0; seedIndex < numSeeds; seedIndex++){
		IntPoint point, newPoint, seed = seeds[seedIndex];
		IntPoint *stack;
		int stackSize, stackPos, k;
		int minLeft = seed.x, maxRight = seed.x, minTop = seed.y, maxBottom = seed.y;
		int i, j;
		unsigned char firstPixel[4];
		int origTolerance = tolerance;

		// If the overlay alread contains this point, then our work is already done
		BOOL visited = YES;
		for (k = 0; k < spp; k++){
			// Compare to see if the fill exists at this point in the overlay
			if(overlay[(seed.y * width + seed.x) * spp + k] != fillColor[k]){
				visited = NO;
			}
		}
		if(visited){
			// We have in fact already filled this point so there's no reason 
			// to do another bucket fill from this point
			continue;
		}

		if (!IntContainsRect(IntMakeRect(0, 0, width, height), rect)) NSLog(@"Bad rectangle passed to textureFill()");
		if (fillColor[spp - 1] == 0) return IntMakeRect(0, 0, 0, 0);
		
		if (tolerance > 0 && tolerance < 255) {
			tolerance = 255;
			memcpy(firstPixel, data, spp);
			for (j = rect.origin.y; j < rect.origin.y + rect.size.height && tolerance != origTolerance; j++) {
				for	(i = rect.origin.x; i < rect.origin.x + rect.size.width; i++) {
					if (memcmp(firstPixel, &data[(j * width + i) * spp], spp) != 0) {
						tolerance = origTolerance;
						break;
					}
				}
			}
		}
		
		if (tolerance < 0) {
			result = IntMakeRect(0, 0, 0, 0);
		}
		else if (tolerance >= 255) {
			for (j = rect.origin.y; j < rect.origin.y + rect.size.height; j++) {
				for	(i = rect.origin.x; i < rect.origin.x + rect.size.width; i++) {
					memcpy(&(overlay[(j * width + i) * spp]), fillColor, spp);
				}
			}
			
			result = rect;
		}
		else {
			stack = malloc(sizeof(IntPoint) * kStackSizeIncrement);
			stackSize = kStackSizeIncrement;
			stackPos = 0;
			point = seed;
			do {
				
				if (stackPos == stackSize) {
					stackSize += kStackSizeIncrement;
					stack = realloc(stack, sizeof(IntPoint) * stackSize);
				}
				
				if (overlay[(point.y * width + point.x) * spp + spp - 1] == 0)  {
					for (k = 0; k < spp; k++)
						overlay[(point.y * width + point.x) * spp + k] = fillColor[k];
				}
				
				newPoint = point;
				newPoint.y++;
				if (IntPointInRect(newPoint, rect) && shouldFill(overlay, data, seeds, numSeeds, newPoint, width, spp, tolerance, channel)) {
					stack[stackPos] = point;
					stackPos++;
					point = newPoint;
					if (point.y > maxBottom) maxBottom = point.y;
				}
				else {
				
					newPoint = point;
					newPoint.y--;
					if (IntPointInRect(newPoint, rect) && shouldFill(overlay, data, seeds, numSeeds, newPoint, width, spp, tolerance, channel)) {
						stack[stackPos] = point;
						stackPos++;
						point = newPoint;
						if (point.y < minTop) minTop = point.y;
					}
					else {
					
						newPoint = point;
						newPoint.x++;
						if (IntPointInRect(newPoint, rect) && shouldFill(overlay, data, seeds, numSeeds, newPoint, width, spp, tolerance, channel)) {
							stack[stackPos] = point;
							stackPos++;
							point = newPoint;
							if (point.x > maxRight) maxRight = point.x;
						}
						else {
							
							newPoint = point;
							newPoint.x--;
							if (IntPointInRect(newPoint, rect) && shouldFill(overlay, data, seeds, numSeeds, newPoint, width, spp, tolerance, channel)) {
								stack[stackPos] = point;
								stackPos++;
								point = newPoint;
								if (point.x < minLeft) minLeft = point.x;
							}
							else {
								stackPos--;
								if (stackPos > -1)
									point = stack[stackPos];
							}
				
						}
						
					}
					
				}
				
			} while (stackPos > -1);
			
			free(stack);
			result = IntSumRects(result, IntMakeRect(minLeft, minTop, maxRight - minLeft + 1, maxBottom - minTop + 1));
		}
	}
	
	return result;
}

void textureFill(int spp, IntRect rect, unsigned char *data, int width, int height, unsigned char *texture, int textureWidth, int textureHeight)
{
	int i, j, k;
	
	for (j = rect.origin.y; j < rect.size.height + rect.origin.y; j++) {
		for (i = rect.origin.x; i < rect.size.width + rect.origin.x; i++) {
			if (data[(j * width + i + 1) * spp - 1] != 0x00) {
				for (k = 0; k < spp - 1; k++) {
					data[(j * width + i) * spp + k] = texture[((j % textureHeight) * textureWidth + (i % textureWidth)) * (spp - 1) + k];
				}
			}
		}
	}
}

void cloneFill(int spp, IntRect rect, unsigned char *data, unsigned char *replace, int width, int height, unsigned char *source, int sourceWidth, int sourceHeight, IntPoint spt)
{
	int i, ai, j, aj, sai, saj, k;
	
	for (j = rect.origin.y; j < rect.size.height + rect.origin.y; j++) {
		for (i = rect.origin.x; i < rect.size.width + rect.origin.x; i++) {
			ai = i - rect.origin.x;
			aj = j - rect.origin.y;
			sai = ai + spt.x;
			saj = aj + spt.y;
			if (data[(j * width + i + 1) * spp - 1] != 0x00 && saj >= 0 && saj < sourceHeight && sai >= 0 && sai < sourceWidth) {
				for (k = 0; k < spp - 1; k++) {
					data[(j * width + i) * spp + k] = source[(saj * sourceWidth + sai) * spp + k];
				}
				replace[j * width + i] = source[(saj * sourceWidth + sai + 1) * spp - 1];
			}
			else {
				replace[j * width + i] = 0x00;
			}
		}
	}
}
