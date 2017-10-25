#import "AltiVecCore.h"

#ifndef NO_ALTIVEC

inline vector unsigned char mvec_mult(vector unsigned char A, vector unsigned char B)
{
	const vector unsigned short K1 = (vector unsigned short)(0x0080, 0x0080, 0x0080, 0x0080, 0x0080, 0x0080, 0x0080, 0x0080);
	const vector unsigned short K2 = (vector unsigned short)(0x0008, 0x0008, 0x0008, 0x0008, 0x0008, 0x0008, 0x0008, 0x0008);
	const vector unsigned char K3 = (vector unsigned char)(0x01, 0x11, 0x03, 0x13, 0x05, 0x15, 0x07, 0x17, 0x09, 0x19, 0x0B, 0x1B, 0x0D, 0x1D, 0x0F, 0x1F);
	vector unsigned short R1, R2, R1F, R2F;
	vector unsigned char RTF;
	
	R1 = vec_mule(A, B);
	R1 = vec_add(R1, K1);
	R1F = vec_sr(R1, K2);
	R1F = vec_add(R1F, R1);
	R1F = vec_sr(R1F, K2);
	
	R2 = vec_mulo(A, B);
	R2 = vec_add(R2, K1);
	R2F = vec_sr(R2, K2);
	R2F = vec_add(R2F, R2);
	R2F = vec_sr(R2F, K2);

	RTF = vec_perm((vector unsigned char)R1F, (vector unsigned char)R2F, K3);
	
	return RTF;
}

inline unsigned char mvec_get_uchar(vector unsigned char A, int pos)
{
	return ((unsigned char *)&A)[pos]; 
}

inline void mvec_set_uchar(vector unsigned char *A, int pos, unsigned char e)
{
	((unsigned char *)A)[pos] = e; 
}

#endif