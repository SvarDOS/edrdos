PCMDATA group PCMODE_DATA,FDOS_DSEG,FIXED_DOS_DATA,PCMODE_CODE
PCMDATA group GLOBAL_DATA,BDOS_DATA,PCMODE_DSIZE

PCMCODE group PCM_HEADER,PCM_CODE,BDOS_CODE,PCM_RODATA,PCM_HISTORY
PCMCODE group PCM_ICODE,PCM_CODEND

PCM_HEADER segment public para 'CODE'
PCM_HEADER ends

PCM_CODE segment public byte 'CODE'
PCM_CODE ends

BDOS_CODE segment public word 'CODE'
BDOS_CODE ends

PCM_RODATA segment public word 'CODE'
PCM_RODATA ends

PCM_HISTORY segment public byte 'CODE'
PCM_HISTORY ends

PCM_ICODE segment public byte 'CODE'
PCM_ICODE ends

PCM_CODEND segment public para 'CODE'
PCM_CODEND ends



PCMODE_DATA segment public word 'DATA'
PCMODE_DATA ends

FDOS_DSEG segment common word 'DATA'
FDOS_DSEG ends

FIXED_DOS_DATA segment public word 'DATA'
FIXED_DOS_DATA ends

PCMODE_CODE segment public word 'DATA'
PCMODE_CODE ends

GLOBAL_DATA segment public word 'DATA'
GLOBAL_DATA ends

BDOS_DATA segment common word 'DATA'
BDOS_DATA ends

PCMODE_DSIZE segment public para 'DATA'
PCMODE_DSIZE ends


end
