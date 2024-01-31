/*
COMPBIOS - a re-implementation of COMPBIOS.EXE of EDR-DOS LTOOLS

MIT License

Copyright (c) 2023 Bernd Boeckmann

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/


/*
DRBIOS.SYS is compressed by RLE encoding regions of zero of its data area.
The start offset of the region to be compressed is stored as a word at
offset 3 of DRBIOS.SYS. Bytes in front of the area to be compressed are
copied unaltered to the output file.

COMPBIOS encodes regions of zero as a 16-bit count with the highest bit set
to one. So, if 16 zeroes are encoded this becomes 0x8010. Data regions that
are to be copied literally are preceeded by the 16-bit byte count, with
the highest bit cleared. So 32 bytes to be copied are encoded as 0x0020
followed by the actual bytes. The end of the compressed region is encoded by
0x0000.
*/


#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#define ZEROCOMP_ADDR_WORD 3	/* location in input file holding the start
								   offset (WORD) of zero-compressed data */


void zerocomp( char *data, size_t data_len, char *out, size_t *out_len );
char * read_file( const char *fn, size_t *size );
int write_file( const char *fn, const char *data, size_t size );


int main( int argc, char *argv[] )
{
	char *in_data, *out_data, *in_ptr, *out_ptr;
	size_t in_size, out_size;
	uint16_t comp_start;

	if ( argc != 3 ) {
		puts( "Usage: COMPBIOS.EXE in-file out-file" );
		return 1;
	}

	in_data = read_file( argv[1], &in_size );
	if ( !in_data ) {
		puts( "error: can not read input file" );
		return 1;
	}

	/* get start offset of data to be compressed */
	comp_start = *(uint16_t*)(in_data + ZEROCOMP_ADDR_WORD);
	in_data[ZEROCOMP_ADDR_WORD] = in_data[ZEROCOMP_ADDR_WORD+1] = 0;

	if ( !comp_start ) {
		puts( "BIOS already compressed" );
		free( in_data );
		return 0;
	}
	/*printf( "start compressing at %04x\n", comp_start );*/
	

	out_data = malloc( in_size );
	if ( !out_data ) {
		puts( "allocation error" );
		return 1;
	}

	/* copy uncompressed part of file */
	memcpy( out_data, in_data, comp_start );

	/* zero-compress file... */
	in_ptr = in_data + comp_start;
	out_ptr = out_data + comp_start;
	zerocomp( in_ptr, in_size - comp_start, out_ptr, &out_size );
	/*printf( "in-size: %zu, out-size: %zu\n ", in_size - comp_start, out_size );*/
	
	/* ...and write everything to output file */
	if ( !write_file( argv[2], out_data, comp_start + out_size ) ) {
		puts( "error: could not write output file" );
		free( out_data );
		free( in_data );
		return 1;
	}

	free( out_data );
	free( in_data );
	return 0;
}


#define ZERO_THRESHOLD 5

/* encodes a single block of either non-zero data or zeroes. Up to 
   ZERO_THRESHOLD consecutive zeroes are allowed in non-zero data blocks */
void zerocomp_block( char **in, char *eof, char **out )
{
	char *data = *in;
	size_t len;
	uint16_t zero_count = 0;
	char *last_non_zero = NULL;
	char *outp = *out;

	if ( data >= eof ) return;

	while ( data < eof ) {
		if ( *data ) {
			if ( zero_count >= ZERO_THRESHOLD ) {
				break;
			}
			last_non_zero = data;
			zero_count = 0;

		}
		else {
			/* zero encountered */
			zero_count++;
			if ( zero_count >= ZERO_THRESHOLD && last_non_zero ) {
				data = last_non_zero + 1;
				break;
			}
		}
		data++;
	}

	len = data - *in;

	if ( last_non_zero ) {
		/*printf( "NON-ZERO: %04tX\n", len );*/
		*(uint16_t*)outp = len;
		outp += 2;
		memcpy( outp, *in, len);
		outp += len;
	}
	else {
		/*printf( "ZERO    : %04tX\n", 0x8000 | len );*/
		*(uint16_t*)outp = 0x8000 | len;
		outp+=2;
	}

	*out = outp;
	*in = data;
}


void zerocomp( char *data, size_t data_len, char *out, size_t *out_len )
{
	char *eof = data + data_len;
	char *end = eof;
	char *outp = out;

	/* Optimization: scan for trailing zeroes. Three or four trailing zeroes
	   may be encoded more efficiently as RLE compared to when included in
	   the last non-zero block

	   Not actually useful for DRBIOS, but for the future...
	*/
	while ( ( --end >= data ) && !*end );
	end++;
	if ( eof - end < 3 ) end = eof;

	while ( data < end ) {
		zerocomp_block( &data, end, &outp );
	}
	zerocomp_block( &end, eof, &outp );

	*outp++ = 0;
	*outp++ = 0;
	*out_len = outp - out;
}


char * read_file( const char *fn, size_t *size )
{
	FILE *f;
	char *buf;

	f = fopen( fn, "rb" );
	if ( !f ) {
		return NULL;
	}

	fseek( f, 0, SEEK_END );
	*size = ftell( f );
	buf = malloc( *size );
	if ( !buf ) {
		fclose( f );
		return NULL;
	}
	fseek( f, 0, SEEK_SET );

	if ( fread( buf, 1, *size, f ) != *size ) {
		free( buf );
		fclose( f );
		return NULL;
	}

	fclose( f );
	return buf;
}


int write_file( const char *fn, const char *data, size_t size )
{
	FILE *f;

	f = fopen( fn, "wb" );
	if ( !f ) {
		return 0;
	}

	if ( fwrite( data, 1, size, f ) != size ) {
		fclose( f );
		return 0;
	}

	fclose( f );
	return 1;
}

