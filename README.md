# merge2d
 merge2d - Repair "defective" traces in a 2D FID. Such traces (as they can
 be obtained due to magnet environment / homogeneity changes, sudden
 temperature changes, spurious floor vibrations etc.) can be reacquired
 as single or arrayed 1D data sets (one experiment per consecutive
 series of bad FIDs) and "merged" into the 2D FID. "merge2d" copies
 as many FIDs as it finds in the (arrayed) 1D data set.

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
Date submitted: 2004-04-01 (from the earlier "packages/adv2d" contribution)
                2006-03-04 (made compatible with Linux and MacOS X)
                2008-07-08 (enhanced PC/Linux architecture detection)

File name:      merge2d
Directory:      bin
Description:    Repair "defective" traces in a 2D FID. Such traces (as they
                can be obtained due to magnet environment / homogeneity
                changes, sudden temperature changes, spurious floor vibrations
                etc.) can be reacquired as single or arrayed 1D data sets (one
                experiment per consecutive series of bad FIDs) and "merged"
                into the 2D FID. "merge2d" copies as many FIDs as it finds in
                the (arrayed) 1D data set.

Related files:  bin/merge2d        manual/merge2d       source/merge2d.c

Existing VnmrJ / VNMR files which are superseded or
otherwise affected by this submission:  none
Hardware configuration limitations:     none
Known software version compatibility:   VNMR 6.1C - VnmrJ 2.1B
Known OS version compatibility:         Solaris 2.x - 9, RHEL 4, MacOS X 10.4
Special instructions for installation:
    If you are downloading from the Internet, store
    the file merge2d.tar.Z in /vnmr/userlib/bin, then use
        cd /vnmr/userlib
        ./extract bin/merge2d /vnmr
        rehash

**This software has not been tested on OpenVnmrJ. Use at your own risk.**

To install this user contribution:  
Download the repository from GitHub and checkout the tag of the contribution you want.
Typically tags end in the version (e.g. -v1.0)

     git clone https://github.com/OpenVnmrJ/bin  
     cd bin  
     git checkout merge2d-v1.0


You may also download the archive directly from github at

    https://github.com/OpenVnmrJ/maclib/archive/merge2d-v1.0.zip

Read merge2d.README for installation instructions.

In most cases, move the contribution to /vnmr/userlib/bin 
then use extract to install the contribution:  

    extract bin/merge2d