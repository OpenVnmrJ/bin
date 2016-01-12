#Userlib/bin
This repository contains the userlib/bin contributions for VnmrJ as
packaged in VnmrJ 4.2

##NOTES & CAUTIONS
* Many of these contributions were incorporated into the core VnmrJ
software years ago, so may be redundant with core capabilities
* Most of the contributions are obsolete.
* Though many contributions work, there is often a better way of doing
things in the more modern software
* These contributions are not guaranteed to work
* These tools may work on some systems but not others. Many will only
work with certain versions of VnmrJ, VNMR, RHEL, or Solaris.
* Use these tools at your own risk. Some of them, such as pulse sequences,
could potentially damage hardware, and neither Agilent nor UO is
responsible for such damage.
* Though this is the User Library, users' contributions are mixed
with those from Varian and Agilent staff. On Spinsights, similar
Agilent-provided materials like Chempack are available in Toolkit, and
shared materials from users/customers are here in User Library. Agilent
staff still do contribute to the currently active User Library, but,
like all other contributions, those are personal materials that they
have developed and find useful, and they are not officially supported by
Agilent or guaranteed to work.
* The last update to this file was performed on February 1, 2013, and it
will not be updated again.
* This initially should only contain contributions from Agilent and/or
Varian but your contributions are welcome

##Downloading
You may download this repository from GitHub at:
https://github.com/OpenVnmrJ/bin.git

##Updating and adding
- Fork on GitHub
- Do not add your contribution to the master branch
- If updating contribution, checkout the tag of the contribution, update
and commit on the contribution branch
- If adding a new contribution, checkout a new branch with the name of
the contribution, push the new branch to your repository, add and commit
on the new branch
- Tag your update of change with the name of the contribution, followed
by a version, for example, mymacro-v1.1
- Push your branch to your fork; remember to push the tags too
- Make a pull request to the OpenVnmrJ repository

##Contributions

Below is a list of each contribution. To access a contributions, check
out its tag

##bruspec2var
>Import a transformed Bruker 1D dataset into VnmrJ / VNMR.

---
To install the contribution, checkout the tag bruspec2var-v1.0:

    git checkout bruspec2var-v1.0

then read bruspec2var.README

Usually use extract to install the contribution:

    extract bin/bruspec2var

##combine2d
>Calculate linear combinations of two 1D or 2D data sets, i.e.,
calculating sums and differences of FIDs, doing "2D / FID mathematics".

---
To install the contribution, checkout the tag combine2d-v1.0:

    git checkout combine2d-v1.0

then read combine2d.README

Usually use extract to install the contribution:

    extract bin/combine2d

##fixmsl
>Pre-processor for Bruker MSL data sets

---
To install the contribution, checkout the tag fixmsl-v1.0:

    git checkout fixmsl-v1.0

then read fixmsl.README

Usually use extract to install the contribution:

    extract bin/fixmsl

##jeoltovar
>Converts JEOL data to VNMR format, works for 1D, 2D and
arrayed 1D data sets, as well as phase-sensitive 2D data (States
method). Can capture incoming JEOL data sets, convert and process them
automatically. Acknowledgements:  The concept for maclib/jeoltovar and
bin/jeoltovar.c was taken over from the original submitter; all the
additional enhancements were only possible through extensive assistance
on the part of Dr. Martin Kipps, ICI/Zeneca Agrochemicals, Bracknell,
Berkshire, U.K., who also assisted with numerous suggestions.

---
To install the contribution, checkout the tag jeoltovar-v1.0:

    git checkout jeoltovar-v1.0

then read jeoltovar.README

Usually use extract to install the contribution:

    extract bin/jeoltovar

##makecd
>Create ISO9660 archive disk image or archive data to CD-R disks
directly; "makecd" also handles the case where the amount of data
in the archive directory exceeds the capacity of the archival media;
highly customizable. NOTE: Under Solaris 8 and older releases you need
to install "mkisofs" (to create ISO9660 file systems) and "cdrecord"
(if you also want to burn archival media directly). Also, there are
possible limitations in partial archiving with older (pre-Solaris 9)
versions of "mkisofs".

---
To install the contribution, checkout the tag makecd-v1.0:

    git checkout makecd-v1.0

then read makecd.README

Usually use extract to install the contribution:

    extract bin/makecd

##merge2d
>Repair "defective" traces in a 2D FID. Such traces (as they can
be obtained due to magnet environment / homogeneity changes, sudden
temperature changes, spurious floor vibrations etc.) can be reacquired
as single or arrayed 1D data sets (one experiment per consecutive
series of bad FIDs) and "merged" into the 2D FID. "merge2d" copies
as many FIDs as it finds in the (arrayed) 1D data set.

---
To install the contribution, checkout the tag merge2d-v1.0:

    git checkout merge2d-v1.0

then read merge2d.README

Usually use extract to install the contribution:

    extract bin/merge2d

##parhandler
>This is a collection of parameter handling tools. In its core it
uses a utility "listparam" that lists VNMR parameter files (or
better: selected parameter groups from such a file) in a simple,
one-line-per-parameter format. Based on this utility the parlist
macro allows listing ALL parameters in the current experiment (also
those not contained in any dg screen!).  The same utility is used in a
UNIX (diffparam) and a macro (pardiff) utility that allows comparing
COMPLETE parameter sets at a glance. The macro "svfj" saves an FID
(1D, or a FID trace from a 2D or an arrayed 1D data set) in JCAMP-DX
format. The macros "svsj" and "svlsj" save a spectrum in JCAMP-DX
format (16- and 24-bit digital precision). The macro "svxyj" saves
a spectrum in JCAMP-DX "X,Y" format (one X,Y pair per line). "svsj",
"svlsj" and "svxyj" also work for traces from arrayed 1D spectra, as
well as for f1 and f2 traces from partially and fully transformed 2D
spectra. Entire 2D data sets or 1D arrays can NOT be saved in JCAMP-DX
format at this point. Known limitation: "svfj" does not work with
"nf>1". The macro "svllj" saves X,Y peak lists in JCAMP-DX format
(X,Y,M lists if DEPT analysis results are present). A new utility,
"import1Dspec" reads 1D ASCII spectra such as from "writetrace"
or "writexy" (i.e., Y .. Y or X,Y .. X,Y data) into the current
experiment in VnmrJ / VNMR. Note for VNMR 6.1C users: for better
GLP and 21CFRpart11 compliance of the exported JCAMP-DX data under
VNMR 6.1C (NOT VnmrJ) it is strongly recommended also to download
and install the contribution "maclib/glp". NOTE: this contribution
includes ALL features of the smaller contribution "maclib/writetrace".

---
To install the contribution, checkout the tag parhandler-v1.0:

    git checkout parhandler-v1.0

then read parhandler.README

Usually use extract to install the contribution:

    extract bin/parhandler

##pcosyproc
>Process P.COSY (i.e. cosyps) data set according to literature (see
D.Marion & A.Bax, J.Magn.Reson. 80, 528 (1988)) by subtracting a 1D
spectrum (1st trace of cosyps with read pulse replaced by a delay)
from each trace, left-shifted by one data point per t1 dwell time.

---
To install the contribution, checkout the tag pcosyproc-v1.0:

    git checkout pcosyproc-v1.0

then read pcosyproc.README

Usually use extract to install the contribution:

    extract bin/pcosyproc

##rephasefid
>Allows rephasing of 1D/2D FIDs or parts thereof by altering the
zero-order phase of specified FIDs in a dataset. This may be required
for processing certain kinds of imported 2D datasets, or for parts
that were acquired separately and merged in "after the fact", in
order to correct problems with the originally acquired FID.

---
To install the contribution, checkout the tag rephasefid-v1.0:

    git checkout rephasefid-v1.0

then read rephasefid.README

Usually use extract to install the contribution:

    extract bin/rephasefid

##stripheaders
>"stripheaders" is a utility for removing file headers from binary
VNMR data files, such that third party software does not need to deal
with the header files. The "pure data" information is stored in a new
file *.bin, the header information is collected in a separate file
*.hdr. In addition to that, "stripheaders" creates a text file (*.txt)
with readable information about the file structure. "stripheaders"
works for VNMR FIDs of any kind, for datdir/data (2D data only when
processed with "wft", NOT wft1d/wft2d), and datdir/phasefile (both
1D and 2D).

---
To install the contribution, checkout the tag stripheaders-v1.0:

    git checkout stripheaders-v1.0

then read stripheaders.README

Usually use extract to install the contribution:

    extract bin/stripheaders

##sysprofiler
>"sysprofiler" is a utility the collects information about the
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

---
To install the contribution, checkout the tag sysprofiler-v1.0:

    git checkout sysprofiler-v1.0

then read sysprofiler.README

Usually use extract to install the contribution:

    extract bin/sysprofiler

##trsub
>subtracts reference trace from all other traces in arrayed 1D spectrum
(e.g., for NOE experiments); subtracts a horizontal (f1 or f2)
reference trace from all traces in a 2D spectrum.

---
To install the contribution, checkout the tag trsub-v1.0:

    git checkout trsub-v1.0

then read trsub.README

Usually use extract to install the contribution:

    extract bin/trsub

##v2v
>Converts Varian FID files to double precision integer, single precision
integer or floating point formats.

---
To install the contribution, checkout the tag v2v-v1.0:

    git checkout v2v-v1.0

then read v2v.README

Usually use extract to install the contribution:

    extract bin/v2v

##vxrimport
>Utilities for reading QIC tapes with XL/VXR/GEMINI legacy data, and
for recursively decomposing directories from imported XL/VXR/GEMINI,
and converting FID files contained therein into VNMR / VnmrJ format.

---
To install the contribution, checkout the tag vxrimport-v1.0:

    git checkout vxrimport-v1.0

then read vxrimport.README

Usually use extract to install the contribution:

    extract bin/vxrimport

