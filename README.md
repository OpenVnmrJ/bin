# makecd
 makecd - Create ISO9660 archive disk image or archive data to CD-R disks
 directly; "makecd" also handles the case where the amount of data
 in the archive directory exceeds the capacity of the archival media;
 highly customizable. NOTE: Under Solaris 8 and older releases you need
 to install "mkisofs" (to create ISO9660 file systems) and "cdrecord"
 (if you also want to burn archival media directly). Also, there are
 possible limitations in partial archiving with older (pre-Solaris 9)
 versions of "mkisofs".

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
Date submitted: 2005-04-06 - First "official" version
                2005-04-07 - Adjusted defaults to comply with "bin/makeCD"
                2008-03-21 - Adjusted "head" / "tail" calls for RHEL 5.1

File name:      makecd
Directory:      bin
Description:    Create ISO9660 archive disk image or archive data to CD-R
                disks directly; "makecd" also handles the case where the
                amount of data in the archive directory exceeds the capacity
                of the archival media; highly customizable.
                NOTE: Under Solaris 8 and older releases you need to install
                "mkisofs" (to create ISO9660 file systems) and "cdrecord" (if
                you also want to burn archival media directly). Also, there
                are possible limitations in partial archiving with older
                (pre-Solaris 9) versions of "mkisofs".

Related files:  app-defaults/makecd   maclib/imakecd    manual/imakecd
                bin/makecd            maclib/makecd     manual/makecd

Existing VnmrJ / VNMR files which are superseded or
otherwise affected by this submission:  none
Hardware configuration limitations:     none
Known software version compatibility:   n.a.
Known OS version compatibility:         Solaris 9, RedHat Linux (?);
                                        Solaris 8 & older requires installing
                                        shareware "mkisofs" & "cdrecord".

Special instructions for installation:

**This software has not been tested on OpenVnmrJ. Use at your own risk.**

To install this user contribution:  
Download the repository from GitHub and checkout the tag of the contribution you want.
Typically tags end in the version (e.g. -v1.0)

     git clone https://github.com/OpenVnmrJ/bin  
     cd bin  
     git checkout makecd-v1.0


You may also download the archive directly from github at

    https://github.com/OpenVnmrJ/maclib/archive/makecd-v1.0.zip

Read makecd.README for installation instructions.

In most cases, move the contribution to /vnmr/userlib/bin 
then use extract to install the contribution:  

    extract bin/makecd