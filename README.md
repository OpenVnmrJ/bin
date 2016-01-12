# vxrimport
 vxrimport - Utilities for reading QIC tapes with XL/VXR/GEMINI legacy data,
 and
 for recursively decomposing directories from imported XL/VXR/GEMINI,
 and converting FID files contained therein into VNMR / VnmrJ format.

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
Date submitted: 2008-05-25 - Separated from packages/tools

File name:      vxrimport
Directory:      bin
Description:    Utilities for reading QIC tapes with XL/VXR/GEMINI legacy data,
                and for recursively decomposing directories from imported
                XL/VXR/GEMINI, and converting FID files contained therein into
                VNMR / VnmrJ format.

Related files:  bin/Gconvert            bin/readvxrtape
                manual/Gconvert         manual/readvxrtape

Existing VnmrJ / VNMR files which are superseded or
otherwise affected by this submission:  none
Hardware configuration limitations:     none
Known software version compatibility:   VNMR 4.x - VnmrJ 2.1B
Known OS version compatibility:         SunOS 4.x, Solaris 2.4 - 9
Special instructions for installation:

**This software has not been tested on OpenVnmrJ. Use at your own risk.**

To install this user contribution:  
Download the repository from GitHub and checkout the tag of the contribution you want.
Typically tags end in the version (e.g. -v1.0)

     git clone https://github.com/OpenVnmrJ/bin  
     cd bin  
     git checkout vxrimport-v1.0


You may also download the archive directly from github at

    https://github.com/OpenVnmrJ/maclib/archive/vxrimport-v1.0.zip

Read vxrimport.README for installation instructions.

In most cases, move the contribution to /vnmr/userlib/bin 
then use extract to install the contribution:  

    extract bin/vxrimport