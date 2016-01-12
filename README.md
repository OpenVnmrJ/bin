# bruspec2var
 bruspec2var - Import a transformed Bruker 1D dataset into VnmrJ / VNMR.

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
Date submitted: 2005-01-23
                2005-10-05 - Macro bugs fixed (Thanks to Krish for reporting!)
                2005-10-06 - Imports also real-only data (sugg. by Krish)
                2006-02-12 - Supports PC/Linux and PowerPC/MacOS X
                2006-02-22 - "maclib/bruspec2var" bugs fixed (krishk@lilly.com)
                2006-02-24 - Avoids compiler errors under MacOS X and Linux
                2006-03-11 - Fixed major bugs (rep. by P. Mercier, Chenomx)
                2006-05-04 - Better architecture recognition for byte-swapping
                2008-03-21 - Adjusted "head" calls for RHEL 5.1
                2008-07-08 - Avoids Solaris 8 compiler warning

File name:      bruspec2var
Directory:      bin
Description:    Import a transformed Bruker 1D dataset into VnmrJ / VNMR.

Related files:  bin/bruspec2var         maclib/bruspec2var
                manual/bruspec2var      source/bruspec2var.c

Existing VnmrJ / VNMR files which are superseded or
otherwise affected by this submission:  none
Hardware configuration limitations:     none
Known software version compatibility:   VnmrJ 1.1D - 2.1B
Known OS version compatibility:         Solaris 8/9, RHEL 3/4, MacOS X 10.4
Special instructions for installation:
    If you are downloading from the Internet, store
    the file "bruspec2var.tar.Z" in "/vnmr/userlib/bin", then use
        cd /vnmr/userlib
        ./extract bin/bruspec2var /vnmr
        rehash

**This software has not been tested on OpenVnmrJ. Use at your own risk.**

To install this user contribution:  
Download the repository from GitHub and checkout the tag of the contribution you want.
Typically tags end in the version (e.g. -v1.0)

     git clone https://github.com/OpenVnmrJ/bin  
     cd bin  
     git checkout bruspec2var-v1.0


You may also download the archive directly from github at

    https://github.com/OpenVnmrJ/maclib/archive/bruspec2var-v1.0.zip

Read bruspec2var.README for installation instructions.

In most cases, move the contribution to /vnmr/userlib/bin 
then use extract to install the contribution:  

    extract bin/bruspec2var