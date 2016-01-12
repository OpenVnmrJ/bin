# sysprofiler
 sysprofiler - "sysprofiler" is a utility the collects information about the
 workstation hardware, operating environment and application software
 configuration in the following areas: - workstation type & hardware
 configuration - OS version, installed OS patches / updates, networking
 and security information (currently limited in Linux) - VnmrJ / VNMR
 version and installed VnmrJ / VNMR software options, patches and user
 library contributions - acquisition console configuration - software
 and workstation hardware upgrade recommendations. "sysprofiler" is
 useful when trying to assess whether and how a system can or needs
 to be upgraded to run current OS and/or VnmrJ / VNMR software. It
 also permits inexperienced users to extract configuration information
 for the purpose of assisting Varian support people. As the software
 development for Sun/Solaris at Varian has stopped, the Solaris part
 of this contribution is essentially "frozen", while the Linux part
 is frequently updated in order to provide up-to-date coverage of
 PC hardware, RHEL and VnmrJ versions. Under Linux, "sysprofiler"
 may be installed and used prior to installing VnmrJ - e.g., in order
 to pre-check whether a "vanilla" RHEL installation (such as RHEL 5.1
 or RHEL 5.3/5.4) is suited for installing and running VnmrJ. In this
 case, the executables will automatically be removed from "/bin" after
 completion, i.e., to re-execute you would need to reinstall. Under
 Linux, and when installed by vnmr1 (in "/vnmr"), the "sysprofiler"
 utility features an auto-update feature, whereby the tool can download
 the current version and install it by itself (start-up dialog).

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
Date submitted: 2003-09-25 Original submission
                2003-10-09 Added checks for presence of GNU C and
                           "End User" option only Solaris installs
                2003-10-17 Added device name for UFS disk partitions
                2003-11-03 Added networking config output / checks
                2003-11-07 Patch recommendations
                2003-11-10 Summary and upgrade recommendations added
                2003-11-13 Added console hardware info, where available
                2004-03-07 Major expansions: userlib contributions in
                           "/vnmr", VnmrJ / VNMR users, printers/plotters
                2004-03-15 Avoids error if "/etc/group" inaccessible (report
                           R.McKay, NANUC); VnmrJ / VNMR user info includes
                           UID / GID if available; rearrangements in output
                           order, new "-r" option, limit "showstat" output,
                           list probe calibrations in "/vnmr/probes" & shims
                           in "/vnmr/shims", prompt for contribution updates,
                           limited security info (suggestions by R.Machinek)
                2004-03-18 Security warning in recommendations, shims & probe
                           calibration listings improved; shim maps, new "-a"
                           ("-acq") & "-u" ("-users") options.
                2004-03-21 Enhanced security checks (rating "/etc/inetd.conf"
                           and "/etc/services")
                2004-03-23 Adjusted "sadmind" security check for latest info
                2004-04-19 Additional security check enhancements, checks for
                           TCP wrapper in Solaris 9
                2004-05-19 Print UFS dump dates, if available
                2004-05-23 Improved output for local UFS partitions
                2004-06-09 Facilitates calls from within VNMR
                2004-06-10 Added info about VnmrJ installation path & options
                2004-06-13 Covers VnmrJ / VNMR & Solaris compatibility issues
                2004-06-16 Userlib install history in "/vnmr", if available
                2004-06-30 Enhanced output about VnmrJ / VNMR users
                2004-07-06 Added hostid to output, adjustments for VnmrJ 1.1D
                2004-07-08 Clarifications in printer information
                2004-08-17 Graphics controllers, Java and "cc" versions,
                           "sendmail" info, last reboot, network access
                2004-09-12 Report acquisition kernel selection for UNITY INOVA
                2004-09-16 Updated partitioning recommendations, enhancements.
                2004-09-27 Improved remote access & reboot reports
                2004-10-02 More updates on disk partitioning recommendations
                2004-10-08 Minimum swap corrected, report logging file systems
                           Corrected bug with output about XVR-100 graphics
                2004-10-10 Enhanced remote access report
                2004-10-23 Numerous enhancements and corrections.
                2004-12-08 Major expansions in printer/plotter checks & output
                2004-12-18 Reports date & time of VnmrJ / VNMR patch installs;
                           detect clashes of 64-bit mode and HAL-based systems.
                2004-12-23 Minor enhancements in printer/plotter output.
                2004-12-25 Report extraneous files "/etc/hostname.*"
                2005-01-08 Relaxed swap space recommendations for big RAM
                2005-02-08 Improved output for remote access log
                2005-03-02 Bug fixes & improvements for older Solaris versions
                2005-03-17 No access log for Solaris 7, netmask readout fixed
                2005-03-24 Limited support for DirectDrive architecture
                2005-03-28 Minor fix with VnmrJ installation options
                2005-04-18 Fixes for DirectDrive architecture
                2005-06-22 Swap space definitions / virtual memory usage
                2005-08-08 Fixed minor bug in install script
                2005-09-15 Added info about language / locale settings
                2005-11-17 Minor changes in install script
                2005-12-03 Secured against potential string comparison errors
                2006-01-16 Amendments for VnmrJ 2.1B
                2006-01-24 Locator database statistics, minor output cleanup
                2007-01-24 Renamed from "showconfig" to "sysprofiler"
                2007-02-23 Output wording adjusted
                2008-01-01 Added (currently limited) PC/Linux support
                2008-03-20 Addressed "head" / "tail" issue in RHEL 5.1
                2008-09-18 Minor fix (RHEL only)
                2008-10-04 Two bug fixes, enhancements
                2008-11-08 MAJOR ENHANCEMENTS for Linux
                2008-11-12 First version with "full" Linux coverage
                2008-11-13 Added recommendation output in Linux part
                2008-11-14 Fixed several bugs / issues with RHEL 4
                2008-11-19 Additions in recommendations part for Linux
                2009-01-08 Major enhancements, especially under RHEL 4
                2009-01-14 Added RHEL language checks
                2009-01-16 Enhancements in printer/plotter analysis
                2009-01-21 Amendments for RHEL 5.3
                2009-01-27 More OS level checks, "seqgen" check
                2009-01-28 Extracts additional BIOS information
                2009-01-30 Various fixes and enhancements
                2009-02-03 Updates, fixed syntax error in built-in C module
                2009-03-06 Various additions / enhancements for RHEL
                2009-03-10 Major enhancements / additions for RHEL 5, graphics
                2009-03-19 Shows VnmrJ user / operator info / definitions
                2009-03-24 Allow use prior to VnmrJ installation in Linux
                2009-04-02 Covers Dell Precision T3400, several enhancements
                2009-04-06 Various updates and fixes (mostly for RHEL 5.x)
                2009-04-21 Several enhancements added
                2009-05-01 Several bug fixes and enhancements
                2009-05-27 Added checks on file ownership in "/vnmr"
                2009-06-23 Added check for acquisition communication issues
                2009-07-24 Numerous enhancements & expansions
                2009-09-18 Adds coverage of RHEL 5.4
                2010-01-18 New version, with auto-updating (Linux only)
                2010-07-12 Additions and enhancements
                2010-07-14 Expanded network configuration output
                2010-07-16 Output reordered (Linux), new "--printers" option
                2010-07-18 Expanded checking for DNS setup (Linux)
                2010-07-27 Expanded check on "/etc/hosts" (Linux)
                2010-09-13 Bug fixed (occasional endless loops), enhancements
                2010-09-17 Various bug fixes and updates
                2010-11-30 Various enhancements
                2011-09-11 Various enhancements

File name:      sysprofiler
Directory:      bin
Description:    "sysprofiler" is a utility the collects information about the
                workstation hardware, operating environment and application
                software configuration in the following areas:
                 - workstation type & hardware configuration
                 - OS version, installed OS patches / updates, networking
                   and security information (currently limited in Linux)
                 - VnmrJ / VNMR version and installed VnmrJ / VNMR software
                   options, patches and user library contributions
                 - acquisition console configuration
                 - software and workstation hardware upgrade recommendations.
                "sysprofiler" is useful when trying to assess whether and how
                a system can or needs to be upgraded to run current OS and/or
                VnmrJ / VNMR software. It also permits inexperienced users to
                extract configuration information for the purpose of assisting
                Varian support people.
                As the software development for Sun/Solaris at Varian has
                stopped, the Solaris part of this contribution is essentially
                "frozen", while the Linux part is frequently updated in order
                to provide up-to-date coverage of PC hardware, RHEL and VnmrJ
                versions.
                Under Linux, "sysprofiler" may be installed and used prior to
                installing VnmrJ - e.g., in order to pre-check whether a
                "vanilla" RHEL installation (such as RHEL 5.1 or RHEL 5.3/5.4)
                is suited for installing and running VnmrJ. In this case, the
                executables will automatically be removed from "/bin" after
                completion, i.e., to re-execute you would need to reinstall.
                Under Linux, and when installed by vnmr1 (in "/vnmr"), the
                "sysprofiler" utility features an auto-update feature, whereby
                the tool can download the current version and install it by
                itself (start-up dialog).

Related files:  bin/eval_netmask        bin/sysprofiler
                bin/sysprof.lnx         bin/sysprof.sol
                maclib/sysprofiler      manual/sysprofiler
                source/eval_netmask.c

Existing VnmrJ / VNMR files which are superseded or
otherwise affected by this submission:  none
Hardware configuration limitations:     PC/Linux and Sun/Solaris
Known software version compatibility:   VNMR 6.1C - VnmrJ 2.3A
Known OS version compatibility:         Solaris 2.x - Solaris 9, RHEL 4/5
Special instructions for installation:
    If you are downloading from the Internet, as vnmr1, store
    the file "sysprofiler.tar.Z" in "/vnmr/userlib/bin", then use
        cd /vnmr/userlib
        ./extract bin/sysprofiler /vnmr
        rehash
    which safely installs the contribution in "/vnmr" (no standard VnmrJ files
    are altered or overwritten). Alternatively, VnmrJ users can perform an
    installation in their local directories - in this case, simply omit the
    argument "/vnmr".

    If you have NOT installed VnmrJ under Linux yet (the symbolic link "/vnmr"

**This software has not been tested on OpenVnmrJ. Use at your own risk.**

To install this user contribution:  
Download the repository from GitHub and checkout the tag of the contribution you want.
Typically tags end in the version (e.g. -v1.0)

     git clone https://github.com/OpenVnmrJ/bin  
     cd bin  
     git checkout sysprofiler-v1.0


You may also download the archive directly from github at

    https://github.com/OpenVnmrJ/maclib/archive/sysprofiler-v1.0.zip

Read sysprofiler.README for installation instructions.

In most cases, move the contribution to /vnmr/userlib/bin 
then use extract to install the contribution:  

    extract bin/sysprofiler