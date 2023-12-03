/*
FIXUPP - a re-implementation of the Digital Research FIXUPP utility

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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef unsigned char  u8;
typedef unsigned short u16;

#define MAX_SEGMENTS 255            /* maximum number of segments */
#define REC_BUF_SZ   1028

/* OMF record type definitions */
#define SEGDEF16_REC 0x98
#define GRPDEF16_REC 0x9a
#define FIXUP16_REC  0x9c
#define MODEND16_REC 0x8a

/* OMF target and frame types */
#define TARGET_SEGDEF_IDX 0
#define FRAME_GRPDEF_IDX  1
#define FRAME_TARGET_IDX  5


u8 segment_count;
u8 group_count;
u8 segment_group[MAX_SEGMENTS+1];   /* group number of segment n (0=none) */

typedef struct {
   unsigned mode:1;
   unsigned location:4;
   unsigned offset:10;
   unsigned f_thread:1;
   unsigned frame:3;
   unsigned t_thread:1;
   unsigned target:3;
   u16 target_datum;
   u16 frame_datum;
   u16 displacement;
} fixup_t;


static u16 get_index( u8 **p )
{
   u8 v = *(*p)++;
   if ( v < 0x80 ) return v;
   return ((v & 0x7f) << 8) | *(*p)++;
}


static void put_index( u16 v, u8 **p )
{
   if ( v >= 0x80 ) {
      *(*p)++ = (u8)(v >> 8) | 0x80;
   }
   *(*p)++ = (u8)v;
}


static u16 get_16( u8 **p )
{
   u8 lo = *(*p)++;
   u8 hi = *(*p)++;
   return hi << 8 | lo;
}


static void put_16( u16 v, u8 *p )
{
   *p++ = (u8)v;
   *p++ = (u8)(v >> 8);
}


static size_t read_record( FILE *f, u8 *buf, size_t buf_sz )
{
   size_t rec_len;
   if ( buf_sz < 4 ) return 0;
   if ( fread( buf, 3, 1, f ) == -1 ) return 0;
   rec_len = buf[1] | (buf[2] << 8);
   if ( rec_len + 3 > buf_sz ) return 0;
   if ( fread( buf + 3, 1, rec_len, f ) != rec_len ) return 0;
   return rec_len + 3;
}


static size_t write_record( FILE *f, u8 *data, size_t sz )
{
   return fwrite( data, 1, sz, f );
}


static u8 calculate_checksum( const u8 *data, size_t len )
{
   u8 chksum = 0;
   size_t i = 0;
   for (; i < len; i++ ) chksum += data[i];
   return chksum;
}


/* The only purpose for us to process the SEGDEF records is to count the
   number of defined segments */
static int process_segdef( const u8 *data, size_t len )
{
   segment_count++;
   return 1;
}


/* We process the GRPDEF records to find out which segments have assigned
   a group. For earch segment we store its group index in segment_group or
   zero, if no group is assigned. We use this information when
   processing FIXUP records. */
static int process_grpdef( u8 *data, size_t len  )
{
   const char *data_end = data + len - 1;
   u8 *p = data + 3;       /* skip record type and length fields */
   u16 seg_idx;
   u16 name_idx;
   group_count++;          /* group count now stores idx of current group */

   (void) get_index( &p ); /* skip group name index (we do not need it) */

   while ( p < data_end ) {
      if ( *p++ != 0xff ) {
         /* 0xff indicates a segment index follows. We only support segment
            indexes, not external indexes. */
         puts( "GRPDEF error!" );
         return 0;
      }
      seg_idx = get_index( &p );
      segment_group[seg_idx] = group_count;
   }
   return 1;
}


static int decode_fixup( u8 **data, u8 *data_end, fixup_t *fixup )
{
   u8 *p = *data;

   if ( p + 2 > data_end ) return 0;

   /* THREAD definitions are not supported */
   if ( ( *p & 0x80 ) == 0 ) {
      puts( "THREAD subrecord not supported" );
      return 0;
   }

   /* REMEMBER: in the following, implicit masking by the bit width of the 
      fixup_t fields takes place, so it is not explicitly performed! */
   fixup->mode = *p >> 6;
   fixup->location = *p >> 2;
   fixup->offset = ((*p & 0x03) << 8) | *(p+1);
   p += 2;
   fixup->f_thread = *p >> 7;
   fixup->frame = *p >> 4;
   fixup->t_thread = *p >> 3;
   fixup->target = *p;
   p++;

   /* FRAME and TARGET THREAD references not supported */
   if ( fixup->f_thread || fixup->t_thread ) {
      puts( "THREAD target / frame not supported" );
      return 0;
   }
   fixup->frame_datum = ( fixup->frame < 4 ) ? get_index( &p ) : 0;
   fixup->target_datum = ( fixup->target < 7 ) ? get_index( &p ) : 0;
   fixup->displacement = ( fixup->target < 4 ) ? get_16( &p ) : 0;

   *data = p;

   return 1;
}


static void encode_fixup( fixup_t *fixup, u8 **data )
{
   u8 *p = *data;
   
   /* 16-it LOCAT field */
   *p++ = 0x80 | (fixup->mode << 6) | (fixup->location << 2) 
        | (fixup->offset >> 8) ;
   *p++ = fixup->offset;
   
   /* 8-bit FIXDAT field */
   *p++ = (fixup->f_thread << 7) | (fixup->frame << 4)
        | (fixup->t_thread << 3) | fixup->target;
   
   if ( fixup->frame < 4 ) put_index( fixup->frame_datum, &p );
   if ( fixup->target < 7 ) put_index( fixup->target_datum, &p );
   if ( fixup->target < 4 ) {
      put_16( fixup->displacement, p );
      p += 2;
   }

   *data = p;
}


static void dump_fixup( fixup_t *fixup )
{
#if 0
      printf( "M%d L%d O=%04x F%d T%d : F=%04x T=%04x D=%04x",
      fixup->mode, fixup->location, fixup->offset, fixup->frame, fixup->target,
      fixup->frame_datum, fixup->target_datum, fixup->displacement);
#endif
}


/* When processing a FIXUPP we have to decide if we accept it or if we must
   change it. We have to change it if it is a segment-relative FIXUP with
   a SEGMENT target and frame, and the segment is part of a group. We then
   have to adjust the frame to reference the group instead of the segment.
   len = whole record length incl. type, length and chksum */
static int process_fixup( u8 *data, size_t *len )
{
   static u8 original[REC_BUF_SZ];
   u8 *s = original + 3;            /* s points to original fixups */
   u8 *s_end = original + *len - 1; /* process until chksum is reached */
   u8 *p = data + 3;                /* p points to patched fixups */
   fixup_t fixup;

   /* make backup copy of the original fixups */
   memcpy( original, data, *len );

   while ( s < s_end ) {
      if ( !decode_fixup( &s, s_end, &fixup ) ) return 0;

      dump_fixup( &fixup );

      if ( ( fixup.target & 3 ) == TARGET_SEGDEF_IDX 
           && fixup.frame == FRAME_TARGET_IDX
           && segment_group[fixup.target_datum] ) {

         /* set the frame to the group of the segment specified by target */
         fixup.frame = FRAME_GRPDEF_IDX;
         fixup.frame_datum = segment_group[fixup.target_datum];

         dump_fixup( &fixup );
      }

      encode_fixup( &fixup, &p );

   }

   /* encode new record length and checksum */
   put_16( p - data - 3 + 1, data + 1 );
   *p = -calculate_checksum( data, p - data );
   *len = p - data + 1;

   return 1;
}


int process_records( FILE *inf, FILE *outf )
{
   static u8 record_data[REC_BUF_SZ];   /* incl. type, length and chksum */
   u8 record_type;
   size_t record_sz;
   int finished = 0;
   int result = 1;

   while ( !finished ) {
      record_sz = read_record( inf, record_data, sizeof( record_data ) );
      if ( !record_sz ) {
         return 0;
      }
      if ( calculate_checksum( record_data, record_sz ) != 0 ) {
         puts("checksum error!");
         return 0;
      }

      record_type = record_data[0];
      /*printf("rec %02x len: %zu\n", (int)record_type, record_sz - 3); */

      switch ( record_type ) {
         case FIXUP16_REC:
            result = process_fixup( record_data, &record_sz );
            break;
         case SEGDEF16_REC:
            result = process_segdef( record_data, record_sz );
            break;
         case GRPDEF16_REC:
            result = process_grpdef( record_data, record_sz );
            break;
         case MODEND16_REC:
            finished = 1;
            break;
      }

      if ( !result || !write_record( outf, record_data, record_sz ) )
         return 0;
   }

   return 1;
}


int main( int argc, char *argv[] )
{
   FILE *inf, *outf;
   int result = EXIT_SUCCESS;

   if ( argc != 3 ) {
      puts( "Usage: fixupp input.obj output.obj");
      result = EXIT_FAILURE;
      goto ret0;
   }

   /* open input and output files */
   inf = fopen( argv[1], "rb" );
   if ( !inf ) {
      result = EXIT_FAILURE;
      goto ret0;

   }
   outf = fopen( argv[2], "wb" );
   if ( !outf ) {
      result = EXIT_FAILURE;
      goto ret1;
   }

   if ( !process_records( inf, outf ) ) {
      puts( "error!" );
      result = EXIT_FAILURE;
   }

   fclose( outf );
   ret1:
   fclose( inf );
   ret0:
   return result;
}
