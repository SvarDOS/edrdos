# RASM86 to JWasm conversion

In July 2024 the [EDR-DOS][1] kernel source was ported from the proprietary, DOS-only assembler _RASM86_ created by Digital Research to the open source [JWasm][2] assembler in an effort to cross-build the EDR kernel from operating systems other than DOS. This document lists some differences between the two assemblers that were encountered while porting the source.


## IF directive

Unlike RASM, the `IF` directive understood by JWasm does not work for non-defined symbols. One either has to set a symbol explicitly, either by setting it to zero (false case) or any other value (true case), or replace it by an `IFDEF` if one only wants to test if a symbol is defined.


## Arithmetic

JWasm expressions are 32-bit, while RASM expressions are 16-bit. JWasm expressions are signed by default, and as such the division operator `/` treats its arguments as signed. This sometimes leads to results the programmer does not expect. Example:

	(NOT 4000H) / 100H

yields

	RASM : 0BFH
	JWASM: 0FFFFFFC0H

Not only is the result sign-extended in JWasm, it is also rounded downwards, leading to a larger value (negative two-complement value)!

I think it is saver to rely upon the right shift operator `SHR` instead of the division operator if dividing by a multiple of two. This prevents the rounding "down". JWasm `SHR` operator is an arithmetic right shift, meaning a one gets shifted in if the hightest bit is set before the shift.


## Length operator

In RASM the `LENGTH` operator gives the length of the whole initializer list in a data definition, while under JWasm it returns the length of the first element of the initializer list. The JWasm `LENGTHOF` operator may be used to get a behaviour according to RASM.


## Instruction encoding

JWasm prefers sign-extended instruction encodings, even if this does not result in smaller code.

	ADD AX,1

for example differs in encoding between RASM and JWasm. One may force JWasm to use the non sign-extended encoding by using the type cast operator:

	ADD AX,WORD PTR 1

The latter is encoded as `05 01 00` while the former is encoded as `83 C0 01`.


# Forward-referenced jumps

RASM is not able to optimize forward jumps. It instead provides a way to manually encode short jumps via the `JMPS` mnemonic. This mnemonic is unknown to JWasm, which provides `JMP SHORT`, but also optimizes forward jumps by default. `JMP SHORT` therefore only has to be used if one wants to make sure that the generated jump is indeed a two-byte short jump.

It shall be noted that JWasm does not provide a means to explicitly encode a near jump. There is no `JMP NEAR` to make sure a three-byte jump is encoded. But a near jump can either be encoded directly as data or implemented as a macro:

	JMPNEAR MACRO ADDRESS
	DB 0E9H
	DW (ADDRESS-$)-2
	ENDM


## String operations

The string operations like `LODS` may be given a memory operand for the purpose of specifying a segment override. RASM allows the following:

	LODS ES:AL

For JWasm, es:al is no valid memory reference. You may use the following instead:

	LODSB ES:0


## Address displacements

RASM allows negative displacements to be specified like

	MOV AL,-2[DI]

To make this work on JWasm, move the negative displacement into the square brackets:

	MOV AL,[DI-2]


## Variable creation operator

RASM has an explicit variable creation operator `.`, yielding a variable assigned to the current segment and numeric offset given to the right. So the following will not move the immediate value 2CH into ax, but the memory contents at DS:2CH:

	MOV AX,WORD PTR .002CH

The variable creation operator has to be combined with the `PTR` operator to specify the type of the variable.

JWasm does not have the variable creation operator. Instead, one may for example explicitly give a segment override to make JWasm treat the following as a variable reference:

	MOV AX,DS:2CH


## Value range checking

The following assembles under RASM, but not under JWasm:

	TRUE EQU 0FFFFH
	MOV AL,TRUE

This is because JWasm detects that the number is too large to be stored in AL register. The high bits can be masked to make this work, or you may use the PTR operator:

	MOV AL,TRUE AND 0FFH
	MOV AL,BYTE PTR TRUE


## Segment definitions

The RASM segment definitions do not have to be closed and can not be nested. JWasm segment definitions must be closed and may be nested.


## Manual segment overrides

RASM supports multiple concatenated segment overrides, with the leftmost the one becoming effective. JWasm does not allow this. This is a problem if given something like this:

	PSP_ENVIRON	EQU	ES:WORD PTR .002CH
	MOV AX, DS:PSP_ENVIRON

JWasm does not accept this because of multiple segment overrides. Therefore I recommend not using segment overrides in equates at all.


## Automatic segment overrides

Both RASM and JWasm "aid" the programmer by automatically generating segment override prefixes in some situations, but they do it in a different way. RASM has four directives to define segments, namley `CSEG`, `DSEG`, `ESEG` and `SSEG`. If a variable definition appears inside a DSEG, RASM generates no segment override prefix when dealing with the variable. It generates an ES prefix override if the variable is defined within an ESEG segment, CS for a CSEG variable and SS for a SSEG variable.

	EXTRA_DATA ESEG
	X DB 0

	CODE CSEG
	MOV AL,X		; ES segment override generated

JWasm follows the Microsoft way by making use of the _ASSUME_ directive to find out if and which segment override prefix is appropriate.

	EXTRA_DATA SEGMENT
	X DB 0
	EXTRA_DATA ENDS

	CODE SEGMENT
	ASSUME ES:EXTRA_DATA
	MOV AL,X		; ES segment override generated
	CODE ENDS


## Relocations

If not explicitly told otherwise, RASM always generates relocations relative to a segment, even if the segment is part of a group. In the following example, the offset stored in SI is the offset relative to the segment _data_, not gelative to the _dgroup_ that _data_ is part of.

	DGROUP GROUP DATA
	DATA SEGMENT
	MSG DB 'HELLO'
	DATA ENDS
	CODE
		...
		MOV SI,OFFSET MSG
		...
	CODE ENDS

This behaviour matches the behaviour of MASM versions up to 5.1. MASM 6 changed this to by default generate relocations relative to the group a segment is part of, and JWasm does so either.

The EDRDOS kernel source, prior to switching to JWasm, made use of the _FIXUPP_ utility under the ltools directory to alter the generated .obj files by rewriting segment relative relocations to group relative relocations for segments which are part of a group. Since using JWasm, this is not necessary anymore.


## Linker specific: empty segments

Segments may be created in the JWasm source files solely for assigning external symbols to them, making them zero-sized, like the following:

	BDOS_DATA	SEGMENT PUBLIC WORD 'DATA'
		EXTRN	DCNT:WORD
		EXTRN	FDOS_PB:WORD
	BDOS_DATA	ENDS

However, if these segments have an alignment other than byte given, at least WLINK 1.9 and v2 seem to handle this differently. WLINK 1.9 aligns the segment in the produced output even if it has no data in it. This sometimes adds unneccessary zero bytes to the output. WLINK v2 does not seem to do this. To prevent this, define segments containing only external definitions to be byte-aligned.


[1]: <https://github.com/SvarDOS/edrdos> "Enhanced DR-DOS"
[2]: <https://github.com/Baron-von-Riedesel/JWasm> "JWasm Assembler"
