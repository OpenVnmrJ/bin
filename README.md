# v2v
 v2v - Converts Varian FID files to double precision integer, single
 precision
 integer or floating point formats.

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

Your name:      Eriks Kupce, Agilent Technologies, U.K.

Date submitted: 2002-07-06 - original submission
                2007-06-04 - R.Kyburz, added byte swapping for Intel arch.
                2007-06-06 - E.Kupce, added scaling for conversions to 16-bit
                2007-06-07 - E.Kupce, fixed a bug
                2007-03-21 - R.Kyburz, adjusted "head" call for RHEL 5.1

File name:              v2v
Directory:              bin
Description:            Converts Varian FID files to double precision integer,
                        single precision integer or floating point formats.

Related files:          manual/v2v      source/v2v.c

Existing VnmrJ / VNMR files which are superseded or
otherwise affected by this submission:  none
Hardware configuration limitations:     none
Known software version compatibility:   VnmrJ, VNMR 6.1C and earlier
Known OS version compatibility:         Solaris 2.x - 9, RHEL 4
Special instructions for installation:

**This software has not been tested on OpenVnmrJ. Use at your own risk.**

To install this user contribution:  
Download the repository from GitHub and checkout the tag of the contribution you want.
Typically tags end in the version (e.g. -v1.0)

     git clone https://github.com/OpenVnmrJ/bin  
     cd bin  
     git checkout v2v-v1.0


You may also download the archive directly from github at

    https://github.com/OpenVnmrJ/maclib/archive/v2v-v1.0.zip

Read v2v.README for installation instructions.

In most cases, move the contribution to /vnmr/userlib/bin 
then use extract to install the contribution:  

    extract bin/v2v