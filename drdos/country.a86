NOIFLIST
TITLE 'National Data'
;    File              : $COUNTRY.A86$
;
;    Description       :
;
;    Original Author   : DIGITAL RESEARCH
;
;    Last Edited By    : $CALDERA$
;
;-----------------------------------------------------------------------;
;    Copyright Work of Caldera, Inc. All Rights Reserved.
;      
;    THIS WORK IS A COPYRIGHT WORK AND CONTAINS CONFIDENTIAL,
;    PROPRIETARY AND TRADE SECRET INFORMATION OF CALDERA, INC.
;    ACCESS TO THIS WORK IS RESTRICTED TO (I) CALDERA, INC. EMPLOYEES
;    WHO HAVE A NEED TO KNOW TO PERFORM TASKS WITHIN THE SCOPE OF
;    THEIR ASSIGNMENTS AND (II) ENTITIES OTHER THAN CALDERA, INC. WHO
;    HAVE ACCEPTED THE CALDERA OPENDOS SOURCE LICENSE OR OTHER CALDERA LICENSE
;    AGREEMENTS. EXCEPT UNDER THE EXPRESS TERMS OF THE CALDERA LICENSE
;    AGREEMENT NO PART OF THIS WORK MAY BE USED, PRACTICED, PERFORMED,
;    COPIED, DISTRIBUTED, REVISED, MODIFIED, TRANSLATED, ABRIDGED,
;    CONDENSED, EXPANDED, COLLECTED, COMPILED, LINKED, RECAST,
;    TRANSFORMED OR ADAPTED WITHOUT THE PRIOR WRITTEN CONSENT OF
;    CALDERA, INC. ANY USE OR EXPLOITATION OF THIS WORK WITHOUT
;    AUTHORIZATION COULD SUBJECT THE PERPETRATOR TO CRIMINAL AND
;    CIVIL LIABILITY.
;-----------------------------------------------------------------------;
;
;    *** Current Edit History ***
;    *** End of Current Edit History ***
;
;    $Log$
;
;    COUNTRY.A86 1.14 94/09/07 11:47:03
;    Added Brazilian (55) country support.    
;    COUNTRY.A86 1.10 93/11/19 16:25:11
;    Change some countries to 24 hour format
;    COUNTRY.A86 1.9 93/11/18 19:49:03
;    Change German time seperator from '.' to ':' - 
;    COUNTRY.A86 1.8 93/09/02 22:23:32
;    Turn on COMPATIBLE flag
;    COUNTRY.A86 1.6 93/06/23 19:58:29
;    Remove historic CDOS and DOSPLUS defines, add new COUNTRY define
;
;    ENDLOG
;

; COUNTRY.ASM source for  DR-DOS 3.3 COUNTRY.SYS
; generation:
;             RASM86 country
;             LINKEXE country
;             BIN2ASC -ob -s512 country.exe 
;             DEL country.sys
;             REN country.bin country.sys
;
;
; History:
; 26/May/88 Remove incorrect CS override in International Uppercase routine.
; 20/Jun/89 Added AUSTRIA (43) for German Office.
; 10/Oct/89 Added double byte character set lead byte range table DBCS_tbl.
; 16/Feb/90 Change default Japanese and Korean Code Pages to be 932 and 934 respectively.
; 21/Feb/90 cur_cp and cur_country added
; 23/May/90 Added Russian Country data and CodePage 866 Support
; ??/???/90 Added compatibility flag
; 23/Jul/90 Added Turkish Country Data and CodePage 853 Support
; 17/Sep/90 Turkish uses CodePage 857
; 17/Sep/90 Change Spain 850 to 3 character currency symbol 'Pts'
; 21/Sep/90 Added Hungarian Country data and CodePage 852 Support
; 31/Oct/90 Amended Hungarian data
; 21/Nov/90 Corrected Hungarian Codepages 852 and 850
; 13/Dec/90 Corrected SpainCollating entries for 'Ä', 'á', '§', and '•'.
; 19/Dec/90 Use Collating850 for Spain and Denmark.
;
VALID_SIG	equ	0EDC1h

COMPATIBLE	equ	1
TURKCP		equ	857		; Turkish Code Page (853 or 857)
;
	eject	! include i:country.def
;
DGROUP	group	_DATA
_DATA	dseg	word 'DATA'
;
; File structure:   List of country information pointers
;			country code     dw	; Header words
;			code page number dw	; 
;                       unused    dw
;                       Data      dw ->  ; Pointer to 16 byte data area
;                       StdUcase  dw ->  ; Pointer to Std Uppercase table
;                       unused dw
;                       Ucase     dw ->  ; Pointer to Uppercase table
;                       FileChars dw ->  ; Pointer to legal file characters
;                       Collating dw ->  ; Pointer to collating table
;                       unused    dw
;
; ** IMPORTANT ** The list is sorted by country code, codepage and is 
;                 terminated by a record of nulls
;
;
;
; Copyright message such that it will be displayed if a user tries to 'type' the
; file. *NOTE* This message is of a fixed length, (3Fh) bytes.

	org	0
copyright:
	db	'COUNTRY.SYS R2.01  Copyright (c) 1988,1996 Caldera, Inc.'
	db	0Ah,0Dh,0
	db	01Ah		; End of file to stop 'type'.

	org	7Eh
	dw	VALID_SIG	; signature word

	org	80h
US_xlat		equ	0
Russian_xlat	equ	0
Turkish_xlat	equ	0
Canadian_xlat	equ	0
Dutch_xlat	equ	0
Belgian_xlat	equ	0
French_xlat	equ	0
Spanish_xlat	equ	0
Hungarian_xlat	equ	0
Italian_xlat	equ	0
Swiss_xlat	equ	0
UK_xlat		equ	0
Danish_xlat	equ	0
Swedish_xlat	equ	0
Norwegian_xlat	equ	0
German_xlat	equ	0
Australian_xlat	equ	0
Portugese_xlat	equ	0
Finish_xlat	equ	0
Arabic_xlat	equ	0
Jewish_xlat	equ	0
xlat_850	equ	0
Default_xlat	equ	0

;
;	The following array of country information contain all the 
;	predefined country data tables used by PCMODE.
;

UnitedStates:
	dw	1			; Country code
	dw	437			; Code page number
        dw	0
	dw	offset UnitedStatesData	; Data area
	dw	offset Ucasetbl		; Uppercase table
        dw	0
	dw	offset Ucasetbl		; Uppercase table
        dw	offset FileCharstbl	; File character table
	dw	offset Collatingtbl	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



UnitedStates850:
	dw	1			; Country code
	dw	850			; Code page number
        dw	0
	dw	offset UnitedStatesData850	; Data area
	dw	offset Ucasetbl850	; Uppercase table
        dw	0
	dw	offset Ucasetbl850	; Uppercase table
        dw	offset FileCharstbl	; File character table
	dw	offset Collating850	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



Canada:
	dw	2			; Country code
	dw	863			; Code page number
        dw	0
	dw	offset CanadaData	; Data area
	dw	offset CanadaUcase	; Standard Uppercase table
        dw	0
	dw	offset CanadaUcase	; Uppercase table
        dw	offset FileCharstbl	; File character table
	dw	offset CanadaCollating	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



Canada850:
	dw	2			; Country code
	dw	850			; Code page number
        dw	0
	dw	offset CanadaData850	; Data area
	dw	offset Ucasetbl850	; Standard Uppercase table
        dw	0
	dw	offset Ucasetbl850	; Uppercase table
        dw	offset FileCharstbl	; File character table
	dw	offset Collating850	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



LatinAmerica:
	dw	3			; Country code
	dw	437			; Code page number
        dw	0
	dw	offset LatinAmericaData	; Data area
	dw	offset Ucasetbl		; Uppercase table
        dw	0
	dw	offset Ucasetbl		; Uppercase table
        dw	offset FileCharstbl	; File character table
	dw	offset SpainCollating	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



LatinAmerica850:
	dw	3			; Country code
	dw	850			; Code page number
        dw	0
	dw	offset LatinAmericaData850	; Data area
	dw	offset LatiCase850	; Uppercase table
        dw	0
	dw	offset LatiCase850	; Uppercase table
        dw	offset FileCharstbl	; File character table
	dw	offset LatiCollating850	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



Russian:
	dw	7			; Country code
	dw	866			; Code page number
        dw	0
	dw	offset RussianData	; Data area
	dw	offset RussianUcase	; Standard Uppercase table
        dw	0
	dw	offset RussianUcase	; Uppercase table
        dw	offset FileCharstbl	; File character table
	dw	offset RussianCollating	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



Russian850:
	dw	7			; Country code
	dw	850			; Code page number
        dw	0
	dw	offset RussianData850	; Data area
	dw	offset Ucasetbl850	; Standard Uppercase table
        dw	0
	dw	offset Ucasetbl850	; Uppercase table
        dw	offset FileCharstbl	; File character table
	dw	offset Collating850	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



Netherlands:
	dw	31			; Country code
	dw	437			; Code page number
        dw	0
	dw	offset NetherlandsData	; Data area
	dw	offset NetherlandsUcase	; Standard Uppercase table
        dw	0
	dw	offset NetherlandsUcase	; Uppercase table
        dw	offset FileCharstbl	; File character table
	dw	offset NetherlandsCollating	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



Netherlands850:
	dw	31			; Country code
	dw	850			; Code page number
        dw	0
	dw	offset NetherlandsData850	; Data area
	dw	offset NethCase850	; Standard Uppercase table
        dw	0
	dw	offset NethCase850	; Uppercase table
        dw	offset FileCharstbl	; File character table
	dw	offset NethCollating850	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



Belgium:
	dw	32			; Country code
	dw	437			; Code page number
        dw	0
	dw	offset BelgiumData	; Data area
	dw	offset SwedenUcase	; Standard Uppercase table
        dw	0
	dw	offset SwedenUcase	; Uppercase table
        dw	offset FileCharstbl	; File character table
	dw	offset BelgiumCollating	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



Belgium850:
	dw	32			; Country code
	dw	850			; Code page number
        dw	0
	dw	offset BelgiumData850	; Data area
	dw	offset LatiCase850	; Standard Uppercase table
        dw	0
	dw	offset LatiCase850	; Uppercase table
        dw	offset FileCharstbl	; File character table
	dw	offset BelgCollating850	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



France:
	dw	33			; Country code
	dw	437			; Code page number
        dw	0
	dw	offset FranceData	; Data area
	dw	offset Ucasetbl		; Uppercase table
        dw	0
	dw	offset Ucasetbl		; Uppercase table
	dw	offset FileCharstbl	; File character table
	dw	offset Collatingtbl	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



France850:
	dw	33			; Country code
	dw	850			; Code page number
        dw	0
	dw	offset FranceData850	; Data area
	dw	offset Ucasetbl850	; Uppercase table
        dw	0
	dw	offset Ucasetbl850	; Uppercase table
	dw	offset FileCharstbl	; File character table
	dw	offset Collating850	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



Spain:
	dw	34			; Country code
	dw	437			; Code page number
        dw	0
	dw	offset SpainData	; Data area
	dw	offset Ucasetbl		; Uppercase table
        dw	0
	dw	offset Ucasetbl		; Uppercase table
	dw	offset FileCharstbl	; File character table
	dw	offset SpainCollating	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



Spain850:
	dw	34			; Country code
	dw	850			; Code page number
        dw	0
	dw	offset SpainData850	; Data area
	dw	offset LatiCase850	; Uppercase table
        dw	0
	dw	offset LatiCase850	; Uppercase table
	dw	offset FileCharstbl	; File character table
	dw	offset Collating850	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



Hungary:
	dw	36			; Country code
	dw	852			; Code page number
        dw	0
	dw	offset HungaryData	; Data area
	dw	offset HungaryUcase	; Uppercase table
        dw	0
	dw	offset HungaryUcase	; Uppercase table
	dw	offset FileCharstbl	; File character table
	dw	offset HungaryCollating	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



Hungary850:
	dw	36			; Country code
	dw	850			; Code page number
        dw	0
	dw	offset HungaryData850	; Data area
	dw	offset Ucasetbl850	; Uppercase table
        dw	0
	dw	offset Ucasetbl850	; Uppercase table
	dw	offset FileCharstbl	; File character table
	dw	offset Collating850	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



Italy:
	dw	39			; Country code
	dw	437			; Code page number
        dw	0
	dw	offset ItalyData	; Data area
	dw	offset Ucasetbl		; Uppercase table
        dw	0
	dw	offset Ucasetbl		; Uppercase table
	dw	offset FileCharstbl	; File character table
	dw	offset Collatingtbl	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



Italy850:
	dw	39			; Country code
	dw	850			; Code page number
        dw	0
	dw	offset ItalyData850	; Data area
	dw	offset Ucasetbl850	; Uppercase table
        dw	0
	dw	offset Ucasetbl850	; Uppercase table
	dw	offset FileCharstbl	; File character table
	dw	offset Collating850	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



Switzerland:
	dw	41			; Country code
	dw	437			; Code page number
        dw	0
	dw	offset SwitzerlandData	; Data area
	dw	offset SwitzerlandUcase	; Standard Uppercase table
        dw	0
	dw	offset SwitzerlandUcase	; Uppercase table
        dw	offset FileCharstbl	; File character table
	dw	offset SwitzerlandCollating	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



Switzerland850:
	dw	41			; Country code
	dw	850			; Code page number
        dw	0
	dw	offset SwitzerlandData850	; Data area
	dw	offset LatiCase850	; Standard Uppercase table
        dw	0
	dw	offset LatiCase850	; Uppercase table
        dw	offset FileCharstbl	; File character table
	dw	offset SwisCollating850	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



Czechoslovakia:
	dw	42			; Country code
	dw	852			; Code page number
        dw	0
	dw	offset CzechoslovakiaData	; Data area
	dw	offset CzecUcase	; Uppercase table
        dw	0
	dw	offset CzecUcase	; Uppercase table
	dw	offset FileCharstbl	; File character table
	dw	offset CzecCollating	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



Czechoslovakia850:
	dw	42			; Country code
	dw	850			; Code page number
        dw	0
	dw	offset CzechoslovakiaData850	; Data area
	dw	offset CzecUcase850	; Uppercase table
        dw	0
	dw	offset CzecUcase850	; Uppercase table
	dw	offset FileCharstbl	; File character table
	dw	offset CzecCollating850	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



Austria:
	dw	43			; Country code
	dw	437			; Code page number
        dw	0
	dw	offset AustriaData	; Data area
	dw	offset Ucasetbl		; Uppercase table
        dw	0
	dw	offset Ucasetbl		; Uppercase table
	dw	offset FileCharstbl	; File character table
	dw	offset Collatingtbl	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



Austria850:
	dw	43			; Country code
	dw	850			; Code page number
        dw	0
	dw	offset AustriaData850	; Data area
	dw	offset GermCase850	; Uppercase table
        dw	0
	dw	offset GermCase850	; Uppercase table
	dw	offset FileCharstbl	; File character table
	dw	offset Collating850	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



GreatBritain:
	dw	44			; Country code
	dw	437			; Code page number
	dw	0
	dw	offset GreatBritainData	; Data area
	dw	offset Ucasetbl		; Uppercase table
	dw	0
	dw	offset Ucasetbl		; Uppercase table
	dw	offset FileCharstbl	; File character table
	dw	offset Collatingtbl	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table
        


GreatBritain850:
	dw	44			; Country code
	dw	850			; Code page number
	dw	0
	dw	offset GreatBritainData850	; Data area
	dw	offset Ucasetbl850	; Uppercase table
	dw	0
	dw	offset Ucasetbl850	; Uppercase table
	dw	offset FileCharstbl	; File character table
	dw	offset Collating850	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table
        


Denmark:
	dw	45			; Country code
	dw	865			; Code page number
        dw	0
	dw	offset DenmarkData	; Data area
	dw	offset DenmarkUcase	; Standard Uppercase table
        dw	0
	dw	offset DenmarkUcase	; Uppercase table
	dw	offset FileCharstbl	; File character table
	dw	offset DenmarkCollating	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



Denmark850:
	dw	45			; Country code
	dw	850			; Code page number
        dw	0
	dw	offset DenmarkData850	; Data area
	dw	offset LatiCase850	; Standard Uppercase table
        dw	0
	dw	offset LatiCase850	; Uppercase table
	dw	offset FileCharstbl	; File character table
	dw	offset Collating850	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



Sweden:
	dw	46			; Country code
	dw	437			; Code page number
        dw	0
	dw	offset SwedenData	; Data area
	dw	offset SwedenUcase	; Standard Uppercase table
        dw	0
	dw	offset SwedenUcase	; Uppercase table
	dw	offset FileCharstbl	; File character table
	dw	offset SwedenCollating	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



Sweden850:
	dw	46			; Country code
	dw	850			; Code page number
        dw	0
	dw	offset SwedenData850	; Data area
	dw	offset LatiCase850	; Standard Uppercase table
        dw	0
	dw	offset LatiCase850	; Uppercase table
	dw	offset FileCharstbl	; File character table
	dw	offset SwedCollating850	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



Norway:
	dw	47			; Country code
	dw	865			; Code page number
        dw	0
	dw	offset NorwayData	; Data area
	dw	offset DenmarkUcase	; Standard Uppercase table
        dw	0
	dw	offset DenmarkUcase	; Uppercase table
        dw	offset FileCharstbl	; File character table
	dw	offset NorwayCollating	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



Norway850:
	dw	47			; Country code
	dw	850			; Code page number
        dw	0
	dw	offset NorwayData850	; Data area
	dw	offset LatiCase850	; Standard Uppercase table
        dw	0
	dw	offset LatiCase850	; Uppercase table
        dw	offset FileCharstbl	; File character table
	dw	offset NorwCollating850	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



Poland:
	dw	48			; Country code
	dw	852			; Code page number
        dw	0
	dw	offset PolandData	; Data area
	dw	offset PolandUcase	; Uppercase table
        dw	0
	dw	offset PolandData	; Uppercase table
	dw	offset FileCharstbl	; File character table
	dw	offset PolCollating	; Collating table
	dw	offset DBCS_tbl		; double byte char set range table



Poland850:
	dw	48			; Country code
	dw	850			; Code page number
        dw	0
	dw	offset PolandData850	; Data area
	dw	offset PolandUcase850	; Uppercase table
        dw	0
	dw	offset PolandUcase850	; Uppercase table
	dw	offset FileCharstbl	; File character table
	dw	offset PolCollating850	; Collating table
	dw	offset DBCS_tbl		; double byte char set range table



Germany:
	dw	49			; Country code
	dw	437			; Code page number
        dw	0
	dw	offset GermanyData	; Data area
	dw	offset Ucasetbl		; Uppercase table
        dw	0
	dw	offset Ucasetbl		; Uppercase table
	dw	offset FileCharstbl	; File character table
	dw	offset Collatingtbl	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



Germany850:
	dw	49			; Country code
	dw	850			; Code page number
        dw	0
	dw	offset GermanyData850	; Data area
	dw	offset GermCase850	; Uppercase table
        dw	0
	dw	offset GermCase850	; Uppercase table
	dw	offset FileCharstbl	; File character table
	dw	offset Collating850	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table


Brazil:
	dw	55			; Country code
	dw	437			; Code page number
        dw	0
	dw	offset BrazilData	; Data area
	dw	offset BrazilUcase	; Uppercase table
        dw	0
	dw	offset BrazilUcase	; Uppercase table
	dw	offset FileCharstbl	; File character table
	dw	offset BrazilCollating	; Collating table
	dw	offset DBCS_tbl		; double byte char set range table


Brazil850:
	dw	55			; Country code
	dw	850			; Code page number
        dw	0
	dw	offset BrazilData850	; Data area
	dw	offset BrazilUcase850	; Uppercase table
        dw	0
	dw	offset BrazilUcase850	; Uppercase table
	dw	offset FileCharstbl	; File character table
	dw	offset BrazilCollat850	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table


Australia:
	dw	61			; Country code
	dw	437			; Code page number
        dw	0
	dw	offset AustraliaData	; Data area
	dw	offset Ucasetbl		; Uppercase table
        dw	0
	dw	offset Ucasetbl		; Uppercase table
        dw	offset FileCharstbl	; File character table
	dw	offset Collatingtbl	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



Australia850:
	dw	61			; Country code
	dw	437			; Code page number
        dw	0
	dw	offset AustraliaData850	; Data area
	dw	offset Ucasetbl850	; Uppercase table
        dw	0
	dw	offset Ucasetbl850	; Uppercase table
        dw	offset FileCharstbl	; File character table
	dw	offset Collating850	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



Japan:
	dw	81			; Country code
	dw	437			; Code page number
        dw	0
	dw	offset JapanData	; Data area
	dw	offset Ucasetbl		; Uppercase table
        dw	0
	dw	offset Ucasetbl		; Uppercase table
        dw	offset FileCharstbl	; File character table
	dw	offset Collatingtbl	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



Japan932:
	dw	81			; Country code
	dw	932			; Code page number
        dw	0
	dw	offset JapanData932	; Data area
	dw	offset Ucasetbl932	; Uppercase table
        dw	0
	dw	offset Ucasetbl932	; Uppercase table
        dw	offset FileCharstbl	; File character table
	dw	offset Collating932	; Collating table
        dw	offset DBCS_932		; double byte char set range table



Korea:
	dw	82			; Country code
	dw	437			; Code page number
        dw	0
	dw	offset KoreaData	; Data area
	dw	offset Ucasetbl		; Uppercase table
        dw	0
	dw	offset Ucasetbl		; Uppercase table
        dw	offset FileCharstbl	; File character table
	dw	offset Collatingtbl	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



Korea934:
	dw	82			; Country code
	dw	934			; Code page number
        dw	0
	dw	offset KoreaData934	; Data area
	dw	offset Ucasetbl932	; Uppercase table
        dw	0
	dw	offset Ucasetbl932	; Uppercase table
        dw	offset FileCharstbl	; File character table
	dw	offset Collating934	; Collating table
        dw	offset DBCS_934		; double byte char set range table

Turkish:
	dw	90			; Country code
	dw	TURKCP			; Code page number
        dw	0
	dw	offset TurkishData	; Data area
	dw	offset TurkishUcase	; Standard Uppercase table
        dw	0
	dw	offset TurkishUcase	; Uppercase table
        dw	offset FileCharstbl	; File character table
	dw	offset TurkishCollating	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



Turkish850:
	dw	90			; Country code
	dw	850			; Code page number
        dw	0
	dw	offset TurkishData850	; Data area
	dw	offset Ucasetbl850	; Standard Uppercase table
        dw	0
	dw	offset Ucasetbl850	; Uppercase table
        dw	offset FileCharstbl	; File character table
	dw	offset Collating850	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



Portugal:
	dw	351			; Country code
	dw	860			; Code page number
        dw	0
	dw	offset PortugalData	; Data area
	dw	offset PortugalUcase	; Standard Uppercase table
        dw	0
	dw	offset PortugalUcase	; Uppercase table
        dw	offset FileCharstbl	; File character table
	dw	offset PortugalCollating	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



Portugal850:
	dw	351			; Country code
	dw	850			; Code page number
        dw	0
	dw	offset PortugalData850	; Data area
	dw	offset Ucasetbl850	; Standard Uppercase table
        dw	0
	dw	offset Ucasetbl850	; Uppercase table
        dw	offset FileCharstbl	; File character table
	dw	offset Collating850	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



Finland:
	dw	358			; Country code
	dw	437			; Code page number
        dw	0
	dw	offset FinlandData	; Data area
	dw	offset SwedenUcase	; Standard Uppercase table
        dw	0
	dw	offset SwedenUcase	; Uppercase table
        dw	offset FileCharstbl	; File character table
	dw	offset SwedenCollating	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



Finland850:
	dw	358			; Country code
	dw	850			; Code page number
        dw	0
	dw	offset FinlandData850	; Data area
	dw	offset LatiCase850	; Standard Uppercase table
        dw	0
	dw	offset LatiCase850	; Uppercase table
        dw	offset FileCharstbl	; File character table
	dw	offset FinlCollating850	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



MiddleEast:
	dw	785			; Country code
	dw	864			; Code page number
        dw	0
	dw	offset MiddleEastData	; Data area
	dw	offset Ucasetbl		; Uppercase table
        dw	0
	dw	offset Ucasetbl		; Uppercase table
        dw	offset FileCharstbl	; File character table
	dw	offset MiddleEastCollating	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



MiddleEast850:
	dw	785			; Country code
	dw	850			; Code page number
        dw	0
	dw	offset MiddleEastData850	; Data area
	dw	offset Ucasetbl850	; Uppercase table
        dw	0
	dw	offset Ucasetbl850	; Uppercase table
        dw	offset FileCharstbl	; File character table
	dw	offset Collating850	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



Israel:
	dw	972			; Country code
	dw	862			; Code page number
        dw	0
	dw	offset IsraelData	; Data area
	dw	offset IsraelUcase	; Standard Uppercase table
        dw	0
	dw	offset IsraelUcase	; Uppercase table
        dw	offset FileCharstbl	; File character table
	dw	offset IsraelCollating	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



Israel850:
	dw	972			; Country code
	dw	850			; Code page number
        dw	0
	dw	offset IsraelData850	; Data area
	dw	offset Ucasetbl850	; Standard Uppercase table
        dw	0
	dw	offset Ucasetbl850	; Uppercase table
        dw	offset FileCharstbl	; File character table
	dw	offset Collating850	; Collating table
        dw	offset DBCS_tbl		; double byte char set range table



LastEntry:
	dw	0			; Country code
	dw	0			; Code page number
        dw	0
	dw	0			; Data area
	dw	0			; Standard Uppercase table
        dw	0
	dw	0			; Uppercase table
        dw	0			; File character table
	dw	0			; Collating table
        dw	0			; double byte char set range table


;		Country Data for UnitedStates (Code - 1)
UnitedStatesData:
	dw	1		; Country Code
	dw	437		; Code Page
	dw	US_DATE		; Date Format (Binary)
	db	'$',0,0,0,0	; Currency Symbol
	db	',',0		; Thousands Separator
	db	'.',0		; Decimal Separator
	db	'-',0		; Date Separator
	db	':',0		; Time Separator
	db	0		; Symbol before Value without Space ($n.nn)
	db	2		; Significant Currency Digits
	db	CLOCK_12	; Time Format
	dw	US_xlat		; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	',',0		; Data List Separator


UnitedStatesData850:
	dw	1		; Country Code
	dw	850		; Code Page
	dw	US_DATE		; Date Format (Binary)
	db	'$',0,0,0,0	; Currency Symbol
	db	',',0		; Thousands Separator
	db	'.',0		; Decimal Separator
	db	'-',0		; Date Separator
	db	':',0		; Time Separator
	db	0		; Symbol before Value without Space ($n.nn)
	db	2		; Significant Currency Digits
	db	CLOCK_12	; Time Format
	dw	xlat_850	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	',',0		; Data List Separator

;		Country Data for Canada (Code - 2)
CanadaData850:
	dw	2		; Country Code
	dw	850		; Code Page
	dw	JAP_DATE	; Date Format (Binary)
	db	'$',0,0,0,0	; Currency Symbol
	db	' ',0		; Thousands Separator
	db	',',0		; Decimal Separator
	db	'-',0		; Date Separator
	db	':',0		; Time Separator
	db	3		; Symbol after Value with Space (n.nn $)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	xlat_850	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	';',0		; Data List Separator


;		Country Data for Canada (Code - 2)
CanadaData:
	dw	2		; Country Code
	dw	863		; Code Page
	dw	JAP_DATE	; Date Format (Binary)
	db	'$',0,0,0,0	; Currency Symbol
	db	' ',0		; Thousands Separator
	db	',',0		; Decimal Separator
	db	'-',0		; Date Separator
	db	':',0		; Time Separator
	db	3		; Symbol after Value with Space (n.nn $)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	Canadian_xlat	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	';',0		; Data List Separator


;		Country Data for LatinAmerica (Code - 3)
LatinAmericaData:
	dw	3		; Country Code
	dw	437		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	'$',0,0,0,0	; Currency Symbol
	db	',',0		; Thousands Separator
	db	'.',0		; Decimal Separator
	db	'/',0		; Date Separator
	db	':',0		; Time Separator
	db	0		; Symbol before Value without Space ($n.nn)
	db	2		; Significant Currency Digits
	db	CLOCK_12	; Time Format
	dw	Default_xlat	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	',',0		; Data List Separator


;		Country Data for LatinAmerica (Code - 3)
LatinAmericaData850:
	dw	3		; Country Code
	dw	850		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	'$',0,0,0,0	; Currency Symbol
	db	',',0		; Thousands Separator
	db	'.',0		; Decimal Separator
	db	'/',0		; Date Separator
	db	':',0		; Time Separator
	db	0		; Symbol before Value without Space ($n.nn)
	db	2		; Significant Currency Digits
	db	CLOCK_12	; Time Format
	dw	xlat_850	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	',',0		; Data List Separator


RussianData850:		; ##JC##
	dw	7		; Country Code
	dw	850		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	' rub.'		; Currency Symbol
	db	' ',0		; Thousands Separator
	db	'.',0		; Decimal Separator
	db	'/',0		; Date Separator
	db	':',0		; Time Separator
	db	3		; Symbol after Value with Space (n.nn $)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	Russian_xlat	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	';',0		; Data List Separator


;		Country Data for Russia (Code - 7)
RussianData:
	dw	7		; Country Code
	dw	866		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	'˝',0,0,0,0	; Currency Symbol
	db	' ',0		; Thousands Separator
	db	'.',0		; Decimal Separator
	db	'/',0		; Date Separator
	db	':',0		; Time Separator
	db	0		; Symbol before Value without Space ($n.nn)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	Russian_xlat	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	';',0		; Data List Separator


;		Country Data for Netherlands (Code - 31)
NetherlandsData:
	dw	31		; Country Code
	dw	437		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	159,0,0,0,0	; Currency Symbol
	db	'.',0		; Thousands Separator
	db	',',0		; Decimal Separator
	db	'-',0		; Date Separator
	db	':',0		; Time Separator
	db	2		; Symbol before Value with Space ($ n.nn)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	Dutch_xlat	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	';',0		; Data List Separator


;		Country Data for Netherlands (Code - 31)
NetherlandsData850:
	dw	31		; Country Code
	dw	850		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	159,0,0,0,0	; Currency Symbol
	db	'.',0		; Thousands Separator
	db	',',0		; Decimal Separator
	db	'-',0		; Date Separator
	db	':',0		; Time Separator
	db	2		; Symbol before Value with Space ($ n.nn)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	xlat_850	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	';',0		; Data List Separator


;		Country Data for Belgium (Code - 32)
BelgiumData:
	dw	32		; Country Code
	dw	437		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	'BF',0,0,0	; Currency Symbol
	db	'.',0		; Thousands Separator
	db	',',0		; Decimal Separator
	db	'/',0		; Date Separator
	db	':',0		; Time Separator
	db	2		; Symbol before Value with Space ($ n.nn)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	Belgian_xlat	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	';',0		; Data List Separator


;		Country Data for Belgium (Code - 32)
BelgiumData850:
	dw	32		; Country Code
	dw	850		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	'BF',0,0,0	; Currency Symbol
	db	'.',0		; Thousands Separator
	db	',',0		; Decimal Separator
	db	'/',0		; Date Separator
	db	':',0		; Time Separator
	db	2		; Symbol before Value with Space ($ n.nn)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	xlat_850	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	';',0		; Data List Separator


;		Country Data for France (Code - 33)
FranceData:
	dw	33		; Country Code
	dw	437		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	'F',0,0,0,0	; Currency Symbol
	db	' ',0		; Thousands Separator
	db	',',0		; Decimal Separator
	db	'.',0		; Date Separator
	db	':',0		; Time Separator
	db	3		; Symbol after Value with Space (n.nn $)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	French_xlat	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	';',0		; Data List Separator



;		Country Data for France (Code - 33)
FranceData850:
	dw	33		; Country Code
	dw	850		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	'F',0,0,0,0	; Currency Symbol
	db	' ',0		; Thousands Separator
	db	',',0		; Decimal Separator
	db	'.',0		; Date Separator
	db	':',0		; Time Separator
	db	3		; Symbol after Value with Space (n.nn $)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	xlat_850	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	';',0		; Data List Separator



;		Country Data for Spain (Code - 34)
SpainData:
	dw	34		; Country Code
	dw	437		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	158,0,0,0,0	; Currency Symbol
	db	'.',0		; Thousands Separator
	db	',',0		; Decimal Separator
	db	'/',0		; Date Separator
	db	':',0		; Time Separator
	db	2		; Symbol before Value with Space ($ n.nn)
	db	0		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	Spanish_xlat	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	';',0		; Data List Separator


;		Country Data for Spain (Code - 34)
SpainData850:
	dw	34		; Country Code
	dw	850		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	'Pts',0,0	; Currency Symbol
	db	'.',0		; Thousands Separator
	db	',',0		; Decimal Separator
	db	'/',0		; Date Separator
	db	':',0		; Time Separator
	db	2		; Symbol before Value with Space ($ n.nn)
	db	0		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	xlat_850	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	';',0		; Data List Separator


;		Country Data for Hungary (Code - 36)
HungaryData:
	dw	36		; Country Code
	dw	852		; Code Page
	dw	JAP_DATE	; Date Format (Binary)
	db	'Ft',0,0,0	; Currency Symbol
	db	' ',0		; Thousands Separator
	db	',',0		; Decimal Separator
	db	'.',0		; Date Separator
	db	':',0		; Time Separator
	db	3		; Symbol after Value with Space (n.nn $)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	Hungarian_xlat	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	';',0		; Data List Separator


;		Country Data for Hungary (Code - 36)
HungaryData850:
	dw	36		; Country Code
	dw	850		; Code Page
	dw	JAP_DATE	; Date Format (Binary)
	db	'Ft',0,0,0	; Currency Symbol
	db	' ',0		; Thousands Separator
	db	',',0		; Decimal Separator
	db	'.',0		; Date Separator
	db	':',0		; Time Separator
	db	3		; Symbol after Value with Space (n.nn $)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	xlat_850	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	';',0		; Data List Separator


;		Country Data for Italy (Code - 39)
ItalyData:
	dw	39		; Country Code
	dw	437		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	'L.',0,0,0	; Currency Symbol
	db	'.',0		; Thousands Separator
	db	',',0		; Decimal Separator
	db	'/',0		; Date Separator
	db	'.',0		; Time Separator
	db	2		; Symbol before Value with Space ($ n.nn)
	db	0		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	Italian_xlat	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	';',0		; Data List Separator


;		Country Data for Italy (Code - 39)
ItalyData850:
	dw	39		; Country Code
	dw	850		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	'L.',0,0,0	; Currency Symbol
	db	'.',0		; Thousands Separator
	db	',',0		; Decimal Separator
	db	'.',0		; Date Separator
	db	':',0		; Time Separator
	db	2		; Symbol before Value with Space ($ n.nn)
	db	0		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	xlat_850	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	';',0		; Data List Separator



;		Country Data for Switzerland (Code - 41)
SwitzerlandData:
	dw	41		; Country Code
	dw	437		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	'Fr.',0,0	; Currency Symbol
	db	39,0		; Thousands Separator
	db	'.',0		; Decimal Separator
	db	'.',0		; Date Separator
	db	',',0		; Time Separator
	db	2		; Symbol before Value with Space ($ n.nn)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	Swiss_xlat	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	';',0		; Data List Separator

;		Country Data for Switzerland (Code - 41)
SwitzerlandData850:
	dw	41		; Country Code
	dw	850		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	'Fr.',0,0	; Currency Symbol
	db	39,0		; Thousands Separator
	db	'.',0		; Decimal Separator
	db	'.',0		; Date Separator
	db	',',0		; Time Separator
	db	2		; Symbol before Value with Space ($ n.nn)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	xlat_850	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	';',0		; Data List Separator


;		Country Data for Czechoslovakia (Code - 42)
CzechoslovakiaData:
	dw	42		; Country Code
	dw	852		; Code Page
	dw	JAP_DATE	; Date Format (Binary)
	db	'K',159,'s',0,0	; Currency Symbol
	db	'.',0		; Thousands Separator
	db	',',0		; Decimal Separator
	db	'-',0		; Date Separator
	db	':',0		; Time Separator
	db	2		; Symbol before Value without Space ($n.nn)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	US_xlat		; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	',',0		; Data List Separator


CzechoslovakiaData850:
	dw	42		; Country Code
	dw	850		; Code Page
	dw	JAP_DATE	; Date Format (Binary)
	db	'K',159,'s',0,0	; Currency Symbol
	db	'.',0		; Thousands Separator
	db	',',0		; Decimal Separator
	db	'-',0		; Date Separator
	db	':',0		; Time Separator
	db	2		; Symbol before Value without Space ($n.nn)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	xlat_850	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	',',0		; Data List Separator


;		Country Data for Austria (Code - 43)
AustriaData:
	dw	43		; Country Code
	dw	437		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	'ôS',0,0,0	; Currency Symbol
	db	'.',0		; Thousands Separator
	db	',',0		; Decimal Separator
	db	'.',0		; Date Separator
	db	'.',0		; Time Separator
	db	2		; Symbol before Value with Space ($ n.nn)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	German_xlat	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	';',0		; Data List Separator

;		Country Data for Austrian (Code - 43)
AustriaData850:
	dw	43		; Country Code
	dw	850		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	'ôS',0,0,0	; Currency Symbol
	db	'.',0		; Thousands Separator
	db	',',0		; Decimal Separator
	db	'.',0		; Date Separator
	db	'.',0		; Time Separator
	db	2		; Symbol before Value with Space ($ n.nn)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	xlat_850	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	';',0		; Data List Separator


;		Country Data for GreatBritain (Code - 44)

GreatBritainData:
	dw	44		; Country Code
	dw	437		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	156,0,0,0,0	; Currency Symbol
	db	',',0		; Thousands Separator
	db	'.',0		; Decimal Separator
	db	'/',0		; Date Separator
	db	':',0		; Time Separator
	db	0		; Symbol before Value without Space ($n.nn)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	UK_xlat		; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	',',0		; Data List Separator


;		Country Data for GreatBritain (Code - 44)

GreatBritainData850:
	dw	44		; Country Code
	dw	850		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	156,0,0,0,0	; Currency Symbol
	db	',',0		; Thousands Separator
	db	'.',0		; Decimal Separator
	db	'/',0		; Date Separator
	db	':',0		; Time Separator
	db	0		; Symbol before Value without Space ($n.nn)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	xlat_850		; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	',',0		; Data List Separator


;		Country Data for Denmark (Code - 45)
DenmarkData:
	dw	45		; Country Code
	dw	865		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	'kr',0,0,0	; Currency Symbol
	db	'.',0		; Thousands Separator
	db	',',0		; Decimal Separator
	db	'-',0		; Date Separator
	db	'.',0		; Time Separator
	db	2		; Symbol before Value with Space ($ n.nn)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	Danish_xlat	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	';',0		; Data List Separator


;		Country Data for Denmark (Code - 45)
DenmarkData850:
	dw	45		; Country Code
	dw	850		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	'kr',0,0,0	; Currency Symbol
	db	'.',0		; Thousands Separator
	db	',',0		; Decimal Separator
	db	'-',0		; Date Separator
	db	'.',0		; Time Separator
	db	2		; Symbol before Value with Space ($ n.nn)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	xlat_850	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	';',0		; Data List Separator


;		Country Data for Sweden (Code - 46)
SwedenData:
	dw	46		; Country Code
	dw	437		; Code Page
	dw	JAP_DATE	; Date Format (Binary)
	db	'Kr',0,0,0	; Currency Symbol
	db	' ',0		; Thousands Separator
	db	',',0		; Decimal Separator
	db	'-',0		; Date Separator
	db	'.',0		; Time Separator
	db	3		; Symbol after Value with Space (n.nn $)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	Swedish_xlat	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	';',0		; Data List Separator


;		Country Data for Sweden (Code - 46)
SwedenData850:
	dw	46		; Country Code
	dw	850		; Code Page
	dw	JAP_DATE	; Date Format (Binary)
	db	'Kr',0,0,0	; Currency Symbol
	db	' ',0		; Thousands Separator
	db	',',0		; Decimal Separator
	db	'-',0		; Date Separator
	db	'.',0		; Time Separator
	db	3		; Symbol after Value with Space (n.nn $)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	xlat_850	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	';',0		; Data List Separator


;		Country Data for Norway (Code - 47)
NorwayData:
	dw	47		; Country Code
	dw	865		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	'Kr',0,0,0	; Currency Symbol
	db	'.',0		; Thousands Separator
	db	',',0		; Decimal Separator
	db	'.',0		; Date Separator
	db	':',0		; Time Separator
	db	2		; Symbol before Value with Space ($ n.nn)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	Norwegian_xlat	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	';',0		; Data List Separator


;		Country Data for Norway (Code - 47)
NorwayData850:
	dw	47		; Country Code
	dw	850		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	'Kr',0,0,0	; Currency Symbol
	db	'.',0		; Thousands Separator
	db	',',0		; Decimal Separator
	db	'.',0		; Date Separator
	db	':',0		; Time Separator
	db	2		; Symbol before Value with Space ($ n.nn)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	xlat_850	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	';',0		; Data List Separator


;		Country Data for Poland (Code - 48)
PolandData:
	dw	48		; Country Code
	dw	852		; Code Page
	dw	JAP_DATE	; Date Format (Binary)
	db	'Z',136,0,0,0	; Currency Symbol
	db	'.',0		; Thousands Separator
	db	',',0		; Decimal Separator
	db	'-',0		; Date Separator
	db	':',0		; Time Separator
	db	0		; Symbol before Value without Space ($n.nn)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	US_xlat		; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	',',0		; Data List Separator


PolandData850:
	dw	48		; Country Code
	dw	850		; Code Page
	dw	JAP_DATE	; Date Format (Binary)
	db	'Z',136,0,0,0	; Currency Symbol
	db	'.',0		; Thousands Separator
	db	',',0		; Decimal Separator
	db	'-',0		; Date Separator
	db	':',0		; Time Separator
	db	0		; Symbol before Value without Space ($n.nn)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	xlat_850	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	',',0		; Data List Separator


;		Country Data for Germany (Code - 49)
GermanyData:
	dw	49		; Country Code
	dw	437		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	'DM',0,0,0	; Currency Symbol
	db	'.',0		; Thousands Separator
	db	',',0		; Decimal Separator
	db	'.',0		; Date Separator
	db	':',0		; Time Separator
	db	0		; Symbol before Value without Space ($n.nn)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	German_xlat	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	';',0		; Data List Separator



;		Country Data for Germany (Code - 49)
GermanyData850:
	dw	49		; Country Code
	dw	850		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	'DM',0,0,0	; Currency Symbol
	db	'.',0		; Thousands Separator
	db	',',0		; Decimal Separator
	db	'.',0		; Date Separator
	db	'.',0		; Time Separator
	db	0		; Symbol before Value without Space ($n.nn)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	xlat_850	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	';',0		; Data List Separator



;		Country Data for Brazil (Code - 55)
BrazilData:
	dw	55		; Country Code
	dw	437		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	'Cr$',0,0	; Currency Symbol
	db	'.',0		; Thousands Separator
	db	',',0		; Decimal Separator
	db	'/',0		; Date Separator
	db	':',0		; Time Separator
	db	2		; Symbol before Value with Space ($ n.nn)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	Default_xlat	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	';',0		; Data List Separator



;		Country Data for Brazil (Code - 55)
BrazilData850:
	dw	55		; Country Code
	dw	850		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	'Cr$',0,0	; Currency Symbol
	db	'.',0		; Thousands Separator
	db	',',0		; Decimal Separator
	db	'/',0		; Date Separator
	db	':',0		; Time Separator
	db	2		; Symbol before Value with Space ($ n.nn)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	xlat_850	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	';',0		; Data List Separator



;		Country Data for Australia (Code - 61)
AustraliaData:
	dw	61		; Country Code
	dw	437		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	'$',0,0,0,0	; Currency Symbol
	db	',',0		; Thousands Separator
	db	'.',0		; Decimal Separator
	db	'-',0		; Date Separator
	db	':',0		; Time Separator
	db	0		; Symbol before Value without Space ($n.nn)
	db	2		; Significant Currency Digits
	db	CLOCK_12	; Time Format
	dw	Australian_xlat	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	',',0		; Data List Separator



;		Country Data for Australia (Code - 61)
AustraliaData850:
	dw	61		; Country Code
	dw	850		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	'$',0,0,0,0	; Currency Symbol
	db	',',0		; Thousands Separator
	db	'.',0		; Decimal Separator
	db	'-',0		; Date Separator
	db	':',0		; Time Separator
	db	0		; Symbol before Value without Space ($n.nn)
	db	2		; Significant Currency Digits
	db	CLOCK_12	; Time Format
	dw	xlat_850	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	',',0		; Data List Separator



;		Country Data for Japan (Code - 81)
JapanData:
	dw	81		; Country Code
	dw	437
	dw	JAP_DATE	; Date Format (Binary)
;;	db	05Ch,0,0,0,0	; 'ù' Currency Symbol (NEC 9801 Character Set)
	db	09Dh,0,0,0,0	; 'ù' Currency Symbol (IBM CodePage 437)
	db	',',0		; Thousands Separator
	db	'.',0		; Decimal Separator
	db	'-',0		; Date Separator
	db	':',0		; Time Separator
	db	0		; Symbol after Value with Space (n.nn $)
	db	0		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	Default_xlat	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	',',0		; Data List Separator


;		Country Data for Japan (Code - 81)
JapanData932:
	dw	81		; Country Code
	dw	932
	dw	JAP_DATE	; Date Format (Binary)
	db	05Ch,0,0,0,0	; 'ù' Currency Symbol (NEC 9801 Character Set)
;;	db	09Dh,0,0,0,0	; 'ù' Currency Symbol (IBM CodePage 437)
	db	',',0		; Thousands Separator
	db	'.',0		; Decimal Separator
	db	'-',0		; Date Separator
	db	':',0		; Time Separator
	db	0		; Symbol after Value with Space (n.nn $)
	db	0		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	Default_xlat	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	',',0		; Data List Separator


;		Country Data for Korea (Code - 82)
KoreaData:
	dw	82		; Country Code
	dw	437
	dw	JAP_DATE	; Date Format (Binary)
	db	05Ch,0,0,0,0	; 'W' with two horizontal lines through
;;	db	09Dh,0,0,0,0	; 'ù' Currency Symbol (IBM CodePage 437)
	db	',',0		; Thousands Separator
	db	'.',0		; Decimal Separator
	db	'.',0		; Date Separator
	db	':',0		; Time Separator
	db	0		; Symbol after Value with Space (n.nn $)
	db	0		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	Default_xlat	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	',',0		; Data List Separator


;		Country Data for Korea (Code - 82)
KoreaData934:
	dw	82		; Country Code
	dw	934
	dw	JAP_DATE	; Date Format (Binary)
	db	05Ch,0,0,0,0	; 'W' with two horizontal lines through
;;	db	09Dh,0,0,0,0	; 'ù' Currency Symbol (IBM CodePage 437)
	db	',',0		; Thousands Separator
	db	'.',0		; Decimal Separator
	db	'.',0		; Date Separator
	db	':',0		; Time Separator
	db	0		; Symbol after Value with Space (n.nn $)
	db	0		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	Default_xlat	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	',',0		; Data List Separator


;		Country Data for Turkey (Code - 90)
TurkishData:
	dw	90		; Country Code
	dw	TURKCP		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	'TL',0,0,0	; Currency Symbol
	db	'.',0		; Thousands Separator
	db	',',0		; Decimal Separator
	db	'/',0		; Date Separator
	db	':',0		; Time Separator
	db	4		; Symbol in middle Value without Space (n$nn)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	Turkish_xlat	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	',',0		; Data List Separator


;		Country Data for Turkey (Code - 90)
TurkishData850:
	dw	90		; Country Code
	dw	850		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	'TL',0,0,0	; Currency Symbol
	db	'.',0		; Thousands Separator
	db	',',0		; Decimal Separator
	db	'/',0		; Date Separator
	db	':',0		; Time Separator
	db	4		; Symbol in middle Value without Space (n$nn)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	Turkish_xlat	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	',',0		; Data List Separator


;		Country Data for Portugal (Code - 351)
PortugalData850:
	dw	351		; Country Code
	dw	850		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	'Esc.',0	; Currency Symbol
	db	'.',0		; Thousands Separator
	db	',',0		; Decimal Separator
	db	'/',0		; Date Separator
	db	':',0		; Time Separator
	db	3		; Symbol after Value with Space (n.nn $)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	xlat_850	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	';',0		; Data List Separator


;		Country Data for Portugal (Code - 351)
PortugalData:
	dw	351		; Country Code
	dw	860		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	'Esc.',0	; Currency Symbol
	db	'.',0		; Thousands Separator
	db	',',0		; Decimal Separator
	db	'-',0		; Date Separator
	db	':',0		; Time Separator
	db	3		; Symbol after Value with Space (n.nn $)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	Portugese_xlat	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	';',0		; Data List Separator


;		Country Data for Finland (Code - 358)
FinlandData:
	dw	358		; Country Code
	dw	437		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	'mk',0,0,0	; Currency Symbol
	db	' ',0		; Thousands Separator
	db	',',0		; Decimal Separator
	db	'.',0		; Date Separator
	db	'.',0		; Time Separator
	db	3		; Symbol after Value with Space (n.nn $)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	Finish_xlat	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	';',0		; Data List Separator



;		Country Data for Finland (Code - 358)
FinlandData850:
	dw	358		; Country Code
	dw	850		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	'mk',0,0,0	; Currency Symbol
	db	' ',0		; Thousands Separator
	db	',',0		; Decimal Separator
	db	'.',0		; Date Separator
	db	'.',0		; Time Separator
	db	3		; Symbol after Value with Space (n.nn $)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	xlat_850	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	';',0		; Data List Separator



;		Country Data for MiddleEast (Code - 785)
MiddleEastData850:
	dw	785		; Country Code
	dw	850		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	207,0,0,0,0	; Currency Symbol
	db	'.',0		; Thousands Separator
	db	',',0		; Decimal Separator
	db	'/',0		; Date Separator
	db	':',0		; Time Separator
	db	3		; Symbol after Value with Space (n.nn $)
	db	3		; Significant Currency Digits
	db	CLOCK_12	; Time Format
	dw	xlat_850	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	';',0		; Data List Separator


;		Country Data for MiddleEast (Code - 785)
MiddleEastData:
	dw	785		; Country Code
	dw	864		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	164,0,0,0,0	; Currency Symbol
	db	'.',0		; Thousands Separator
	db	',',0		; Decimal Separator
	db	'/',0		; Date Separator
	db	':',0		; Time Separator
	db	3		; Symbol after Value with Space (n.nn $)
	db	3		; Significant Currency Digits
	db	CLOCK_12	; Time Format
	dw	Arabic_xlat	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	';',0		; Data List Separator


;		Country Data for Israel (Code - 972)
IsraelData850:
	dw	972		; Country Code
	dw	850		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	153,0,0,0,0	; Currency Symbol
	db	',',0		; Thousands Separator
	db	'.',0		; Decimal Separator
	db	' ',0		; Date Separator
	db	':',0		; Time Separator
	db	2		; Symbol before Value with Space ($ n.nn)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	xlat_850	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	',',0		; Data List Separator

;		Country Data for Israel (Code - 972)
IsraelData:
	dw	972		; Country Code
	dw	862		; Code Page
	dw	EURO_DATE	; Date Format (Binary)
	db	153,0,0,0,0	; Currency Symbol
	db	',',0		; Thousands Separator
	db	'.',0		; Decimal Separator
	db	' ',0		; Date Separator
	db	':',0		; Time Separator
	db	2		; Symbol before Value with Space ($ n.nn)
	db	2		; Significant Currency Digits
	db	CLOCK_24	; Time Format
	dw	Jewish_xlat	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	',',0		; Data List Separator

	dw	0		; End of Country Data Marker

if COMPATIBLE
Ucasetbl:
else
Ucasetbl:
NetherlandsUcase:
SwedenUcase:
SwitzerlandUcase:
endif
		dw  128	; Table Size
standard_table	db	080h, 09ah
if COMPATIBLE
		db	'E'
else	
		db	090h
endif
	db  			   'A', 08eh,  'A', 08fh, 080h
	db	 'E',  'E',  'E',  'I',  'I',  'I', 08eh, 08fh
	db	090h, 092h, 092h,  'O', 099h,  'O',  'U',  'U'
	db	 'Y', 099h, 09ah, 09bh, 09ch, 09dh, 09eh, 09fh
	db	 'A',  'I',  'O',  'U', 0a5h
	db	0a5h, 0a6h, 0a7h
	db	0a8h, 0a9h, 0aah, 0abh, 0ach, 0adh, 0aeh, 0afh
	db	0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 0b5h, 0b6h, 0b7h
	db	0b8h, 0b9h, 0bah, 0bbh, 0bch, 0bdh, 0beh, 0bfh
	db	0c0h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 0c6h, 0c7h
	db	0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 0cfh
	db	0d0h, 0d1h, 0d2h, 0d3h, 0d4h, 0d5h, 0d6h, 0d7h
	db	0d8h, 0d9h, 0dah, 0dbh, 0dch, 0ddh, 0deh, 0dfh
	db	0e0h, 0e1h, 0e2h, 0e3h, 0e4h, 0e5h, 0e6h, 0e7h
	db	0e8h, 0e9h, 0eah, 0ebh, 0ech, 0edh, 0eeh, 0efh
	db	0f0h, 0f1h, 0f2h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h
	db	0f8h, 0f9h, 0fah, 0fbh, 0fch, 0fdh, 0feh, 0ffh
info2_len	equ	word ptr (offset $ - offset Ucasetbl)

FileCharstbl:
		dw  22	; Table Size
	db	 001h, 000h, 0ffh, 000h, 000h, 020h, 002h, 00eh
	db	 02eh, 022h, 02fh, 05ch, 05bh, 05dh, 03ah, 07ch
	db	 03ch, 03eh, 02bh, 03dh, 03bh, 02ch
info5_len	equ	word ptr (offset $ - offset FileCharstbl)

Collatingtbl:
		dw  256	; Table Size
	db	 000h, 001h, 002h, 003h, 004h, 005h, 006h, 007h
	db	 008h, 009h, 00ah, 00bh, 00ch, 00dh, 00eh, 00fh
	db	 010h, 011h, 012h, 013h, 014h, 015h, 016h, 017h
	db	 018h, 019h, 01ah, 01bh, 01ch, 01dh, 01eh, 01fh
	db	 020h, 021h, 022h, 023h, 024h, 025h, 026h, 027h
	db	 028h, 029h, 02ah, 02bh, 02ch, 02dh, 02eh, 02fh
	db	 030h, 031h, 032h, 033h, 034h, 035h, 036h, 037h
	db	 038h, 039h, 03ah, 03bh, 03ch, 03dh, 03eh, 03fh
	db	 040h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 05bh, 05ch, 05dh, 05eh, 05fh
	db	 060h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 07bh, 07ch, 07dh, 07eh, 07fh
	db	 043h, 055h, 045h, 041h, 041h, 041h, 041h, 043h
	db	 045h, 045h, 045h, 049h, 049h, 049h, 041h, 041h
	db	 045h, 041h, 041h, 04fh, 04fh, 04fh, 055h, 055h
	db	 059h, 04fh, 055h, 024h, 024h, 024h, 024h, 024h
	db	 041h, 049h, 04fh, 055h, 04eh, 04eh, 0a6h, 0a7h
	db	 03fh, 0a9h, 0aah, 0abh, 0ach, 021h, 022h, 022h
	db	 0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 0b5h, 0b6h, 0b7h
	db	 0b8h, 0b9h, 0bah, 0bbh, 0bch, 0bdh, 0beh, 0bfh
	db	 0c0h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 0c6h, 0c7h
	db	 0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 0cfh
	db	 0d0h, 0d1h, 0d2h, 0d3h, 0d4h, 0d5h, 0d6h, 0d7h
	db	 0d8h, 0d9h, 0dah, 0dbh, 0dch, 0ddh, 0deh, 0dfh
	db	 0e0h, 053h, 0e2h, 0e3h, 0e4h, 0e5h, 0e6h, 0e7h
	db	 0e8h, 0e9h, 0eah, 0ebh, 0ech, 0edh, 0eeh, 0efh
	db	 0f0h, 0f1h, 0f2h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h
	db	 0f8h, 0f9h, 0fah, 0fbh, 0fch, 0fdh, 0feh, 0ffh
info6_len	equ	word ptr (offset $ - offset Collatingtbl)

DBCS_tbl:
		dw	0	; Table Size
	db	 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
	db	 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
info7_len	equ	word ptr (offset $ - offset DBCS_tbl)


Collating850:
		dw	256	; Table Size
	db	 000h, 001h, 002h, 003h, 004h, 005h, 006h, 007h
	db	 008h, 009h, 00ah, 00bh, 00ch, 00dh, 00eh, 00fh
	db	 010h, 011h, 012h, 013h, 014h, 015h, 016h, 017h
	db	 018h, 019h, 01ah, 01bh, 01ch, 01dh, 01eh, 01fh
	db	 020h, 021h, 022h, 023h, 024h, 025h, 026h, 027h
	db	 028h, 029h, 02ah, 02bh, 02ch, 02dh, 02eh, 02fh
	db	 030h, 031h, 032h, 033h, 034h, 035h, 036h, 037h
	db	 038h, 039h, 03ah, 03bh, 03ch, 03dh, 03eh, 03fh
	db	 040h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 05bh, 05ch, 05dh, 05eh, 05fh
	db	 060h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 07bh, 07ch, 07dh, 07eh, 07fh
	db	 043h, 055h, 045h, 041h, 041h, 041h, 041h, 043h
	db	 045h, 045h, 045h, 049h, 049h, 049h, 041h, 041h
	db	 045h, 041h, 041h, 04fh, 04fh, 04fh, 055h, 055h
	db	 059h, 04fh, 055h, 04fh, 024h, 04fh, 09eh, 024h
	db	 041h, 049h, 04fh, 055h, 04eh, 04eh, 0a6h, 0a7h
	db	 03fh, 0a9h, 0aah, 0abh, 0ach, 021h, 022h, 022h
	db	 0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 041h, 041h, 041h
	db	 0b8h, 0b9h, 0bah, 0bbh, 0bch, 024h, 024h, 0bfh
	db	 0c0h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 041h, 041h
	db	 0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 024h
	db	 044h, 044h, 045h, 045h, 045h, 049h, 049h, 049h
	db	 049h, 0d9h, 0dah, 0dbh, 0dch, 0ddh, 049h, 0dfh
	db	 04fh, 053h, 04fh, 04fh, 04fh, 04fh, 0e6h, 0e8h
	db	 0e8h, 055h, 055h, 055h, 059h, 059h, 0eeh, 0efh
	db	 0f0h, 0f1h, 0f2h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h
	db	 0f8h, 0f9h, 0fah, 0fbh, 0fch, 0fdh, 0feh, 0ffh


LatiCollating850:
		dw	256	; Table Size
	db	 000h, 096h, 097h, 098h, 099h, 09ah, 09bh, 09ch
	db	 09dh, 09eh, 09fh, 0a0h, 0a1h, 0a2h, 0a3h, 0a4h
	db	 0a5h, 0a6h, 0a7h, 0a8h, 0a9h, 0aah, 0abh, 0ach
	db	 0adh, 0aeh, 0afh, 0b0h, 0b1h, 0b2h, 0b3h, 0b4h
	db	 000h, 03ch, 03dh, 03eh, 03fh, 040h, 041h, 000h
	db	 042h, 043h, 044h, 045h, 046h, 000h, 047h, 048h
	db	 022h, 023h, 024h, 025h, 026h, 027h, 028h, 029h
	db	 02ah, 02bh, 049h, 04ah, 04bh, 04ch, 04dh, 04eh
	db	 04fh, 001h, 002h, 003h, 006h, 008h, 009h, 00ah
	db	 00bh, 00ch, 00dh, 00eh, 00fh, 011h, 012h, 014h
	db	 015h, 016h, 017h, 018h, 01ah, 01ch, 01dh, 01eh
	db	 01fh, 020h, 021h, 050h, 051h, 052h, 053h, 054h
	db	 055h, 001h, 002h, 003h, 006h, 008h, 009h, 00ah
	db	 00bh, 00ch, 00dh, 00eh, 00fh, 011h, 012h, 014h
	db	 015h, 016h, 017h, 018h, 01ah, 01ch, 01dh, 01eh
	db	 01fh, 020h, 021h, 056h, 057h, 058h, 059h, 05ah
	db	 004h, 01ch, 008h, 001h, 001h, 001h, 001h, 004h
	db	 008h, 008h, 008h, 00ch, 00ch, 00ch, 001h, 001h
	db	 008h, 001h, 001h, 014h, 014h, 014h, 01ch, 01ch
	db	 020h, 014h, 01ch, 014h, 05ch, 014h, 05eh, 05fh
	db	 001h, 00ch, 014h, 01ch, 013h, 013h, 001h, 014h
	db	 060h, 061h, 062h, 063h, 064h, 065h, 066h, 067h
	db	 068h, 069h, 06ah, 06bh, 06ch, 001h, 001h, 001h
	db	 0b8h, 06dh, 06eh, 001h, 001h, 05bh, 05dh, 071h
	db	 072h, 073h, 074h, 075h, 076h, 077h, 0bbh, 0bch
	db	 078h, 079h, 07ah, 07bh, 07ch, 07dh, 07eh, 0bdh
	db	 007h, 007h, 008h, 008h, 008h, 00ch, 00ch, 00ch
	db	 00ch, 07fh, 080h, 081h, 082h, 0c7h, 00ch, 083h
	db	 014h, 019h, 014h, 014h, 014h, 014h, 084h, 01bh
	db	 01bh, 01ch, 01ch, 01ch, 020h, 020h, 0d5h, 0d6h
	db	 000h, 085h, 0d8h, 0d9h, 0dah, 0dbh, 086h, 0dch
	db	 0ddh, 0deh, 000h, 0dfh, 0e0h, 087h, 088h, 0e1h

SwedCollating850:
		dw	256	; Table Size
	db	 000h, 001h, 002h, 003h, 004h, 005h, 006h, 007h
	db	 008h, 009h, 00ah, 00bh, 00ch, 00dh, 00eh, 00fh
	db	 010h, 011h, 012h, 013h, 014h, 015h, 016h, 017h
	db	 018h, 019h, 01ah, 01bh, 01ch, 01dh, 01eh, 01fh
	db	 020h, 021h, 022h, 023h, 024h, 025h, 026h, 027h
	db	 028h, 029h, 02ah, 02bh, 02ch, 02dh, 02eh, 02fh
	db	 030h, 031h, 032h, 033h, 034h, 035h, 036h, 037h
	db	 038h, 039h, 03ah, 03bh, 03ch, 03dh, 03eh, 03fh
	db	 040h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 05bh, 05ch, 05dh, 05eh, 05fh
	db	 060h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 07bh, 07ch, 07dh, 07eh, 07fh
	db	 043h, 059h, 045h, 041h, 05ch, 041h, 05bh, 043h
	db	 045h, 045h, 045h, 049h, 049h, 049h, 05ch, 05bh
	db	 045h, 05ch, 05ch, 04fh, 05dh, 04fh, 055h, 055h
	db	 059h, 05dh, 059h, 05dh, 024h, 05dh, 09eh, 024h
	db	 041h, 049h, 04fh, 055h, 04eh, 04eh, 0a6h, 0a7h
	db	 03fh, 0a9h, 0aah, 0abh, 0ach, 021h, 022h, 022h
	db	 0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 041h, 041h, 041h
	db	 0b8h, 0b9h, 0bah, 0bbh, 0bch, 024h, 024h, 0bfh
	db	 0c0h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 041h, 041h
	db	 0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 024h
	db	 044h, 044h, 045h, 045h, 045h, 049h, 049h, 049h
	db	 049h, 0d9h, 0dah, 0dbh, 0dch, 0ddh, 049h, 0dfh
	db	 04fh, 053h, 04fh, 04fh, 05dh, 05dh, 0e6h, 0e8h
	db	 0e8h, 055h, 055h, 055h, 059h, 059h, 0eeh, 0efh
	db	 0f0h, 0f1h, 0f2h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h
	db	 0f8h, 0f9h, 0fah, 0fbh, 0fch, 0fdh, 0feh, 0ffh

DenmCollating850:
		dw	256	; Table Size
	db	 000h, 001h, 002h, 003h, 004h, 005h, 006h, 007h
	db	 008h, 009h, 00ah, 00bh, 00ch, 00dh, 00eh, 00fh
	db	 010h, 011h, 012h, 013h, 014h, 015h, 016h, 017h
	db	 018h, 019h, 01ah, 01bh, 01ch, 01dh, 01eh, 01fh
	db	 020h, 021h, 022h, 023h, 024h, 025h, 026h, 027h
	db	 028h, 029h, 02ah, 02bh, 02ch, 02dh, 02eh, 02fh
	db	 030h, 031h, 032h, 033h, 034h, 035h, 036h, 037h
	db	 038h, 039h, 03ah, 03bh, 03ch, 03dh, 03eh, 03fh
	db	 040h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 028h, 02fh, 029h, 05eh, 05fh
	db	 060h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 028h, 02fh, 029h, 07eh, 07fh
	db	 043h, 059h, 045h, 041h, 05bh, 041h, 05dh, 043h
	db	 045h, 045h, 045h, 049h, 049h, 049h, 05bh, 05dh
	db	 045h, 05bh, 05bh, 04fh, 05ch, 04fh, 055h, 055h
	db	 059h, 05ch, 059h, 05ch, 024h, 05ch, 09eh, 024h
	db	 041h, 049h, 04fh, 055h, 04eh, 04eh, 041h, 04fh
	db	 03fh, 0a9h, 0aah, 0abh, 0ach, 021h, 022h, 022h
	db	 0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 041h, 041h, 041h
	db	 0b8h, 0b9h, 0bah, 0bbh, 0bch, 024h, 024h, 0bfh
	db	 0c0h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 041h, 041h
	db	 0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 024h
	db	 044h, 044h, 045h, 045h, 045h, 049h, 049h, 049h
	db	 049h, 0d9h, 0dah, 0dbh, 0dch, 0ddh, 049h, 0dfh
	db	 04fh, 053h, 04fh, 04fh, 04fh, 04fh, 0e6h, 050h
	db	 050h, 055h, 055h, 055h, 059h, 059h, 0eeh, 0efh
	db	 0f0h, 0f1h, 0f2h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h
	db	 0f8h, 0f9h, 0fah, 0fbh, 0fch, 0fdh, 0feh, 0ffh

SwisCollating850:
		dw	256	; Table Size
	db	 0e0h, 0e1h, 0e2h, 0e3h, 0e4h, 0e5h, 0e6h, 0e7h
	db	 0e8h, 0e9h, 0eah, 0ebh, 0ech, 0edh, 0eeh, 0efh
	db	 0f0h, 0f1h, 0f2h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h
	db	 0f8h, 0f9h, 0fah, 0fbh, 0fch, 0fdh, 0feh, 0ffh
	db	 000h, 0a5h, 0a8h, 085h, 0b9h, 086h, 087h, 0a9h
	db	 0aah, 0abh, 088h, 09eh, 0ach, 0aeh, 0afh, 0b0h
	db	 075h, 076h, 078h, 07ah, 07ch, 07dh, 07eh, 07fh
	db	 080h, 081h, 0b1h, 0b2h, 0a0h, 0a1h, 0a2h, 0b3h
	db	 089h, 002h, 012h, 014h, 018h, 01ch, 026h, 028h
	db	 02ah, 02ch, 037h, 039h, 03bh, 03dh, 03fh, 043h
	db	 051h, 053h, 055h, 057h, 05ah, 05eh, 068h, 06ah
	db	 06ch, 06eh, 073h, 08ah, 08bh, 08ch, 0bfh, 0adh
	db	 0beh, 003h, 013h, 015h, 019h, 01dh, 027h, 029h
	db	 02bh, 038h, 02dh, 03ah, 03ch, 03eh, 040h, 044h
	db	 052h, 054h, 056h, 058h, 05bh, 05fh, 069h, 06bh
	db	 06dh, 06fh, 074h, 08eh, 08fh, 090h, 0c1h, 09dh
	db	 016h, 067h, 01fh, 009h, 00bh, 007h, 00fh, 017h
	db	 023h, 025h, 021h, 035h, 033h, 031h, 00ah, 00eh
	db	 01eh, 011h, 010h, 04ah, 04ch, 048h, 065h, 063h
	db	 072h, 04bh, 066h, 050h, 0b8h, 04fh, 0a4h, 0bch
	db	 005h, 02fh, 046h, 061h, 042h, 041h, 095h, 094h
	db	 0b4h, 09ah, 09ch, 083h, 082h, 0a6h, 0b5h, 0b6h
	db	 0cfh, 0d0h, 0d1h, 0ceh, 0cch, 004h, 008h, 006h
	db	 099h, 0d2h, 0d3h, 0d4h, 0d5h, 0bah, 0bbh, 0c6h
	db	 0c5h, 0cah, 0c9h, 0cbh, 0cdh, 0c8h, 00dh, 00ch
	db	 0d6h, 0d7h, 0d8h, 0d9h, 0dah, 0dbh, 0dch, 0b7h
	db	 01bh, 01ah, 022h, 024h, 020h, 036h, 02eh, 032h
	db	 034h, 0c7h, 0c4h, 0dfh, 0ddh, 09bh, 030h, 0deh
	db	 045h, 059h, 049h, 047h, 04eh, 04dh, 092h, 05ch
	db	 05dh, 060h, 064h, 062h, 071h, 070h, 091h, 0bdh
	db	 0a7h, 09fh, 08dh, 084h, 097h, 096h, 0a3h, 0c2h
	db	 093h, 0c0h, 0c3h, 077h, 07bh, 079h, 098h, 001h

CzecCollating850:
		dw	256	; Table Size
	db	000h, 001h, 002h, 003h, 004h, 005h, 006h, 007h
	db	008h, 009h, 00Ah, 00Bh, 00Ch, 00Dh, 00Eh, 00Fh
	db	010h, 011h, 012h, 013h, 014h, 015h, 016h, 017h
	db	018h, 019h, 01Ah, 01Bh, 01Ch, 01Dh, 01Eh, 01Fh
	db	020h, 021h, 022h, 023h, 024h, 025h, 026h, 027h
	db	028h, 029h, 02Ah, 02Bh, 02Ch, 02Dh, 02Eh, 02Fh
	db	030h, 031h, 032h, 033h, 034h, 035h, 036h, 037h
	db	038h, 039h, 03Ah, 03Bh, 03Ch, 03Dh, 03Eh, 03Fh
	db	040h, 041h, 043h, 044h, 045h, 047h, 049h, 04Ah
	db	04Bh, 04Ch, 04Eh, 04Fh, 050h, 051h, 052h, 053h
	db	055h, 056h, 057h, 058h, 059h, 05Ah, 05Ch, 05Dh
	db	05Eh, 05Fh, 061h, 028h, 02Fh, 029h, 05Eh, 05Fh
	db	060h, 041h, 043h, 044h, 045h, 047h, 049h, 04Ah
	db	04Bh, 04Ch, 04Eh, 04Fh, 050h, 051h, 052h, 053h
	db	055h, 056h, 057h, 058h, 059h, 05Ah, 05Ch, 05Dh
	db	05Eh, 05Fh, 061h, 028h, 02Fh, 029h, 07Eh, 07Fh
	db	044h, 05Bh, 048h, 042h, 042h, 042h, 042h, 044h
	db	048h, 048h, 048h, 04Dh, 04Dh, 04Dh, 042h, 042h
	db	048h, 063h, 063h, 054h, 064h, 054h, 05Bh, 05Bh
	db	060h, 064h, 05Bh, 054h, 024h, 054h, 09Eh, 024h
	db	042h, 04Dh, 054h, 05Bh, 052h, 052h, 041h, 054h
	db	03Fh, 0A9h, 0AAh, 0ABh, 0ACh, 021h, 022h, 022h
	db	0B0h, 0B1h, 0B2h, 0B3h, 0B4h, 042h, 042h, 042h
	db	0B8h, 0B9h, 0BAh, 0BBh, 0BCh, 024h, 024h, 0BFh
	db	0C0h, 0C1h, 0C2h, 0C3h, 0C4h, 0C5h, 042h, 042h
	db	0C8h, 0C9h, 0CAh, 0CBh, 0CCh, 0CDh, 0CEh, 024h
	db	046h, 046h, 048h, 048h, 048h, 04Ch, 04Dh, 04Dh
	db	04Dh, 0D9h, 0DAh, 0DBh, 0DCh, 0DDh, 04Dh, 0DFh
	db	054h, 043h, 054h, 054h, 054h, 054h, 0E6h, 062h
	db	062h, 05Bh, 05Bh, 05Bh, 060h, 060h, 0EEh, 0EFh
	db	0F0h, 0F1h, 0F2h, 0F3h, 0F4h, 0F5h, 09Fh, 001h
	db	04Fh, 00Eh, 080h, 0FCh, 014h, 074h, 005h, 02Eh

PolCollating850:
		dw 256 ; Table Size
	db	000h, 001h, 002h, 003h, 004h, 005h, 006h, 007h
	db	008h, 009h, 00Ah, 00Bh, 00Ch, 00Dh, 00Eh, 00Fh
	db	010h, 011h, 012h, 013h, 014h, 015h, 016h, 017h
	db	018h, 019h, 01Ah, 01Bh, 01Ch, 01Dh, 01Eh, 01Fh
	db	020h, 021h, 022h, 023h, 024h, 025h, 026h, 027h
	db	028h, 029h, 02Ah, 02Bh, 02Ch, 02Dh, 02Eh, 02Fh
	db	030h, 031h, 032h, 033h, 034h, 035h, 036h, 037h
	db	038h, 039h, 03Ah, 03Bh, 03Ch, 03Dh, 03Eh, 03Fh
	db	040h, 041h, 043h, 044h, 045h, 047h, 049h, 04Ah
	db	04Bh, 04Ch, 04Eh, 04Fh, 050h, 051h, 052h, 053h
	db	055h, 056h, 057h, 058h, 059h, 05Ah, 05Ch, 05Dh
	db	05Eh, 05Fh, 061h, 028h, 02Fh, 029h, 05Eh, 05Fh
	db	060h, 041h, 043h, 044h, 045h, 047h, 049h, 04Ah
	db	04Bh, 04Ch, 04Eh, 04Fh, 050h, 051h, 052h, 053h
	db	055h, 056h, 057h, 058h, 059h, 05Ah, 05Ch, 05Dh
	db	05Eh, 05Fh, 061h, 028h, 02Fh, 029h, 07Eh, 07Fh
	db	044h, 05Bh, 048h, 042h, 042h, 042h, 042h, 044h
	db	048h, 048h, 048h, 04Dh, 04Dh, 04Dh, 042h, 042h
	db	048h, 063h, 063h, 054h, 064h, 054h, 05Bh, 05Bh
	db	060h, 064h, 05Bh, 054h, 024h, 054h, 09Eh, 024h
	db	042h, 04Dh, 054h, 05Bh, 052h, 052h, 041h, 054h
	db	03Fh, 0A9h, 0AAh, 0ABh, 0ACh, 021h, 022h, 022h
	db	0B0h, 0B1h, 0B2h, 0B3h, 0B4h, 042h, 042h, 042h
	db	0B8h, 0B9h, 0BAh, 0BBh, 0BCh, 024h, 024h, 0BFh
	db	0C0h, 0C1h, 0C2h, 0C3h, 0C4h, 0C5h, 042h, 042h
	db	0C8h, 0C9h, 0CAh, 0CBh, 0CCh, 0CDh, 0CEh, 024h
	db	046h, 046h, 048h, 048h, 048h, 04Ch, 04Dh, 04Dh
	db	04Dh, 0D9h, 0DAh, 0DBh, 0DCh, 0DDh, 04Dh, 0DFh
	db	054h, 043h, 054h, 054h, 054h, 054h, 0E6h, 062h
	db	062h, 05Bh, 05Bh, 05Bh, 060h, 060h, 0EEh, 0EFh
	db	0F0h, 0F1h, 0F2h, 0F3h, 0F4h, 0F5h, 09Fh, 001h
	db	04Fh, 00Eh, 080h, 0FCh, 014h, 074h, 005h, 02Eh

NorwCollating850:
		dw	256	; Table Size
	db	 000h, 001h, 002h, 003h, 004h, 005h, 006h, 007h
	db	 008h, 009h, 00ah, 00bh, 00ch, 00dh, 00eh, 00fh
	db	 010h, 011h, 012h, 013h, 014h, 015h, 016h, 017h
	db	 018h, 019h, 01ah, 01bh, 01ch, 01dh, 01eh, 01fh
	db	 020h, 021h, 022h, 023h, 024h, 025h, 026h, 027h
	db	 028h, 029h, 02ah, 02bh, 02ch, 02dh, 02eh, 02fh
	db	 030h, 031h, 032h, 033h, 034h, 035h, 036h, 037h
	db	 038h, 039h, 03ah, 03bh, 03ch, 03dh, 03eh, 03fh
	db	 040h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 05bh, 05ch, 05dh, 05eh, 05fh
	db	 060h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 07bh, 07ch, 07dh, 07eh, 07fh
	db	 043h, 055h, 045h, 041h, 05bh, 041h, 05dh, 043h
	db	 045h, 045h, 045h, 049h, 049h, 049h, 05bh, 05dh
	db	 045h, 05bh, 05bh, 04fh, 05ch, 04fh, 055h, 055h
	db	 059h, 05ch, 059h, 05ch, 024h, 05ch, 09eh, 024h
	db	 041h, 049h, 04fh, 055h, 04eh, 04eh, 041h, 04fh
	db	 03fh, 0a9h, 0aah, 0abh, 0ach, 021h, 022h, 022h
	db	 0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 041h, 041h, 041h
	db	 0b8h, 0b9h, 0bah, 0bbh, 0bch, 024h, 024h, 0bfh
	db	 0c0h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 041h, 041h
	db	 0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 024h
	db	 044h, 044h, 045h, 045h, 045h, 049h, 049h, 049h
	db	 049h, 0d9h, 0dah, 0dbh, 0dch, 0ddh, 049h, 0dfh
	db	 04fh, 053h, 04fh, 04fh, 04fh, 04fh, 0e6h, 050h
	db	 050h, 055h, 055h, 055h, 059h, 059h, 0eeh, 0efh
	db	 0f0h, 0f1h, 0f2h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h
	db	 0f8h, 0f9h, 0fah, 0fbh, 0fch, 0fdh, 0feh, 0ffh

BelgCollating850:
		dw	256	; Table Size
	db	 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh
	db	 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh
	db	 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh
	db	 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh
	db	 0ffh, 021h, 022h, 023h, 024h, 025h, 026h, 0ffh
	db	 028h, 029h, 02ah, 02bh, 02ch, 0ffh, 02eh, 02fh
	db	 030h, 031h, 032h, 033h, 034h, 035h, 036h, 037h
	db	 038h, 039h, 03ah, 03bh, 03ch, 03dh, 03eh, 03fh
	db	 040h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 05bh, 05ch, 05dh, 05eh, 05fh
	db	 060h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 07bh, 07ch, 07dh, 07eh, 07fh
	db	 043h, 055h, 045h, 041h, 041h, 041h, 041h, 043h
	db	 045h, 045h, 045h, 049h, 049h, 049h, 041h, 041h
	db	 045h, 041h, 041h, 04fh, 04fh, 04fh, 055h, 055h
	db	 059h, 04fh, 055h, 04fh, 09ch, 04fh, 09eh, 09fh
	db	 041h, 049h, 04fh, 055h, 04eh, 0a4h, 0a6h, 0a7h
	db	 0a8h, 0a9h, 0aah, 0abh, 0ach, 0adh, 0aeh, 0afh
	db	 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 041h, 041h, 041h
	db	 0b8h, 0ffh, 0ffh, 0ffh, 0ffh, 0bdh, 0beh, 0ffh
	db	 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 041h, 041h
	db	 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0cfh
	db	 044h, 044h, 045h, 045h, 045h, 049h, 049h, 049h
	db	 049h, 0ffh, 0ffh, 0ffh, 0ffh, 0ddh, 049h, 0ffh
	db	 04fh, 053h, 04fh, 04fh, 04fh, 04fh, 0e6h, 054h
	db	 054h, 055h, 055h, 055h, 059h, 059h, 0eeh, 0efh
	db	 0ffh, 0f1h, 0f2h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h
	db	 0f8h, 0f9h, 0fah, 0fbh, 0fch, 0fdh, 0ffh, 0ffh

NethCollating850:
		dw	256	; Table Size
	db	 000h, 001h, 002h, 003h, 004h, 005h, 006h, 007h
	db	 008h, 009h, 00ah, 00bh, 00ch, 00dh, 00eh, 00fh
	db	 010h, 011h, 012h, 013h, 014h, 015h, 016h, 017h
	db	 018h, 019h, 01ah, 01bh, 01ch, 01dh, 01eh, 01fh
	db	 020h, 021h, 022h, 023h, 024h, 025h, 026h, 027h
	db	 028h, 029h, 02ah, 02bh, 02ch, 02dh, 02eh, 02fh
	db	 030h, 031h, 032h, 033h, 034h, 035h, 036h, 037h
	db	 038h, 039h, 03ah, 03bh, 03ch, 03dh, 03eh, 03fh
	db	 040h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 05bh, 05ch, 05dh, 05eh, 05fh
	db	 060h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 07bh, 07ch, 07dh, 07eh, 07fh
	db	 043h, 055h, 045h, 041h, 041h, 041h, 08fh, 043h
	db	 045h, 045h, 045h, 049h, 049h, 049h, 041h, 08fh
	db	 045h, 092h, 092h, 04fh, 04fh, 04fh, 055h, 055h
	db	 098h, 04fh, 055h, 04fh, 09ch, 04fh, 09eh, 09fh
	db	 041h, 049h, 04fh, 055h, 0a5h, 0a5h, 0a6h, 0a7h
	db	 0a8h, 0a9h, 0aah, 0abh, 0ach, 0adh, 0aeh, 0afh
	db	 0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 041h, 041h, 041h
	db	 0b8h, 0b9h, 0bah, 0bbh, 0bch, 0bdh, 0beh, 0bfh
	db	 0c0h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 041h, 041h
	db	 0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 0cfh
	db	 0d1h, 0d1h, 045h, 045h, 045h, 049h, 049h, 049h
	db	 049h, 0d9h, 0dah, 0dbh, 0dch, 0ddh, 049h, 0dfh
	db	 04fh, 0e1h, 04fh, 04fh, 04fh, 04fh, 0e6h, 0e8h
	db	 0e8h, 055h, 055h, 055h, 059h, 059h, 0eeh, 0efh
	db	 0f0h, 0f1h, 0f2h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h
	db	 0f8h, 0f9h, 0fah, 0fbh, 0fch, 0fdh, 0feh, 0ffh


FinlCollating850:
		dw	256	; Table Size
	db	 000h, 001h, 002h, 003h, 004h, 005h, 006h, 007h
	db	 008h, 009h, 00ah, 00bh, 00ch, 00dh, 00eh, 00fh
	db	 010h, 011h, 012h, 013h, 014h, 015h, 016h, 017h
	db	 018h, 019h, 01ah, 01bh, 01ch, 01dh, 01eh, 01fh
	db	 020h, 021h, 022h, 023h, 024h, 025h, 026h, 027h
	db	 028h, 029h, 02ah, 02bh, 02ch, 02dh, 02eh, 02fh
	db	 030h, 031h, 032h, 033h, 034h, 035h, 036h, 037h
	db	 038h, 039h, 03ah, 03bh, 03ch, 03dh, 03eh, 03fh
	db	 040h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 05bh, 05ch, 05dh, 05eh, 05fh
	db	 060h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 07bh, 07ch, 07dh, 07eh, 07fh
	db	 043h, 059h, 045h, 041h, 05ch, 041h, 05bh, 043h
	db	 045h, 045h, 045h, 049h, 049h, 049h, 05ch, 05bh
	db	 045h, 05ch, 05ch, 04fh, 05dh, 04fh, 055h, 055h
	db	 059h, 05dh, 059h, 05dh, 024h, 05dh, 09eh, 024h
	db	 041h, 049h, 04fh, 055h, 04eh, 04eh, 0a6h, 0a7h
	db	 03fh, 0a9h, 0aah, 0abh, 0ach, 021h, 022h, 022h
	db	 0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 041h, 041h, 041h
	db	 0b8h, 0b9h, 0bah, 0bbh, 0bch, 024h, 024h, 0bfh
	db	 0c0h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 041h, 041h
	db	 0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 024h
	db	 044h, 044h, 045h, 045h, 045h, 049h, 049h, 049h
	db	 049h, 0d9h, 0dah, 0dbh, 0dch, 0ddh, 049h, 0dfh
	db	 04fh, 053h, 04fh, 04fh, 04fh, 04fh, 0e6h, 0e8h
	db	 0e8h, 055h, 055h, 055h, 059h, 059h, 0eeh, 0efh
	db	 0f0h, 0f1h, 0f2h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h
	db	 0f8h, 0f9h, 0fah, 0fbh, 0fch, 0fdh, 0feh, 0ffh


Collating932:
		dw	256	; Table size
	db	 000h, 001h, 002h, 003h, 004h, 005h, 006h, 007h
	db	 008h, 009h, 00ah, 00bh, 00ch, 00dh, 00eh, 00fh
	db	 010h, 011h, 012h, 013h, 014h, 015h, 016h, 017h
	db	 018h, 019h, 01ah, 01bh, 01ch, 01dh, 01eh, 01fh
	db	 020h, 021h, 022h, 023h, 024h, 025h, 026h, 027h
	db	 028h, 029h, 02ah, 02bh, 02ch, 02dh, 02eh, 02fh
	db	 030h, 031h, 032h, 033h, 034h, 035h, 036h, 037h
	db	 038h, 039h, 03ah, 03bh, 03ch, 03dh, 03eh, 03fh
	db	 040h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 05bh, 05ch, 05dh, 05eh, 05fh
	db	 060h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 07bh, 07ch, 07dh, 07eh, 07fh
	db	 080h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 0c6h, 0c7h
	db	 0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 0cfh
	db	 0d0h, 0d1h, 0d2h, 0d3h, 0d4h, 0d5h, 0d6h, 0d7h
	db	 0d8h, 0d9h, 0dah, 0dbh, 0dch, 0ddh, 0deh, 0dfh
	db	 081h, 082h, 083h, 084h, 085h, 0bdh, 086h, 087h
	db	 088h, 089h, 08ah, 08bh, 08ch, 08dh, 08eh, 08fh
	db	 090h, 091h, 092h, 093h, 094h, 095h, 096h, 097h
	db	 098h, 099h, 09ah, 09bh, 09ch, 09dh, 09eh, 09fh
	db	 0a0h, 0a1h, 0a2h, 0a3h, 0a4h, 0a5h, 0a6h, 0a7h
	db	 0a8h, 0a9h, 0aah, 0abh, 0ach, 0adh, 0aeh, 0afh
	db	 0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 0b5h, 0b6h, 0b7h
	db	 0b8h, 0b9h, 0bah, 0bbh, 0bch, 0beh, 0bfh, 0c0h
	db	 0e0h, 0e1h, 0e2h, 0e3h, 0e4h, 0e5h, 0e6h, 0e7h
	db	 0e8h, 0e9h, 0eah, 0ebh, 0ech, 0edh, 0eeh, 0efh
	db	 0f0h, 0f1h, 0f2h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h
	db	 0f8h, 0f9h, 0fah, 0fbh, 0fch, 0fdh, 0feh, 0ffh


Collating934:
		dw	256	; Table size
	db	000h, 001h, 002h, 003h, 004h, 005h, 006h, 007h
	db	008h, 009h, 00ah, 00bh, 00ch, 00dh, 00eh, 00fh
	db	010h, 011h, 012h, 013h, 014h, 015h, 016h, 017h
	db	018h, 019h, 01ah, 01bh, 01ch, 01dh, 01eh, 01fh
	db	020h, 021h, 022h, 023h, 024h, 025h, 026h, 027h
	db	028h, 029h, 02ah, 02bh, 02ch, 02dh, 02eh, 02fh
	db	030h, 031h, 032h, 033h, 034h, 035h, 036h, 037h
	db	038h, 039h, 03ah, 03bh, 03ch, 03dh, 03eh, 03fh
	db	040h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	058h, 059h, 05ah, 05bh, 05ch, 05dh, 05eh, 05fh
	db	060h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	058h, 059h, 05ah, 07bh, 07ch, 07dh, 07eh, 07fh
	db	080h, 0beh, 0bfh, 0c0h, 0c1h, 0c2h, 0c3h, 0c4h
	db	0c5h, 0c6h, 0c7h, 0c8h, 0c9h, 0cah, 0cbh, 0cch
	db	0cdh, 0ceh, 0cfh, 0d0h, 0d1h, 0d2h, 0d3h, 0d4h
	db	0d5h, 0d6h, 0d7h, 0d8h, 0d9h, 0dah, 0dbh, 0dch
	db	0ddh, 0deh, 0dfh, 0e0h, 0e1h, 0e2h, 0e3h, 0e4h
	db	0e5h, 0e6h, 0e7h, 0e8h, 0e9h, 0eah, 0ebh, 0ech
	db	0edh, 0eeh, 0efh, 0f0h, 0f1h, 0f2h, 0f3h, 0f4h
	db	0f5h, 0f6h, 0f7h, 0f8h, 0f9h, 0fah, 0fbh, 0fch
	db	081h, 082h, 083h, 084h, 085h, 086h, 087h, 088h
	db	089h, 08ah, 08bh, 08ch, 08dh, 08eh, 08fh, 090h
	db	091h, 092h, 093h, 094h, 095h, 096h, 097h, 098h
	db	099h, 09ah, 09bh, 09ch, 09dh, 09eh, 09fh, 0a0h
	db	0a1h, 0a2h, 0a3h, 0a4h, 0a5h, 0a6h, 0a7h, 0a8h
	db	0a9h, 0aah, 0abh, 0ach, 0adh, 0aeh, 0afh, 0b0h
	db	0b1h, 0b2h, 0b3h, 0b4h, 0b5h, 0b6h, 0b7h, 0b8h
	db	0b9h, 0bah, 0bbh, 0bch, 0bdh, 0fdh, 0feh, 0ffh


CanadaUcase:
		dw  128	; Table Size

Canadian_table	db	 'C',  'U',  'E',  'A',  'A',  'A', 086h,  'C'
	db	 'E',  'E',  'E',  'I',  'I', 08dh,  'A', 08fh
	db	 'E',  'E',  'E',  'O',  'E',  'I',  'U',  'U'
	db	098h,  'O',  'U', 09bh, 09ch,  'U',  'U', 09fh
	db	0a0h, 0a1h,  'O',  'U', 0a4h, 0a5h, 0a6h, 0a7h
	db	 'I'
	db 	0a9h, 0aah, 0abh, 0ach, 0adh, 0aeh, 0afh
	db	0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 0b5h, 0b6h, 0b7h
	db	0b8h, 0b9h, 0bah, 0bbh, 0bch, 0bdh, 0beh, 0bfh
	db	0c0h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 0c6h, 0c7h
	db	0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 0cfh
	db	0d0h, 0d1h, 0d2h, 0d3h, 0d4h, 0d5h, 0d6h, 0d7h
	db	0d8h, 0d9h, 0dah, 0dbh, 0dch, 0ddh, 0deh, 0dfh
	db	0e0h, 0e1h, 0e2h, 0e3h, 0e4h, 0e5h, 0e6h, 0e7h
	db	0e8h, 0e9h, 0eah, 0ebh, 0ech, 0edh, 0eeh, 0efh
	db	0f0h, 0f1h, 0f2h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h
	db	0f8h, 0f9h, 0fah, 0fbh, 0fch, 0fdh, 0feh, 0ffh

CanadaCollating:
		dw  256	; Table Size
	db	 000h, 001h, 002h, 003h, 004h, 005h, 006h, 007h
	db	 008h, 009h, 00ah, 00bh, 00ch, 00dh, 00eh, 00fh
	db	 010h, 011h, 012h, 013h, 014h, 015h, 016h, 017h
	db	 018h, 019h, 01ah, 01bh, 01ch, 01dh, 01eh, 01fh
	db	 020h, 021h, 022h, 023h, 024h, 025h, 026h, 027h
	db	 028h, 029h, 02ah, 02bh, 02ch, 02dh, 02eh, 02fh
	db	 030h, 031h, 032h, 033h, 034h, 035h, 036h, 037h
	db	 038h, 039h, 03ah, 03bh, 03ch, 03dh, 03eh, 03fh
	db	 040h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 05bh, 05ch, 05dh, 05eh, 05fh
	db	 060h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 07bh, 07ch, 07dh, 07eh, 07fh
	db	 043h, 055h, 045h, 041h, 041h, 041h, 086h, 043h
	db	 045h, 045h, 045h, 049h, 049h, 08dh, 041h, 08fh
	db	 045h, 045h, 045h, 04fh, 045h, 049h, 055h, 055h
	db	 098h, 04fh, 055h, 09bh, 09ch, 055h, 055h, 09fh
	db	 0a0h, 0a1h, 04fh, 055h, 0a4h, 0a5h, 0a6h, 0a7h
	db	 049h, 0a9h, 0aah, 0abh, 0ach, 0adh, 0aeh, 0afh
	db	 0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 0b5h, 0b6h, 0b7h
	db	 0b8h, 0b9h, 0bah, 0bbh, 0bch, 0bdh, 0beh, 0bfh
	db	 0c0h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 0c6h, 0c7h
	db	 0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 0cfh
	db	 0d0h, 0d1h, 0d2h, 0d3h, 0d4h, 0d5h, 0d6h, 0d7h
	db	 0d8h, 0d9h, 0dah, 0dbh, 0dch, 0ddh, 0deh, 0dfh
	db	 0e0h, 0e1h, 0e2h, 0e3h, 0e4h, 0e5h, 0e6h, 0e7h
	db	 0e8h, 0e9h, 0eah, 0ebh, 0ech, 0edh, 0eeh, 0efh
	db	 0f0h, 0f1h, 0f2h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h
	db	 0f8h, 0f9h, 0fah, 0fbh, 0fch, 0fdh, 0feh, 0ffh


;
;	UpperCase Table for Russian CodePage 866
;
RussianUcase:
		dw  128	; Table Size
Russian_table:
	db	080h, 081h, 082h, 083h, 084h, 085h, 086h, 087h
	db	088h, 089h, 08ah, 08bh, 08ch, 08dh, 08eh, 08fh
	db	090h, 091h, 092h, 093h, 094h, 095h, 096h, 097h
	db	098h, 099h, 09ah, 09Bh, 09Ch, 09Dh, 09Eh, 09Fh
	db	080h, 081h, 082h, 083h, 084h, 085h, 086h, 087h
	db	088h, 089h, 08ah, 08bh, 08ch, 08dh, 08eh, 08fh
	db	0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 0b5h, 0b6h, 0b7h
	db	0b8h, 0b9h, 0bah, 0bbh, 0bch, 0bdh, 0beh, 0bfh
	db	0c0h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 0c6h, 0c7h
	db	0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 0cfh
	db	0d0h, 0d1h, 0d2h, 0d3h, 0d4h, 0d5h, 0d6h, 0d7h
	db	0d8h, 0d9h, 0dah, 0dbh, 0dch, 0ddh, 0deh, 0dfh
	db	090h, 091h, 092h, 093h, 094h, 095h, 096h, 097h
	db	098h, 099h, 09ah, 09Bh, 09Ch, 09Dh, 09Eh, 09Fh
	db	0f0h, 0f0h, 0f2h, 0f2h, 0f4h, 0f4h, 0f6h, 0f6h
	db	0f8h, 0f9h, 0fah, 0fbh, 0fch, 0fdh, 0feh, 0ffh

RussianCollating:
		dw  256	; Table Size
	db	 000h, 001h, 002h, 003h, 004h, 005h, 006h, 007h
	db	 008h, 009h, 00ah, 00bh, 00ch, 00dh, 00eh, 00fh
	db	 010h, 011h, 012h, 013h, 014h, 015h, 016h, 017h
	db	 018h, 019h, 01ah, 01bh, 01ch, 01dh, 01eh, 01fh
	db	 020h, 021h, 022h, 023h, 024h, 025h, 026h, 027h
	db	 028h, 029h, 02ah, 02bh, 02ch, 02dh, 02eh, 02fh
	db	 030h, 031h, 032h, 033h, 034h, 035h, 036h, 037h
	db	 038h, 039h, 03ah, 03bh, 03ch, 03dh, 03eh, 03fh
	db	 040h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 05bh, 05ch, 05dh, 05eh, 05fh
	db	 060h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 07bh, 07ch, 07dh, 07eh, 07fh

	db	 080h, 081h, 082h, 083h, 084h, 085h ;;
	db	 088h, 089h, 08ah, 08ch, 08dh, 08eh, 08fh ;;
	db	 090h, 091h, 092h, 093h, 094h, 095h, 096h ;;
	db	 098h, 099h, 09ah, 09Bh, 09Ch, 09Dh, 09Eh, 09Fh ;;
	db	 0A0h, 0A1h, 0A2h, 0A3h ;;
	db	 080h, 081h, 082h, 083h, 084h, 085h ;;
	db	 088h, 089h, 08ah, 08ch, 08dh, 08eh, 08fh ;;
	db	 090h, 091h, 092h ;;
	
	db	 0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 0b5h, 0b6h, 0b7h
	db	 0b8h, 0b9h, 0bah, 0bbh, 0bch, 0bdh, 0beh, 0bfh
	db	 0c0h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 0c6h, 0c7h
	db	 0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 0cfh
	db	 0d0h, 0d1h, 0d2h, 0d3h, 0d4h, 0d5h, 0d6h, 0d7h
	db	 0d8h, 0d9h, 0dah, 0dbh, 0dch, 0ddh, 0deh, 0dfh
	
	db	 093h, 094h, 095h, 096h ;;
	db	 098h, 099h, 09ah, 09Bh, 09Ch, 09Dh, 09Eh, 09Fh ;;
	db	 0A0h, 0A1h, 0A2h, 0A3h ;;

	db	 086h, 086h, 087h, 087h, 08Bh, 08Bh, 097h, 097h
	db	 0f8h, 0f9h, 0fah, 0fbh, 023h, 024h, 0feh, 0ffh


if COMPATIBLE
NetherlandsUcase:
		dw  128	; Table Size

	db	080h,  'U',  'E',  'A',  'A',  'A', 08fh, 080h
	db	 'E',  'E',  'E',  'I',  'I',  'I',  'A', 08fh
	db	 'E', 092h, 092h,  'O',  'O',  'O',  'U',  'U'
	db	098h,  'O',  'U', 09bh, 09ch, 09dh, 09eh, 09fh
	db	 'A',  'I',  'O',  'U', 0a5h, 0a5h, 0a6h, 0a7h
	db	0a8h, 0a9h, 0aah, 0abh, 0ach, 0adh, 0aeh, 0afh
	db	0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 0b5h, 0b6h, 0b7h
	db	0b8h, 0b9h, 0bah, 0bbh, 0bch, 0bdh, 0beh, 0bfh
	db	0c0h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 0c6h, 0c7h
	db	0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 0cfh
	db	0d0h, 0d1h, 0d2h, 0d3h, 0d4h, 0d5h, 0d6h, 0d7h
	db	0d8h, 0d9h, 0dah, 0dbh, 0dch, 0ddh, 0deh, 0dfh
	db	0e0h, 0e1h, 0e2h, 0e3h, 0e4h, 0e5h, 0e6h, 0e7h
	db	0e8h, 0e9h, 0eah, 0ebh, 0ech, 0edh, 0eeh, 0efh
	db	0f0h, 0f1h, 0f2h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h
	db	0f8h, 0f9h, 0fah, 0fbh, 0fch, 0fdh, 0feh, 0ffh
endif

NetherlandsCollating:
		dw  256	; Table Size
	db	 000h, 001h, 002h, 003h, 004h, 005h, 006h, 007h
	db	 008h, 009h, 00ah, 00bh, 00ch, 00dh, 00eh, 00fh
	db	 010h, 011h, 012h, 013h, 014h, 015h, 016h, 017h
	db	 018h, 019h, 01ah, 01bh, 01ch, 01dh, 01eh, 01fh
	db	 020h, 021h, 022h, 023h, 024h, 025h, 026h, 027h
	db	 028h, 029h, 02ah, 02bh, 02ch, 02dh, 02eh, 02fh
	db	 030h, 031h, 032h, 033h, 034h, 035h, 036h, 037h
	db	 038h, 039h, 03ah, 03bh, 03ch, 03dh, 03eh, 03fh
	db	 040h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 05bh, 05ch, 05dh, 05eh, 05fh
	db	 060h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 07bh, 07ch, 07dh, 07eh, 07fh
	db	 080h, 09ah, 090h, 041h, 08eh, 041h, 08fh, 080h
	db	 045h, 045h, 045h, 049h, 049h, 049h, 08eh, 08fh
	db	 090h, 092h, 092h, 04fh, 04fh, 04fh, 055h, 055h
	db	 098h, 04fh, 055h, 09bh, 09ch, 09dh, 09eh, 09fh
	db	 041h, 049h, 04fh, 055h, 0a5h, 0a5h, 0a6h, 0a7h
	db	 0a8h, 0a9h, 0aah, 0abh, 0ach, 0adh, 0aeh, 0afh
	db	 0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 0b5h, 0b6h, 0b7h
	db	 0b8h, 0b9h, 0bah, 0bbh, 0bch, 0bdh, 0beh, 0bfh
	db	 0c0h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 0c6h, 0c7h
	db	 0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 0cfh
	db	 0d0h, 0d1h, 0d2h, 0d3h, 0d4h, 0d5h, 0d6h, 0d7h
	db	 0d8h, 0d9h, 0dah, 0dbh, 0dch, 0ddh, 0deh, 0dfh
	db	 0e0h, 0e1h, 0e2h, 0e3h, 0e4h, 0e5h, 0e6h, 0e7h
	db	 0e8h, 0e9h, 0eah, 0ebh, 0ech, 0edh, 0eeh, 0efh
	db	 0f0h, 0f1h, 0f2h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h
	db	 0f8h, 0f9h, 0fah, 0fbh, 0fch, 0fdh, 0feh, 0ffh



BelgiumCollating:
		dw  256	; Table Size
	db	 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh
	db	 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh
	db	 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh
	db	 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh
	db	 0ffh, 021h, 022h, 023h, 024h, 025h, 026h, 0ffh
	db	 028h, 029h, 02ah, 02bh, 02ch, 0ffh, 02eh, 02fh
	db	 030h, 031h, 032h, 033h, 034h, 035h, 036h, 037h
	db	 038h, 039h, 03ah, 03bh, 03ch, 03dh, 03eh, 03fh
	db	 040h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 05bh, 05ch, 05dh, 05eh, 05fh
	db	 060h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 07bh, 07ch, 07dh, 07eh, 07fh
	db	 043h, 055h, 045h, 041h, 041h, 041h, 041h, 043h
	db	 045h, 045h, 045h, 049h, 049h, 049h, 041h, 041h
	db	 045h, 041h, 041h, 04fh, 04fh, 04fh, 055h, 055h
	db	 059h, 04fh, 055h, 09bh, 09ch, 09dh, 09eh, 09fh
	db	 041h, 049h, 04fh, 055h, 04eh, 04eh, 0a6h, 0a7h
	db	 0a8h, 0a9h, 0aah, 0abh, 0ach, 0adh, 0aeh, 0afh
	db	 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh
	db	 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh
	db	 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh
	db	 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh
	db	 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh
	db	 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh
	db	 0e0h, 053h, 0e2h, 0e3h, 0e4h, 0e5h, 0e6h, 0e7h
	db	 0e8h, 0e9h, 0eah, 0ebh, 0ech, 0edh, 0eeh, 0efh
	db	 0f0h, 0f1h, 0f2h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h
	db	 0f8h, 0f9h, 0fah, 0fbh, 0fch, 0fdh, 0ffh, 0ffh


SpainCollating:
		dw  256	; Table Size
	db	 000h, 001h, 002h, 003h, 004h, 005h, 006h, 007h
	db	 008h, 009h, 00ah, 00bh, 00ch, 00dh, 00eh, 00fh
	db	 010h, 011h, 012h, 013h, 014h, 015h, 016h, 017h
	db	 018h, 019h, 01ah, 01bh, 01ch, 01dh, 01eh, 01fh
	db	 020h, 021h, 022h, 023h, 024h, 025h, 026h, 027h
	db	 028h, 029h, 02ah, 02bh, 02ch, 02dh, 02eh, 02fh
	db	 030h, 031h, 032h, 033h, 034h, 035h, 036h, 037h
	db	 038h, 039h, 03ah, 03bh, 03ch, 03dh, 03eh, 03fh
	db	 040h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 05bh, 05ch, 05dh, 05eh, 05fh
	db	 060h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 07bh, 07ch, 07dh, 07eh, 07fh
	db	 043h, 055h, 045h, 041h, 041h, 041h, 041h, 043h
	db	 045h, 045h, 045h, 049h, 049h, 049h, 041h, 041h
	db	 045h, 041h, 041h, 04fh, 04fh, 04fh, 055h, 055h
	db	 059h, 04fh, 055h, 024h, 024h, 024h, 024h, 024h
	db	 041h, 049h, 04fh, 055h, 04eh, 04eh, 0a6h, 0a7h
	db	 03fh, 0a9h, 0aah, 0abh, 0ach, 021h, 022h, 022h
	db	 0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 0b5h, 0b6h, 0b7h
	db	 0b8h, 0b9h, 0bah, 0bbh, 0bch, 0bdh, 0beh, 0bfh
	db	 0c0h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 0c6h, 0c7h
	db	 0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 0cfh
	db	 0d0h, 0d1h, 0d2h, 0d3h, 0d4h, 0d5h, 0d6h, 0d7h
	db	 0d8h, 0d9h, 0dah, 0dbh, 0dch, 0ddh, 0deh, 0dfh
	db	 0e0h, 053h, 0e2h, 0e3h, 0e4h, 0e5h, 0e6h, 0e7h
	db	 0e8h, 0e9h, 0eah, 0ebh, 0ech, 0edh, 0eeh, 0efh
	db	 0f0h, 0f1h, 0f2h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h
	db	 0f8h, 0f9h, 0fah, 0fbh, 0fch, 0fdh, 0feh, 0ffh

HungaryUcase:
	dw	128
	db	080h, 09ah, 090h, 0b6h, 08eh, 0deh, 08fh, 080h
	db	09dh, 0d3h, 08ah, 08ah, 0d7h, 08dh, 08eh, 08fh
	db	090h, 091h, 0d6h, 0e2h, 099h, 095h, 095h, 097h
	db	097h, 099h, 09ah, 09bh, 09bh, 09dh, 09eh, 0ach
	db	0b5h, 0d6h, 0e0h, 0e9h, 0a4h, 0a4h, 0a6h, 0a6h
	db	0a8h, 0a8h, 0aah, 08dh, 0ach, 0b8h, 0aeh, 0afh
	db	0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 0b5h, 0b6h, 0b7h
	db	0b8h, 0b9h, 0bah, 0bbh, 0bch, 0bdh, 0bdh, 0bfh
	db	0c0h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 0c6h, 0c6h
	db	0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 0cfh
	db	0d1h, 0d1h, 0d2h, 0d3h, 0d2h, 0d5h, 0d6h, 0d7h
	db	0b7h, 0d9h, 0dah, 0dbh, 0dch, 0ddh, 0deh, 0dfh
	db	0e0h, 053h, 0e2h, 0e3h, 0e3h, 0d5h, 0e6h, 0e6h
	db	0e8h, 0e9h, 0e8h, 0ebh, 0edh, 0edh, 0ddh, 0efh
	db	0f0h, 0f1h, 0f2h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h
	db	0f8h, 0f9h, 0fah, 0ebh, 0fch, 0fch, 0feh, 0ffh

HungaryCollating:
		dw  256	; Table Size
	db	 000h, 001h, 002h, 003h, 004h, 005h, 006h, 007h
	db	 008h, 009h, 00ah, 00bh, 00ch, 00dh, 00eh, 00fh
	db	 010h, 011h, 012h, 013h, 014h, 015h, 016h, 017h
	db	 018h, 019h, 01ah, 01bh, 01ch, 01dh, 01eh, 01fh
	db	 020h, 021h, 022h, 023h, 024h, 025h, 026h, 027h
	db	 028h, 029h, 02ah, 02bh, 02ch, 02dh, 02eh, 02fh
	db	 030h, 031h, 032h, 033h, 034h, 035h, 036h, 037h
	db	 038h, 039h, 03ah, 03bh, 03ch, 03dh, 03eh, 03fh
	db	 040h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 05bh, 05ch, 05dh, 05eh, 05fh
	db	 060h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 07bh, 07ch, 07dh, 07eh, 07fh
	db	 043h, 055h, 045h, 041h, 041h, 055h, 043h, 043h
	db	 04ch, 045h, 04fh, 04fh, 049h, 05ah, 041h, 043h
	db	 045h, 04ch, 049h, 04fh, 04fh, 04ch, 049h, 053h
	db	 053h, 04fh, 055h, 054h, 054h, 04ch, 09eh, 043h
	db	 041h, 049h, 04fh, 055h, 041h, 041h, 05ah, 05ah
	db	 045h, 045h, 0aah, 05ah, 043h, 053h, 0aeh, 0afh
	db	 0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 041h, 041h, 045h
	db	 053h, 0b9h, 0bah, 0bbh, 0bch, 05ah, 05ah, 0bfh
	db	 0c0h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 041h, 041h
	db	 0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 0cfh
	db	 044h, 044h, 044h, 045h, 044h, 04eh, 049h, 049h
	db	 045h, 0d9h, 0dah, 0dbh, 0dch, 054h, 055h, 0dfh
	db	 04fh, 053h, 04fh, 04eh, 04eh, 04eh, 053h, 053h
	db	 052h, 055h, 052h, 055h, 059h, 059h, 054h, 0efh
	db	 0f0h, 0f1h, 0f2h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h
	db	 0f8h, 0f9h, 0fah, 055h, 052h, 052h, 0feh, 0ffh


if COMPATIBLE
SwitzerlandUcase:
		dw  128	; Table Size

	db	080h, 09ah, 090h,  'A', 08eh,  'A', 08fh, 080h
	db	 'E',  'E',  'E',  'I',  'I',  'I', 08eh, 08fh
	db	090h, 092h, 092h,  'O', 099h,  'O',  'U',  'U'
	db	 'Y', 099h, 09ah, 09bh, 09ch, 09dh, 09eh, 09fh
	db	 'A',  'I',  'O',  'U', 0a5h, 0a5h,  'A',  'O'
	db	0a8h, 0a9h, 0aah, 0abh, 0ach, 0adh, 0aeh, 0afh
	db	0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 0b5h, 0b6h, 0b7h
	db	0b8h, 0b9h, 0bah, 0bbh, 0bch, 0bdh, 0beh, 0bfh
	db	0c0h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 0c6h, 0c7h
	db	0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 0cfh
	db	0d0h, 0d1h, 0d2h, 0d3h, 0d4h, 0d5h, 0d6h, 0d7h
	db	0d8h, 0d9h, 0dah, 0dbh, 0dch, 0ddh, 0deh, 0dfh
	db	0e0h, 0e1h, 0e2h, 0e3h, 0e4h, 0e5h, 0e6h, 0e7h
	db	0e8h, 0e9h, 0eah, 0ebh, 0ech, 0edh, 0eeh, 0efh
	db	0f0h, 0f1h, 0f2h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h
	db	0f8h, 0f9h, 0fah, 0fbh, 0fch, 0fdh, 0feh, 0ffh
endif
SwitzerlandCollating:
		dw  256	; Table Size
	db	 001h, 0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh
	db	 0cfh, 0d0h, 0d1h, 0d2h, 0d3h, 0d4h, 0d5h, 0d6h
	db	 0d7h, 0d8h, 0d9h, 0dah, 08ch, 08dh, 0dbh, 0dch
	db	 0ddh, 0deh, 0dfh, 0e0h, 0e1h, 0e2h, 0e3h, 0e4h
	db	 001h, 03ch, 03dh, 03dh, 03fh, 040h, 041h, 042h
	db	 043h, 044h, 045h, 046h, 047h, 048h, 049h, 04ah
	db	 020h, 021h, 022h, 023h, 024h, 025h, 026h, 027h
	db	 028h, 029h, 04bh, 04ch, 04dh, 04eh, 04fh, 050h
	db	 051h, 002h, 003h, 004h, 005h, 007h, 008h, 009h
	db	 00ah, 00bh, 00ch, 00dh, 00eh, 00fh, 010h, 012h
	db	 013h, 014h, 015h, 016h, 018h, 01ah, 01bh, 01ch
	db	 01dh, 01eh, 01fh, 052h, 053h, 054h, 034h, 055h
	db	 033h, 002h, 003h, 004h, 005h, 007h, 008h, 009h
	db	 00ah, 00bh, 00ch, 00dh, 00eh, 00fh, 010h, 012h
	db	 013h, 014h, 015h, 016h, 018h, 01ah, 01bh, 01ch
	db	 01dh, 01eh, 01fh, 056h, 057h, 058h, 036h, 059h
	db	 004h, 01ah, 007h, 002h, 002h, 002h, 002h, 004h
	db	 007h, 007h, 007h, 00bh, 00bh, 00bh, 002h, 002h
	db	 007h, 002h, 002h, 012h, 012h, 012h, 01ah, 01ah
	db	 01eh, 012h, 01ah, 06fh, 05ah, 070h, 096h, 05ch
	db	 002h, 00bh, 012h, 01ah, 011h, 011h, 002h, 012h
	db	 05dh, 097h, 05fh, 060h, 061h, 062h, 063h, 064h
	db	 065h, 066h, 067h, 068h, 069h, 098h, 099h, 09ah
	db	 09bh, 06bh, 06ch, 06dh, 06eh, 09ch, 09dh, 071h
	db	 072h, 073h, 074h, 075h, 076h, 077h, 09eh, 09fh
	db	 078h, 079h, 07ah, 07bh, 07ch, 07dh, 07eh, 0a0h
	db	 0a1h, 0a2h, 0a3h, 0a4h, 0a5h, 0a6h, 0a7h, 0a8h
	db	 0a9h, 080h, 081h, 082h, 083h, 0aah, 0abh, 085h
	db	 0ach, 017h, 0adh, 0aeh, 0afh, 0b0h, 086h, 0b1h
	db	 0b2h, 0b3h, 0b4h, 0b5h, 0b6h, 0b7h, 0b8h, 0b9h
	db	 0bah, 089h, 0bbh, 0bch, 0bdh, 0beh, 08eh, 0bfh
	db	 08fh, 0c0h, 090h, 0c1h, 0c2h, 093h, 094h, 001h
	
CzecCollating:
		dw 256 ; Table Size
	db	000h, 001h, 002h, 003h, 004h, 005h, 006h, 007h
	db	008h, 009h, 00Ah, 00Bh, 00Ch, 00Dh, 00Eh, 00Fh
	db	010h, 011h, 012h, 013h, 014h, 015h, 016h, 017h
	db	018h, 019h, 01Ah, 01Bh, 01Ch, 01Dh, 01Eh, 01Fh
	db	06Eh, 06Fh, 070h, 071h, 072h, 073h, 074h, 075h
	db	076h, 077h, 078h, 079h, 07Ah, 07Bh, 07Ch, 07Dh
	db	064h, 065h, 066h, 067h, 068h, 069h, 06Ah, 06Bh
	db	06Ch, 06Dh, 07Eh, 07Fh, 080h, 081h, 082h, 083h
	db	084h, 021h, 027h, 028h, 02Ch, 02Fh, 034h, 035h
	db	036h, 037h, 03Ah, 03Bh, 03Ch, 040h, 041h, 044h
	db	049h, 04Ah, 04Bh, 04Eh, 053h, 056h, 05Bh, 05Ch
	db	05Dh, 05Eh, 060h, 085h, 086h, 087h, 088h, 089h
	db	08Ah, 021h, 027h, 028h, 02Ch, 02Fh, 034h, 035h
	db	036h, 037h, 03Ah, 03Bh, 03Ch, 040h, 041h, 044h
	db	049h, 04Ah, 04Bh, 04Eh, 053h, 056h, 05Bh, 05Ch
	db	05Dh, 05Eh, 060h, 08Bh, 08Ch, 08Dh, 08Eh, 020h
	db	02Bh, 059h, 030h, 026h, 023h, 058h, 029h, 02Bh
	db	03Fh, 033h, 048h, 048h, 039h, 062h, 023h, 029h
	db	030h, 03Dh, 03Dh, 046h, 047h, 03Eh, 03Eh, 052h
	db	052h, 047h, 059h, 054h, 054h, 03Fh, 08Fh, 02Ah
	db	022h, 038h, 045h, 057h, 024h, 024h, 061h, 061h
	db	032h, 032h, 090h, 062h, 02Ah, 051h, 091h, 092h
	db	097h, 098h, 099h, 09Ah, 09Bh, 022h, 026h, 031h
	db	051h, 09Ch, 09Dh, 09Eh, 09Fh, 063h, 063h, 0A0h
	db	0A1h, 0A2h, 0A3h, 0A4h, 0A5h, 0A6h, 025h, 025h
	db	0A7h, 0A8h, 0A9h, 0AAh, 0ABh, 0ACh, 0ADh, 093h
	db	02Dh, 02Dh, 02Eh, 033h, 02Eh, 042h, 038h, 039h
	db	031h, 0AEh, 0AFh, 0B0h, 0B1h, 055h, 058h, 0B2h
	db	045h, 04Fh, 046h, 043h, 043h, 042h, 050h, 050h
	db	04Ch, 057h, 04Ch, 05Ah, 05Fh, 05Fh, 055h, 0B4h
	db	094h, 0B5h, 0B6h, 0B7h, 0B8h, 095h, 09Fh, 001h
	db	04Fh, 00Eh, 080h, 0FCh, 014h, 074h, 005h, 0FFh

PolCollating:
		dw 256 ; Table Size
	db	000h, 001h, 002h, 003h, 004h, 005h, 006h, 007h
	db	008h, 009h, 00Ah, 00Bh, 00Ch, 00Dh, 00Eh, 00Fh
	db	010h, 011h, 012h, 013h, 014h, 015h, 016h, 017h
	db	018h, 019h, 01Ah, 01Bh, 01Ch, 01Dh, 01Eh, 01Fh
	db	06Eh, 06Fh, 070h, 071h, 072h, 073h, 074h, 075h
	db	076h, 077h, 078h, 079h, 07Ah, 07Bh, 07Ch, 07Dh
	db	064h, 065h, 066h, 067h, 068h, 069h, 06Ah, 06Bh
	db	06Ch, 06Dh, 07Eh, 07Fh, 080h, 081h, 082h, 083h
	db	084h, 021h, 027h, 028h, 02Ch, 02Fh, 034h, 035h
	db	036h, 037h, 03Ah, 03Bh, 03Ch, 040h, 041h, 044h
	db	049h, 04Ah, 04Bh, 04Eh, 053h, 056h, 05Bh, 05Ch
	db	05Dh, 05Eh, 060h, 085h, 086h, 087h, 088h, 089h
	db	08Ah, 021h, 027h, 028h, 02Ch, 02Fh, 034h, 035h
	db	036h, 037h, 03Ah, 03Bh, 03Ch, 040h, 041h, 044h
	db	049h, 04Ah, 04Bh, 04Eh, 053h, 056h, 05Bh, 05Ch
	db	05Dh, 05Eh, 060h, 08Bh, 08Ch, 08Dh, 08Eh, 020h
	db	02Bh, 059h, 030h, 026h, 023h, 058h, 029h, 02Bh
	db	03Fh, 033h, 048h, 048h, 039h, 062h, 023h, 029h
	db	030h, 03Dh, 03Dh, 046h, 047h, 03Eh, 03Eh, 052h
	db	052h, 047h, 059h, 054h, 054h, 03Fh, 08Fh, 02Ah
	db	022h, 038h, 045h, 057h, 024h, 024h, 061h, 061h
	db	032h, 032h, 090h, 062h, 02Ah, 051h, 091h, 092h
	db	097h, 098h, 099h, 09Ah, 09Bh, 022h, 026h, 031h
	db	051h, 09Ch, 09Dh, 09Eh, 09Fh, 063h, 063h, 0A0h
	db	0A1h, 0A2h, 0A3h, 0A4h, 0A5h, 0A6h, 025h, 025h
	db	0A7h, 0A8h, 0A9h, 0AAh, 0ABh, 0ACh, 0ADh, 093h
	db	02Dh, 02Dh, 02Eh, 033h, 02Eh, 042h, 038h, 039h
	db	031h, 0AEh, 0AFh, 0B0h, 0B1h, 055h, 058h, 0B2h
	db	045h, 04Fh, 046h, 043h, 043h, 042h, 050h, 050h
	db	04Ch, 057h, 04Ch, 05Ah, 05Fh, 05Fh, 055h, 0B4h
	db	094h, 0B5h, 0B6h, 0B7h, 0B8h, 095h, 09Fh, 001h
	db	04Fh, 00Eh, 080h, 0FCh, 014h, 074h, 005h, 02Eh

CzecUcase:
		dw 128 ; Table Size
	db	080h, 09Ah, 090h, 0B6h, 08Eh, 0DEh, 08Fh, 080h
	db	09Dh, 0D3h, 08Ah, 08Ah, 0D7h, 08Dh, 08Eh, 08Fh
	db	090h, 091h, 091h, 0E2h, 099h, 095h, 095h, 097h
	db	097h, 099h, 09Ah, 09Bh, 09Bh, 09Dh, 09Eh, 0ACh
	db	0B5h, 0D6h, 0E0h, 0E9h, 0A4h, 0A4h, 0A6h, 0A6h
	db	0A8h, 0A8h, 0AAh, 08Dh, 0ACh, 0B8h, 0AEh, 0AFh
	db	0B0h, 0B1h, 0B2h, 0B3h, 0B4h, 0B5h, 0B6h, 0B7h
	db	0B8h, 0B9h, 0BAh, 0BBh, 0BCh, 0BDh, 0BDh, 0BFh
	db	0C0h, 0C1h, 0C2h, 0C3h, 0C4h, 0C5h, 0C6h, 0C6h
	db	0C8h, 0C9h, 0CAh, 0CBh, 0CCh, 0CDh, 0CEh, 0CFh
	db	0D1h, 0D1h, 0D2h, 0D3h, 0D2h, 0D5h, 0D6h, 0D7h
	db	0B7h, 0D9h, 0DAh, 0DBh, 0DCh, 0DDh, 0DEh, 0DFh
	db	0E0h, 0E1h, 0E2h, 0E3h, 0E3h, 0D5h, 0E6h, 0E6h
	db	0E8h, 0E9h, 0E8h, 0EBh, 0EDh, 0EDh, 0DDh, 0EFh
	db	0F0h, 0F1h, 0F2h, 0F3h, 0F4h, 0F5h, 0F6h, 0F7h
	db	0F8h, 0F9h, 0FAh, 0EBh, 0FCh, 0FCh, 0FEh, 0FFh

CzecUcase850:
		dw 128 ; Table Size
	db	080h, 09Ah, 090h, 0B6h, 08Eh, 0B7h, 08Fh, 080h
	db	0D2h, 0D3h, 0D4h, 0D8h, 0D7h, 0DEh, 08Eh, 08Fh
	db	090h, 092h, 092h, 0E2h, 099h, 0E3h, 0EAh, 0EBh
	db	098h, 099h, 09Ah, 09Dh, 09Ch, 09Dh, 09Eh, 09Fh
	db	0B5h, 0D6h, 0E0h, 0E9h, 0A5h, 0A5h, 0A6h, 0A7h
	db	0A8h, 0A9h, 0AAh, 0ABh, 0ACh, 0ADh, 0AEh, 0AFh
	db	0B0h, 0B1h, 0B2h, 0B3h, 0B4h, 0B5h, 0B6h, 0B7h
	db	0B8h, 0B9h, 0BAh, 0BBh, 0BCh, 0BDh, 0BEh, 0BFh
	db	0C0h, 0C1h, 0C2h, 0C3h, 0C4h, 0C5h, 0C7h, 0C7h
	db	0C8h, 0C9h, 0CAh, 0CBh, 0CCh, 0CDh, 0CEh, 0CFh
	db	0D1h, 0D1h, 0D2h, 0D3h, 0D4h, 0D5h, 0D6h, 0D7h
	db	0D8h, 0D9h, 0DAh, 0DBh, 0DCh, 0DDh, 0DEh, 0DFh
	db	0E0h, 0E1h, 0E2h, 0E3h, 0E5h, 0E5h, 0E6h, 0E8h
	db	0E8h, 0E9h, 0EAh, 0EBh, 0EDh, 0EDh, 0EEh, 0EFh
	db	0F0h, 0F1h, 0F2h, 0F3h, 0F4h, 0F5h, 0F6h, 0F7h
	db	0F8h, 0F9h, 0FAh, 0FBh, 0FCh, 0FDh, 0FEh, 0FFh

PolandUcase:
		dw 128 ; Table Size
	db	080h, 09Ah, 090h, 0B6h, 08Eh, 0DEh, 08Fh, 080h
	db	09Dh, 0D3h, 08Ah, 08Ah, 0D7h, 08Dh, 08Eh, 08Fh
	db	090h, 091h, 091h, 0E2h, 099h, 095h, 095h, 097h
	db	097h, 099h, 09Ah, 09Bh, 09Bh, 09Dh, 09Eh, 0ACh
	db	0B5h, 0D6h, 0E0h, 0E9h, 0A4h, 0A4h, 0A6h, 0A6h
	db	0A8h, 0A8h, 0AAh, 08Dh, 0ACh, 0B8h, 0AEh, 0AFh
	db	0B0h, 0B1h, 0B2h, 0B3h, 0B4h, 0B5h, 0B6h, 0B7h
	db	0B8h, 0B9h, 0BAh, 0BBh, 0BCh, 0BDh, 0BDh, 0BFh
	db	0C0h, 0C1h, 0C2h, 0C3h, 0C4h, 0C5h, 0C6h, 0C6h
	db	0C8h, 0C9h, 0CAh, 0CBh, 0CCh, 0CDh, 0CEh, 0CFh
	db	0D1h, 0D1h, 0D2h, 0D3h, 0D2h, 0D5h, 0D6h, 0D7h
	db	0B7h, 0D9h, 0DAh, 0DBh, 0DCh, 0DDh, 0DEh, 0DFh
	db	0E0h, 0E1h, 0E2h, 0E3h, 0E3h, 0D5h, 0E6h, 0E6h
	db	0E8h, 0E9h, 0E8h, 0EBh, 0EDh, 0EDh, 0DDh, 0EFh
	db	0F0h, 0F1h, 0F2h, 0F3h, 0F4h, 0F5h, 0F6h, 0F7h
	db	0F8h, 0F9h, 0FAh, 0EBh, 0FCh, 0FCh, 0FEh, 0FFh

PolandUcase850:
		dw 128 ; Table Size
	db	080h, 09Ah, 090h, 0B6h, 08Eh, 0B7h, 08Fh, 080h
	db	0D2h, 0D3h, 0D4h, 0D8h, 0D7h, 0DEh, 08Eh, 08Fh
	db	090h, 092h, 092h, 0E2h, 099h, 0E3h, 0EAh, 0EBh
	db	098h, 099h, 09Ah, 09Dh, 09Ch, 09Dh, 09Eh, 09Fh
	db	0B5h, 0D6h, 0E0h, 0E9h, 0A5h, 0A5h, 0A6h, 0A7h
	db	0A8h, 0A9h, 0AAh, 0ABh, 0ACh, 0ADh, 0AEh, 0AFh
	db	0B0h, 0B1h, 0B2h, 0B3h, 0B4h, 0B5h, 0B6h, 0B7h
	db	0B8h, 0B9h, 0BAh, 0BBh, 0BCh, 0BDh, 0BEh, 0BFh
	db	0C0h, 0C1h, 0C2h, 0C3h, 0C4h, 0C5h, 0C7h, 0C7h
	db	0C8h, 0C9h, 0CAh, 0CBh, 0CCh, 0CDh, 0CEh, 0CFh
	db	0D1h, 0D1h, 0D2h, 0D3h, 0D4h, 0D5h, 0D6h, 0D7h
	db	0D8h, 0D9h, 0DAh, 0DBh, 0DCh, 0DDh, 0DEh, 0DFh
	db	0E0h, 0E1h, 0E2h, 0E3h, 0E5h, 0E5h, 0E6h, 0E8h
	db	0E8h, 0E9h, 0EAh, 0EBh, 0EDh, 0EDh, 0EEh, 0EFh
	db	0F0h, 0F1h, 0F2h, 0F3h, 0F4h, 0F5h, 0F6h, 0F7h
	db	0F8h, 0F9h, 0FAh, 0FBh, 0FCh, 0FDh, 0FEh, 0FFh

BrazilUcase:
		dw 128 ; Table Size
	db	080h, 09Ah, 045h, 041h, 08Eh, 041h, 08Fh, 080h
	db	045h, 045h, 045h, 049h, 049h, 049h, 08Eh, 08Fh
	db	090h, 092h, 092h, 04Fh, 099h, 04Fh, 055h, 055h
	db	059h, 099h, 09Ah, 09Bh, 09Ch, 09Dh, 09Eh, 09Fh
	db	041h, 049h, 04Fh, 055h, 0A5h, 0A5h, 0A6h, 0A7h
	db	0A8h, 0A9h, 0AAh, 0ABh, 0ACh, 0ADh, 0AEh, 0AFh
	db	0B0h, 0B1h, 0B2h, 0B3h, 0B4h, 0B5h, 0B6h, 0B7h
	db	0B8h, 0B9h, 0BAh, 0BBh, 0BCh, 0BDh, 0BEh, 0BFh
	db	0C0h, 0C1h, 0C2h, 0C3h, 0C4h, 0C5h, 0C6h, 0C7h
	db	0C8h, 0C9h, 0CAh, 0CBh, 0CCh, 0CDh, 0CEh, 0CFh
	db	0D0h, 0D1h, 0D2h, 0D3h, 0D4h, 0D5h, 0D6h, 0D7h
	db	0D8h, 0D9h, 0DAh, 0DBh, 0DCh, 0DDh, 0DEh, 0DFh
	db	0E0h, 0E1h, 0E2h, 0E3h, 0E4h, 0E5h, 0E6h, 0E7h
	db	0E8h, 0E9h, 0EAh, 0EBh, 0ECh, 0EDh, 0EEh, 0EFh
	db	0F0h, 0F1h, 0F2h, 0F3h, 0F4h, 0F5h, 0F6h, 0F7h
	db	0F8h, 0F9h, 0FAh, 0FBh, 0FCh, 0FDh, 0FEh, 0FFh

BrazilUcase850:
		dw 128 ; Table Size
	db	080h, 09Ah, 090h, 0B6h, 08Eh, 0B7h, 08Fh, 080h
	db	0D2h, 0D3h, 0D4h, 0D8h, 0D7h, 0DEh, 08Eh, 08Fh
	db	090h, 092h, 092h, 0E2h, 099h, 0E3h, 0EAh, 0EBh
	db	098h, 099h, 09Ah, 09Dh, 09Ch, 09Dh, 09Eh, 09Fh
	db	0B5h, 0D6h, 0E0h, 0E9h, 0A5h, 0A5h, 0A6h, 0A7h
	db	0A8h, 0A9h, 0AAh, 0ABh, 0ACh, 0ADh, 0AEh, 0AFh
	db	0B0h, 0B1h, 0B2h, 0B3h, 0B4h, 0B5h, 0B6h, 0B7h
	db	0B8h, 0B9h, 0BAh, 0BBh, 0BCh, 0BDh, 0BEh, 0BFh
	db	0C0h, 0C1h, 0C2h, 0C3h, 0C4h, 0C5h, 0C7h, 0C7h
	db	0C8h, 0C9h, 0CAh, 0CBh, 0CCh, 0CDh, 0CEh, 0CFh
	db	0D1h, 0D1h, 0D2h, 0D3h, 0D4h, 0D5h, 0D6h, 0D7h
	db	0D8h, 0D9h, 0DAh, 0DBh, 0DCh, 0DDh, 0DEh, 0DFh
	db	0E0h, 0E1h, 0E2h, 0E3h, 0E5h, 0E5h, 0E6h, 0E8h
	db	0E8h, 0E9h, 0EAh, 0EBh, 0EDh, 0EDh, 0EEh, 0EFh
	db	0F0h, 0F1h, 0F2h, 0F3h, 0F4h, 0F5h, 0F6h, 0F7h
	db	0F8h, 0F9h, 0FAh, 0FBh, 0FCh, 0FDh, 0FEh, 0FFh

BrazilCollating:
		dw 256 ; Table Size
	db	000h, 001h, 002h, 003h, 004h, 005h, 006h, 007h
	db	008h, 009h, 00Ah, 00Bh, 00Ch, 00Dh, 00Eh, 00Fh
	db	010h, 011h, 012h, 013h, 014h, 015h, 016h, 017h
	db	018h, 019h, 01Ah, 01Bh, 01Ch, 01Dh, 01Eh, 01Fh
	db	020h, 021h, 022h, 023h, 024h, 025h, 026h, 027h
	db	028h, 029h, 02Ah, 02Bh, 02Ch, 02Dh, 02Eh, 02Fh
	db	030h, 031h, 032h, 033h, 034h, 035h, 036h, 037h
	db	038h, 039h, 03Ah, 03Bh, 03Ch, 03Dh, 03Eh, 03Fh
	db	040h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	048h, 049h, 04Ah, 04Bh, 04Ch, 04Dh, 04Eh, 04Fh
	db	050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	058h, 059h, 05Ah, 05Bh, 05Ch, 05Dh, 05Eh, 05Fh
	db	060h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	048h, 049h, 04Ah, 04Bh, 04Ch, 04Dh, 04Eh, 04Fh
	db	050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	058h, 059h, 05Ah, 07Bh, 07Ch, 07Dh, 07Eh, 07Fh
	db	043h, 055h, 045h, 041h, 041h, 041h, 041h, 043h
	db	045h, 045h, 045h, 049h, 049h, 049h, 041h, 041h
	db	045h, 041h, 041h, 04Fh, 04Fh, 04Fh, 055h, 055h
	db	059h, 04Fh, 055h, 024h, 024h, 024h, 024h, 024h
	db	041h, 049h, 04Fh, 055h, 04Eh, 04Eh, 0A6h, 0A7h
	db	03Fh, 0A9h, 0AAh, 0ABh, 0ACh, 021h, 022h, 022h
	db	0B0h, 0B1h, 0B2h, 0B3h, 0B4h, 0B5h, 0B6h, 0B7h
	db	0B8h, 0B9h, 0BAh, 0BBh, 0BCh, 0BDh, 0BEh, 0BFh
	db	0C0h, 0C1h, 0C2h, 0C3h, 0C4h, 0C5h, 0C6h, 0C7h
	db	0C8h, 0C9h, 0CAh, 0CBh, 0CCh, 0CDh, 0CEh, 0CFh
	db	0D0h, 0D1h, 0D2h, 0D3h, 0D4h, 0D5h, 0D6h, 0D7h
	db	0D8h, 0D9h, 0DAh, 0DBh, 0DCh, 0DDh, 0DEh, 0DFh
	db	0E0h, 053h, 0E2h, 0E3h, 0E4h, 0E5h, 0E6h, 0E7h
	db	0E8h, 0E9h, 0EAh, 0EBh, 0ECh, 0EDh, 0EEh, 0EFh
	db	0F0h, 0F1h, 0F2h, 0F3h, 0F4h, 0F5h, 0A0h, 001h
	db	0C4h, 012h, 080h, 0FCh, 014h, 074h, 005h, 02Eh

BrazilCollat850:
		dw 256 ; Table Size
	db	000h, 001h, 002h, 003h, 004h, 005h, 006h, 007h
	db	008h, 009h, 00Ah, 00Bh, 00Ch, 00Dh, 00Eh, 00Fh
	db	010h, 011h, 012h, 013h, 014h, 015h, 016h, 017h
	db	018h, 019h, 01Ah, 01Bh, 01Ch, 01Dh, 01Eh, 01Fh
	db	020h, 021h, 022h, 023h, 024h, 025h, 026h, 027h
	db	028h, 029h, 02Ah, 02Bh, 02Ch, 02Dh, 02Eh, 02Fh
	db	030h, 031h, 032h, 033h, 034h, 035h, 036h, 037h
	db	038h, 039h, 03Ah, 03Bh, 03Ch, 03Dh, 03Eh, 03Fh
	db	040h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	048h, 049h, 04Ah, 04Bh, 04Ch, 04Dh, 04Eh, 04Fh
	db	050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	058h, 059h, 05Ah, 05Bh, 05Ch, 05Dh, 05Eh, 05Fh
	db	060h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	048h, 049h, 04Ah, 04Bh, 04Ch, 04Dh, 04Eh, 04Fh
	db	050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	058h, 059h, 05Ah, 07Bh, 07Ch, 07Dh, 07Eh, 07Fh
	db	043h, 055h, 045h, 041h, 041h, 041h, 041h, 043h
	db	045h, 045h, 045h, 049h, 049h, 049h, 041h, 041h
	db	045h, 041h, 041h, 04Fh, 04Fh, 04Fh, 055h, 055h
	db	059h, 04Fh, 055h, 04Fh, 024h, 04Fh, 09Eh, 024h
	db	041h, 049h, 04Fh, 055h, 04Eh, 04Eh, 0A6h, 0A7h
	db	03Fh, 0A9h, 0AAh, 0ABh, 0ACh, 021h, 022h, 022h
	db	0B0h, 0B1h, 0B2h, 0B3h, 0B4h, 041h, 041h, 041h
	db	0B8h, 0B9h, 0BAh, 0BBh, 0BCh, 024h, 024h, 0BFh
	db	0C0h, 0C1h, 0C2h, 0C3h, 0C4h, 0C5h, 041h, 041h
	db	0C8h, 0C9h, 0CAh, 0CBh, 0CCh, 0CDh, 0CEh, 024h
	db	044h, 044h, 045h, 045h, 045h, 049h, 049h, 049h
	db	049h, 0D9h, 0DAh, 0DBh, 0DCh, 0DDh, 049h, 0DFh
	db	04Fh, 053h, 04Fh, 04Fh, 04Fh, 04Fh, 0E6h, 0E8h
	db	0E8h, 055h, 055h, 055h, 059h, 059h, 0EEh, 0EFh
	db	0F0h, 0F1h, 0F2h, 0F3h, 0F4h, 0F5h, 0F6h, 0F7h
	db	0F8h, 0F9h, 0FAh, 0FBh, 0FCh, 0FDh, 0FEh, 0FFh

DenmarkUcase:
		dw  128	; Table Size

	db	080h, 09ah, 090h,  'A', 08eh,  'A', 08fh, 080h
	db	 'E',  'E',  'E',  'I',  'I',  'I', 08eh, 08fh
	db	090h, 092h, 092h,  'O', 099h,  'O',  'U',  'U'
	db	 'Y', 099h, 09ah
danish_table:	
	db	09dh, 09ch, 09dh, 09eh, 09fh	; 9Bh
	db	 'A',  'I',  'O',  'U', 0a5h, 0a5h, 0a6h, 0a7h
	db	0a8h, 0a9h
	db	0aah, 0abh, 0ach, 0adh, 0aeh, 0afh
	db	0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 0b5h, 0b6h, 0b7h
	db	0b8h, 0b9h, 0bah, 0bbh, 0bch, 0bdh, 0beh, 0bfh
	db	0c0h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 0c6h, 0c7h
	db	0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 0cfh
	db	0d0h, 0d1h, 0d2h, 0d3h, 0d4h, 0d5h, 0d6h, 0d7h
	db	0d8h, 0d9h, 0dah, 0dbh, 0dch, 0ddh, 0deh, 0dfh
	db	0e0h, 0e1h, 0e2h, 0e3h, 0e4h, 0e5h, 0e6h, 0e7h
	db	0e8h, 0e9h, 0eah, 0ebh, 0ech, 0edh, 0eeh, 0efh
	db	0f0h, 0f1h, 0f2h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h
	db	0f8h, 0f9h, 0fah, 0fbh, 0fch, 0fdh, 0feh, 0ffh

DenmarkCollating:
		dw  256	; Table Size
	db	 000h, 001h, 002h, 003h, 004h, 005h, 006h, 007h
	db	 008h, 009h, 00ah, 00bh, 00ch, 00dh, 00eh, 00fh
	db	 010h, 011h, 012h, 013h, 014h, 015h, 016h, 017h
	db	 018h, 019h, 01ah, 01bh, 01ch, 01dh, 01eh, 01fh
	db	 020h, 021h, 022h, 023h, 024h, 025h, 026h, 027h
	db	 028h, 029h, 02ah, 02bh, 02ch, 02dh, 02eh, 02fh
	db	 030h, 031h, 032h, 033h, 034h, 035h, 036h, 037h
	db	 038h, 039h, 03ah, 03bh, 03ch, 03dh, 03eh, 03fh
	db	 040h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 028h, 02fh, 029h, 05eh, 05fh
	db	 060h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 028h, 02fh, 029h, 07eh, 07fh
	db	 043h, 059h, 045h, 041h, 05bh, 041h, 05dh, 043h
	db	 045h, 045h, 045h, 049h, 049h, 049h, 05bh, 05dh
	db	 045h, 05bh, 05bh, 04fh, 05ch, 04fh, 055h, 055h
	db	 059h, 05ch, 059h, 05ch, 024h, 05ch, 024h, 024h
	db	 041h, 049h, 04fh, 055h, 04eh, 04eh, 041h, 04fh
	db	 03fh, 0a9h, 0aah, 0abh, 0ach, 021h, 022h, 024h
	db	 0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 0b5h, 0b6h, 0b7h
	db	 0b8h, 0b9h, 0bah, 0bbh, 0bch, 0bdh, 0beh, 0bfh
	db	 0c0h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 0c6h, 0c7h
	db	 0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 0cfh
	db	 0d0h, 0d1h, 0d2h, 0d3h, 0d4h, 0d5h, 0d6h, 0d7h
	db	 0d8h, 0d9h, 0dah, 0dbh, 0dch, 0ddh, 0deh, 0dfh
	db	 0e0h, 053h, 0e2h, 0e3h, 0e4h, 0e5h, 0e6h, 0e7h
	db	 0e8h, 0e9h, 0eah, 0ebh, 0ech, 0edh, 0eeh, 0efh
	db	 0f0h, 0f1h, 0f2h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h
	db	 0f8h, 0f9h, 0fah, 0fbh, 0fch, 0fdh, 0feh, 0ffh


if COMPATIBLE
SwedenUcase:
		dw  128	; Table Size

	db	080h, 09ah, 090h,  'A', 08eh,  'A', 08fh, 080h
	db	 'E',  'E',  'E',  'I',  'I',  'I', 08eh, 08fh
	db	090h, 092h, 092h,  'O', 099h,  'O',  'U',  'U'
	db	 'Y', 099h, 09ah, 09bh, 09ch, 09dh, 09eh, 09fh
	db	 'A',  'I',  'O',  'U', 0a5h, 0a5h, 0a6h, 0a7h
	db	0a8h, 0a9h, 0aah, 0abh, 0ach, 0adh, 0aeh, 0afh
	db	0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 0b5h, 0b6h, 0b7h
	db	0b8h, 0b9h, 0bah, 0bbh, 0bch, 0bdh, 0beh, 0bfh
	db	0c0h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 0c6h, 0c7h
	db	0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 0cfh
	db	0d0h, 0d1h, 0d2h, 0d3h, 0d4h, 0d5h, 0d6h, 0d7h
	db	0d8h, 0d9h, 0dah, 0dbh, 0dch, 0ddh, 0deh, 0dfh
	db	0e0h, 0e1h, 0e2h, 0e3h, 0e4h, 0e5h, 0e6h, 0e7h
	db	0e8h, 0e9h, 0eah, 0ebh, 0ech, 0edh, 0eeh, 0efh
	db	0f0h, 0f1h, 0f2h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h
	db	0f8h, 0f9h, 0fah, 0fbh, 0fch, 0fdh, 0feh, 0ffh
endif
SwedenCollating:
		dw  256	; Table Size
	db	 000h, 001h, 002h, 003h, 004h, 005h, 006h, 007h
	db	 008h, 009h, 00ah, 00bh, 00ch, 00dh, 00eh, 00fh
	db	 010h, 011h, 012h, 013h, 014h, 015h, 016h, 017h
	db	 018h, 019h, 01ah, 01bh, 01ch, 01dh, 01eh, 01fh
	db	 020h, 021h, 022h, 023h, 024h, 025h, 026h, 027h
	db	 028h, 029h, 02ah, 02bh, 02ch, 02dh, 02eh, 02fh
	db	 030h, 031h, 032h, 033h, 034h, 035h, 036h, 037h
	db	 038h, 039h, 03ah, 03bh, 03ch, 03dh, 03eh, 03fh
	db	 040h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 05bh, 05ch, 05dh, 05eh, 05fh
	db	 060h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 07bh, 07ch, 07dh, 07eh, 07fh
	db	 043h, 059h, 045h, 041h, 05ch, 041h, 05bh, 043h
	db	 045h, 045h, 045h, 049h, 049h, 049h, 05ch, 05bh
	db	 045h, 05ch, 05ch, 04fh, 05dh, 04fh, 055h, 055h
	db	 059h, 05dh, 059h, 024h, 024h, 024h, 024h, 024h
	db	 041h, 049h, 04fh, 055h, 04eh, 04eh, 0a6h, 0a7h
	db	 03fh, 0a9h, 0aah, 0abh, 0ach, 021h, 022h, 022h
	db	 0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 0b5h, 0b6h, 0b7h
	db	 0b8h, 0b9h, 0bah, 0bbh, 0bch, 0bdh, 0beh, 0bfh
	db	 0c0h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 0c6h, 0c7h
	db	 0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 0cfh
	db	 0d0h, 0d1h, 0d2h, 0d3h, 0d4h, 0d5h, 0d6h, 0d7h
	db	 0d8h, 0d9h, 0dah, 0dbh, 0dch, 0ddh, 0deh, 0dfh
	db	 0e0h, 053h, 0e2h, 0e3h, 0e4h, 0e5h, 0e6h, 0e7h
	db	 0e8h, 0e9h, 0eah, 0ebh, 0ech, 0edh, 0eeh, 0efh
	db	 0f0h, 0f1h, 0f2h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h
	db	 0f8h, 0f9h, 0fah, 0fbh, 0fch, 0fdh, 0feh, 0ffh



NorwayCollating:
		dw  256	; Table Size
	db	 000h, 001h, 002h, 003h, 004h, 005h, 006h, 007h
	db	 008h, 009h, 00ah, 00bh, 00ch, 00dh, 00eh, 00fh
	db	 010h, 011h, 012h, 013h, 014h, 015h, 016h, 017h
	db	 018h, 019h, 01ah, 01bh, 01ch, 01dh, 01eh, 01fh
	db	 020h, 021h, 022h, 023h, 024h, 025h, 026h, 027h
	db	 028h, 029h, 02ah, 02bh, 02ch, 02dh, 02eh, 02fh
	db	 030h, 031h, 032h, 033h, 034h, 035h, 036h, 037h
	db	 038h, 039h, 03ah, 03bh, 03ch, 03dh, 03eh, 03fh
	db	 040h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 05bh, 05ch, 05dh, 05eh, 05fh
	db	 060h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 07bh, 07ch, 07dh, 07eh, 07fh
	db	 043h, 059h, 045h, 041h, 05bh, 041h, 05dh, 043h
	db	 045h, 045h, 045h, 049h, 049h, 049h, 05bh, 05dh
	db	 045h, 05bh, 05bh, 04fh, 05ch, 04fh, 055h, 055h
	db	 059h, 05ch, 059h, 05ch, 024h, 05ch, 024h, 024h
	db	 041h, 049h, 04fh, 055h, 04eh, 04eh, 041h, 04fh
	db	 03fh, 0a9h, 0aah, 0abh, 0ach, 021h, 022h, 024h
	db	 0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 0b5h, 0b6h, 0b7h
	db	 0b8h, 0b9h, 0bah, 0bbh, 0bch, 0bdh, 0beh, 0bfh
	db	 0c0h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 0c6h, 0c7h
	db	 0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 0cfh
	db	 0d0h, 0d1h, 0d2h, 0d3h, 0d4h, 0d5h, 0d6h, 0d7h
	db	 0d8h, 0d9h, 0dah, 0dbh, 0dch, 0ddh, 0deh, 0dfh
	db	 0e0h, 053h, 0e2h, 0e3h, 0e4h, 0e5h, 0e6h, 0e7h
	db	 0e8h, 0e9h, 0eah, 0ebh, 0ech, 0edh, 0eeh, 0efh
	db	 0f0h, 0f1h, 0f2h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h
	db	 0f8h, 0f9h, 0fah, 0fbh, 0fch, 0fdh, 0feh, 0ffh

if TURKCP EQ 853
;
;	UpperCase Table for Turkish CodePage 853 
;
TurkishUcase:
		dw  128	; Table Size
Turkish_table:
	db	080h, 09ah, 090h, 0b6h, 08eh, 0b7h, 08fh, 080h 
	db	0d2h, 0d3h, 0d4h, 0d8h, 0d7h, 049h, 08eh, 08fh 
	db	090h, 092h, 092h, 0e2h, 099h, 0e3h, 0eah, 0ebh 
	db	098h, 099h, 09ah, 09dh, 09ch, 09dh, 09eh, 09eh 
	db	0b5h, 0d6h, 0e0h, 0e9h, 0a5h, 0a5h, 0a6h, 0a6h 
	db	0a8h, 0a8h, 0aah, 0abh, 0ach, 09eh, 0aeh, 0afh 
	db	0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 0b5h, 0b6h, 0b7h 
	db	0b8h, 0b9h, 0bah, 0bbh, 0bch, 0bdh, 0bdh, 0bfh 
	db	0c0h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 0c6h, 0c6h 
	db	0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 0cfh 
	db	0d0h, 0d1h, 0d2h, 0d3h, 0d4h, 049h, 0d6h, 0d7h 	
	db	0d8h, 0d9h, 0dah, 0dbh, 0dch, 0ddh, 0deh, 0dfh 
	db	0e0h, 0e1h, 0e2h, 0e3h, 0e4h, 0e4h, 0e6h, 0e7h 
	db	0e7h, 0e9h, 0eah, 0ebh, 0ech, 0ech, 0eeh, 0efh 	
	db	0f0h, 0f1h, 0f2h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h 
	db	0f8h, 0f9h, 0fah, 0fbh, 0fch, 0fdh, 0feh, 0ffh

TurkishCollating:
		dw	256	; Table Size
	db	 000h, 001h, 002h, 003h, 004h, 005h, 006h, 007h
	db	 008h, 009h, 00ah, 00bh, 00ch, 00dh, 00eh, 00fh
	db	 010h, 011h, 012h, 013h, 014h, 015h, 016h, 017h
	db	 018h, 019h, 01ah, 01bh, 01ch, 01dh, 01eh, 01fh
	db	 020h, 021h, 022h, 023h, 024h, 025h, 026h, 027h
	db	 028h, 029h, 02ah, 02bh, 02ch, 02dh, 02eh, 02fh
	db	 030h, 031h, 032h, 033h, 034h, 035h, 036h, 037h
	db	 038h, 039h, 03ah, 03bh, 03ch, 03dh, 03eh, 03fh
	db	 040h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 05bh, 05ch, 05dh, 05eh, 05fh
	db	 060h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 07bh, 07ch, 07dh, 07eh, 07fh

	db	 043h, 055h, 045h, 041h, 041h, 041h, 043h, 043h
	db	 045h, 045h, 045h, 049h, 049h, 049h, 041h, 043h
	db	 045h, 043h, 043h, 04fh, 04fh, 04fh, 055h, 055h
	db	 049h, 04fh, 055h, 047h, 024h, 047h, 053h, 053h
	db	 041h, 049h, 04fh, 055h, 04eh, 04eh, 047h, 047h
	db	 048h, 048h, 020h, 0abh, 04ah, 053h, 022h, 022h
	db	 0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 041h, 041h, 041h
	db	 053h, 0b9h, 0bah, 0bbh, 0bch, 05ah, 05ah, 0bfh
	db	 0c0h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 053h, 053h
	db	 0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 024h
	db	 020h, 020h, 045h, 045h, 045h, 049h, 049h, 049h
	db	 049h, 0d9h, 0dah, 0dbh, 0dch, 020h, 049h, 0dfh
	db	 04fh, 0e1h, 04fh, 04fh, 047h, 047h, 0e6h, 048h
	db	 048h, 055h, 055h, 055h, 055h, 055h, 020h, 0efh
	db	 0f0h, 020h, 0f2h, 04eh, 0f4h, 0f5h, 0f6h, 0f7h
	db	 0f8h, 0f9h, 0fah, 020h, 0fch, 0fdh, 0feh, 0ffh
endif

if TURKCP EQ 857
;
;	Turkish UpperCase Table codepage 857  ????
;
TurkishUcase:
		dw  128	; Table Size
Turkish_table:
	db	080h, 09ah, 090h, 0b6h, 08eh, 0b7h, 08fh, 080h
	db	0d2h, 0d3h, 0d4h, 0d8h, 0d7h, 049h, 08eh, 08fh
	db	090h, 092h, 092h, 0e2h, 099h, 0e3h, 0eah, 0ebh
	db	098h, 099h, 09ah, 09dh, 09ch, 09dh, 09eh, 09eh
	db	0b5h, 0d6h, 0e0h, 0e9h, 0a5h, 0a5h, 0a6h, 0a6h
	db	0a8h, 0a9h, 0aah, 0abh, 0ach, 0adh, 0aeh, 0afh
	db	0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 0b5h, 0b6h, 0b7h
	db	0b8h, 0b9h, 0bah, 0bbh, 0bch, 0bdh, 0beh, 0bfh
	db	0c0h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 0c7h, 0c7h
	db	0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 0cfh
	db	0d0h, 0d1h, 0d2h, 0d3h, 0d4h, 0d5h, 0d6h, 0d7h
	db	0d8h, 0d9h, 0dah, 0dbh, 0dch, 0ddh, 0deh, 0dfh
	db	0e0h, 0e1h, 0e2h, 0e3h, 0e5h, 0e5h, 0e6h, 0e7h
	db	0e8h, 0e9h, 0eah, 0ebh, 0deh, 0edh, 0eeh, 0efh
	db	0f0h, 0f1h, 0f2h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h
	db	0f8h, 0f9h, 0fah, 0fbh, 0fch, 0fdh, 0feh, 0ffh
;
;
TurkishCollating:
		dw	256	; Table Size
	db	 000h, 001h, 002h, 003h, 004h, 005h, 006h, 007h
	db	 008h, 009h, 00ah, 00bh, 00ch, 00dh, 00eh, 00fh
	db	 010h, 011h, 012h, 013h, 014h, 015h, 016h, 017h
	db	 018h, 019h, 01ah, 01bh, 01ch, 01dh, 01eh, 01fh
	db	 020h, 021h, 022h, 023h, 024h, 025h, 026h, 027h
	db	 028h, 029h, 02ah, 02bh, 02ch, 02dh, 02eh, 02fh
	db	 030h, 031h, 032h, 033h, 034h, 035h, 036h, 037h
	db	 038h, 039h, 03ah, 03bh, 03ch, 03dh, 03eh, 03fh
	db	 040h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 028h, 02fh, 029h, 05eh, 05fh
	db	 060h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 028h, 02fh, 029h, 07eh, 07fh

	db	 043h, 055h, 045h, 041h, 041h, 041h, 041h, 043h
	db	 045h, 045h, 045h, 049h, 049h, 049h, 041h, 041h
	db	 045h, 041h, 041h, 04fh, 04fh, 04fh, 055h, 055h
	db	 049h, 04fh, 055h, 09bh, 024h, 04dh, 053h, 053h
	db	 041h, 049h, 04fh, 055h, 04eh, 04eh, 047h, 047h
	db	 0a8h, 0a9h, 0aah, 0abh, 0ach, 021h, 022h, 022h
	db	 0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 041h, 041h, 041h
	db	 0b8h, 0b9h, 0bah, 0bbh, 0bch, 0bdh, 0beh, 0bfh
	db	 0c0h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 041h, 041h
	db	 0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 024h
	db	 0d0h, 0d1h, 045h, 045h, 045h, 020h, 049h, 049h
	db	 049h, 0d9h, 0dah, 0dbh, 0dch, 0ddh, 049h, 0dfh
	db	 04fh, 0e1h, 04fh, 04fh, 04fh, 04fh, 0e6h, 020h
	db	 0e8h, 055h, 055h, 055h, 049h, 059h, 0eeh, 0efh
	db	 0f0h, 0f1h, 020h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h
	db	 0f8h, 0f9h, 0fah, 0fbh, 0fch, 0fdh, 0feh, 0ffh
endif

;;
PortugalUcase:
	dw  128	; Table Size
Portugese_table:
	db	080h, 09ah, 090h, 08fh, 08eh, 091h, 086h, 080h
	db	089h, 089h, 092h, 08bh, 08ch, 098h, 08eh, 08fh
	db	090h, 091h, 092h, 08ch, 099h, 0a9h, 096h, 09dh
	db	098h, 099h, 09ah, 09bh, 09ch, 09dh, 09eh, 09fh
	db	086h, 08bh, 09fh, 096h, 0a5h
	db	0a5h, 0a6h, 0a7h
	db	0a8h, 0a9h, 0aah, 0abh, 0ach, 0adh, 0aeh, 0afh
	db	0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 0b5h, 0b6h, 0b7h
	db	0b8h, 0b9h, 0bah, 0bbh, 0bch, 0bdh, 0beh, 0bfh
	db	0c0h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 0c6h, 0c7h
	db	0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 0cfh
	db	0d0h, 0d1h, 0d2h, 0d3h, 0d4h, 0d5h, 0d6h, 0d7h
	db	0d8h, 0d9h, 0dah, 0dbh, 0dch, 0ddh, 0deh, 0dfh
	db	0e0h, 0e1h, 0e2h, 0e3h, 0e4h, 0e5h, 0e6h, 0e7h
	db	0e8h, 0e9h, 0eah, 0ebh, 0ech, 0edh, 0eeh, 0efh
	db	0f0h, 0f1h, 0f2h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h
	db	0f8h, 0f9h, 0fah, 0fbh, 0fch, 0fdh, 0feh, 0ffh

PortugalCollating:
		dw  256	; Table Size
	db	 000h, 001h, 002h, 003h, 004h, 005h, 006h, 007h
	db	 008h, 009h, 00ah, 00bh, 00ch, 00dh, 00eh, 00fh
	db	 010h, 011h, 012h, 013h, 014h, 015h, 016h, 017h
	db	 018h, 019h, 01ah, 01bh, 01ch, 01dh, 01eh, 01fh
	db	 020h, 021h, 022h, 023h, 024h, 025h, 026h, 027h
	db	 028h, 029h, 02ah, 02bh, 02ch, 02dh, 02eh, 02fh
	db	 030h, 031h, 032h, 033h, 034h, 035h, 036h, 037h
	db	 038h, 039h, 03ah, 03bh, 03ch, 03dh, 03eh, 03fh
	db	 040h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 05bh, 05ch, 05dh, 05eh, 05fh
	db	 060h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 07bh, 07ch, 07dh, 07eh, 07fh
	db	 043h, 055h, 045h, 041h, 041h, 041h, 041h, 043h
	db	 045h, 045h, 045h, 049h, 04fh, 049h, 041h, 041h
	db	 045h, 041h, 045h, 04fh, 04fh, 04fh, 055h, 055h
	db	 049h, 04fh, 055h, 024h, 024h, 055h, 024h, 04fh
	db	 041h, 049h, 04fh, 055h, 04eh, 04eh, 0a6h, 0a7h
	db	 03fh, 04fh, 0aah, 0abh, 0ach, 021h, 022h, 022h
	db	 0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 0b5h, 0b6h, 0b7h
	db	 0b8h, 0b9h, 0bah, 0bbh, 0bch, 0bdh, 0beh, 0bfh
	db	 0c0h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 0c6h, 0c7h
	db	 0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 0cfh
	db	 0d0h, 0d1h, 0d2h, 0d3h, 0d4h, 0d5h, 0d6h, 0d7h
	db	 0d8h, 0d9h, 0dah, 0dbh, 0dch, 0ddh, 0deh, 0dfh
	db	 0e0h, 053h, 0e2h, 0e3h, 0e4h, 0e5h, 0e6h, 0e7h
	db	 0e8h, 0e9h, 0eah, 0ebh, 0ech, 0edh, 0eeh, 0efh
	db	 0f0h, 0f1h, 0f2h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h
	db	 0f8h, 0f9h, 0fah, 0fbh, 0fch, 0fdh, 0feh, 0ffh



MiddleEastCollating:
		dw  256	; Table Size
	db	 000h, 001h, 002h, 003h, 004h, 005h, 006h, 007h
	db	 008h, 009h, 00ah, 00bh, 00ch, 00dh, 00eh, 00fh
	db	 010h, 011h, 012h, 013h, 014h, 015h, 016h, 017h
	db	 018h, 019h, 01ah, 01bh, 01ch, 01dh, 01eh, 01fh
	db	 020h, 021h, 022h, 023h, 024h, 025h, 026h, 027h
	db	 028h, 029h, 02ah, 02bh, 02ch, 02dh, 02eh, 02fh
	db	 030h, 031h, 032h, 033h, 034h, 035h, 036h, 037h
	db	 038h, 039h, 03ah, 03bh, 03ch, 03dh, 03eh, 03fh
	db	 040h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 05bh, 05ch, 05dh, 05eh, 05fh
	db	 060h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 07bh, 07ch, 07dh, 07eh, 07fh
	db	 080h, 081h, 082h, 083h, 084h, 085h, 086h, 087h
	db	 088h, 089h, 08ah, 08bh, 08ch, 08dh, 08eh, 08fh
	db	 090h, 091h, 092h, 093h, 094h, 095h, 096h, 097h
	db	 098h, 0e9h, 0eah, 0fbh, 0ffh, 0ebh, 0ech, 0b3h
	db	 099h, 09ah, 0b6h, 09bh, 09ch, 0b8h, 0fdh, 0feh
	db	 0bch, 0bdh, 0c0h, 0c2h, 0a3h, 0c4h, 0c6h, 0c8h
	db	 0a4h, 0a5h, 0a6h, 0a7h, 0a8h, 0a9h, 0aah, 0abh
	db	 0ach, 0adh, 0e0h, 0aeh, 0ceh, 0d0h, 0d2h, 0afh
	db	 09dh, 0b4h, 0b5h, 0b7h, 0b9h, 0d9h, 0bah, 0bbh
	db	 0beh, 0bfh, 0c1h, 0c3h, 0c5h, 0c7h, 0c9h, 0cah
	db	 0cbh, 0cch, 0cdh, 0cfh, 0d1h, 0d3h, 0d5h, 0d6h
	db	 0d7h, 0dah, 0deh, 09eh, 09fh, 0a0h, 0a1h, 0d8h
	db	 0b2h, 0e1h, 0e3h, 0e5h, 0edh, 0efh, 0f1h, 0f3h
	db	 0f5h, 0f6h, 0fah, 0d4h, 0dbh, 0ddh, 0dch, 0eeh
	db	 0b1h, 0b0h, 0f0h, 0f2h, 0f4h, 0f7h, 0f9h, 0dfh
	db	 0e2h, 0e7h, 0e8h, 0e6h, 0e4h, 0f8h, 0a2h, 0ffh




IsraelUcase:
		dw  128	; Table Size

	db	080h, 081h, 082h, 083h, 084h, 085h, 086h, 087h
	db	088h, 089h, 08ah, 08bh, 08ch, 08dh, 08eh, 08fh
	db	090h, 091h, 092h, 093h, 094h, 095h, 096h, 097h
	db	098h, 099h, 09ah, 09bh, 09ch, 09dh, 09eh, 09fh
	db	 'A',  'I',  'O',  'U', 0a5h, 0a5h, 0a6h, 0a7h
	db	0a8h, 0a9h, 0aah, 0abh, 0ach, 0adh, 0aeh, 0afh
	db	0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 0b5h, 0b6h, 0b7h
	db	0b8h, 0b9h, 0bah, 0bbh, 0bch, 0bdh, 0beh, 0bfh
	db	0c0h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 0c6h, 0c7h
	db	0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 0cfh
	db	0d0h, 0d1h, 0d2h, 0d3h, 0d4h, 0d5h, 0d6h, 0d7h
	db	0d8h, 0d9h, 0dah, 0dbh, 0dch, 0ddh, 0deh, 0dfh
	db	0e0h, 0e1h, 0e2h, 0e3h, 0e4h, 0e5h, 0e6h, 0e7h
	db	0e8h, 0e9h, 0eah, 0ebh, 0ech, 0edh, 0eeh, 0efh
	db	0f0h, 0f1h, 0f2h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h
	db	0f8h, 0f9h, 0fah, 0fbh, 0fch, 0fdh, 0feh, 0ffh
IsraelCollating:
		dw  256	; Table Size
	db	 000h, 001h, 002h, 003h, 004h, 005h, 006h, 007h
	db	 008h, 009h, 00ah, 00bh, 00ch, 00dh, 00eh, 00fh
	db	 010h, 011h, 012h, 013h, 014h, 015h, 016h, 017h
	db	 018h, 019h, 01ah, 01bh, 01ch, 01dh, 01eh, 01fh
	db	 020h, 021h, 022h, 023h, 024h, 025h, 026h, 027h
	db	 028h, 029h, 02ah, 02bh, 02ch, 02dh, 02eh, 02fh
	db	 030h, 031h, 032h, 033h, 034h, 035h, 036h, 037h
	db	 038h, 039h, 03ah, 03bh, 03ch, 03dh, 03eh, 03fh
	db	 040h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 05bh, 05ch, 05dh, 05eh, 05fh
	db	 060h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 07bh, 07ch, 07dh, 07eh, 07fh
	db	 080h, 081h, 082h, 083h, 084h, 085h, 086h, 087h
	db	 088h, 089h, 08ah, 08bh, 08ch, 08dh, 08eh, 08fh
	db	 090h, 091h, 092h, 093h, 094h, 095h, 096h, 097h
	db	 098h, 099h, 09ah, 024h, 024h, 024h, 024h, 024h
	db	 041h, 049h, 04fh, 055h, 04eh, 04eh, 0a6h, 0a7h
	db	 03fh, 0a9h, 0aah, 0abh, 0ach, 021h, 022h, 022h
	db	 0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 0b5h, 0b6h, 0b7h
	db	 0b8h, 0b9h, 0bah, 0bbh, 0bch, 0bdh, 0beh, 0bfh
	db	 0c0h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 0c6h, 0c7h
	db	 0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 0cfh
	db	 0d0h, 0d1h, 0d2h, 0d3h, 0d4h, 0d5h, 0d6h, 0d7h
	db	 0d8h, 0d9h, 0dah, 0dbh, 0dch, 0ddh, 0deh, 0dfh
	db	 0e0h, 053h, 0e2h, 0e3h, 0e4h, 0e5h, 0e6h, 0e7h
	db	 0e8h, 0e9h, 0eah, 0ebh, 0ech, 0edh, 0eeh, 0efh
	db	 0f0h, 0f1h, 0f2h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h
	db	 0f8h, 0f9h, 0fah, 0fbh, 0fch, 0fdh, 0feh, 0ffh

if COMPATIBLE
Ucasetbl850:
		dw	128	; Table Size
	db	043h, 055h, 045h, 041h, 041h, 041h, 041h, 043h 
	db	045h, 045h, 045h, 049h, 049h, 049h, 041h, 041h
	db	045h, 092h, 092h, 04fh, 04fh, 04fh, 055h, 055h 
	db	059h, 04fh, 055h, 04fh, 09ch, 04fh, 09eh, 09fh
	db	041h, 049h, 04fh, 055h, 0a5h, 0a5h, 0a6h, 0a7h
	db	0a8h, 0a9h, 0aah, 0abh, 0ach, 0adh, 0aeh, 0afh
	db	0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 041h, 041h, 041h
	db	0b8h, 0b9h, 0bah, 0bbh, 0bch, 0bdh, 0beh, 0bfh
	db	0c0h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 041h, 041h
	db	0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 0cfh
	db	0d1h, 0d1h, 045h, 045h, 045h, 049h, 049h, 049h
	db	049h, 0d9h, 0dah, 0dbh, 0dch, 0ddh, 049h, 0dfh
	db	04fh, 0e1h, 04fh, 04fh, 04fh, 04fh, 0e6h, 0e8h
	db	0e8h, 055h, 055h, 055h, 059h, 059h, 0eeh, 0efh
	db	0f0h, 0f1h, 0f2h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h
	db	0f8h, 0f9h, 0fah, 0fbh, 0fch, 0fdh, 0feh, 0ffh
else

Ucasetbl850:
Nethcase850:
Germcase850:
endif

LatiCase850:
		dw	128	; Table Size
	db	080h, 09ah, 090h, 0b6h, 08eh, 0b7h, 08fh, 080h 
	db	0d2h, 0d3h, 0d4h, 0d8h, 0d7h, 0deh, 08eh, 08fh 
	db	090h, 092h, 092h, 0e2h, 099h, 0e3h, 0eah, 0ebh 
	db	059h, 099h, 09ah, 09dh, 09ch, 09dh, 09eh, 09fh 
	db	0b5h, 0d6h, 0e0h, 0e9h, 0a5h, 0a5h, 0a6h, 0a7h 
	db	0a8h, 0a9h, 0aah, 0abh, 0ach, 0adh, 0aeh, 0afh 
	db	0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 0b5h, 0b6h, 0b7h 
	db	0b8h, 0b9h, 0bah, 0bbh, 0bch, 0bdh, 0beh, 0bfh 
	db	0c0h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 0c7h, 0c7h 
	db	0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 0cfh 
	db	0d1h, 0d1h, 0d2h, 0d3h, 0d4h, 049h, 0d6h, 0d7h 	
	db	0d8h, 0d9h, 0dah, 0dbh, 0dch, 0ddh, 0deh, 0dfh 
	db	0e0h, 0e1h, 0e2h, 0e3h, 0e5h, 0e5h, 0e6h, 0e8h 
	db	0e8h, 0e9h, 0eah, 0ebh, 0edh, 0edh, 0eeh, 0efh 	
	db	0f0h, 0f1h, 0f2h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h 
	db	0f8h, 0f9h, 0fah, 0fbh, 0fch, 0fdh, 0feh, 0ffh

if COMPATIBLE
NethCase850:
		dw	128	; Table Size

	db	080h, 055h, 45h, 041h, 041h, 041h, 08fh, 080h
	db	045h, 045h, 045h, 049h, 049h, 049h, 041h, 08fh
	db	045h, 092h, 092h, 04fh, 04fh, 04fh, 055h, 055h
	db	098h, 04fh, 055h, 04fh, 09ch, 04fh, 09eh, 09fh
	db	041h, 049h, 04fh, 055h, 0a5h, 0a5h, 0a6h, 0a7h
	db	0a8h, 0a9h, 0aah, 0abh, 0ach, 0adh, 0aeh, 0afh
	db	0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 041h, 041h, 041h
	db	0b8h, 0b9h, 0bah, 0bbh, 0bch, 0bdh, 0beh, 0bfh
	db	0c0h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 041h, 041h
	db	0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 0cfh
	db	0d1h, 0d1h, 045h, 045h, 045h, 049h, 049h, 049h
	db	049h, 0d9h, 0dah, 0dbh, 0dch, 0ddh, 049h, 0dfh
	db	04fh, 0e1h, 04fh, 04fh, 04fh, 04fh, 0e6h, 0e8h
	db	0e8h, 055h, 055h, 055h, 059h, 059h, 0eeh, 0efh
	db	0f0h, 0f1h, 0f2h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h
	db	0f8h, 0f9h, 0fah, 0fbh, 0fch, 0fdh, 0feh, 0ffh

GermCase850:
		dw	128	; Table Size
	db	043h, 09ah, 045h, 041h, 08eh, 041h, 041h, 043h
	db	045h, 045h, 045h, 049h, 049h, 049h, 08eh, 041h
	db	045h, 092h, 092h, 04fh, 099h, 04fh, 055h, 055h
	db	059h, 099h, 09ah, 04fh, 09ch, 04fh, 09eh, 09fh
	db	041h, 049h, 04fh, 055h, 0a5h, 0a5h, 0a6h, 0a7h
	db	0a8h, 0a9h, 0aah, 0abh, 0ach, 0adh, 0aeh, 0afh
	db	0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 041h, 041h, 041h
	db	0b8h, 0b9h, 0bah, 0bbh, 0bch, 0bdh, 0beh, 0bfh
	db	0c0h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 041h, 041h
	db	0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 0cfh
	db	0d1h, 0d1h, 045h, 045h, 045h, 049h, 049h, 049h
	db	049h, 0d9h, 0dah, 0dbh, 0dch, 0ddh, 049h, 0dfh
	db	04fh, 0e1h, 04fh, 04fh, 04fh, 04fh, 0e6h, 0e8h
	db	0e8h, 055h, 055h, 055h, 059h, 059h, 0eeh, 0efh
	db	0f0h, 0f1h, 0f2h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h
	db	0f8h, 0f9h, 0fah, 0fbh, 0fch, 0fdh, 0feh, 0ffh
endif

Ucasetbl932:
		dw	128	; Table size
	db	080h, 081h, 082h, 083h, 084h, 085h, 086h, 087h
	db	088h, 089h, 08ah, 08bh, 08ch, 08dh, 08eh, 08fh
	db	090h, 091h, 092h, 093h, 094h, 095h, 096h, 097h
	db	098h, 099h, 09ah, 09bh, 09ch, 09dh, 09eh, 09fh
	db	0a0h, 0a1h, 0a2h, 0a3h, 0a4h, 0a5h, 0a6h, 0a7h
	db	0a8h, 0a9h, 0aah, 0abh, 0ach, 0adh, 0aeh, 0afh
	db	0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 0b5h, 0b6h, 0b7h
	db	0b8h, 0b9h, 0bah, 0bbh, 0bch, 0bdh, 0beh, 0bfh
	db	0c0h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 0c6h, 0c7h
	db	0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 0cfh
	db	0d0h, 0d1h, 0d2h, 0d3h, 0d4h, 0d5h, 0d6h, 0d7h
	db	0d8h, 0d9h, 0dah, 0dbh, 0dch, 0ddh, 0deh, 0dfh
	db	0e0h, 0e1h, 0e2h, 0e3h, 0e4h, 0e5h, 0e6h, 0e7h
	db	0e8h, 0e9h, 0eah, 0ebh, 0ech, 0edh, 0eeh, 0efh
	db	0f0h, 0f1h, 0f2h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h
	db	0f8h, 0f9h, 0fah, 0fbh, 0fch, 0fdh, 0feh, 0ffh

DBCS_932:
		dw	6	; Table Size
	db	 081h, 09fh, 0e0h, 0fch, 000h, 000h


DBCS_934:
		dw	4	; Table Size
	db	 0a1h, 0feh, 000h, 000h


DBCS_936:
		dw	4	; Table Size
	db	 081h, 0fch, 000h, 000h


	END
