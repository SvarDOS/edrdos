         Caldera OpenDOS Machine Readable Source Kit (M.R.S) 7.01
         ========================================================


1.0 SOURCE CODE LICENSE AGREEMENT

    Please familiarise your self with the Caldera Source Code
    License agreement in the file LICENSE.TXT before doing anything
    with this M.R.S. kit.

2.0 BUILDING THE COMPONENTS


2.1 INSTALLING SOURCE FROM CD MEDIA

    Copy the SOURCE directory from the CD to your hard disk. Use
    XCOPY /S to preserve subdirectories.

    Use the ATTRIB command to reset the READ-ONLY attribute on the
    files copied to the hard disk prior to building, since all files
    copied from the CD-ROM will have the READ-ONLY bit set.


2.2 INSTALLING SOURCE FROM A ZIP FILE
    
    PKUNZIP the source archive file to hard disk using the -d switch 
    to preserve the subdirectory structure.


2.3 BUILDING THE MRS KIT

    The Caldera OpenDOS MRS kit contains the following components:

                 IBMBIO, IBMDOS and COMMAND

    These components are accompanied with batch files (MAKE.BAT)
    that enable them to be built.  These batch files are to be
    found at the root of each component directory.

    TOOLS
    =====
    In order to build these components we have provided some of
    the "in house" tools that were developed to aid the process.
    The remainder of the tools have been omitted as you need to
    obtain the required licences for them.

    The following third party tools were used to build the 
    executables. Other versions of these tools may work but have
    not been tested.

    Tool			Component
    ====			=========
    Watcom C v7.0		COMMAND
    Borland C v2.0		COMMAND
    Microsoft MASM v4.0 	IBMBIO, COMMAND
    Microsoft Link v5.10	IBMBIO, COMMAND
    Microsoft Lib v3.0		IBMBIO

    IBMBIO
    ======
    To build IBMBIO.COM run the MAKE.BAT found in the root of the
    IBMBIO\ directory.  The MAKE.BAT file sets environment variables
    that point to the local tools directory and to the Third Party
    tools required.  The Third party tools directory is set to 
    C:\TOOLS but this can be changed by editing the MAKE.BAT file 
    if required.

    When this component has built all built files are placed in the
    BIN\ directory under the component.


    IBMDOS
    ======
    To build IBMDOS.COM run the MAKE.BAT found in the root of the
    IBMDOS\ directory.  The MAKE.BAT file sets environment variables
    that point to the local tools directory and to the Third party tools
    required.  The Third party tools directory is set to C:\TOOLS 
    but this can be changed by editing the MAKE.BAT file if required.

    When this component has built all built files are placed in the
    BIN\ directory under the component.


    COMMAND
    =======
    To build COMMAND.COM run the MAKE.BAT found in the root of the
    COMMAND\ directory.  The MAKE.BAT file sets environment variables
    that point to the local tools directory and to the Third party 
    tools required.  The Third party tools directory is set to 
    C:\TOOLS but this can be changed by editing the MAKE.BAT file 
    if required.

    When this component has built all built files are placed in the
    BIN\ directory under the component.

    For this component we use the WATCOM optimising compiler, which
    greatly reduces the size of COMMAND.COM when built.  For this
    reason it is highly likely that the COMMAND.COM built on your
    local machine will differ from the shipped version of COMMAND.COM.

    To gain better optimisation you will need a large TPA. This is best
    achieved by installing OpenDOS 7.01 setup to map Video memory into
    TPA.

    In days past this component used to be built with the standard
    Borland compilers (v2.0) and if required can be modified to do so.

    




