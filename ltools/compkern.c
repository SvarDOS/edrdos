/*
COMPKERN - zero-compresses a single-file version of the EDR-DOS kernel

MIT License

Copyright (c) 2024 Bernd Boeckmann

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
COMPKERN creates a single-file EDR-DOS kernel by zero-compressing the
uncompressed DRBIO and DRDOS files and concatenating them to a single
EDRKERN.SYS.
  
DRBIO gets compressed starting from the the offset given in the word
at offset 3 of the DRBIO file, with the bytes before are copied unaltered.
The DRDOS file is compressed without the padding area.

COMPKERN encodes regions of zero as a 16-bit count with the highest bit set
to one. So, if 16 zeroes are encoded this becomes 0x8010. Data regions that
are to be copied literally are preceeded by the 16-bit byte count, with
the highest bit cleared. So 32 bytes to be copied are encoded as 0x0020
followed by the actual bytes. The end of the compressed region is encoded by
0x0000.

The kernel decompression is implemented in init0 in DRBIO\INIT.ASM
*/


#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#ifdef __FAR
 #include <libi86/malloc.h>
 #define farkeyword __far
 #define farmalloc _fmalloc
 #define farmemcpy _fmemcpy
 #define farfree _ffree
#else
 #define farkeyword
 #define farmalloc malloc
 #define farmemcpy memcpy
 #define farfree free
#endif

#include "zerocomp.h"

#define ZEROCOMP_ADDR_WORD 3  /* location in input file holding the start
                           offset (WORD) of zero-compressed data */
#define ZEROCOMP_FLAG_BYTE 5  /* location in input file holding the 
                           flag if file is zero-compressed */


int main( int argc, char *argv[] )
{
   farkeyword char *bio_data, *bdos_data;
   char *out_data[2];
   size_t bio_size, bio_comp_size;
   size_t bdos_size, bdos_comp_size;
   size_t out_size[2];
   uint16_t bio_comp_start;
   uint8_t bio_comp_flag;
   uint16_t comp_paras;    /* size of compressed parts */
   uint16_t decomp_paras;  /* size of compressed parts after decompression */
   
   uint16_t bdos_padding;  /* size of BDOS padding area that will be stripped */
   int result;

   if ( argc < 4 ) {
      puts( "Usage: COMPBIOS.EXE DRBIO-file DRDOS-file out-file [uncompressed]" );
      return 1;
   }

   bio_data = read_file( argv[1], &bio_size );
   if ( !bio_data ) {
      puts( "error: can not read DRBIO file" );
      return 1;
   }

   /* get start offset of data to be compressed */
   bio_comp_start = *(farkeyword uint16_t*)(bio_data + ZEROCOMP_ADDR_WORD);
   bio_comp_flag = *(farkeyword uint8_t*)(bio_data + ZEROCOMP_FLAG_BYTE);

   if ( bio_comp_flag ) {
      puts( "BIOS already compressed" );
      farfree( bio_data );
      return 0;
   }

   bdos_data = read_file( argv[2], &bdos_size );
   if ( !bdos_data ) {
      puts( "error: can not read DRDOS file" );
      free( bio_data );
      return 1;
   }

   /* number of padding bytes to be skipped */
   bdos_padding = *(farkeyword uint16_t*)bdos_data;


   if ( argv[4] && !strcmp( argv[4], "uncompressed" ) ) {
      printf( "Creating uncompressed kernel file\n" );

      bio_data[ZEROCOMP_FLAG_BYTE] = 0x80;   /* combined 0x80 + uncompressed 0x00*/
      out_data[0] = bio_data;
      out_size[0] = bio_size;
      out_data[1] = bdos_data + bdos_padding;
      out_size[1] = bdos_size - bdos_padding;

      result = write_file_multiple( argv[3], (const char **)out_data, out_size, 2 );
      if ( !result ) {
         puts( "error: cannot write kernel file" );
      }

      printf( "BIO size: %zu(%zu), BDOS size: %zu(%zu)\n", out_size[0], bio_size, out_size[1], bdos_size );

      farfree( bdos_data );
      farfree( bio_data );

      return !result;
   }
   else {
      printf( "Creating compressed kernel file\n" );

      bio_data[ZEROCOMP_FLAG_BYTE] = 0x81;   /* combined 0x80 + compressed 0x01 */

      out_data[0] = farmalloc( bio_size );
      if ( !out_data[0] ) {
         puts( "allocation error" );
         farfree( bdos_data );
         farfree( bio_data );
         return 1;
      }
   
      out_data[1] = farmalloc( bdos_size );
      if ( !out_data[1] ) {
         puts( "allocation error" );
         farfree( out_data[0] );
         farfree( bdos_data );
         farfree( bio_data );
         return 1;
      }
   
      /* copy uncompressed part of DRBIO file */
      farmemcpy( out_data[0], bio_data, bio_comp_start );
   
      /* zero-compress files... */
      zerocomp( bio_data + bio_comp_start, bio_size - bio_comp_start,
                out_data[0] + bio_comp_start + 4, &bio_comp_size, 0 );
      zerocomp( bdos_data + bdos_padding, bdos_size - bdos_padding,
                out_data[1], &bdos_comp_size, 1 );
   
      if ( (uint32_t)bio_comp_size + bdos_comp_size > 0xffff ) {
         puts( "error: compressed kernel larger than 64K" );
         result = 0;
         goto error;
      }
      comp_paras = (uint16_t)((uint32_t)bio_comp_size + bdos_comp_size + 15) >> 4;
      decomp_paras = (uint16_t)(((uint32_t)(bio_size - bio_comp_start) + (bdos_size - bdos_padding) + 15) >> 4);

      /* prepend compressed and uncompressed size in paras to compressed area */
      *(uint16_t*)(out_data[0] + bio_comp_start) = comp_paras;
      *(uint16_t*)(out_data[0] + bio_comp_start + 2) = decomp_paras;

      out_size[0] = 4 + bio_comp_start + bio_comp_size;
      out_size[1] = bdos_comp_size;
      
      /* ...and write everything to output file */

      result = write_file_multiple( argv[3], (const char **)out_data, out_size, 2 );
      if ( !result ) {
         puts( "error: cannot write kernel file" );
         goto error;
      }

      printf( "kernel compression starts at offset %04xh\n", bio_comp_start );
      printf( "size of compressed area: %04xh paras, uncompressed: %04xh paras\n", comp_paras, decomp_paras );  
      printf( "BIO size: %zu(%zu), BDOS size: %zu(%zu)\n", out_size[0], bio_size, out_size[1], bdos_size );
error:
      farfree( out_data[1] );
      farfree( out_data[0] );
      farfree( bdos_data );
      farfree( bio_data );

      return !result;
   }

   farfree( bdos_data );
   farfree( bio_data );

   return !result;
}
