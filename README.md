# stripheaders
 stripheaders - "stripheaders" is a utility for removing file headers from
 binary
 VNMR data files, such that third party software does not need to deal
 with the header files. The "pure data" information is stored in a new
 file *.bin, the header information is collected in a separate file
 *.hdr. In addition to that, "stripheaders" creates a text file (*.txt)
 with readable information about the file structure. "stripheaders"
 works for VNMR FIDs of any kind, for datdir/data (2D data only when
 processed with "wft", NOT wft1d/wft2d), and datdir/phasefile (both
 1D and 2D).

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
Date submitted: 1999-06-19

File name:      stripheaders
Directory:      bin
Description:    "stripheaders" is a utility for removing file headers from
                binary VNMR data files, such that third party software does
                not need to deal with the header files. The "pure data"
                information is stored in a new file *.bin, the header
                information is collected in a separate file *.hdr. In
                addition to that, "stripheaders" creates a text file (*.txt)
                with readable information about the file structure.
                "stripheaders" works for VNMR FIDs of any kind, for
                datdir/data (2D data only when processed with "wft", NOT
                wft1d/wft2d), and datdir/phasefile (both 1D and 2D).

Related files:  manual/stripheaders     source/stripheaders.c

Existing VnmrJ / VNMR files which are superseded or
otherwise affected by this submission:  none
Hardware configuration limitations:     none
Known software version compatibility:   any
Known OS version compatibility:         Solaris 2.x
Special instructions for installation:
    If you are downloading from the Internet, store

**This software has not been tested on OpenVnmrJ. Use at your own risk.**

To install this user contribution:  
Download the repository from GitHub and checkout the tag of the contribution you want.
Typically tags end in the version (e.g. -v1.0)

     git clone https://github.com/OpenVnmrJ/bin  
     cd bin  
     git checkout stripheaders-v1.0


You may also download the archive directly from github at

    https://github.com/OpenVnmrJ/maclib/archive/stripheaders-v1.0.zip

Read stripheaders.README for installation instructions.

In most cases, move the contribution to /vnmr/userlib/bin 
then use extract to install the contribution:  

    extract bin/stripheaders