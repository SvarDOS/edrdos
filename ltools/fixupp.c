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
#define MAX_GROUPS   255            /* maximum number of groups */
#define MAX_LNAMES   1024
#define REC_BUF_SZ   1028

/* OMF record type definitions */
#define PUBDEF_REC   0x90
#define LNAMES_REC   0x96
#define SEGDEF16_REC 0x98
#define GRPDEF16_REC 0x9a
#define FIXUP16_REC  0x9c
#define MODEND16_REC 0x8a
#define LEDATA16_REC 0xA0
#define LIDATA16_REC 0xA2

/* OMF target and frame types */
#define TARGET_SEGDEF_IDX 0
#define FRAME_GRPDEF_IDX  1
#define FRAME_TARGET_IDX  5


unsigned verbose = 0;
unsigned reloc = 0;
unsigned displaygroupchange = 0;
unsigned segment_count;
unsigned group_count;
unsigned segment_group[MAX_SEGMENTS+1];   /* group number of segment n (0=none) */
unsigned groups[MAX_GROUPS + 1];
unsigned lnames_count;
u8 emptylname[] = "";
u8* lnames[MAX_LNAMES + 1];
unsigned segments[MAX_SEGMENTS + 1];
unsigned current_segment = 0;
unsigned current_base = 0;

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
   if ( fread( buf, 1, 3, f ) != 3 ) return 0;
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


static int process_lnames( u8 *data, size_t len  )
{
   const u8 *data_end = data + len - 1;
   u8 *p = data + 3;       /* skip record type and length fields */
   u8 length;
   u8* lname;

   while ( p < data_end ) {
      length = *p++;
      if ( lnames_count >= MAX_LNAMES ) {
         fputs( "Error: Too many lnames!\n", stderr );
         return 0;
      }
      ++ lnames_count;
      if ( !length ) {
         lnames[lnames_count] = emptylname;
         continue;
      }
      lname = malloc(length + 1);
      if ( !lname ) {
         fputs( "Error: Out of memory for lnames!\n", stderr );
         return 0;
      }
      memcpy( lname, p, length );
      lname[length] = 0;
      lnames[lnames_count] = lname;
      p += length;
   }
   if ( p != data_end ) {
      fputs( "Error: Overflow in lnames!\n", stderr );
      return 0;
   }

   return 1;
}


static int process_segdef( u8 *data, size_t len )
{
   unsigned a, c, b, pbit;
   u16 length, name_idx;
   u8 *p = data + 3;       /* skip record type and length fields */

   (void)data; (void)len; /* unused */
   segment_count++;

   if ( segment_count > MAX_SEGMENTS ) {
      fputs( "Error: Too many segments!\n", stderr );
      return 0;
   }

   a = (*p >> 5) & 7;
   c = (*p >> 2) & 7;
   b = (*p >> 1) & 1;
   pbit = (*p >> 0) & 1;

   ++ p;

   if ( a == 0 ) {
      p += 3;
   }

   length = get_16( &p );
   name_idx = get_index( &p );
   segments[segment_count] = name_idx;

   if ( !verbose ) {
      return 1;
   }

   printf("seg=%04Xh a=%Xh c=%Xh b=%Xh p=%Xh length=%u name_idx=%u ",
      (unsigned)segment_count, a, c, b, pbit,
      (unsigned)length, (unsigned)name_idx);
   printf("name=\"%s\"\n", lnames[name_idx]);

   return 1;
}


/* We process the GRPDEF records to find out which segments have assigned
   a group. For earch segment we store its group index in segment_group or
   zero, if no group is assigned. We use this information when
   processing FIXUP records. */
static int process_grpdef( u8 *data, size_t len  )
{
   const u8 *data_end = data + len - 1;
   u8 *p = data + 3;       /* skip record type and length fields */
   u16 seg_idx, name_idx;
   group_count++;          /* group count now stores idx of current group */

   if ( group_count > MAX_GROUPS ) {
      fputs( "Error: Too many groups!\n", stderr );
      return 0;
   }

   name_idx = get_index( &p ); /* skip group name index (we do not need it) */
   groups[group_count] = name_idx;

   while ( p < data_end ) {
      if ( *p++ != 0xff ) {
         /* 0xff indicates a segment index follows. We only support segment
            indexes, not external indexes. */
         fputs( "Error: GRPDEF error!\n", stderr );
         return 0;
      }
      seg_idx = get_index( &p );
      segment_group[seg_idx] = group_count;
   }
   return 1;
}


static int process_ledata_lidata( u8 *data, size_t len  )
{
   /*const u8 *data_end = data + len - 1;*/
   u8 *p = data + 3;       /* skip record type and length fields */
   u16 seg_idx, data_offset;

   seg_idx = get_index( &p ); /* segment index */

   data_offset = get_16( &p );

   current_segment = seg_idx;
   current_base = data_offset;
   if ( seg_idx == 0 ||
      segments[seg_idx] == 0 ||
      lnames[segments[seg_idx]] == NULL ||
      *lnames[segments[seg_idx]] == 0)
   {
      fputs( "Error: Invalid segment for LEDATA/LIDATA!\n", stderr );
      return 0;
   }

   if ( !verbose ) {
      return 1;
   }

   printf("seg=%04Xh offset=%04Xh\n", (unsigned)seg_idx, (unsigned)data_offset);

   return 1;
}


static int decode_fixup( u8 **data, const u8 *data_end, fixup_t *fixup )
{
   u8 *p = *data;

   if ( p + 2 > data_end ) return 0;

   /* THREAD definitions are not supported */
   if ( ( *p & 0x80 ) == 0 ) {
      fputs( "Error: THREAD subrecord not supported\n", stderr );
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
      fputs( "Error: THREAD target / frame not supported\n", stderr );
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
   *p++ = (u8)fixup->offset;
   
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
#if 1
   unsigned length = 0;

   if ( !verbose && !reloc ) {
      return;
   }

   if ( verbose ) {
      printf( "M%d L%d O=%04x F%d T%d : F=%04x T=%04x D=%04x\n",
         fixup->mode, fixup->location, fixup->offset, fixup->frame, fixup->target,
         fixup->frame_datum, fixup->target_datum, fixup->displacement);
   }

   switch( fixup->location ) {
   case 0:
   case 4:
      length = 1;
      break;
   case 1:
   case 2:
   case 5:
      length = 2;
      break;
   case 3:
   case 9:
   case 13:
      length = 4;
      break;
   case 11:
      length = 6;
      break;
   default:
      break;
   }
   printf( "segment=\"%s\" offset=%04Xh length=%u\n",
      lnames[segments[current_segment]], current_base + fixup->offset, length );
#else
   (void)fixup;
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
   put_16( (u16)(p - data - 3 + 1), data + 1 );
   *p = -calculate_checksum( data, p - data );
   *len = p - data + 1;

   return 1;
}

static int process_pubdef( u8 *data, size_t *len )
{
   static u8 original[REC_BUF_SZ];
   u8 *s = original + 3;            /* s points to original record */
   u8 *s_end = original + *len - 1; /* process until chksum is reached */
   u8 *p = data + 3;                /* p points to patched record */
   u8 *s_past_index;
   u16 group, newgroup, segment, slen;
   unsigned skip = 0;

   /* make backup copy of the original fixups */
   memcpy( original, data, *len );

   group = get_index( &s );
   segment = get_index( &s );

   s_past_index = s;

   if ( segment == 0 ) {
      skip = 1;		/* base frame present (absolute) */
   }
   if ( group != 0 ) {
      skip = 1;		/* group already present */
   }
   newgroup = segment_group[ segment ];
   if ( newgroup == 0 ) {
      skip = 1;		/* segment isn't in a group  */
   }

   if ( verbose || (displaygroupchange && !skip) ) {
      char *initial = "\n";
      char *quotgroup = "";
      char *groupstring = "(none)";
      char *quotsegment = "";
      char *segmentstring = "(none)";
      unsigned amount = 0;
      if ( group ) {
         groupstring = (char *)lnames[groups[group]];
         quotgroup = "\"";
      }
      if ( segment ) {
         segmentstring = (char *)lnames[segments[segment]];
         quotsegment = "\"";
      }
      printf("PUBDEF group=%04Xh,%s%s%s segment=%04Xh,%s%s%s:",
         (unsigned)group, quotgroup, groupstring, quotgroup,
         (unsigned)segment, quotsegment, segmentstring, quotsegment);
      if ( !segment ) {
         u16 frame = get_16( &s );
         printf(" frame=%04Xh:", (unsigned)frame);
      }
      while ( s < s_end ) {
         u8 namelength = *s++;
         u8* name = s;
         u16 offset, type;
         amount += 1;
         s += namelength;
         if ( !namelength ) {
            fprintf( stderr, "Error: Empty pubdef name!\n" );
            return 0;
         }
         offset = get_16( &s );
         type = get_index( &s );
         if ( verbose ) {
            printf("%s offset=%04Xh, type=%04Xh, name=\"%.*s\"\n",
               initial,
               (unsigned)offset, (unsigned)type,
               namelength, name);
            initial = "";
         }
      }
      if ( !verbose ) {
         char *plural = "";
         if ( amount != 1 ) {
            plural = "s";
         }
         printf(" %u symbol%s\n", amount, plural);
      }
      if ( s != s_end ) {
         fprintf( stderr, "Error: Overflow in pubdef record!\n" );
         return 0;
      }
   }

   if ( skip ) {
      return 1;
   }
   if ( verbose || displaygroupchange ) {
      printf("Replacing segment=\"%s\" group=0 by segment_group=%04Xh,\"%s\"\n",
          lnames[segments[segment]], (unsigned)newgroup,
          lnames[groups[newgroup]]);
   }
   put_index( newgroup, &p );
   put_index( segment, &p );
   slen = s_end - s_past_index;
   memcpy( p, s_past_index, slen );
   p += slen;

   /* encode new record length and checksum */
   put_16( (u16)(p - data - 3 + 1), data + 1 );
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
         fputs("Error: Checksum error!\n", stderr);
         return 0;
      }

      record_type = record_data[0];
      if ( verbose ) {
         printf("rec %02x len: %zu\n", (int)record_type, record_sz - 3);
      }

      switch ( record_type ) {
         case PUBDEF_REC:
            result = process_pubdef( record_data, &record_sz );
            break;
         case LNAMES_REC:
            result = process_lnames( record_data, record_sz );
            break;
         case LEDATA16_REC:
         case LIDATA16_REC:
            result = process_ledata_lidata( record_data, record_sz );
            break;
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
         default:
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

   if ( argc != 3 && argc != 4 ) {
      fputs( "Usage: fixupp input.obj output.obj [VERBOSE|RELOC|GROUP]\n", stderr );
      result = EXIT_FAILURE;
      goto ret0;
   }

   if ( argc == 4 ) {
      if ( ! strcmp( argv[3], "verbose" ) || ! strcmp( argv[3], "VERBOSE" ) ) {
         verbose = 1;
      } else if ( ! strcmp( argv[3], "reloc" ) || ! strcmp( argv[3], "RELOC" ) ) {
         reloc = 1;
      } else if ( ! strcmp( argv[3], "group" ) || ! strcmp( argv[3], "GROUP" ) ) {
         displaygroupchange = 1;
      } else {
         fputs( "Usage: fixupp input.obj output.obj [VERBOSE|RELOC|GROUP]\n", stderr );
         result = EXIT_FAILURE;
         goto ret0;
      }
   }

   /* open input and output files */
   inf = fopen( argv[1], "rb" );
   if ( !inf ) {
      fputs( "Error: Failed to open input file!\n", stderr );
      result = EXIT_FAILURE;
      goto ret0;

   }
   outf = fopen( argv[2], "wb" );
   if ( !outf ) {
      fputs( "Error: Failed to open output file!\n", stderr );
      result = EXIT_FAILURE;
      goto ret1;
   }

   if ( !process_records( inf, outf ) ) {
      fputs( "Error: Failed in process_records!\n", stderr );
      result = EXIT_FAILURE;
   }

   fclose( outf );
   ret1:
   fclose( inf );
   ret0:
   return result;
}
