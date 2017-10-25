#import "RLE.h"

BOOL RLEDecompress(unsigned char *output, unsigned char *input, int inputLength, int width, int height, int spp)
{
	unsigned char *destData;
	unsigned char *srcData = input;
	unsigned char *srcDataLimit = input + inputLength;
	unsigned char value;
	unsigned short tmp_short;
	int length;
  	int destRemaining, i, j;

	// Select sample to focus on
	for (i = 0; i < spp; i++) {
		
		// Make note of the amount of work we've got to do
		destRemaining = width * height;
		
		// Move into position for current sample
		destData = output + i;
		
		// While we've still got work to do
		while (destRemaining > 0) {
		
			if (srcData > srcDataLimit)
				return NO;
			
			// Get the length
			length = (int)srcData[0];
			srcData += 1;
			
			// Two cases we either have unique items or repeated items...
			if (length >= 128) {
			
				// UNIQUE ITEMS
				
				// Invert the length so it is between 1 and 128
				length = 255 - (length - 1);
				
				// If the number is 128, we are being told that the next two bytes represent a short signifying length
				if (length == 128) {
					if (srcData >= srcDataLimit)
						return NO;
					tmp_short = ((unsigned short *)srcData)[0];
					tmp_short = ntohs(tmp_short);
					length = tmp_short;
					srcData += 2;
				}
				
				// Now take the length off our workload
				destRemaining -= (int)length;
				
				if (destRemaining < 0)
					return NO;
				if (&srcData[length - 1] >= srcDataLimit)
					return NO;
				
				// Now repeatedly copy for as long as necessary 
				for (j = 0; j < length; j++) {
					destData[0] = srcData[0];
					srcData += 1;
					destData += spp;
				}
				
			}
			else {
				
				// REPEATED ITEMS
				
				// Add 1 to the length so it is between 1 and 128
				length += 1;
				
				// If the number is 128, we are being told that the next two bytes represent a short signifying length
				if (length == 128) {
					if (srcData >= srcDataLimit)
						return NO;
					tmp_short = ((unsigned short *)srcData)[0];
					tmp_short = ntohs(tmp_short);
					length = tmp_short;
					srcData += 2;
				}
				
				// Now take the length off our workload
				destRemaining -= (int)length;
				
				if (destRemaining < 0)
					return NO;
				
				// Store the value to be repeated
				value = srcData[0];
				srcData += 1;
				
				// Now repeatedly copy for as long as necessary 
				for (j = 0; j < length; j++) {
					destData[0] = value;
					destData += spp;
				}
				
			}
			
		}
		
    }

	return YES;
}


int RLECompress(unsigned char *output, unsigned char *input, int width, int height, int spp)
{
	int state, length, last, i, j;
	int srcRemaining;
	unsigned char *destData = output;
	unsigned char *srcData;
	int destLength = 0;
	BOOL hold = NO;
	unsigned short write_length;
	unsigned short *destShortData;
	
	// Select sample to focus on
	for (i = 0; i < spp; i++) {
	
		// Reset values
		state = length = 0;
		last = -1;
		
		// Make note of the amount of work we've got to do
		srcRemaining = width * height;
		
		// Move into position for current sample
		srcData = input + i;
		
		// While we've still got work to do
		while (srcRemaining > 0) {
			
			switch (state) {
				case 0:
					
					// REPEATED ITEMS
					
					// If we have the longest run possible, are out of data or have come to the end of our repeating run...
					if (length == 32768 || srcRemaining - length <= 0 || (length > 1 && last != *srcData)) {
						
						// If we have a run of 128 or more...
						if (length >= 128) {
						
							// Place a symbol to indicate a run of 128 or more
							destData[destLength] = 127;
							
							// Write the actual run size as a short in the next two bytes
							write_length = length;
							write_length = htons(write_length);
							destShortData = (unsigned short *)(destData + destLength + 1);
							destShortData[0] = write_length;
							
							// Write the repeating item in the fourth byte
							destData[destLength + 3] = last;
							
							// Move forward 4 bytes
							destLength += 4;
							
						}
						else {
							
							// Write the size of the run in the first byte (for the sake of neatness we typically count a run of 1 as a unique item)
							if (length == 1)
								destData[destLength] = 255 - (length - 1);
							else
								destData[destLength] = length - 1;
							
							// And the repeating item in the second
							destData[destLength + 1] = last;
						
							// Move forward 2 bytes
							destLength += 2;

						}
							
						// Take the length of our workload
						srcRemaining -= length;
						
						// Reset the length
						length = 0;
						
					}
					else {
						
						// If our run is only 1 item in length switch to the next state (don't advance)
						if (length == 1 && (last != *srcData)) {
							hold = YES;
							state = 1;
						}
					
					}
				
				break;
				case 1:
				
					// UNIQUE ITEMS
				
					// Start advancing again
					hold = NO;
					
					// If we have the longest run possible, are out of data or have a repeating item...
					if (length == 32768 || srcRemaining - length <= 0 || (srcRemaining - length > 2 && *srcData == srcData[spp] && *srcData == srcData[spp * 2])) {
					
						// After we finish, go back to state 0
						state = 0;
						
						// If we have a run of 128 or more...
						if (length >= 128) {
						
							// Place a symbol to indicate a run of 128 or more
							destData[destLength] = 255 - 127;
							
							// Write the actual run size as a short in the next two bytes
							write_length = length;
							write_length = htons(write_length);
							destShortData = (unsigned short *)(destData + destLength + 1);
							destShortData[0] = write_length;
							
							// Move forward 3 bytes
							destLength += 3;

						}
						else {
						
							// Write the size of the run in the first byte
							destData[destLength] = 255 - (length - 1);
							
							// Move forward 1 byte
							destLength += 1;

						}

						// Write each of the non-matching bytes
						srcData = srcData - length * spp;
						for (j = 0; j < length; j++) {
							destData[destLength] = *srcData;
							destLength += 1;
							srcData += spp;
						}

						// Take the length of our workload
						srcRemaining -= length;
						
						// Reset the length
						length = 0;
					}
				
				break;
			}
			
			// If there is still data remaining, remember the last piece and move to the next  
			if (srcRemaining > 0 && !hold) {
				last = *srcData;
				length++;
				srcData += spp;
			}
		}
	
	}
	
	return destLength;
}
