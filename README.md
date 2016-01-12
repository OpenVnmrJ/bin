# jeoltovar
 jeoltovar - Converts JEOL data to VNMR format, works for 1D, 2D and
 arrayed 1D data sets, as well as phase-sensitive 2D data (States
 method). Can capture incoming JEOL data sets, convert and process them
 automatically. Acknowledgements:  The concept for maclib/jeoltovar and
 bin/jeoltovar.c was taken over from the original submitter; all the
 additional enhancements were only possible through extensive assistance
 on the part of Dr. Martin Kipps, ICI/Zeneca Agrochemicals, Bracknell,
 Berkshire, U.K., who also assisted with numerous suggestions.

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

Your name:      David Stephenson (original submission)
Date submitted: 1992-03-11

Submitter:      Rolf Kyburz, Agilent Technologies
Date submitted: 1993-02-20
                1993-03-08 (reestablished EX compatibility)
                1994-03-04 (added Solaris 2.x compatibility)
                1999-10-05 (major enhancements in parameter handling: handles
                            missing parameters, tn/dn, better defaults; should
                            also handle DELTA/ECLIPSE data converted to GX
                            format)
                1999-11-28 (fixed bug with interactive filename input)

File name:      jeoltovar
Directory:      bin
Description:    Converts JEOL data to VNMR format, works for 1D, 2D and
                arrayed 1D data sets, as well as phase-sensitive 2D data
                (States method).
                Can capture incoming JEOL data sets, convert and process them
                automatically.
Acknowledgements:  The concept for maclib/jeoltovar and bin/jeoltovar.c was
                   taken over from the original submitter; all the additional
                   enhancements were only possible through extensive assistance
                   on the part of Dr. Martin Kipps, ICI/Zeneca Agrochemicals,
                   Bracknell, Berkshire, U.K., who also assisted with numerous
                   suggestions.

Related files:  bin/jeoltovar.c         bin/test4jeoldata
                bin/cleanupjeoldata     maclib/jeoltovar
                maclib/convertnuc       maclib/files_loadfid
                maclib/wft2dj           maclib/jeolproc
                maclib/_solvent         parlib/jeol.par
                help/files_main         manual/jeoltovar
                manual/wft2dj           manual/convertnuc
                manual/test4jeoldata    manual/cleanupjeoldata
                solventnames
Existing VnmrJ / VNMR files which are superseded or
otherwise affected by this submission:  
                maclib/files_loadfid    help/files_main
                solventnames (from userlib/packages/extend)
Hardware configuration limitations:     n/a
Known software version compatibility:   VNMR 4.1 - 6.1B
Known JEOL compatibility:               EX/GX/GSX spectrometers
Known OS version compatibility:         SunOS 4.1.x, Solaris 2.x
Special instructions for installation:
    If you are downloading from the Internet, store

**This software has not been tested on OpenVnmrJ. Use at your own risk.**

To install this user contribution:  
Download the repository from GitHub and checkout the tag of the contribution you want.
Typically tags end in the version (e.g. -v1.0)

     git clone https://github.com/OpenVnmrJ/bin  
     cd bin  
     git checkout jeoltovar-v1.0


You may also download the archive directly from github at

    https://github.com/OpenVnmrJ/maclib/archive/jeoltovar-v1.0.zip

Read jeoltovar.README for installation instructions.

In most cases, move the contribution to /vnmr/userlib/bin 
then use extract to install the contribution:  

    extract bin/jeoltovar