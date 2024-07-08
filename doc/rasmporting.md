# RASM86 to JWasm conversion

## IF directive
Unlike RASM, the IF directive understood by JWasm does not work for non-defined symbols. One either has to set a symbol explicitly, to zero (false case) or any other value (true case) or use IFDEF to test if a symbol is defined.

## Arithmetic
JWasm expressions are 32-bit instead of the 16-bit RASM expressions. Also, JWasm treats the operands to the division operator `/` as signed. This sometimes leads to results the programmer does not expect. Example:

	(not 4000h) / 100h

yields to:

	RASM : 0BFH
	JWASM: 0FFFFFFC0H

Not only is the result sign-extended in JWasm, it is also rounded downwards, leading to a larger value (negative two-complement value)!

## Length operator
In RASM the `length` operator gives the length of the whole initializer list in a data definition, while under JWasm it returns the length of the first element of the initializer list. The JWasm `lengthof` operator may be used to get a behaviour according to RASM.

## Segment overrides
RASM supports multiple concatenated segment overrides, with the leftmost the one becoming effective. JWasm does not allow this. This is a problem if given something like this:

	PSP_ENVIRON	equ	es:word ptr .002ch
	mov ax, DS:PSP_ENVIRON

JWasm does not accept this because of multiple segment overrides. Therefore I recommend not using segment overrides in equates at all.

## Variable creation operator
RASM has an explicit variable creation operator `.`, yielding a variable assigned to the current segment and from the offset given to the right. So the following will not move the immediate value 2CH into ax, but the memory contents at DS:2CH:

	mov ax,word ptr .002ch

The dot operator has to be combined with the PTR operator to specify the type of the variable.

JWasm does not have the variable creation operator. Instead, one may for example explicitly give a segment override to make JWasm treat the following as a variable reference:

	mov ax,ds:2ch

## Value range checking
The following assembles under RASM, but not under JWasm:

	TRUE equ 0FFFFH
	mov al,TRUE

This is because JWasm detects that the number is too large to be stored in AL register. The high bits can be masked to make this work, or you may use the PTR operator:

	mov al,TRUE and 0FFH
	mov al,byte ptr TRUE

## Relocation entries
If not explicitly told otherwise, RASM always generates relocations relative to a segment, even if the segment is part of a group. In the following example, the offset stored in SI is the offset relative to the segment _data_, not gelative to the _dgroup_ that _data_ is part of.

	dgroup group data
	data segment
	msg db 'Hello'
	data ends
	code
		...
		mov si,offset msg
		...
	code ends

This behaviour matches the behaviour of MASM versions up to 5.1. MASM 6 changed this to by default generate relocations relative to the group a segment is part of, and JWasm does so either.

The EDRDOS kernel source, prior to switching to JWasm, made use of the fixupp utility under the ltools directory to alter the generated .obj files to patch segment relative relocations to group relative relocations for segments which are part of a group. Since using JWasm, this is not necessary anymore.

## Linker specific: empty segments
Segments may be created in the JWasm source files solely for assigning external symbols to them, making them having zero size, like the following:

	BDOS_DATA	segment public word 'DATA'
		extrn	dcnt:word
		extrn	fdos_pb:word
	BDOS_DATA	ends

However, if these segments have an alignment other than byte given, at least WLINK 1.9 and v2 seem to handle this differently. WLINK 1.9 aligns the segment in the produced output even if it has no data in it. This sometimes adds unneccessary zero bytes to the output. WLINK v2 does not seem to do this. To prevent this, define these definition-only segments to be byte-aligned.

