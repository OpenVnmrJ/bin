# rephasefid
 rephasefid - Allows rephasing of 1D/2D FIDs or parts thereof by altering
 the
 zero-order phase of specified FIDs in a dataset. This may be required
 for processing certain kinds of imported 2D datasets, or for parts
 that were acquired separately and merged in "after the fact", in
 order to correct problems with the originally acquired FID.

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
Date submitted: 1995-11-03 Separated from packages/adv2d
                1995-11-13 Fixed problem with temporary file
                2003-04-16 Added precompiled module
                2006-02-10 Added Linux / MacOS X compatibility; added macro;
                           compatible with floating point FIDs
                2006-02-24 Avoids compiler erros under MacOS X & Linux
                2008-03-21 Adjusted "head" call for RHEL 5.1
                2008-07-08 Avoids compiler warning under Solaris 8

File name:      rephasefid
Directory:      bin
Description:    Allows rephasing of 1D/2D FIDs or parts thereof by altering
                the zero-order phase of specified FIDs in a dataset. This may
                be required for processing certain kinds of imported 2D
                datasets, or for parts that were acquired separately and
                merged in "after the fact", in order to correct problems with
                the originally acquired FID.

Related files:  maclib/rephasefid   manual/rephasefid   source/rephasefid.c

Existing VnmrJ / VNMR files which are superseded or
otherwise affected by this submission:  none
Hardware configuration limitations:     none
Known software version compatibility:   VNMR 6.1 - VnmrJ 2.1B
Known OS version compatibility:         Solaris 2.x - 9, RHEL 4, MacOS X 10.4
Special instructions for installation:
    If you are downloading from the Internet, store
    the file "rephasefid.tar.Z" in "/vnmr/userlib/bin", then use
        cd /vnmr/userlib

**This software has not been tested on OpenVnmrJ. Use at your own risk.**

To install this user contribution:  
Download the repository from GitHub and checkout the tag of the contribution you want.
Typically tags end in the version (e.g. -v1.0)

     git clone https://github.com/OpenVnmrJ/bin  
     cd bin  
     git checkout rephasefid-v1.0


You may also download the archive directly from github at

    https://github.com/OpenVnmrJ/maclib/archive/rephasefid-v1.0.zip

Read rephasefid.README for installation instructions.

In most cases, move the contribution to /vnmr/userlib/bin 
then use extract to install the contribution:  

    extract bin/rephasefid