# pcosyproc
 pcosyproc - Process P.COSY (i.e. cosyps) data set according to literature
 (see
 D.Marion & A.Bax, J.Magn.Reson. 80, 528 (1988)) by subtracting a 1D
 spectrum (1st trace of cosyps with read pulse replaced by a delay)
 from each trace, left-shifted by one data point per t1 dwell time.

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
                2008-07-08 (added PC/Linux & MacOS X compatibility)

File name:      pcosyproc
Directory:      bin
Description:    Process P.COSY (i.e. cosyps) data set according to literature
                (see D.Marion & A.Bax, J.Magn.Reson. 80, 528 (1988)) by
                subtracting a 1D spectrum (1st trace of cosyps with read pulse
                replaced by a delay) from each trace, left-shifted by one data
                point per t1 dwell time.

Related files:  bin/pcosyproc           maclib/pcosyproc
                manual/pcosyproc        source/pcosyproc.c

Existing VnmrJ / VNMR files which are superseded or
otherwise affected by this submission:  none
Hardware configuration limitations:     none
Known software version compatibility:   VNMR 6.1C, VnmrJ 1.0 - 2.1B
Known OS version compatibility:         Solaris 2.x - 9, RHEL 3/4, MacOS X
Special instructions for installation:
    If you are downloading from the Internet, store
    the file pcosyproc.tar.Z in /vnmr/userlib/bin, then use
        cd /vnmr/userlib
        ./extract bin/pcosyproc /vnmr
        rehash

**This software has not been tested on OpenVnmrJ. Use at your own risk.**

To install this user contribution:  
Download the repository from GitHub and checkout the tag of the contribution you want.
Typically tags end in the version (e.g. -v1.0)

     git clone https://github.com/OpenVnmrJ/bin  
     cd bin  
     git checkout pcosyproc-v1.0


You may also download the archive directly from github at

    https://github.com/OpenVnmrJ/maclib/archive/pcosyproc-v1.0.zip

Read pcosyproc.README for installation instructions.

In most cases, move the contribution to /vnmr/userlib/bin 
then use extract to install the contribution:  

    extract bin/pcosyproc