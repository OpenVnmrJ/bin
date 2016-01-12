# fixmsl
 fixmsl - Pre-processor for Bruker MSL data sets

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

Your name:              Steve Patt
                        For support questions please contact
                                Rolf Kyburz (rolf.kyburz@agilent.com)
Date submitted:         1995-07-19
                        1998-02-24 - added precompiled (Solaris) C module

File name:              fixmsl
Directory:              bin
Description:            Pre-processor for Bruker MSL data sets

Related files:          bin/fixmsl      bin/fixmsl.c    maclib/rtmsl
                        manual/fixmsl   manual/rtmsl

Existing VnmrJ / VNMR files which are superseded or
otherwise affected by this submission:  none
Hardware configuration limitations:     none
Known software version compatibility:   VNMR 5.1A and later
Known OS version compatibility:         SunOS 4.x, Solaris 2.x
Special instructions for installation:
    If you are downloading from the Internet, store
    the file fixmsl.tar.Z in /vnmr/userlib/bin, then use

**This software has not been tested on OpenVnmrJ. Use at your own risk.**

To install this user contribution:  
Download the repository from GitHub and checkout the tag of the contribution you want.
Typically tags end in the version (e.g. -v1.0)

     git clone https://github.com/OpenVnmrJ/bin  
     cd bin  
     git checkout fixmsl-v1.0


You may also download the archive directly from github at

    https://github.com/OpenVnmrJ/maclib/archive/fixmsl-v1.0.zip

Read fixmsl.README for installation instructions.

In most cases, move the contribution to /vnmr/userlib/bin 
then use extract to install the contribution:  

    extract bin/fixmsl