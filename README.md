# parhandler
 parhandler - This is a collection of parameter handling tools. In its core
 it
 uses a utility "listparam" that lists VNMR parameter files (or
 better: selected parameter groups from such a file) in a simple,
 one-line-per-parameter format. Based on this utility the parlist
 macro allows listing ALL parameters in the current experiment (also
 those not contained in any dg screen!).  The same utility is used in a
 UNIX (diffparam) and a macro (pardiff) utility that allows comparing
 COMPLETE parameter sets at a glance. The macro "svfj" saves an FID
 (1D, or a FID trace from a 2D or an arrayed 1D data set) in JCAMP-DX
 format. The macros "svsj" and "svlsj" save a spectrum in JCAMP-DX
 format (16- and 24-bit digital precision). The macro "svxyj" saves
 a spectrum in JCAMP-DX "X,Y" format (one X,Y pair per line). "svsj",
 "svlsj" and "svxyj" also work for traces from arrayed 1D spectra, as
 well as for f1 and f2 traces from partially and fully transformed 2D
 spectra. Entire 2D data sets or 1D arrays can NOT be saved in JCAMP-DX
 format at this point. Known limitation: "svfj" does not work with
 "nf>1". The macro "svllj" saves X,Y peak lists in JCAMP-DX format
 (X,Y,M lists if DEPT analysis results are present). A new utility,
 "import1Dspec" reads 1D ASCII spectra such as from "writetrace"
 or "writexy" (i.e., Y .. Y or X,Y .. X,Y data) into the current
 experiment in VnmrJ / VNMR. Note for VNMR 6.1C users: for better
 GLP and 21CFRpart11 compliance of the exported JCAMP-DX data under
 VNMR 6.1C (NOT VnmrJ) it is strongly recommended also to download
 and install the contribution "maclib/glp". NOTE: this contribution
 includes ALL features of the smaller contribution "maclib/writetrace".

 Copyright 2016 University of Oregon

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

                                SUBMISSION FORM

Submitter:      Rolf Kyburz, Agilent Technologies
Date submitted: 1995-05-25 Original submission
                1995-06-23 Minor cleanup, added hint for SGI / IRIX
                1996-12-17 Added macros for saving JCAMP-DX FIDs and spectra
                1997-01-14 Fixed several bugs with JCAMP-DX data
                1999-01-22 Several JCAMP-DX updates and corrections
                1999-01-27 JCAMP-DX parameter cleanup for spectra
                1999-02-02 JCAMP-DX added phase params for FIDs
                1999-07-08 Changed JCAMP-DX suffix to ".dx"
                2000-01-29 JCAMP-DX support for 2D/interferogram traces, f1
                           and f2 mode, enhancements
                2001-05-02 JCAMP-DX files now use "origin" and "owner"
                           parameters, if present
                2002-05-13 Minor change in JCAMP-DX comment
                2002-05-15 Fixed missing DUP digit at end of JCAMP-DX output,
                           adjusted for JCAMP-DX 5.01 standard, added JCAMP-DX
                           compression options
                2002-05-16 Added JCAMP-DX X,Y output option for spectra
                2002-05-26 New JCAMP-DX X,Y or X,Y,M peak list output option
                2002-11-19 Accepts alternative extensions for JCAMP-DX files
                2003-09-12 Without arguments, JCAMP-DX files are saved inside
                           the "{file}.fid" directory, if that is writable.
                2004-04-29 Fixed bugs with Varian software & instrument labels
                2004-05-27 Referencing fixes & enhancements in JCAMP-DX output
                2004-10-29 Incorporated enhancements in "maclib/writetrace"
                2006-02-19 Added Linux / MacOS X compatibility
                2006-02-20 Merged in "import1Dspec" from "maclib/writetrace"
                2006-02-22 Fixed bug in "writetrace" utility
                2006-02-24 Fixed bugs under Linux and MacOS X
                2006-04-15 Minor diagnostics addition
                2006-11-19 JCAMP-DX exporting fixed for bug "rev.j2101",
                           enhanced text and OWNER field handling
                2007-03-15 Adjusted for Chempack / VnmrJ 2.2C compatibility;
                           fixed byte swapping for Intel-based Macs (courtesy
                           Pascal Mercier, Chenomx)
                2007-03-19 Fixed typo in "maclib/svfj" (ul_parhandler.j2101)
                2007-03-20 Fixed bugs in C architecture determination
                2007-05-09 Fixed "maclib/getbinpath" for VnmrJ 2.2C
                2007-05-12 Fixed bug in "writetrace" / "writexy" macros
                2007-11-13 Changed installation / documentation to create
                           32-bit executables for more compatibility (Linux)
                2008-03-21 Adjusted "head" / "tail" calls for RHEL 5.1
                2008-06-26 Adjusted "sort" calls for RHEL
                2010-05-11 Adjustment in JCAMP-DX header for VnmrJ 3.0 & up
                2010-05-31 Minor enhancement in "writetrace" debugging output
                2011-02-08 Added option for X column in ppm in "writexy"

File name:      parhandler
Directory:      bin
Description:    This is a collection of parameter handling tools. In its core
                it uses a utility "listparam" that lists VNMR parameter files
                (or better: selected parameter groups from such a file) in a
                simple, one-line-per-parameter format. Based on this utility
                the parlist macro allows listing ALL parameters in the current
                experiment (also those not contained in any dg screen!).  The
                same utility is used in a UNIX (diffparam) and a macro
                (pardiff) utility that allows comparing COMPLETE parameter
                sets at a glance.
                The macro "svfj" saves an FID  (1D, or a FID trace from a 2D
                or an arrayed 1D data set) in JCAMP-DX format. The macros
                "svsj" and "svlsj" save a spectrum in JCAMP-DX format (16- and
                24-bit digital precision). The macro "svxyj" saves a spectrum
                in JCAMP-DX "X,Y" format (one X,Y pair per line).
                "svsj", "svlsj" and "svxyj" also work for traces from arrayed
                1D spectra, as well as for f1 and f2 traces from partially and
                fully transformed 2D spectra. Entire 2D data sets or 1D arrays
                can NOT be saved in JCAMP-DX format at this point. Known
                limitation: "svfj" does not work with "nf>1".
                The macro "svllj" saves X,Y peak lists in JCAMP-DX format
                (X,Y,M lists if DEPT analysis results are present).
                A new utility, "import1Dspec" reads 1D ASCII spectra such as
                from "writetrace" or "writexy" (i.e., Y .. Y or X,Y .. X,Y
                data) into the current experiment in VnmrJ / VNMR.
                Note for VNMR 6.1C users: for better GLP and 21CFRpart11
                compliance of the exported JCAMP-DX data under VNMR 6.1C (NOT
                VnmrJ) it is strongly recommended also to download and install
                the contribution "maclib/glp".
                NOTE: this contribution includes ALL features of the smaller
                      contribution "maclib/writetrace".

Related files:  bin:     diffparam     import1Dspec  jdxfid        jdxlspec
                         jdxspec       listparam     writetrace
                maclib:  getbinpath    import1Dspec  lljdx         pardiff
                         parlist       svfj          svllj         svlsj
                         svsj          svxyj         writetrace    writexy
                         writejxy
                manual:  diffparam     import1Dspec  listparam     pardiff
                         parlist       svfj          svllj         svlsj
                         svsj          svxyj         writetrace    writexy
                         writejxy
                source:  import1Dspec.c  jdxfid.c    jdxspec.c     listparam.c
                         writetrace.c

Existing VnmrJ / VNMR files which are superseded or
otherwise affected by this submission:  none
Hardware configuration limitations:     none
Known software version compatibility:   VNMR 6.1C - VnmrJ 2.2C
Known OS version compatibility:         Solaris 2.x - 9, RHEL 4 / 5, OS X 10.4
Special instructions for installation:
    If you are downloading from the Internet, store
    the file parhandler.tar.Z in /vnmr/userlib/bin, then use
        cd /vnmr/userlib
        ./extract bin/parhandler /vnmr
        rehash
    to install the files in "/vnmr"; for an installation in the user's local
    directories use
        cd /vnmr/userlib
        ./extract bin/parhandler
        rehash
    Solaris executables are already enclosed in the package; the install
    script will recompile all source files, such that the software should be

**This software has not been tested on OpenVnmrJ. Use at your own risk.**

To install this user contribution:  
Download the repository from GitHub and checkout the tag of the contribution you want.
Typically tags end in the version (e.g. -v1.0)

     git clone https://github.com/OpenVnmrJ/bin  
     cd bin  
     git checkout parhandler-v1.0


You may also download the archive directly from github at

    https://github.com/OpenVnmrJ/maclib/archive/parhandler-v1.0.zip

Read parhandler.README for installation instructions.

In most cases, move the contribution to /vnmr/userlib/bin 
then use extract to install the contribution:  

    extract bin/parhandler