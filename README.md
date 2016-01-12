# trsub
 trsub - subtracts reference trace from all other traces in arrayed 1D
 spectrum
 (e.g., for NOE experiments); subtracts a horizontal (f1 or f2)
 reference trace from all traces in a 2D spectrum.

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
Date submitted: 1993-08-23 - Added from earlier "packages/adv2d" contribution
                2003-06-03 - Added precompiled C program
                2008-07-08 - Added PC/Linux and MacOS X compatibility

File name:      trsub
Directory:      bin
Description:    subtracts reference trace from all other traces in arrayed 1D
                spectrum (e.g., for NOE experiments); subtracts a horizontal
                (f1 or f2) reference trace from all traces in a 2D spectrum.

Related files:  bin/trsub, maclib/trsub, manual/trsub, source/trsub.c

Existing VnmrJ / VNMR files which are superseded or
otherwise affected by this submission:  none
Hardware configuration limitations:     none
Known software version compatibility:   VNMR 4.1 - 6.1C, VnmrJ 1.0 - 2.1B
Known OS version compatibility:         Solaris 2.x - 9, RHEL 3/4, MacOS

Special instructions for installation:
    If you are downloading from the Internet, store
    the file trsub.tar.Z in /vnmr/userlib/bin, then use
        cd /vnmr/userlib
        ./extract bin/trsub /vnmr
        rehash

**This software has not been tested on OpenVnmrJ. Use at your own risk.**

To install this user contribution:  
Download the repository from GitHub and checkout the tag of the contribution you want.
Typically tags end in the version (e.g. -v1.0)

     git clone https://github.com/OpenVnmrJ/bin  
     cd bin  
     git checkout trsub-v1.0


You may also download the archive directly from github at

    https://github.com/OpenVnmrJ/maclib/archive/trsub-v1.0.zip

Read trsub.README for installation instructions.

In most cases, move the contribution to /vnmr/userlib/bin 
then use extract to install the contribution:  

    extract bin/trsub