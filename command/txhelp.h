#ifndef _DLS_INCLS_

#ifdef __cplusplus
extern "C" {
#endif
	/* DLS system functions. */
	extern void near      cdecl dls_init(void);
	extern void near * near cdecl dls_get_table(unsigned);
	extern unsigned near  cdecl dls_language(void);
#ifdef __cplusplus
};
#endif

/* DLS parameters passed to dls_get_table() function. */
#define DLS_NO  0
#define DLS_YES 1

#define _DLS_INCLS_
#endif /* !_DLS_INCLS_ */

/* DLS system variables. */
extern void near * near * near cdecl dls_table;


/* DLS static initialisation macros. */
#define DLS_number(n)  (*(unsigned int near *)dls_table[n])
#define DLS_char(n)    (*(char near *)dls_table[n])
#define DLS_string(n)  ((char near *)dls_table[n])
#define DLS_array(n)   ((char near * near *)dls_table[n])

/* Component messages equated to table entries. */
#define DLS_help_aaa		0
#define help_aaa		((char near *)dls_table[0])
#define DLS_help_and		1
#define help_and		((char near *)dls_table[1])
#define DLS_help_break		2
#define help_break		((char near *)dls_table[2])
#define DLS_help_call		3
#define help_call		((char near *)dls_table[3])
#define DLS_help_chcp		4
#define help_chcp		((char near *)dls_table[4])
#define DLS_help_chdir		5
#define help_chdir		((char near *)dls_table[5])
#define DLS_help_cls		6
#define help_cls		((char near *)dls_table[6])
#define DLS_help_copy		7
#define help_copy		((char near *)dls_table[7])
#define DLS_help_ctty		8
#define help_ctty		((char near *)dls_table[8])
#define DLS_help_date		9
#define help_date		((char near *)dls_table[9])
#define DLS_help_del		10
#define help_del		((char near *)dls_table[10])
#define DLS_help_delq		11
#define help_delq		((char near *)dls_table[11])
#define DLS_help_dir		12
#define help_dir		((char near *)dls_table[12])
#define DLS_help_echo		13
#define help_echo		((char near *)dls_table[13])
#define DLS_help_eraq		14
#define help_eraq		((char near *)dls_table[14])
#define DLS_help_erase		15
#define help_erase		((char near *)dls_table[15])
#define DLS_help_exit		16
#define help_exit		((char near *)dls_table[16])
#define DLS_help_for		17
#define help_for		((char near *)dls_table[17])
#define DLS_help_gosubreturn		18
#define help_gosubreturn		((char near *)dls_table[18])
#define DLS_help_goto		19
#define help_goto		((char near *)dls_table[19])
#define DLS_help_hiload		20
#define help_hiload		((char near *)dls_table[20])
#define DLS_help_idle		21
#define help_idle		((char near *)dls_table[21])
#define DLS_help_if		22
#define help_if		((char near *)dls_table[22])
#define DLS_help_mkdir		23
#define help_mkdir		((char near *)dls_table[23])
#define DLS_help_or		24
#define help_or		((char near *)dls_table[24])
#define DLS_help_path		25
#define help_path		((char near *)dls_table[25])
#define DLS_help_pause		26
#define help_pause		((char near *)dls_table[26])
#define DLS_help_prompt		27
#define help_prompt		((char near *)dls_table[27])
#define DLS_help_rem		28
#define help_rem		((char near *)dls_table[28])
#define DLS_help_rename		29
#define help_rename		((char near *)dls_table[29])
#define DLS_help_rmdir		30
#define help_rmdir		((char near *)dls_table[30])
#define DLS_help_set		31
#define help_set		((char near *)dls_table[31])
#define DLS_help_shift		32
#define help_shift		((char near *)dls_table[32])
#define DLS_help_switch		33
#define help_switch		((char near *)dls_table[33])
#define DLS_help_time		34
#define help_time		((char near *)dls_table[34])
#define DLS_help_truename		35
#define help_truename		((char near *)dls_table[35])
#define DLS_help_type		36
#define help_type		((char near *)dls_table[36])
#define DLS_help_ver		37
#define help_ver		((char near *)dls_table[37])
#define DLS_help_verify		38
#define help_verify		((char near *)dls_table[38])
#define DLS_help_vol		39
#define help_vol		((char near *)dls_table[39])
