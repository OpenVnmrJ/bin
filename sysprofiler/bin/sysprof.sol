#!/bin/sh
# sysprof.sol - shell script for reporting Sun hardware & OS facts,
#               as well as VnmrJ/VNMR version, and installed patches
#
# REVISION HISTORY:
#------------------------------------------------------------------------------
# (see the bottom of the script for details)
#


#-------------------
# version ID / date
#-------------------

#(revdate is maintained by packing script)
revdate="2010-12-23_01:58"

#(last version segment incremented by packing script)
version="7.24.1"

#------------------------
# the author's signature
#------------------------
author="Rolf Kyburz, Agilent Technologies"
authoraddr="rolf.kyburz@agilent.com"


#-----------------------------
# global variables / settings
#-----------------------------
#("revday" for recommendation output, derived from "revdate")
revday=`echo $revdate | cut -c1-10`
cmd=`basename $0`
wcmd=sysprofiler
if [ "x$vnmrsystem" = "x" ]; then
  vnmrsystem="/vnmr"
fi
wd=`pwd`
usernow=`id | tr '()' '  ' | cut -f2 -d' '`
tmp=/tmp/$wcmd.$$
lptmp=$tmp.lpstat
patchtmp=/tmp/${cmd}_patch.$$
numrec=0


#-----------------------
# Compatibility section
#-----------------------
os=`uname -s`
echo=`which echo`
if [ "$os" = SunOS ]; then
  awk=nawk
elif [ "$os" = Darwin ]; then
  awk=awk
elif [ "$os" = Linux ]; then
  awk=awk
  echo="$echo -e"
else
  awk=awk
fi


#-------------------------------------------
# Provisions for incomplete path definition
#-------------------------------------------
if [ `which ping | grep -vc '^no ping '` -gt 0 ]; then
  ping=`which ping`
else
  ping=/usr/sbin/ping
fi
if [ `which arp | grep -vc '^no arp '` -gt 0 ]; then
  arp=arp
else
  arp=/usr/sbin/arp
fi
if [ -x ./eval_netmask ]; then
  eval_netmask=`pwd`/eval_netmask
elif [ `which eval_netmask | grep -vc '^no eval_netmask '` -gt 0 ]; then
  eval_netmask=eval_netmask
elif [ `dirname $0` = "." ]; then
  eval_netmask=`pwd`/eval_netmask
else
  eval_netmask=`dirname $0`/eval_netmask
fi


#--------------------------------------------------
# information and flags for recommendation section
#--------------------------------------------------
recom_ws1="Sun Blade 150/650"
recom_ws2="Sun Blade 1500"
cur_vnmr="VNMR 6.1C"
pending_vnmr=""
pending_vnmrdate=""
minrammb=128            # minimum RAM size for running VNMR
m_cur_vnmrj="VnmrJ 1.1D" # current VnmrJ for MERCURY-Vx / MERCURYplus
cur_vnmrj="VnmrJ 2.1B"
#pending_vj="VnmrJ 2.1B" # empty string if no new release to be available soon
pending_vj=""           # empty string if no new release to be available soon
pending_vjdate="January 2006"
minsolrel=""            # minimum Solaris release (configuration specific)
maxsolrel=""            # last possible Solaris release (config specific)
cursolrel="Solaris 9"   # current Solaris release
minrammbj=256           # minimum RAM size for running VnmrJ
mindisk=`expr 8 \* 1024`
mindiskwarn=`expr 6 \* 1024`
bit64on=0               # flag for 64-bit support in Solaris
vnmrbeta=0              # VnmrJ / VNMR beta flag
minswap=512             # minimum swap size recommended by Sun, MiB
minrootsizM=5000        # minimum recommended root slice (if possible at all)
slicedsizM=15000        # minimum disk size for partitioning
recrootsizM=10000       # recommended root slice size, in GiB
optminfreeK=100000      # minimum recommended free space in /opt
usrminfreeK=100000      # minimum recommended free space in /usr
varminfreeK=400000      # minimum recommended free space in /var
varwarnfreeK=1000000    # warning threshold for free space in /var
X1032A=0                # probably does not not have X1032A board yet
slowws=0                # indicator for slow workstations:
                        #  -1 = fast, current
                        #   0 = standard / current
                        #   1 = newer Ultra workstations
                        #   2 = early Ultra workstations (slow for VnmrJ)
                        #   3 = may work for old systems / VNMR / 1D
                        #   4 = obsolete / underpowered (SunOS/SunView only)
recsolnum=900           # recommended Solaris version (* 100)
vlist=20                # number of /vnmr files listed with bad UID/GID
open_hostequiv=0        # security check flag
open_xdmcp=0            # security check flag
bcast_xdmcp=0           # security check flag
sec_sadmind=0           # security check flag
n_inetd=0               # security check: open ports in /etc/inetd.conf
not_inetd=0             # security check: deactivated ports in /etc/inetd.conf
n_servc=0               # security check: open ports in /etc/services
not_servc=0             # security check: deactivated ports in /etc/services
n_wrapwarn=0            # security check: TCP wrapper warnings
pending_printjobs=0     # number of pending print jobs (total)
lpstatok=1              # flag for use of lpstat



#----------------------------------------
# printertype() - interpret printer type
#----------------------------------------
printertype() {
  $echo "                \c"
  if [ `$echo $1 | grep -c '^[TLP][CGPMI][BCDGP][A-H][012][0-9][0-9][0-9]$'` \
        -ne 0 ]; then
    ch1=`$echo $1 | cut -c1`
    ch2=`$echo $1 | cut -c2`
    ch3=`$echo $1 | cut -c3`
    ch4=`$echo $1 | cut -c4`
    dpi=`$echo $1 | cut -c5-8`
    if [ "$ch1" = T ]; then
      plotter=0
    else
      plotter=1
    fi
    case $ch2 in
      "C")
        if [ "$ch1" != T ]; then
          if [ "$ch3" = C ]; then
            $echo "PCL-3 \c"
          elif [ "$ch3" = D ]; then
            $echo "PCL-5/6 \c"
          else
            $echo "PCL \c"
          fi
        else
          $echo "PCL \c"
        fi ;;
      "G")      $echo "HP/GL \c" ;;
      "P")      $echo "PostScript \c" ;;
      "M")      $echo "PostScript->PCL \c" ;;
      "I")      $echo "DICOM \c" ;;
    esac
    case $ch1 in
      "T")      $echo "printer" ;;
      "P")      $echo "portrait\c" ;;
      "L")      $echo "landscape\c" ;;
    esac
    if [ $plotter -eq 1 ]; then
      case $ch3 in
        "B")    $echo "/b&w plotter\c" ;;
        "C")    $echo "/color plotter\c" ;;
        "D")    $echo "/color plotter\c" ;;
        "G")    $echo "/color plotter\c" ;;
        "P")    $echo "/color plotter\c" ;;
      esac
      case $ch4 in
        "A")    $echo ", A4 format\c" ;;
        "B")    $echo ", A3 format\c" ;;
        "C")    $echo ", letter format\c" ;;
        "D")    $echo ", tabloid format\c" ;;
        "E")    $echo ", legal format\c" ;;
        "F")    $echo ", 17x22\" format\c" ;;
        "G")    $echo ", 22x34\" format\c" ;;
        "H")    $echo ", 34x44\" format\c" ;;
      esac
      if [ $ch2 != G ]; then
        dpi0=`$echo $dpi | cut -c1`
        if [ $dpi0 -eq 0 ]; then
          dpi=`$echo $dpi | cut -c2-4`
        fi
        $echo ", $dpi dpi"
      else
        $awk < /vnmr/devicetable 'BEGIN {
          state=0
          ppmm=0
          ych=0
          xchar=0
          wc=0
          wc2=0
          xres=1
          yres=1
          xoffset=0
          yoffset=0
          values=0
        }
        {
          if ($1 == "PrinterType")
          {
            if ($2 == "'$1'")
              state=1
            else
              state=0
          }
          if ((state == 1) && (NF > 1))
          {
            if ($1 == "ppmm")
            {
              ppmm=$2
              values++
            }
            else if ($1 == "xcharp1")
            {
              xch=$2
              values++
            }
            else if ($1 == "ycharp1")
            {
              ych=$2
              values++
            }
            else if ($1 == "wcmaxmax")
            {
              wc=$2
              values++
            }
            else if ($1 == "wc2maxmax")
            {
              wc2=$2
              values++
            }
            else if ($1 == "xoffset")
            {
              xres=$2
              values++
            }
            else if ($1 == "yoffset")
            {
              yres=$2
              values++
            }
            else if ($1 == "xoffset1")
            {
              xoffset=$2
              values++
            }
            else if ($1 == "yoffset1")
            {
              yoffset=$2
              values++
            }
          }
        }
        END {
          if (values > 0)
          {
            line2=0
            if (ppmm > 0)
              printf(", resolution %g points per mm", ppmm)
            else
              ppmm=1
            line2=0
            if ((wc > 0) && (wc2 > 0))
              printf("plot area %d x %d mm\n", wc, wc2)
            if ((xoffset > 0) && (yoffset > 0))
              printf("X/Y offset %3.1f/%3.1f mm\n", xoffset/xres, yoffset/yres)
            else if (xoffset > 0)
              printf("X offset %3.1f mm\n", xoffset/xres)
            else if (yoffset > 0)
              printf("Y offset %3.1f mm\n", yoffset/yres)
            if ((xch > 0) && (ych > 0))
              printf("character size %3.1f x %3.1f mm\n", xch/ppmm, ych/ppmm)
          }
        }'
        $echo
      fi
    fi
  else
    $echo "VnmrJ / VNMR plotter type \"$1\""
    $awk < /vnmr/devicetable 'BEGIN {
      state=0
      ppmm=0
      rt=0
      rcharsiz=0
      rres=0
      ych=0
      xchar=0
      wc=0
      wc2=0
      xres=1
      yres=1
      xoffset=0
      yoffset=0
      values=0
    }
    {
      if ($1 == "PrinterType")
      {
        if ($2 == "'$1'")
          state=1
        else
          state=0
      }
      if ((state == 1) && (NF > 1))
      {
        if ($1 == "ppmm")
        {
          ppmm=$2
          values++
        }
        else if ($1 == "raster")
        {
          rt=$2
          values++
        }
        else if ($1 == "raster_charsize")
        {
          rcharsiz=$2
          values++
        }
        else if ($1 == "raster_resolution")
        {
          rres=$2
          values++
        }
        else if ($1 == "xcharp1")
        {
          xch=$2
          values++
        }
        else if ($1 == "ycharp1")
        {
          ych=$2
          values++
        }
        else if ($1 == "wcmaxmax")
        {
          wc=$2
          values++
        }
        else if ($1 == "wc2maxmax")
        {
          wc2=$2
          values++
        }
        else if ($1 == "xoffset")
        {
          xres=$2
          values++
        }
        else if ($1 == "yoffset")
        {
          yres=$2
          values++
        }
        else if ($1 == "xoffset1")
        {
          xoffset=$2
          values++
        }
        else if ($1 == "yoffset1")
        {
          yoffset=$2
          values++
        }
      }
    }
    END {
      if (values > 0)
      {
        if (rt == 0)
        {
          printf("HP/GL plotter\n")
          if (ppmm > 0)
            printf("resolution %g points per mm\n", ppmm)
          else
            ppmm=1
          if ((wc > 0) && (wc2 > 0))
            printf("X/Y range (wcmax/wc2max) %dx%d mm\n", wc, wc2)
          if ((xoffset > 0) && (yoffset > 0))
            printf("X/Y offset %3.1f/%3.1f mm\n", xoffset/xres, yoffset/yres)
          else if (xoffset > 0)
            printf("X offset %3.1f mm\n", xoffset/xres)
          else if (yoffset > 0)
            printf("Y offset %3.1f mm\n", yoffset/yres)
          if ((xch > 0) && (ych > 0))
            printf("character size %3.1fx%3.1f mm\n", xch/ppmm, ych/ppmm)
        }
        else #PCL and PS printers
        {
          if (rt == 1)
            printf("PCL / portrait mode plotter\n")
          else if (rt == 2)
            printf("PCL / landscape mode plotter\n")
          else if (rt == 3)
            printf("PostScript / portrait mode plotter\n")
          else if (rt == 4)
            printf("PostScript / landscape mode plotter\n")
          if ((wc > 0) && (wc2 > 0))
            printf("X/Y range (wcmax/wc2max) %dx%d mm\n", wc, wc2)
          if ((xoffset > 0) && (yoffset > 0))
            printf("X/Y offset %3.1f/%3.1f mm\n", xoffset/xres, yoffset/yres)
          else if (xoffset > 0)
            printf("X offset %3.1f mm\n", xoffset/xres)
          else if (yoffset > 0)
            printf("Y offset %3.1f mm\n", yoffset/yres)
          if (rres != 0)
            printf("raster resolution %d dpi\n", rres)
          if (rcharsiz != 0)
            printf("raster character size %d\n", rcharsiz)
        }
      }
    }' | sed 's/^/                /'
  fi
}
#-------------------
# END printertype()
#-------------------



#---------------------------------------------------------------
# showprintq() - display UNIX queue status of specified printer
#---------------------------------------------------------------
showprintq() {
  pname=$1
  phost=$2
  prtype=$3

  if [ "$def_printer" = "$pname" ]; then
    $echo "              SYSTEM DEFAULT DESTINATION"
  fi
  if [ $lpstatok -ne 0 ]; then
    pdev="`lpstat -v $pname`"
    if [ "$pdev " != "" ]; then
      $echo "              $pdev"
    fi
  fi

  # print a line such as
  #     accepting requests since ...
  if [ $lpstatok -ne 0 ]; then
    lpstat -a $pname | sed "s/^$pname /              /"
  fi

  # print output such as
  #     printer is idle. (busy, .... )
  #     enabled/disabled since ...
  if [ $lpstatok -ne 0 ]; then
    stat=`lpstat -p $pname`
    lpstat -p $pname | sed "s/^printer $pname /printer /" | $awk '
    {
      pos=match($0,/\. /)
      if (pos == 0)
        print
      else
      {
        s1=""
        s2=""
        s1=substr($0,1,pos)
        s2=substr($0,pos+2,length($0)-(pos+1))
        print s1
        print s2
      }
    }' | sed 's/^/              /'
  fi

  # Report pending print jobs
  if [ $lpstatok -ne 0 ]; then
    pending=`lpstat -o $pname | wc -l`
    pending_printjobs=`expr $pending_printjobs + $pending`
    if [ $pending -eq 1 ]; then
      echo "                ==> 1 PENDING PRINT JOB FOR THIS PRINTER."
    elif [ $pending -gt 1 ]; then
      echo "                ==> $pending PENDING PRINT JOBS FOR THIS PRINTER."
    else
      echo "              no pending print jobs for this printer."
    fi
  fi

  # check network printer / remote print host accessibility, using "ping"
  if [ "x$prtype" = xnetwork -o "x$prtype" = xremote ]; then
    pingOK=`$ping -q -c 1 $phost 2>/dev/null | grep -c ' 1 received,'`
    if [ "x$prtype" = xnetwork ]; then
      if [ $pingOK -gt 0 ]; then
        $echo "              printer responds to \"ping\"."
      else
        $echo "              printer does NOT respond to \"ping\"."
      fi
    else
      if [ $pingOK -gt 0 ]; then
        $echo "              remote print server responds to \"ping\"."
      else
        $echo "              remote print server does NOT respond to \"ping\"."
      fi
    fi
  fi
}
#------------------
# END showprintq()
#------------------



#-------------------------------------------------------------------
# showprinter() - display properties of specified printer / plotter
#-------------------------------------------------------------------
showprinter() {
  name=$1
  makeprinter=$2
  use=`$awk <$vnmrsystem/devicenames \
    '{if (($1 == "Name") && ($2 == "'$name'")) {getline; print $NF}}'`
  type=`$awk <$vnmrsystem/devicenames \
    '{if (($1 == "Name") && ($2 == "'$name'")) {getline; getline; print $NF}}'`
  host=`$awk <$vnmrsystem/devicenames \
    '{if (($1 == "Name") && ($2 == "'$name'")) {getline; getline; getline; print $NF}}'`
  port=`$awk <$vnmrsystem/devicenames \
    '{if (($1 == "Name") && ($2 == "'$name'")) {getline; getline; getline; getline; print $NF}}'`

  $echo "\"$name\"" | $awk '{printf(" %-12s ",$1)}'
  if [ "$host" = dummy -o "$name" = email ]; then
    $echo "dummy \c"
    ptype=dummy
  elif [ "$host" = `uname -n` -o "$host" = localhost ]; then
    $echo "LOCAL \c"
    ptype=local
  elif [ -d /etc/lp/printers/$name ]; then
    $echo "NETWORK \c"
    ptype=network
  else
    $echo "REMOTE \c"
    ptype=remote
  fi
  if [ "$use" = Printer ]; then
    $echo "Printer\c"
  elif [ "$use" = Plotter ]; then
    $echo "Plotter\c"
  else
    $echo "Printer/Plotter\c"
  fi
  if [ "$host" = dummy -o "$name" = email ]; then
    $echo " definition\c"
  fi
  if [ $makeprinter -ne 0 ]; then
    if [ "$host" = dummy -o "$name" = email ]; then
      $echo ", used for file plotting only"
    elif [ "$host" = `uname -n` -o "$host" = localhost ]; then
      $echo $port | $awk '{printf(", connected to port %s\n", $1)}'
    elif [ "$prhost" != "" ]; then
      if [ $ptype = network ]; then
        $echo $prhost | $awk '{printf(" at \"%s\"\n", $1)}'
      else
        $echo $prhost | $awk '{printf(" connected to \"%s\"\n", $1)}'
      fi
    elif [ $ptype = network ]; then
      $echo " at UNKNOWN/UNDEFINED LOCATION / ADDRESS"
    elif [ $ptype = remote ]; then
      $echo " on UNKNOWN/UNDEFINED HOST"
    else
      $echo
    fi
  else
    if [ "$host" = dummy -o "$name" = email ]; then
      $echo " (plotting to file/PDF/e-mail)"
    elif [ "$host" = `uname -n` -o "$host" = localhost ]; then
      if [ "$port" = /dev/null ]; then
        $echo ", used for plotting to file/e-mail only"
      else
        $echo $port | $awk '{printf(", connected to port %s\n", $1)}'
      fi
    elif [ "$prhost" != "" ]; then
      if [ $ptype = network ]; then
        $echo $prhost | $awk '{printf(" at \"%s\"\n", $1)}'
      else
        $echo $prhost | $awk '{printf(" connected to \"%s\"\n", $1)}'
      fi
    else
      if [ $lpstatok -ne 0 ]; then
        prhost=`lpstat -v "$name" | tr '/' ' ' | $awk '{print $(NF-1)}'`
      fi
      if [ $ptype = network ]; then
        $echo " at UNDEFINED LOCATION / ADDRESS"
      elif [ $ptype = remote ]; then
        $echo " on UNDEFINED HOST"
      else
        $echo
      fi
    fi
  fi
  if [ "$type" != "" ]; then
    printertype $type
  else
    cat << %
                NOT defined in "/vnmr/devicenames", i.e., this device is
                NOT a usable printer/plotter within VnmrJ
%
  fi
  if [ "$host" != dummy -a "$name" != email -a \
       `lpstat -p 2>/dev/null | $awk '{if ($0 ~ /^printer /) print $2}' | \
        grep -wc $name` -ne 0 ]; then
    showprintq $name $host $ptype
  fi
}
#-------------------
# END showprinter()
#-------------------



#---------------------------------------------------------------------
# showport() - display properties of specified serial / parallel port
#---------------------------------------------------------------------
showport() {
  name=$1
  $echo $name | $awk '{printf("%-15s ",$1)}'
  d=`ls -l $name | $awk '{print $NF}' | sed 's/\.\.\///g
s/^/\//'`
  owner=`ls -l $d | $awk '{printf("%s/%s\n",$3,$4)}'`
  perm=`ls -l $d | $awk '{printf("%s\n",substr($1,2,9))}'`
  $echo "$perm $owner" | $awk '{printf("   %9s       %s",$1,$2)}'
  if [ "$owner" = "lp/lp" -o "$owner" = "root/lp" ]; then
    $echo "        Used for printing/plotting"
  else
    $echo
  fi
}
#----------------
# END showport()
#----------------



#==============================================================================
# GLOBAL OUTPUT FLAGS
#==============================================================================
showall=0
showacq=0
showpatches=0
showdumps=0
shownet=0
showversion=1
showrevs=0
showusers=0
showsum=0
showrecomm=0
showsecurity=0



#==============================================================================
# CHECK FOR OS AND HARDWARE COMPATIBILITY
#==============================================================================

#---------------------------
# check for SunOS / Solaris
#---------------------------
if [ "$os" = SunOS ]; then

  #------------------------------------------------------------------
  # Check for Solaris 2.x & up (as opposed to SunOS 4.x and earlier)
  #------------------------------------------------------------------
  osv=`uname -r | $awk '{print substr($1,1,1)}'`
  if [ "$osv" != "5" ]; then
    $echo
    $echo "\"$cmd\" currently implemented for Solaris 2.x and higher only -"
    $echo "   ... aborting."
    $echo
    rm -f $tmp $patchtmp
    exit 1
  fi

  #-------------------------------
  # check for SPARC-based systems
  #-------------------------------
  proctype=`uname -p`
  if [ "$proctype" != sparc ]; then
    $echo
    $echo "\"$wcmd\" currently implemented for Sun SPARC based systems only -"
    $echo "   ... aborting."
    $echo
    rm -f $tmp $patchtmp
    exit 1
  fi
elif [ "$os" != Darwin ]; then
  $echo
  $echo "\"$wcmd\" is NOT implemented for the \"$os\" operating"
  $echo "  environment."
  $echo "Installed version: $cmd $version $revdate"
  $echo
  $echo "   ... aborting."
  $echo
  rm -f $tmp $patchtmp
  exit 1
fi



#==============================================================================
# EVALUATE ARGUMENTS
#==============================================================================

args="$*"
w_args=""
while [ $# -gt 0 ]; do
  argvalue=`$echo $1 | sed 's/^[-]*acq/--acq/
        s/^[-]*all.*/--all/
        s/^[-]*current.*/--help/
        s/^-[-]*help.*/--help/
        s/^[-]*hist.*/--history/
        s/^[-]*log.*/--help/
        s/^[-]*net/--net/
        s/^[-]*pack.*/--help/
        s/^[-]*patch.*/--patches/
        s/^[-]*pkg/--help/
        s/^[-]*plot.*/--help/
        s/^[-]*print.*/--help/
        s/^[-]*rec.*/--recomm/
        s/^[-]*sec.*/--security/
        s/^[-]*user.*/--users/
        s/^[-]*ver.*/--version/'`
  case $argvalue in
    -a|--acq)  
        showacq=1; w_args="$w_args $1" ;;
    -n|--net)  
        shownet=1; w_args="$w_args $1" ;;
    -p|--patches)
        showpatches=1; w_args="$w_args $1" ;;
    -r|--recomm)
        showrecomm=1; w_args="$w_args $1" ;;
    -s|--security)
        showsecurity=1; w_args="$w_args $1" ;;
    -u|--users)
        showusers=1; w_args="$w_args $1" ;;
    --all)
        showrecomm=1
        showsecurity=1
        showdumps=1
        showacq=1
        shownet=1
        showrevs=1
        showpatches=1
        showusers=1
        showversion=1
        showsum=1
        showall=1
        w_args="$w_args $1" ;;
    --history)
        hline=`grep -n 'REVISION HISTORY' $0 | tail -1 | tr ':' ' ' | \
                $awk '{print $1}'`
        tlines=`wc -l < $0`
        hlines=`expr $tlines - $hline - 2`
        $echo
        expand $0 | tail +$hline | head -$hlines | sed 's/^.//'
        $echo
        exit 0
        ;;
    -v|--version)
        $echo "$cmd version $version ($revdate)"
        rm -f $tmp $patchtmp
        exit 0
      ;;
    -h|--help)
        cat << %

Usage:  $wcmd <-a|-acq> <-n|-net> <-p|-patches> <-r|-rec> <-s|-sec> <-u|-users>
        $wcmd <-[anprsu]*>
        $wcmd <-all>
        $wcmd <-v|-version>
        $wcmd <-h|-help>

%
        rm -f $tmp $patchtmp
        exit 0
      ;;
    help)
        cat << %

Usage:  sysprofiler
        printon sysprofiler printoff
        sysprofiler(<'acq'><,'net'><,'patches'><,'rec'><,'sec'><,'users'>)
        sysprofiler('all')
        printon sysprofiler('all') printoff
        sysprofiler('version')
        sysprofiler('help')

%
        rm -f $tmp $patchtmp
        exit 0
      ;;
    *)
        if [ `$echo $1 | grep -c '^-[anprsu]*$'` -eq 1 ]; then
          showsum=1
          if [ `$echo $1 | grep -c a` -gt 0 ]; then
            showacq=1
          fi
          if [ `$echo $1 | grep -c n` -gt 0 ]; then
            showsecurity=1
            shownet=1
          fi
          if [ `$echo $1 | grep -c p` -gt 0 ]; then
            showpatches=1
          fi
          if [ `$echo $1 | grep -c r` -gt 0 ]; then
            showrecomm=1
          fi
          if [ `$echo $1 | grep -c s` -gt 0 ]; then
            showsecurity=1
          fi
          if [ `$echo $1 | grep -c u` -gt 0 ]; then
            showusers=1
          fi
          if [ `$echo $1 | $awk '{print length($0)}'` -gt 5 ]; then
            showusers=1
          fi
	  w_args="$w_args $1"
        else
          cat << %

Usage:  $wcmd <-a|-acq> <-n|-net> <-p|-patches> <-r|-rec> <-s|-sec> <-u|-users>
        $wcmd <-[anprsu]*>
        $wcmd <-all>
        $wcmd <-v|-version>
        $wcmd <-h|-help>

%
          rm -f $tmp $patchtmp
          exit 1
        fi
      ;;
  esac
  shift
done
w_args=`$echo "x$w_args" | sed 's/x[ ]*//'`

#------------------------------------------------------------------------------
# argument dependencies
#------------------------------------------------------------------------------
if [ $showacq -ne 0 ]; then
  shownet=1
  showsum=1
fi
if [ $shownet -ne 0 ]; then
  showsum=1
fi
if [ $showpatches -ne 0 ]; then
  showrevs=1
  showsum=1
  showversion=1
fi
if [ $showrecomm -ne 0 ]; then
  showdumps=1
  showsum=1
  showversion=1
fi
if [ $showsecurity -ne 0 ]; then
  shownet=1
  showpatches=1
  showrevs=1
  showsum=1
  showusers=1
  showversion=1
fi
if [ $showusers -ne 0 ]; then
  showversion=1
fi


#==============================================================================
# BANNER TITLE
#==============================================================================

host=`uname -n`
title="HARD- & SOFTWARE CONFIGURATION FOR SYSTEM \"$host\""
timestamp=`date -u '+Information collected on %Y-%m-%d %H:%M:%S %Z'`
($echo $title; $echo $timestamp) | $awk 'BEGIN {
  printf("\n")
  for (i=0; i<79; i++)
  {
    printf("=")
  }
  printf("\n")
}
{
  lead=int((79-length($0))/2-0.5)
  for (i=0; i<lead; i++)
  {
    printf(" ")
  }
  print
}
END {
  for (i=0; i<79; i++)
  {
    printf("=")
  }
  printf("\n")
}'
n_args=`$echo "$w_args" | wc -w`
$echo "  Current user:        ${usernow}\c"
idstr=`id | sed "s/($usernow)//"`
$echo "  [ $idstr ]"
if [ $n_args -gt 1 ]; then
  $echo "  Arguments supplied:  \"$w_args\""
elif [ $n_args -eq 1 ]; then
  $echo "  Argument supplied:   \"$w_args\""
else
  $echo "  (No arguments supplied)"
fi
fmt -w 79 << %
  Dates & time stamps in the text below are usually in ISO-8601 format, i.e.,
  "yyyy-mm-dd" and "yyyy-mm-dd HH:MM", respectively (local time zone, unless
  indicated otherwise).
%
fmt -w 79 << %
  Note: data / disk sizes are given in binary units (KiB, MiB, GiB, etc.);
  disk manufacturers may specify disk sizes in decimal units (MB, GB, etc.) -
  their values may therefore appear larger than the sizes shown below. For
  more information see Agilent MR News 2009-07-10.


%



#-----------------------------------------
# overriding restrictions depending on OS
#-----------------------------------------
restr=0
if [ "$os" = Darwin ]; then
  if [ $showall -eq 0 -a $showacq -ne 0 ]; then
    echo "$wcmd: acquisition not supported under MacOS X"
    restr=`expr $restr + 1`
  fi
  showacq=0

  if [ $showall -eq 0 -a $showpatches -ne 0 ]; then
    echo "$wcmd: OS patch analysis not supported under MacOS X"
    restr=`expr $restr + 1`
  fi
  showpatches=0

  if [ $showall -eq 0 -a $showdumps -ne 0 ]; then
    echo "$wcmd: system backup dump analysis not supported under MacOS X"
    restr=`expr $restr + 1`
  fi
  showdumps=0

  if [ $showall -eq 0 -a $shownet -ne 0 ]; then
    echo "$wcmd: networking setup not reported under MacOS X"
    restr=`expr $restr + 1`
  fi
  shownet=0

  if [ $showall -eq 0 -a $showrevs -ne 0 ]; then
    echo "$wcmd: command version analysis not supported under MacOS X"
    restr=`expr $restr + 1`
  fi
  showrevs=0

  if [ $showall -eq 0 -a $showusers -ne 0 ]; then
    echo "$wcmd: VnmrJ users not reported under MacOS X"
    restr=`expr $restr + 1`
  fi
  showusers=0

  if [ $showall -eq 0 -a $showrecomm -ne 0 ]; then
    echo "$wcmd: no OS installation recommendations under MacOS X"
    restr=`expr $restr + 1`
  fi
  showrecomm=0

  if [ $showall -eq 0 -a $showsecurity -ne 0 ]; then
    echo "$wcmd: no security recommendations under MacOS X"
    restr=`expr $restr + 1`
  fi
  showsecurity=0
fi
if [ $restr -gt 0 ]; then
  $echo
fi



#==============================================================================
# REPORT HARDWARE CONFIGURATION INFORMATION
#==============================================================================

if [ "$os" = SunOS ]; then

  $echo "Sun Workstation Hardware Configuration:"
  $echo "---------------------------------------\c"
  $echo "----------------------------------------"

  #---------------------------------------
  # report host name and workstation type
  #---------------------------------------
  wstype=`uname -i | sed 's/SUNW,//' | tr '-' ' '`

  # pre-determine processor speed
  MHz=0
  ix=0
  while [ $ix -lt 8 -o $MHz -eq 0 ]; do
    MHzstr=`/usr/sbin/psrinfo -v $ix 2>/dev/null | grep operates`
    if [ "$MHzstr" != "" ]; then
      MHz=`$echo $MHzstr | $awk '{print $(NF-1)}'`
    fi
    ix=`expr $ix + 1`
  done

  # EIDE-based workstations may already have X1032A board
  if [ `$echo $wstype | grep -ci Blade` -gt 0 -o \
       "wstype" = "Ultra 5_10" ]; then
    X1032A=1
  fi

  # Blade workstations always run in 64-bit mode
  if [ `$echo $wstype | grep -ci Blade` -gt 0 ]; then
    bit64on=1
  fi

  # find slow workstations, correct workstation type where possible
  if [ `$echo $wstype | grep -ci sparc` -gt 0 ]; then
    if [ `$echo $wstype | grep -cw 20` -gt 0 -o $MHz -gt 120 ]; then
      # SPARCstation 20, SPARCstation 5/170
      slowws=3
    else
      slowws=4
    fi
  elif [ "$wstype" = "Ultra 5_10" ]; then
    case $MHz in
      "267"|"270")        wstype="Ultra 5"; slowws=2 ;;
      "400")              wstype="Ultra 5" ;;
      "360")              slowws=1 ;;
      "300"|"330")        wstype="Ultra 10"; slowws=1 ;;
      "440")              wstype="Ultra 10" ;;
    esac
  elif [ "$wstype" = "Sun Blade 100" ]; then
    if [ $MHz -lt 520 ]; then
      wstype="Sun Blade 100";
    else
      wstype="Sun Blade 150";
    fi
  elif [ "$wstype" = "Sun Blade 1000" ]; then
    if [ $MHz -gt 950 ]; then
      wstype="Sun Blade 2000";
    fi
  elif [ $MHz -lt 240 ]; then
    # Sun Ultra 1, Ultra 2
    slowws=3
  elif [ $MHz -lt 380 ]; then
    slowws=1
  fi
  if [ $MHz -gt 700 -a $slowws -eq 0 ]; then
    slowws=-1
  fi

  # report workstation type
  if [ $shownet -ne 0 ]; then
    $echo "  Workstation is a $wstype\c"
  else
    $echo "  System \"$host\" is a $wstype\c"
  fi
  hostid=`hostid`
  $echo "  (hostid: $hostid)"


  #------------------------------
  # report processor (CPU) speed
  #------------------------------
  ix=0
  prnum=0
  while [ $ix -lt 8 ]; do
    MHzstr=`/usr/sbin/psrinfo -v $ix 2>/dev/null | grep operates`
    if [ "$MHzstr" != "" ]; then
      MHz=`$echo $MHzstr | $awk '{print $(NF-1)}'`
      $echo "  Processor #$prnum operates at $MHz MHz"
      prnum=`expr $prnum + 1`
    fi
    ix=`expr $ix + 1`
  done


  #--------------------------
  # report memory (RAM) size
  #--------------------------
  prtconf | grep '^Mem' | \
    $awk '{printf("  RAM size:         %5d MiB\n",$(NF-1))}'
  rammb=`prtconf | grep '^Mem' | $awk '{print $(NF-1)}'`

  # recommended swap size for installed RAM
  if [ $rammb -gt 2048 ]; then
    recswap=$rammb
    minswap=`expr $rammb / 4`
    minswapwarn=`$echo $rammb | $awk '{printf("%1.0f\n",0.75*$1)}'`
  elif [ $rammb -gt 1024 ]; then
    recswap=2048
    minswapwarn=$rammb
  else
    recswap=`expr $rammb \* 2`
    minswapwarn=`$echo $rammb | $awk '{printf("%1.0f\n",1.5*$1)}'`
  fi
  if [ $recswap -lt $minswap ]; then
    recswap=$minswap
  fi
  if [ $minswapwarn -lt $minswap ]; then
    minswapwarn=$minswap
  fi


  #-----------------------------------
  # report size of swap space (total)
  #-----------------------------------
  swap -l | grep -v '^swapfile' | $awk 'BEGIN {sum=0} {
      sum += $(NF-1)
    }
    END {printf("  Total swap space: %5d MiB\n",sum/2048)}'
  swapmb=`swap -l | tail +2 | $awk 'BEGIN {sum=0} {sum += $(NF-1)} \
    END {printf("%5d\n",sum/2048)}'`
  if [ $swapmb -lt $minswapwarn ]; then
    cat << %
  NOTE: With $rammb MiB of installed RAM we recommend setting the size
        of the swap space to $recswap MiB when installing Solaris ($minswap
        MiB or twice the size of the RAM, whichever is bigger). If the RAM
        size is bigger than 1 GiB, a swap space which is the same size as
        the RAM should be sufficient.
%
  fi


  #---------------------------------------
  # report total available UFS disk space
  #---------------------------------------
  df -k | grep -v ' /var/run$' | egrep '^/dev|^swap' | $awk 'BEGIN {sum=0}
    {sum += $2}
    END {printf("  Total disk size: %6.1f GiB\n",sum/(1024*1024))}'
  diskmb=`df -k | grep -v ' /tmp$' | egrep '^/dev|^swap' | \
  $awk 'BEGIN {sum=0} {sum += $2}
  END {printf("%1.0f\n",sum/1024)}'`
  rootdsk=`df -k / | tail -1 | $awk '{printf("%s\n",substr($1,1,length($1)-2))}'`
  disk1sizM=`df -k | $awk '
    BEGIN {sum=0; disk1name="'$rootdsk'"}
    {
      if ((NF > 5) && (substr($1,1,length($1)-2) == disk1name))
      {
        sum += $2
      }
    }
    END {printf("%1.0f\n",sum/1024)}'`
  disk1swapM=`swap -l | grep $rootdsk | $awk '{printf("%1.0d\n",$4/(2*1024))}'`
  if [ "x$disk1swapM" != x ]; then
    disk1sizM=`expr $disk1sizM + $disk1swapM`
  fi
  disk1ufsslices=`df -k | $awk '
    BEGIN {count=0; disk1name="'$rootdsk'"}
    {
      if ((NF > 5) && (substr($1,1,length($1)-2) == disk1name))
      {
        count += 1
      }
    }
    END {printf("%d\n",count)}'`
  rootsizM=`df -k / | tail -1 | $awk '{ printf("%1.0f\n",$2/1024) }'`
  rootsizK=`df -k / | tail -1 | $awk '{ printf("%d\n",$2) }'`
  rootfreeK=`df -k / | tail -1 | $awk '{ printf("%d\n",$4) }'`
  varsizK=`df -k /var | tail -1 | $awk '{ printf("%d\n",$2) }'`
  varfreeK=`df -k /var | tail -1 | $awk '{ printf("%d\n",$4) }'`
  usrsizK=`df -k /usr | tail -1 | $awk '{ printf("%d\n",$2) }'`
  usrfreeK=`df -k /usr | tail -1 | $awk '{ printf("%d\n",$4) }'`
  optsizK=`df -k /opt | tail -1 | $awk '{ printf("%d\n",$2) }'`
  optfreeK=`df -k /opt | tail -1 | $awk '{ printf("%d\n",$4) }'`


  #--------------------------------------------------------------
  # report size and percent usage of defined UFS disk partitions
  #--------------------------------------------------------------
  (df -k -l -F ufs | tail +2; grep -w ufs < /etc/vfstab) | sort | \
        sed 's/^\/dev\/dsk\///' | sed 's/%//' > $tmp
  $awk < $tmp 'BEGIN {
      siz=0
      used=0
      free=0
      usable=0
      usage=0
      mount=""
      fs=""
      logging=-1
      printf("  Local UFS Partitions (sizes in MiB):\n")
      printf("     Size      Used      Free   Used%%")
      printf("   Device_name   Logging   Mounted as\n")
    }
    {
      if (NF > 6)
      {
        fs=$1
        mount=$3
        if ($NF ~ /logging/)
          logging=1
        else
          logging=0
      }
      else
      {
        fs=$1
        siz=$2
        used=$3
        free=$4
        usable=used+free
        if ($5 > 100)
          usage=$5
        else
          usage=used/usable*100
        mount=$NF
      }
      if ((logging != -1) && (siz != 0))
      {
        printf(" %9.1f %9.1f %9.1f  %4.1f%%  ",
               siz/1024, used/1024, free/1024, usage)
        printf("   %s", fs)
        if (logging == 0)
          printf("        no")
        else
          printf("       yes")
        printf("      %s\n", mount)
        siz=0
        used=0
        free=0
        usage=0
        mount=""
        fs=""
        logging=-1
      }
    }'
  rm -f $tmp $patchtmp
  ndisks=`df -k | grep '^/dev' | $awk '{print substr($1,10,4)}' | sort -u | wc -l`
  ndisks=`expr $ndisks + 0`
  nslices=`df -k | grep '^/dev' | $awk '{print substr($1,10,4)}' | wc -l`
  nslices=`expr $nslices + 0`


  #----------------------------------------
  # Report swap space definition and usage
  #----------------------------------------
  $echo "  Swap space definition & status:"
  swap -l | tail +2 | $awk '
    {
      printf("    %-32s %7.1f MiB (%3.1f%% used)\n",
             $1,$4/2048,($4-$5)/$4*100)
    }'


  #----------------------------------------
  # Report swap space definition and usage
  #----------------------------------------
  $echo "  Current virtual memory status:"
  swap -s | tr '[\:\+\=\,k]' '[     ]' | $awk '
    {
      printf("    Total:       %7.1f MiB\n",($7+$9)/1024)
      printf("    Used:        %7.1f MiB (%4.1f%%)\n",$7/1024,$7/($7+$9)*100)
      printf("      Allocated: %7.1f MiB (%4.1f%%)\n",$2/1024,$2/($7+$9)*100)
      printf("      Reserved:  %7.1f MiB (%4.1f%%)\n",$5/1024,$5/($7+$9)*100)
    }'


  #---------------------------
  # List graphics controllers
  #---------------------------
  if [ `ls /dev/fbs/* 2>/dev/null | wc -l` -gt 0 ]; then
    $echo "  Available graphics controller(s) listed in \"/dev/fbs\":"
    for f in `ls /dev/fbs/*[0-9]`; do
      gctr=`basename $f | $awk '{printf("%s\n",substr($0,1,length($0)-1))}'`
      $echo "$gctr $f" | $awk '{printf("      %-10s  (%s",$1,$2)}'
      b=`basename $gctr`
      config=""
      case $b in
        bwtwo)            $echo ", monochrome graphics)" ;;
        cgtwo)            $echo ", color graphics)" ;;
        cgthree)          $echo ", color frame buffer)" ;;
        cgfour)           $echo ", 8-bit color w/overlay)" ;;
        cgsix)            $echo ", 8-bit color)" ;;
        cgeight)          $echo ", 24-bit color w/overlay)" ;;
        cgfourteen)       $echo ", 24-bit color)" ;;
        tcx)              $echo ", S24, TCX/24-bit TrueColor)" ;;
        gfxp)             $echo ", PGX-24)" ;;
        m64)              $echo ", PGX-64)"; config="m64config" ;;
        ffb)              $echo ", Creator / Creator3D)"; config="ffbconfig" ;;
        afb)              $echo ", Elite3D)"; config="afbconfig" ;;
        pfb)              $echo ", XVR-100)"; config="fbconfig" ;;
        ifb)              $echo ", Expert3D / Expert3D-Lite / XVR-500)";
                          config="ifbconfig" ;;
        gfb)              $echo ", XVR-1000)"; config="gfbconfig" ;;
        jfb)              $echo ", XVR-600 / XVR-1200)"; config="jfbconfig" ;;
        zulu)             $echo ", XVR-4000)" ;;
        *)                $echo ")" ;;
      esac
      if [ "$config" != fbconfig -a "$config" != "" -a \
	   `which "$config" 2>&1 | grep -ic "no $config in"` -ne 0 ]; then
        config=fbconfig
      fi
      if [ "$config" != "" -a \
           `which "$config" 2>&1 | grep -ic "no $config in"` -ne 0 ]; then
        config=""
      fi
      if [ "$config" != "" ]; then
        res=`$echo yes | $config -prconf 2>&1 | grep 'Current resolution' | \
                  head -1 | $awk '{print $NF}'`
        if [ "$res" != "" -a "$res" != "0x0x0" ]; then
          freq=`$echo $res | $awk -F x '{print $NF}'`
          res=`$echo $res | $awk -F x '{printf("%s x %s\n",$1,$2)}'`
          $echo "                    Resolution:  $res Pixels @ $freq Hz"
        fi
        depth=`$echo yes | $config -prconf 2>&1 | grep 'Current depth' | \
                  head -1 | $awk '{print $NF}'`
        if [ "x$depth" != x -a "x$depth" != "x0" ]; then
          $echo "                    Color depth: $depth bits"
        fi
      fi
    done
  fi

elif [ "$os" = Darwin ]; then

  $echo "System Hardware Configuration:"
  $echo "---------------------------------------\c"
  $echo "----------------------------------------"
  $echo "   (not implemented)"

fi


#==============================================================================
# REPORT OPERATING SYSTEM INFORMATION
#==============================================================================


#-------------------
# report OS version
#-------------------

$echo
if [ "$os" = SunOS ]; then
  $echo "Solaris Version / Configuration:"
  $echo "---------------------------------------\c"
  $echo "----------------------------------------"

  osv=`uname -r`
  kernel="`uname -s` $osv `uname -v`"
  case $osv in
    "5.3")   sol="2.3"; solnum=230 ;;
    "5.4")   sol="2.4"; solnum=240 ;;
    "5.5")   sol="2.5"; solnum=250 ;;
    "5.5.1") sol="2.5.1"; solnum=251 ;;
    "5.6")   sol="2.6"; solnum=260 ;;
    "5.7")   sol="7"; solnum=700 ;;
    "5.8")   sol="8"; solnum=800 ;;
    "5.9")   sol="9"; solnum=900 ;;
    "5.10")  sol="10"; solnum=1000 ;;
    "5.11")  sol="11"; solnum=1100 ;;
    "5.12")  sol="12"; solnum=1200 ;;
    *)       solnum=0 ;;
  esac
  if [ "$sol" = "" ]; then
    $echo "  Installed operating system:  $kernel"
    solversion="`uname -s` $osv"
  else
    $echo "  Installed operating system:  Solaris $sol ($kernel)"
    solversion="Solaris $sol"
  fi
  if [ $solnum -ge 700 ]; then
    bit64on=`isainfo -v | grep -ci '64-bit'`
    if [ $bit64on -eq 1 ]; then
      $echo "        64-bit mode enabled"
    else
      $echo "        64-bit mode NOT enabled"
    fi
  fi
elif [ "$os" = Darwin ]; then
  $echo "MacOS X Kernel Version / Configuration:"
  $echo "---------------------------------------\c"
  $echo "----------------------------------------"

  osv=`uname -r`
  ovd=`uname -v | cut -d ' ' -f 5-`
  kernel="`uname -s` $osv $osv"
  $echo "  Installed operating system:  $kernel"
fi


#--------------------------------------------------------------
# check for "make" - warning for End User option only installs
#--------------------------------------------------------------
warn_enduser=0
if [ "$os" = SunOS -a ! -x /usr/ccs/bin/make ]; then
  cat << %
  WARNING: Most likely, only the "End User" option of Solaris has been
           installed; commands such as "seqgen", "psggen", "fixpsg",
           "wtgen", and "cc" (for compiling generic C programs) will
           NOT work!  Suggestion: reinstall Solaris, selecting either
           the "Developer Option" or "Full Release".

%
  warn_enduser=1
fi


#---------------------------------------------------------
# if requested, display list of installed Solaris patches
#---------------------------------------------------------
patched=0
patchdate=""
patches=0
tpatches=0
syspatches=0
bkpatches=0
warn_oldpatch=0
if [ $showpatches -ne 0 -o $showrecomm -ne 0 ]; then
  patches=`showrev -p | grep -vc '[Nn]o patches'`
  if [ $patches -gt 0 ]; then
    patched=1

    #-----------------------------------------------------------------
    # report date & time stamp of most recent installed Solaris patch
    #-----------------------------------------------------------------
    if [ `ls -d /var/sadm/patch/* 2>/dev/null | wc -l` -gt 0 ]; then
      date=`ls -ltrd /var/sadm/patch/* | tail -1`
      lastpatch=`$echo $date | $awk '{printf("%s\n",$NF)}'`
      lastpatch=`basename $lastpatch`
      day=`$echo $date | $awk '{printf("%s\n",$7)}'`
      if [ $day -lt 10 ]; then
        day="0$day"
      fi
      month=`$echo $date | $awk '{printf("%s\n",$6)}'`
      case $month in
        Jan) month=01 ;;
        Feb) month=02 ;;
        Mar) month=03 ;;
        Apr) month=04 ;;
        May) month=05 ;;
        Jun) month=06 ;;
        Jul) month=07 ;;
        Aug) month=08 ;;
        Sep) month=09 ;;
        Oct) month=10 ;;
        Nov) month=11 ;;
        Dec) month=12 ;;
      esac
      curday=`date '+%d'`
      curmonth=`date '+%m'`
      year=`date '+%Y'`
      curyear=$year
      time=`$echo $date | $awk '{printf("%s\n",$8)}'`
      if [ `$echo $time | grep -c ':'` -gt 0 ]; then
        if [ $month -gt $curmonth -o \
             \( $month -eq $curmonth -a $day -gt $curday \) ]; then
          year=`expr $year - 1`
        fi
        patchdate="$year-$month-$day $time"
      else
        year=$time
        patchdate="$year-$month-$day"
      fi
      ydiff=`expr $curyear - $year`
      mdiff=`expr $curmonth - $month`
      if [ \( $ydiff -gt 1 -o \( $mdiff -gt 0 -a $ydiff -gt 0 \) \) -a \
           "$sol" != "" ]; then
        warn_oldpatch=1
      fi
    fi
  fi
fi

if [ $showpatches -ne 0 ]; then
  if [ $patches -gt 0 ]; then
    #--------------------------------------------------------------------
    # NAWK script displays numerically sorted list of installed Solaris
    # patches, suppressing patches that are superseded by newer versions
    #--------------------------------------------------------------------
    showrev -p | cut -f 2 -d ' ' | sort -bdf | $awk 'BEGIN {
        lastid = ""
        lastpatch = ""
      }
      {
        # extract basic patch name
        patchid = substr($1,1,6)
        # suppress older versions if multiple versions installed
        if ((patchid != lastid) && (lastid != ""))
        {
          printf("%s\n",lastpatch)
        }
        lastid = patchid
        lastpatch = $1
      }
      END {
        printf("%s\n",lastpatch)
      }' > $patchtmp

    #--------------------------------------------------------------------
    # Mark patches without backout directory in /var/sadm/patch with '*'
    #--------------------------------------------------------------------
    bkpatches=0
    rm -f ${patchtmp}.1
    for f in `cat $patchtmp`; do
      $echo "$f\c" >> ${patchtmp}.1
      if [ -d /var/sadm/patch/$f ]; then
        bkpatches=`expr $bkpatches + 1`
        $echo >> ${patchtmp}.1
      else
        $echo '*' >> ${patchtmp}.1
      fi
    done
    mv ${patchtmp}.1 $patchtmp
    tpatches=`wc -l < $patchtmp`
    tpatches=`expr $tpatches + 0`
    syspatches=`expr $tpatches - $bkpatches`

    #---------------------------------------------------------
    # NAWK script, displays list of installed Solaris patches
    #---------------------------------------------------------
    cat $patchtmp | $awk 'BEGIN {
        ix = 0
        lineitems = 7
      }
      {
        patch[ix] = $0
        ix++
      }
      END {
        if (ix > 1)
        {
          printf("    %3d installed Solaris patches detected:\n",ix)
        }
        else
        {
          printf("      1 installed Solaris patch detected:\n")
        }
        rem = ix%lineitems
        if (ix >= lineitems)
        {
          lines = (ix-rem)/lineitems
          if (rem == 0)
          {
            shortlines = 0
          }
          else
          {
            lines++
            shortlines = lines-(ix%lines)
          }
        }
        else
        {
          lines = 1
          shortlines = 1
        }
        for (i=0; i<lines-shortlines; i++)
        {
          printf(" ")
          for (j=0; j<(lineitems-1); j++)
          {
            printf(" %-10s",patch[j*lines+i])
          }
          printf(" %s",patch[j*lines+i])
          printf("\n")
        }
        if (ix > lineitems)
        {
          for (i=lines-shortlines; i<lines; i++)
          {
            printf(" ")
            for (j=0; j<(lineitems-2); j++)
            {
              printf(" %-10s",patch[j*lines+i])
            }
            printf(" %s",patch[j*lines+i])
            printf("\n")
          }
        }
        else
        {
          printf(" ")
          for (j=0; j<(ix-1); j++)
          {
            printf(" %-10s",patch[j])
          }
          printf(" %s",patch[j])
          printf("\n")
        }
      }'

    #-----------------------------------------------------------------
    # report date & time stamp of most recent installed Solaris patch
    #-----------------------------------------------------------------
    if [ `ls -d /var/sadm/patch/* 2>/dev/null | wc -l` -gt 0 ]; then
      $echo "    Most recent patch installation ($lastpatch) on $patchdate"
    fi

    tp=$tpatches
    sp=$syspatches
    if [ $syspatches -gt 0 ]; then
      if [ $bkpatches -eq 0 ]; then
        cat  << %
    ALL $tp installed patches were either loaded as integral part of the
      Solaris installation, or they were added using the "-nosave" option
      and can therefore NOT BE BACKED OUT in the case of problems.
%
      else
        cat  << %
    Out of $tp installed patches, $sp (marked with "*" above) were either
      loaded as integral part of the Solaris installation, or they were
      added using the "-nosave" option and can therefore NOT BE BACKED OUT
      in the case of problems.
%
      fi
    fi

    if [ `ls -d /var/sadm/patch/* 2>/dev/null | wc -l` -gt 0 ]; then
      if [ $warn_oldpatch -gt 0 ]; then
        $echo "    WE RECOMMEND INSTALLING THE CURRENT SOLARIS PATCH CLUSTER!"
        $echo "    SOLARIS $sol PATCH CLUSTERS CAN BE DOWNLOADED FROM"
        $echo "                http://www.oracle.com/"
      fi
    fi

  elif [ "$sol" != "" ]; then
    $echo "    NO SOLARIS PATCHES INSTALLED - WE RECOMMEND DOWNLOADING"
    $echo "    AND INSTALLING THE CURRENT SOLARIS $sol PATCH CLUSTER FROM"
    $echo "                http://www.oracle.com/"
  fi
fi


#----------------------------------------------
# Show selected language / locale settings
#----------------------------------------------

if [ `which locale | wc -w` -eq 1 ]; then
  lang=""
  nvals=`locale | grep -v '=$' | $awk -F = '{print $2}' | sort -u | wc -l`
  if [ $nvals -gt 1 ]; then
    $echo "  Language / locale settings:"
    locale | grep -v '=$' | sed 's/"//g' | sort -t = -k 2 | $awk -F = 'BEGIN {
      printf("         Locale value:        Variable name:\n")
      getline
      val=$2
      printf("        %-20s %s",$2,$1)
      len = 29 + length($1)
    }
    {
      if ($2 == val)
      {
        newlen = len + 2 + length($1)
        if (newlen > 78)
        {
          printf(",\n")
          printf("                             %s",$1)
          len = 29 + length($1)
        }
        else
        {
          printf(", %s",$1)
          len = newlen
        }
      }
      else
      {
        printf("\n        %-20s %s",$2,$1)
        val=$2
        len=29+length($1)
      }
    }
    END {
      printf("\n")
    }'
  elif [ $nvals -eq 1 ]; then
    lang=`locale | grep -v '=$' | head -1 | $awk -F = '{print $2}'`
    $echo "  Language / locale setting:  $lang"
  else
    $echo "  Could not determine language / locale settings."
  fi
fi


#----------------------------------------------
# Show when system was last rebooted
#----------------------------------------------

lastboot=`last | grep '^reboot ' | head -1`
if [ "$lastboot" != "" ]; then
  $echo "  Last system reboot:  \c"
  bw=`$echo $lastboot | $awk '{print $(NF-3)}'`
  bt=`$echo $lastboot | $awk '{print $NF}'`
  bd=`$echo $lastboot | $awk '{printf("%02d\n",$(NF-1))}'`
  bm=`$echo $lastboot | $awk '{print $(NF-2)}'`
  by=`date '+%Y'`
  cm=`date '+%m'`
  case $bm in
    Jan) bm="01" ;;
    Feb) bm="02" ;;
    Mar) bm="03" ;;
    Apr) bm="04" ;;
    May) bm="05" ;;
    Jun) bm="06" ;;
    Jul) bm="07" ;;
    Aug) bm="08" ;;
    Sep) bm="09" ;;
    Oct) bm="10" ;;
    Nov) bm="11" ;;
    Dec) bm="12" ;;
  esac
  if [ $bm -gt $cm ]; then
    by=`expr $by - 1`
  fi
  $echo "$by-$bm-$bd $bt \c"
  case $bw in
    Sun) $echo "(Sunday)" ;;
    Mon) $echo "(Monday)" ;;
    Tue) $echo "(Tuesday)" ;;
    Wed) $echo "(Wednesday)" ;;
    Thu) $echo "(Thursday)" ;;
    Fri) $echo "(Friday)" ;;
    Sat) $echo "(Saturday)" ;;
    *)   $echo "($bw)" ;;
  esac
fi



#==============================================================================
# SHOW JAVA VERSION INFORMATION
#==============================================================================

if [ $showrevs -ne 0 ]; then
  activejava=`which java 2>/dev/null`
  if [ "$activejava" = "" ]; then
    $echo "  Java environment (JRE or JSE) not installed."
  else
    $echo "  Java version information:"
    $echo "    Active Java environment: $activejava"
    java -version 2>&1 | sed 's/^/      /'
  fi
  if [ -x /usr/java/bin/java -a "$activejava" = /vnmr/jre/bin/java ]; then
    $echo "    Java environment installed as part of \c"
    if [ "$sol" = "" ]; then
      $echo "$os:"
    else
      $echo "Solaris $sol:"
    fi
    /usr/java/bin/java -version 2>&1 | sed 's/^/      /'
  fi
  if [ warn_enduser -eq 0 -a `which cc | grep -vc '^no '` -ne 0 ]; then
    cc_version=`cc -v 2>&1 | grep 'gcc version'`
    if [ "$cc_version" != "" ]; then
      $echo "  Active C compiler version:  $cc_version"
    fi
  fi
fi



#==============================================================================
# PRINT LOCAL SECURITY INFORMATION
#==============================================================================

h_access_man=0
if [ $showsecurity -ne 0 ]; then
  if [  `man -s 5 hosts_access 2> /dev/null | wc -l` -gt 2 ]; then
    h_access_man=1
  fi

  #------------------------------------------
  # Check if "setacq" was run on this system
  #------------------------------------------
  setacq=0
  if [ -h /etc/rc3.d/S19rc.vnmr -o -f /etc/rc3.d/S19rc.vnmr ]; then
    setacq=1
  fi
  $echo "  Local security information (may not be relevant behind a firewall):"

  #----------------------------------------
  # Check for TCP Wrapper (Solaris 9 only)
  #----------------------------------------
  if [ $solnum -ge 900 ]; then
    inetdef=/etc/default/inetd
    if [ -f $inetdef ]; then
      tcp_wrap=`grep -c '^ENABLE_TCPWRAPPERS=YES[ ]*$' < $inetdef`
      wrapline=`grep ENABLE_TCPWRAPPERS= < $inetdef`
    else
      tcp_wrap=0
    fi
    if [ $tcp_wrap -eq 0 ]; then
      n_wrapwarn=`expr $n_wrapwarn + 1`
      if [ "$wrapline" = "" ]; then
        cat << %
    WE STRONGLY RECOMMEND USING TCP WRAPPING; to activate, change
    the line
            $wrapline
    in the file $inetdef to
            ENABLE_TCPWRAPPERS=YES
    then re-initiate "inetd" with
            pkill -HUP inetd
    For information on setting up the TCP denial and access lists
%
        if [ $h_access_man -ne 0 ]; then
          cat << %
    ("/etc/hosts.deny" and "/etc/hosts.allow") see
            man -s 5 hosts_access
    or Agilent MR News 2004-04-19.
%
        else
          cat << %
    ("/etc/hosts.deny" & "/etc/hosts.allow") see Agilent MR News 2004-04-19."
%
        fi
      elif [ $h_access_man -ne 0 ]; then
        cat << %
    WE STRONGLY RECOMMEND USING TCP WRAPPING; for information see
    Agilent MR News 2004-04-19 or
            man -s 5 hosts_access
%
      else
        cat << %
    WE STRONGLY RECOMMEND USING TCP WRAPPING; for information see
    Agilent MR News 2004-04-19
%
      fi
    else
      $echo "    TCP Wrapping activated;"
      if [ -s /etc/hosts.deny ]; then
        $echo "      TCP DENIAL LIST as per \"/etc/hosts.deny\":"
        cat /etc/hosts.deny | sed 's/^/        /'
      else
        n_wrapwarn=`expr $n_wrapwarn + 1`
        cat << %
      WARNING: TCP denial list NOT SET UP; we recommend
      setting up "/etc/hosts.deny" with a single line
                ALL: ALL
%
        if [ $h_access_man -ne 0 ]; then
          cat << %
      See Agilent MR News 2004-04-19 for information, or
                man -s 5 hosts_access
%
        else
          $echo "      See Agilent MR News 2004-04-19 for information."
        fi
      fi
      if [ -s /etc/hosts.allow ]; then
        $echo "      TCP ACCESS LIST as per \"/etc/hosts.allow\":"
        cat /etc/hosts.allow | sed 's/^/        /'
      else
        cat << %
      TCP ACCESS LIST NOT FOUND; for information on setting up
%
        if [ $h_access_man -ne 0 ]; then
          cat << %
      "/etc/hosts.allow" see Agilent MR News 2004-04-19, or
                man -s 5 hosts_access
%
        else
          $echo "      \"/etc/hosts.allow\" see Agilent MR News 2004-04-19."
        fi
      fi
    fi
  fi

  #----------------------------
  # Info about /etc/inetd.conf
  #----------------------------
  $echo "    Internet services / ports as defined per \"/etc/inetd.conf\":"
  if [ $setacq -ne 0 ]; then
    n_inetd=`grep -v '^[ ]*#[# ]*' < /etc/inetd.conf | grep -cv '^[ ]*tftp'`
    $echo $n_inetd | $awk '{printf("      ACTIVE:      %3d services",$1)}'
    $echo " (excluding \"tftp\")"
  else
    n_inetd=`grep -cv '^[ ]*#[# ]*' < /etc/inetd.conf`
    $echo $n_inetd | $awk '{printf("      ACTIVE:      %3d services\n",$1)}'
  fi
  not_inetd=`cat /etc/inetd.conf | \
      $awk '{if ((($4 == "wait") || ($4 == "nowait")) && (NF >= 6)) print}' | \
      grep -v '@(#)' | grep -c '^#'`
  if [ $not_inetd -gt 0 ]; then
    $echo $not_inetd | $awk '{printf("      Deactivated: %3d services\n",$1)}'
  fi
  if [ `grep -v '^[ ]*#' < /etc/inetd.conf | grep -c 'sadmind[ ]*$'` -gt 0 ]
  then
    sec_sadmind=1
    if [ `uname -r` = "5.9" ]; then
      if [ `showrev -p|grep -c '116453-[0-9]'` -gt 0 ]; then
        sec_sadmind=0
      fi
    elif [ `uname -r` = "5.8" ]; then
      if [ `showrev -p|grep -c '116455-[0-9]'` -gt 0 ]; then
        sec_sadmind=0
      fi
    elif [ `uname -r` = "5.7" ]; then
      if [ `showrev -p|grep -c '116456-[0-9]'` -gt 0 ]; then
        sec_sadmind=0
      fi
    fi
    if [ $sec_sadmind -ne 0 ]; then
      sadmline=`grep -nv '^[ ]*#' < /etc/inetd.conf | grep -w sadmind | \
        tr ':' ' ' | $awk '{print $1}'`
      cat << %
    ATTENTION: "/etc/inetd.conf" has "sadmind" (line $sadmline) activated.
        This service has a known security hole; WE STRONGLY RECOMMEND
        DEACTIVATING IT by commenting out line $sadmline in "/etc/inetd.conf".
%
    fi
  fi

  #--------------------------
  # Info about /etc/services
  #--------------------------
  $echo "    Internet services / ports as defined per \"/etc/services\":"
  if [ $setacq -ne 0 ]; then
    n_servc=`grep -v '^[ ]*#[# ]*' </etc/services|egrep -cv '^bootps|^bootpc'`
    $echo $n_servc | $awk '{printf("      ACTIVE:      %3d services",$1)}'
    $echo " (excluding \"bootps\" / \"bootpc\")"
  else
    n_servc=`grep -cv '^[ ]*#[# ]*' </etc/services`
    $echo $n_servc | $awk '{printf("      ACTIVE:      %3d services\n",$1)}'
  fi
  not_servc=`grep '^[ ]*#' </etc/services | grep -v '@(#)' | grep -c '[0-9]/'`
  if [ $not_servc -gt 0 ]; then
    $echo $not_servc | $awk '{printf("      Deactivated: %3d services\n",$1)}'
  fi
  if [ $setacq -ne 0 ]; then
    $echo "      (the above exclusions are required for the acquisition)"
  fi

  #-----------------------------
  # Info about /etc/hosts.equiv
  #-----------------------------
  if [ -r /etc/hosts.equiv ]; then
    if [ `cat /etc/hosts.equiv | grep -c '^+[ ]*$'` -ne 0 ]; then
      $echo "    ALL HOSTS TRUSTED VIA \"/etc/hosts.equiv\" - \c"
      $echo "this is HIGHLY INSECURE!"
      open_hostequiv=1
    elif [ $setacq -ne 0 ]; then
      cat /etc/hosts.equiv | egrep -v "^$host$|^localhost$|^#" | \
        egrep -v '^gemcon$|^inova$|^inovaauto$|^wormhole$' | egrep -v \
          '^master1$|^rf[1-8]$|^pfg[1-3]$|^grad[1-3]$|^lock[1-3]$|ddr[1-8]$' |\
        $awk '{if (NF>0) print}' > ${tmp}.hostequiv
      if [ `wc -l < ${tmp}.hostequiv` -gt 0 ]; then
        $echo "    Trusted host entries per \"/etc/hosts.equiv\""
        $echo "      not including hosts required for acquisition:"
        cat ${tmp}.hostequiv | sed 's/^/        /'
      else
        $echo "    No trusted host entries per \"/etc/hosts.equiv\""
        $echo "      other than those required for acquisition."
      fi
      rm -f ${tmp}.hostequiv
    elif [ `egrep -cv "^#|^$host$|^localhost$" </etc/hosts.equiv` -gt 0 ]; then
      $echo "    Trusted hosts per \"/etc/hosts.equiv\":"
      egrep -v "^#|^$host$|^localhost$" < /etc/hosts.equiv | \
        $awk '{if (NF>0) print}' | sed 's/^/        /'
    else
      $echo "    \"/etc/hosts.equiv\" lists no trusted hosts (secure setting)"
    fi
  else
    $echo "    \"/etc/hosts.equiv\" not present - \c"
    $echo "no trusted hosts (secure setting)"
  fi

  #-----------------------------------
  # report SSH version and activities
  #-----------------------------------
  if [ `which ssh 2>/dev/null | grep -c '^/'` -gt 0 ]; then
    if [ $showrevs -ne 0 ]; then
      $echo "    SSH Version and Activities:"
      sshrev=`ssh -V 2>&1 >/dev/null`
      $echo "      Version:  $sshrev"
    else
      $echo "    SSH Activities:"
    fi
    nsshd=`ps -ec | grep -c sshd`
    nssha=`ps -ec | grep -c ssh-agent`
    if [ $nsshd -gt 1 ]; then
      $echo "      $nsshd instances of \"sshd\" running"
    elif [ $nsshd -eq 1 ]; then
      $echo "      $nsshd instance  of \"sshd\" running"
    else
      $echo "      \"sshd\" currently not used / active"
    fi
    if [ $nssha -gt 1 ]; then
      $echo "      $nssha instances of \"ssh-agent\" running"
    elif [ $nssha -eq 1 ]; then
      $echo "      1 instance  of \"ssh-agent\" running"
    fi
  fi

  #------------------
  # check "sendmail"
  #------------------
  if [ `ps -ef | grep 'sendmail [ ]*-bd' | grep -vc grep` -eq 1 ]; then
    $echo "    \"sendmail\" is listening to incoming connections"
    if [ $showrevs -ne 0 ]; then
      smrev=`cat /etc/mail/sendmail.cf | grep '^DZ' | sed 's/DZ//'`
      $echo "      sendmail version:  $smrev"
      mailhost=`grep '^DSsmtp:' < /etc/mail/sendmail.cf | sed 's/^DSsmtp://'`
      if [ "$mailhost" != "" ]; then
        if [ `expand /etc/hosts | sed 's/#.*$//' | \
	  	egrep -c " $mailhost\$| $mailhost "` -gt 0 ]; then
          ipmailh=`expand /etc/hosts | sed 's/#.*$//' | \
		egrep " $mailhost\$| $mailhost " | $awk '{print $1}' | head -1`
          if [ "$ipmailh" != "" ]; then
            $echo "      uses system \"$mailhost\" ($ipmailh)\c"
          else
            $echo "      uses system \"$mailhost\"\c"
          fi
          $echo " as SMTP relay for outgoing mail"
        fi
      fi
    fi
  fi

  #----------------------
  # Check for "/.rhosts"
  #----------------------
  if [ -f /.rhosts ]; then
    if [ -r /.rhosts -a -s /.rhosts ]; then
      if [ `grep -v '^-' /.rhosts | wc -w` -gt 0 ]; then
        $echo "    ATTENTION: using \"/.rhosts\" to allow for remote root"
        $echo "               logins creates a serious security risk!"
      fi
    else
      $echo "    ATTENTION: we STRONGLY recommend NOT defining \"/.rhosts\""
    fi
  fi

  #--------------------
  # Check XDMCP access
  #--------------------
  xdmcpconfig=/usr/dt/config/Xaccess
  if [ -f /etc/dt/config/Xaccess ]; then
    xdmcpconfig=/etc/dt/config/Xaccess
  fi
  if [ -r $xdmcpconfig ]; then
    if [ `grep -c '^[ ]*\*[     ]*$' < $xdmcpconfig` -gt 0 -o \
         `grep -c '^[ ]*\*[     ]*#' < $xdmcpconfig` -gt 0 ]; then
      open_xdmcp=1
      $echo "    System is open for remote CDE (XDMCP) logins from any host"
    fi
    if [ `grep -c '^[ ]*\*[     ]*CHOOSER [ ]*BROADCAST[        ]*$' < $xdmcpconfig` -gt 0 -o \
         `grep -c '^[ ]*\*[     ]*CHOOSER [ ]*BROADCAST[        ]*#' < $xdmcpconfig` -gt 0 ]
    then
      bcast_xdmcp=1
      if [ $open_xdmcp -ne 0 ]; then
        $echo "      host name shown on the XDMCP chooser list of any host"
      else
        $echo "    Host name shown on ANY remote CDE login (XDMCP) chooser list"
      fi
    fi
    if [ $open_xdmcp -ne 0 -o $bcast_xdmcp -ne 0 ]; then
      $echo "      active configuration file: $xdmcpconfig"
      $echo "      (see Agilent MR News 2002-06-03 for more information)"
    fi
  fi

  #--------------------------------
  # REMOTE ACCESS STATISTICS
  #--------------------------------
  # local host name
  lh=`uname -n`

  # determine relevant accounting file
  if [ -f /var/adm/wtmpx ]; then
    wtmp=/var/adm/wtmpx
  else
    wtmp=/var/adm/wtmp
  fi

  #------------------------------------------------
  # Generate access statistics from "last" output
  #------------------------------------------------
  accesses=`last | $awk '{
        if (($3 != ":0") && ($3 != ":0.0") && ($2 != "console") &&
            ($1 != "reboot") && (NF > 0)) print }' | wc -l`
  if [ $accesses -gt 2 ]; then
    if [ $solnum -lt 800 ]; then
      $echo "  Remote Access Statistics not available for Solaris 7 and older"
    else
      $echo "  Remote Access Statistics, as per \"last\", i.e., \"$wtmp\":"
      $echo "     User     Type    #  Last access       Remote Host"
      year=`date '+%Y'`
      month=`date '+%b'`
      last -a | egrep -v '^reboot |^wtmp begins ' | $awk '
      BEGIN {
        cyear='$year'
        cmonth="'$month'"
      }
      {
        if ((NF > 9) && ($NF != ":0") && ($NF != ":0.0") &&
            ($NF != "localhost") && ($NF != "'$lh'"))
        {
          if (((cmonth != "Dec") && (cmonth != "Nov") && (cmonth != "Oct")) &&
              (($4 == "Dec") || ($4 == "Nov") || ($4 == "Oct")))
          {
            cyear--
          }
          cmonth=$4
          if (cmonth == "Jan")
            month="01"
          else if (cmonth == "Feb")
            month="02"
          else if (cmonth == "Mar")
            month="03"
          else if (cmonth == "Apr")
            month="04"
          else if (cmonth == "May")
            month="05"
          else if (cmonth == "Jun")
            month="06"
          else if (cmonth == "Jul")
            month="07"
          else if (cmonth == "Aug")
            month="08"
          else if (cmonth == "Sep")
            month="09"
          else if (cmonth == "Oct")
            month="10"
          else if (cmonth == "Nov")
            month="11"
          else if (cmonth == "Dec")
            month="12"
          else
            month=cmonth
          if ($2 ~ /^pts\//)
            type="pts"
          else
            type=$2
          printf("%s %s %s",$1,$NF,type)
          printf(" %d-%s-%02d %s\n",cyear,month,$5,$6)
        }
      }' | sort -df | $awk 'BEGIN {
        getline
        lastuser=$1
        lasttype=$3
        #if (lasttype == "pts")
        #  lasttype=""
        lasthost=$2
        lastdate=$4
        lasttime=$5
        count=1
      }
      {
        if (NF > 0)
        {
          user=$1
          type=$3
          #if (type == "pts")
          #   type=""
          host=$2
          if ((user == lastuser) && (type == lasttype) && (host == lasthost))
          {
            lastdate=$4
            lasttime=$5
            count++
          }
          else
          {
            printf("    %-9s",lastuser)
            printf(" %-5s %3d",lasttype,count)
            printf(" %s %s",lastdate,lasttime)
            printf("  %s\n",lasthost)
            lastuser=user
            lasttype=type
            lasthost=host
            lastdate=$4
            lasttime=$5
            count=1
          }
        }
      }
      END {
        printf("    %-9s",lastuser)
        printf(" %-5s %3d",lasttype,count)
        printf(" %s %s",lastdate,lasttime)
        printf("  %s\n",lasthost)
      }' | sort +3
    fi


    #------------------------------------
    # Report start of accounting period
    #------------------------------------
    accstart=`last | tail -1`
    startm=`$echo $accstart | $awk '{print $4}'`
    case $startm in
        Jan) startm=01 ;;
        Feb) startm=02 ;;
        Mar) startm=03 ;;
        Apr) startm=04 ;;
        May) startm=05 ;;
        Jun) startm=06 ;;
        Jul) startm=07 ;;
        Aug) startm=08 ;;
        Sep) startm=09 ;;
        Oct) startm=10 ;;
        Nov) startm=11 ;;
        Dec) startm=12 ;;
    esac
    startd=`$echo $accstart | $awk '{print $5}'`
    if [ $startd -lt 10 ]; then
      startd=0$startd
    fi
    startt=`$echo $accstart | $awk '{print $6}'`
    starty=`date '+%Y'`
    curmon=`date +%b`
    starty=`last | expand | cut -c 41-100 | sort -mu +1 -2 | \
    $awk 'BEGIN {
      starty='$starty'
      cmon="'$curmon'"
      getline
      if (($2 == "Dec") && (cmon != "Dec"))
        starty--
    }
    {
      if ($2 == "Dec")
        starty--
    }
    END { print starty }'`
    accstart="$starty-$startm-$startd $startt"
    $echo "  Accounting started on  $accstart"

    #----------------------------------------------------
    # Report number of reboots during accounting period
    #----------------------------------------------------
    reboots=`last | grep -c '^reboot'`
    if [ $reboots -gt 1 ]; then
      $echo "  The system was rebooted $reboots times since $accstart"
    elif [ $reboots -eq 1 ]; then
      $echo "  The system was last rebooted on $accstart"
    else
      $echo "  The system was not rebooted during the accounting period."
    fi
  fi
fi



#==============================================================================
# CHECK FOR ACQPROC / EXPPROC
#==============================================================================

acq=0           # flag for acquisition / spectrometer host
acqtype=""      # hal, router, dualnet, net (spectrometer not networked)
if [ `ps -e | egrep -c 'Expproc|Acqproc'` -gt 0 ]; then
  acq=1
fi



#==============================================================================
# REPORT OPERATING SYSTEM INFORMATION
#==============================================================================

if [ -s /etc/dumpdates -a $showdumps -eq 1 ]; then
  $echo
  $echo "Information About File System (ufsdump) Backups:"
  $echo "---------------------------------------\c"
  $echo "----------------------------------------"


  #--------------------------------------------------------------
  # report size and percent usage of defined UFS disk partitions
  #--------------------------------------------------------------
  ufss=`df -k -F ufs | tail +2 | tr '/' ' ' | cut -d ' ' -f 4`
  for f in $ufss; do
    if [ `grep -c $f < /etc/dumpdates` -gt 0 ]; then
      mount=`df -k -F ufs | grep $f | $awk '{print $NF}'`
      $echo "  /dev/rdsk/$f (mounted as $mount)":
      grep $f < /etc/dumpdates | $awk 'BEGIN {dumps=0}
      {
        if ($4 == "Jan") mo="01"
        else if ($4 == "Feb") mo="02"
        else if ($4 == "Mar") mo="03"
        else if ($4 == "Apr") mo="04"
        else if ($4 == "May") mo="05"
        else if ($4 == "Jun") mo="06"
        else if ($4 == "Jul") mo="07"
        else if ($4 == "Aug") mo="08"
        else if ($4 == "Sep") mo="09"
        else if ($4 == "Oct") mo="10"
        else if ($4 == "Nov") mo="11"
        else if ($4 == "Dec") mo="12"
        else mo=$4
        printf("        last level %d dump: ",$2)
        printf(" %s, %d-%s-%02d %s\n",$3,$NF,mo,$5,$6)
        dumps++
      }
      END {
        if (dumps == 0)
        {
          printf("        NO UFS (ufsdump) DUMPS LOGGED\n")
        }
      }'
    else
      mount=`df -k -F ufs | grep $f | $awk '{print $NF}'`
      $echo "  /dev/rdsk/$f (mounted as $mount)":
      $echo "        NO UFS (ufsdump) DUMPS LOGGED"
    fi
  done
fi



#==============================================================================
# REPORT VnmrJ / VNMR VERSION INFORMATION
#==============================================================================

$echo
$echo "VnmrJ / VNMR Version / Configuration:"
$echo "---------------------------------------\c"
$echo "----------------------------------------"


#------------------------------------------------------------------
# if /vnmr/vnmrrev is found, report installed VnmrJ / VNMR version
#------------------------------------------------------------------
warn_vpatch=0
warn_gnuc=0
sol9=1
hal=0
vnmrj=1
vjlx=0
vjsec=0
spincad=0
vnmropt=none
blade=1
vnmr=0
lastvpatch=""
if [ -f $vnmrsystem/vnmrrev ]; then
  vnmr=1
  $echo "  Active version of VnmrJ / VNMR:"
  vjlx=`head -1 $vnmrsystem/vnmrrev | egrep -ic 'vnmrj_lx'`
  vjsec=`head -1 $vnmrsystem/vnmrrev | egrep -ic 'trusted|secure|21.*cfr'`
  vnmrrev=`head -1 $vnmrsystem/vnmrrev | sed 's/VERSION //
    s/VNMRJ/VnmrJ/
    s/VJ1 /VnmrJ 1.1 /
    s/ REVISION //
    s/Trusted_VnmrJ/VnmrJ_Secure/
    s/VNMR [ ]*VnmrJ/VnmrJ/'`
  vnmrbeta=`head -1 $vnmrsystem/vnmrrev | egrep -ic 'alpha|beta'`
  if [ `$echo $vnmrrev | grep -ic vnmr` -eq 0 ]; then
    vnmrrev="VNMR $vnmrrev"
  fi
  vnmrrevdate=`head -2 $vnmrsystem/vnmrrev | tail -1`
  vnmropt=`tail -1 $vnmrsystem/vnmrrev | tr '[A-Z]' '[a-z]'`
  sol9=1
  case $vnmropt in
    vnmrs)              system="DirectDrive" ;;
    inova|inova.sol)    system="UNITY INOVA"; spincad=1 ;;
    uplus)              system="UNITYplus"; hal=1 ;;
    unity)              system="UNITY"; hal=1 ;;
    vxrs|vxr-s)         system="VXR-S"; hal=1 ;;
    mercplus|mplus)     system="MERCURYplus"; vnmrj=2 ;;
    mercvx)             system="MERCURY-Vx"; vnmrj=2 ;;
    mercury)            system="MERCURY"; sol9=0; vnmrj=0 ;;
    g2000)              system="GEMINI 2000"; sol9=0; vnmrj=0 ;;
    *)                  system=$vnmropt ;;
  esac
  if [ `$echo $vnmrrev | grep -ic '2\.1a'` -ne 0 ]; then
    system="DirectDrive"
  fi
  if [ "$system" = DirectDrive ]; then
    spincad=0
  fi
  if [ $hal -ne 0 ]; then
    vnmrj=0
    blade=0
  fi
  if [ $vnmrj -eq 2 ]; then
    cur_vnmrj=$m_cur_vnmrj
  fi
  $echo "        $vnmrrev ($vnmrrevdate)"
  if [ "$system" != "$vnmropt" ]; then
    $echo "        Installed version \"$vnmropt\" for $system architecture"
  else
    $echo "        Installed version \"$vnmropt\""
  fi
  cd /vnmr
  inst_path=`pwd`
  cd $wd
  $echo "        Installation path:  $inst_path"
  if [ $hal -ne 0 ]; then
    if [ $bit64on -eq 1 ]; then
      if [ `$echo $wstype | grep -ci Blade` -gt 0 ]; then
        cat << %
  WARNING: The installed VNMR version is for HAL-based systems, but this
    is a Blade workstation which always runs with the 64-bit mode turned
    on. You will NOT be able to use this workstation as host computer for
    a $system spectrometer!

%
      else
        cat << %
  WARNING: The installed VNMR version is for HAL-based systems, but Solaris
    is installed with the 64-bit mode turned on - you will NOT be able to use
    this workstation as host computer for a $system spectrometer unless
    you disable the 64-bit mode:
     - check whether you have a file "/platform/sun4u/kernel/unix";
     - if this file is missing you need to REINSTALL Solaris in 32-bit mode
     - if this file is present, run the system down to monitor mode, using
       "init 0"; then, at the "ok" prompt, type
                setenv boot-file kernel/unix
       and boot the system. After this, "isainfo -v" should report
                32-bit sparc applications
       ONLY.

%
      fi
    fi
  fi


  #-------------------------------------------------------------------
  # Report installed VnmrJ (VNMR) software options, if possible
  #-------------------------------------------------------------------
  if [ `$echo $vnmrrev | egrep -c '1\.1[B-Z]|1\.[2-9]|[2-9]\.[0-9]'` -gt 0 \
       -a $vnmrj -eq 1 -a -d $vnmrsystem/adm/log ]; then
    $echo "  VnmrJ software components selected at installation:"
    cd $vnmrsystem/adm/log
    if [ `find . \
        -name 'vnmrj2[0-9][0-9][0-9][01][0-9][0-3][0-9]-[012][0-9][0-5][0-9]' \
        -a -type f -a \! -size 0 | wc -l` -ne 0 ]; then
      for f in vnmrj2[0-9][0-9][0-9][01][0-9][0-3][0-9]-[012][0-9][0-5][0-9]; do
        if [ -s $f ]; then
          inst_y=`$echo $f | cut -c 6-9`
          inst_m=`$echo $f | cut -c 10-11`
          inst_d=`$echo $f | cut -c 12-13`
          inst_H=`$echo $f | cut -c 15-16`
          inst_M=`$echo $f | cut -c 17-18`
          $echo "    Installation log dated \c"
          $echo "${inst_y}-${inst_m}-${inst_d} ${inst_H}:${inst_M}"
          $echo "      Standard installation options selected:"
          cat $f | tr '"' ' ' | $awk 'BEGIN {
            option=""
            n_options=0
            ok=1
            kb=0
          }
          {
            if (($0 ~ /GENERIC files/) && ($0 ~ /^Installing/))
            {
              n_options=0
            }
            else if ($0 ~ /PASSWORDED OPTION files/)
            {
              if (option != "")
              {
                if (kb == 0)
                {
                  printf("        %-20s  NOT INSTALLED\n", option)
                }
                else if (ok == 0)
                {
                  printf("        %-20s  %6d KiB / %6.2f MiB",
                         option,kb,kb/1024)
                  printf(", PARTIAL INSTALL\n")
                }
                else
                {
                  printf("        %-20s  %6d KiB / %6.2f MiB\n",
                         option,kb,kb/1024)
                }
                option=""
              }
              else if (n_options == 0)
              {
                printf("        No standard options selected / installed.\n")
              }
              if ($0 ~ /Skipping/)
              {
                printf("      No passworded installation options selected.\n")
                n_options=0
              }
              else
              {
                printf("      Passworded installation options selected:\n")
                n_options=0
              }
            }
            else if ($0 ~ /^  Extracting/)
            {
              if (option == "")
              {
                option=$2
                n_options += 1
                ok=1
                res = getline
                while ((($0 ~ /^Replaced /) || ($0 ~ /^tar: blocksize = 0/))
                       && (res > 0))
                {
                  res = getline
                }
                if ($1 ~ /^DONE/)
                {
                  kb = $2
                }
                else
                {
                  ok=0
                }
              }
              else if (option == $2)
              {
                res = getline
                while ((($0 ~ /^Replaced /) || ($0 ~ /^tar: blocksize = 0/))
                       && (res > 0))
                {
                  res = getline
                }
                if ($1 ~ /^DONE/)
                {
                  kb += $2
                }
                else
                {
                  ok=0
                }
              }
              else
              {
                if (kb == 0)
                {
                  printf("        %-20s  NOT INSTALLED\n", option)
                }
                else if (ok == 0)
                {
                  printf("        %-20s  %6d KiB / %6.2f MiB",
                         option,kb,kb/1024)
                  printf(", PARTIAL INSTALL\n")
                }
                else
                {
                  printf("        %-20s  %6d KiB / %6.2f MiB\n",
                         option,kb,kb/1024)
                }
                option=$2
                n_options += 1
                ok=1
                res = getline
                while ((($0 ~ /^Replaced /) || ($0 ~ /^tar: blocksize = 0/))
                       && (res > 0))
                {
                  res = getline
                }
                if ($1 ~ /^DONE/)
                {
                  kb = $2
                }
                else
                {
                  ok=0
                }
              }
            }
          }
          END {
            if (option != "")
            {
              if (kb == 0)
              {
                printf("        %-20s  NOT INSTALLED\n", option)
              }
              else if (ok == 0)
              {
                printf("        %-20s  %6d KiB / %6.2f MiB",
                       option,kb,kb/1024)
                printf(", PARTIAL INSTALL\n")
              }
              else
              {
                printf("        %-20s  %6d KiB / %6.2f MiB\n",
                       option,kb,kb/1024)
              }
            }
          }'
        fi
      done
    else
      cat << %
        No VnmrJ installation log available in "/vnmr/adm/log";
        installation aborted prematurely or by killing process?
%
    fi
    cd $wd
  fi


  #-------------------------------------------------------------------
  # check for presence of GNU C compiler as part of VNMR installation
  #-------------------------------------------------------------------
  if [ ! -d $vnmrsystem/gnu ]; then
    cat << %
  WARNING: When installing VnmrJ / VNMR, the "GNU C" option was apparently
           NOT selected; commands such as "seqgen", "psggen", "fixpsg",
           "wtgen", and "cc" (for compiling generic C programs) will NOT
           work! Suggestion: insert VnmrJ / VNMR CD-ROM, proceed as if you
           wanted to reinstall the software on top of the current version
           (specify the same install path), but ONLY select the "GNU C"
           option.
%
    warn_gnuc=1
  fi


  #---------------------------------------
  # report installed VnmrJ / VNMR patches
  #---------------------------------------
  pnames=""
  if [ -d $vnmrsystem/adm/patch ]; then
    cd $vnmrsystem/adm/patch
    pnames=`find * -type d -a -prune 2> /dev/null | grep \
'^[0-9]...[a-z][a-z][a-z][A-Z][A-Z][A-Z][a-z][a-z][a-z0-9][c0-9][p0-9][0-9]'`
  fi
  if [ `$echo $pnames | wc -w` -gt 0 ]; then
    $echo "  VnmrJ / VNMR patch history:"
    cd $vnmrsystem/adm/patch
    lastvpatch=""
    $echo "           Date    Time    Patch name"
    for p in `ls -d1tr $pnames`; do
      m=`ls -ld $p | $awk '{print $6}'`
      case $m in
        Jan) month=01 ;;
        Feb) month=02 ;;
        Mar) month=03 ;;
        Apr) month=04 ;;
        May) month=05 ;;
        Jun) month=06 ;;
        Jul) month=07 ;;
        Aug) month=08 ;;
        Sep) month=09 ;;
        Oct) month=10 ;;
        Nov) month=11 ;;
        Dec) month=12 ;;
        *)   month=$m ;;
      esac
      day=`ls -ld $p | $awk '{print $7}'`
      year=`ls -ld $p | $awk '{print $8}'`
      if [ `$echo $year | grep -c ':'` -gt 0 ]; then
        time=$year
        year=`date '+%Y'`
        if [ $month -gt `date '+%m'` ]; then
          year=`expr $year - 1`
        elif [ $month -eq `date '+%m'` -a $day -gt `date '+%d'` ]; then
          year=`expr $year - 1`
        fi
      else
        time=""
      fi
      if [ $day -lt 10 ]; then
        day=0$day
      fi
      $echo "$year-$month-$day $time $p" | $awk '{
        if (NF == 2)
        {
          printf("        %s        %s\n",$1,$NF)
        }
        else if (NF > 2)
        {
          printf("        %s %s  %s\n",$1,$2,$NF)
        }
        else
        {
          printf("                          %s\n",$NF)
        }
      }'
      lastvpatch=$p
    done
  elif [ $vnmrbeta -ne 0 ]; then
    cat << %
  No VnmrJ / VNMR patches installed. You may want to check the Agilent
     "VnmrJ / VNMR Beta Test" Web site at
        http://www.chem.agilent.com/en-US/Support/Pages/default.aspx
     for a possible patch for your beta version of VnmrJ / VNMR!
%
    warn_vpatch=1
  else
    cat << %
  No VnmrJ / VNMR patches installed. You may want to check the Agilent
     "VnmrJ / VNMR Patches" Web site at
        http://www.chem.agilent.com/en-US/Support/Pages/default.aspx
     for a patch for your VnmrJ / VNMR release!
%
    warn_vpatch=1
  fi
  if [ "$system" = "UNITY INOVA" -a $solnum -lt 700 ]; then
    minsolrel="Solaris 7"
  fi
  if [ \( "$system" = "MERCURYplus" -o "$system" = "MERCURY-Vx" \) -a \
          $solnum -lt 260 ]; then
    minsolrel="Solaris 2.6"
  fi
  if [ "$system" = "MERCURY" -o "$system" = "GEMINI 2000" ]; then
    maxsolrel="Solaris 8"
  fi
  if [ "$minsolrel" != "" ]; then
    if [ $vnmrj -ne 0 ]; then
      cat << %
  With the currently installed version of Solaris (Solaris $sol) you
    can NOT upgrade to $cur_vnmr with the latest patch or to VnmrJ;
    you should upgrade to $minsolrel AT LEAST
%
    else
      cat << %
  With the currently installed version of Solaris (Solaris $sol) you
    can NOT upgrade to $cur_vnmr with the latest patch; you should
    upgrade to $minsolrel AT LEAST
%
    fi
    if [ "$maxsolrel" != "" ]; then
      cat << %
  Note: $maxsolrel is the LAST Solaris release that is compatible with
        $system spectrometers; newer Solaris versions CANNOT be used.
%
    fi
  fi
else
  $echo "Link \"/vnmr\" or file \"/vnmr/vnmrrev\" not present -"
  if [ $vnmrj -ne 0 ]; then
    $echo "  VnmrJ / VNMR version not reported."
  else
    $echo "  VNMR version not reported."
  fi
fi
cd $wd

# correct minimum RAM size for VnmrJ
if [ $vnmrj -ne 0 ]; then
  minrammb=$minrammbj
fi
if [ $sol9 -eq 0 ]; then
  recsolnum=800
fi



#==============================================================================
# CHECK FOR INSTALLATION USER LIBRARY CONTRIBUTIONS INTO /vnmr
#==============================================================================

if [ $vnmr -ne 0 ]; then
  if [ -d $vnmrsystem/adm/log/userlib_installs ]; then
    cd $vnmrsystem/adm/log/userlib_installs
    if [ -f 2[0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]_[0-2][0-9]h[0-5][0-9]_* ]
    then
      cat << %
  User library contributions installed in "/vnmr" (may NOT cover
    installations with an older version of "extract"):
           Date    Time    Contribution
%
      for f in 2[0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]_[0-2][0-9]h[0-5][0-9]_*; do
        date=`$echo $f | cut -c 1-16 | tr 'h' ':' | tr '_' ' '`
        item=`$echo $f | cut -c 18-200 | sed 's/-/\//'`
        rep=`$echo $item | $awk -F '.' '{if ($2 ~ /^[0-9]*$/) print $2}'`
        if [ "$rep" != "" ]; then
          rep=`expr $rep + 1`
          item=`$echo $item | sed 's/\.[0-9]*$//'`
          $echo "        $date  $item ($rep)"
        else
          $echo "        $date  $item"
        fi
      done
    fi
  elif [ \( $vnmrj -eq 0 -o `$echo $vnmrrev | egrep -c '1\.1[A-C]'` -ne 0 \) -a \
         ! -d $vnmrsystem/adm/log/userlib_installs -a \
         ! -d $HOME/vnmrsys/userlib_installs ]; then
    cat << %
  If you download and install the current version of "extract" from the
    Agilent On-line User Library at
        http://www.chem.agilent.com/en-US/Support/Pages/default.aspx
    "extract" will log User Library installations, and "$wcmd" will
    report any User Library contributions that are installed in "/vnmr"
    using that new version of "extract".
%
  fi
fi



#==============================================================================
# CHECK FOR INSTALLATION OF MAJOR USER LIBRARY PACKAGES INTO /vnmr
#==============================================================================

mkpr=0
if [ $vnmr -ne 0 ]; then
  majorul=0

  #--------------------------
  # Deal with psglib/BioPack
  #--------------------------
  if [ -s $vnmrsystem/BioPack.dir/BP_rev ]; then
    if [ $majorul -eq 0 ]; then
      $echo "  Major user library contributions installed in \"/vnmr\":"
    fi
    majorul=`expr $majorul + 1`
    $echo "     \"psglib/BioPack\" version information and installation log:"
    cat $vnmrsystem/BioPack.dir/BP_rev | $awk '
    {
      if (NF > 0) {print}
    }' | sed 's/^/        /'
  elif [ -s $vnmrsystem/biopack/BioPack.dir/BP_rev ]; then
    if [ $majorul -eq 0 ]; then
      $echo "  Major user library contributions installed in \"/vnmr\":"
    fi
    majorul=`expr $majorul + 1`
    $echo "     \"psglib/BioPack\" version information and installation log:"
    $echo "        APPDIR installation in \"/vnmr/biopack\""
    cat $vnmrsystem/biopack/BioPack.dir/BP_rev | $awk '
    {
      if (NF > 0) {print}
    }' | sed 's/^/        /'
  fi

  #--------------------------------------
  # Deal with chempack/CP / chempack/CP4
  #--------------------------------------
  if [ -s $vnmrsystem/CP_Readme/CP_Version ]; then
    if [ $majorul -eq 0 ]; then
      $echo "  Major user library contributions installed in \"/vnmr\":"
    fi
    majorul=`expr $majorul + 1`
    $echo "     \"chempack/CP\" version information:"
    cat $vnmrsystem/CP_Readme/CP_Version | $awk '
    {
      if (NF > 0) {print}
    }' | sed 's/^/        /'
  elif [ -s $vnmrsystem/chempack/CP_Readme/CP_Version ]; then
    if [ $majorul -eq 0 ]; then
      $echo "  Major user library contributions installed in \"/vnmr\":"
    fi
    majorul=`expr $majorul + 1`
    $echo "     \"chempack/CP\" version information:"
    $echo "        APPDIR installation in \"/vnmr/chempack\""
    cat $vnmrsystem/chempack/CP_Readme/CP_Version | $awk '
    {
      if (NF > 0) {print}
    }' | sed 's/^/        /'
  fi

  #---------------------------
  # Deal with bin/makePrinter
  #---------------------------
  if [ `which makePrinter | grep -vc '^no makePrinter'` -ne 0 ]; then
    if [ $majorul -eq 0 ]; then
      $echo "  Major user library contributions installed in \"/vnmr\":"
    fi
    majorul=`expr $majorul + 1`
    mkpr=1
    if [ -r /printers/mkprrev ]; then
      $echo "     \"bin/makePrinter\" version information:"
      cat /printers/mkprrev | $awk '{
        if (NF > 0) {print}
      }' | sed 's/^/        /'
    else
      $echo "     \"bin/makePrinter\" is installed"
    fi
  fi
fi



#==============================================================================
# LIST DEFINED VNMR / VnmrJ USERS
#==============================================================================

numusers=0
if [ $vnmr -ne 0 -a $showusers -ne 0 -a -r /etc/group ]; then
  vnmrowner=`ls -ld /vnmr/bin | $awk '{print $3}'`
  if [ `grep -c '^nmr:' < /etc/group` -gt 0 ]; then
    nmrusers=`grep '^nmr:' < /etc/group | $awk -F : '{print $4}' | tr ',' ' '`
    numusers=`$echo $nmrusers | $awk '{print NF}'`
  fi
  if [ $numusers -ne 0 ]; then
    $echo "  VnmrJ / VNMR users (group \"nmr\")\c"
    $echo " as defined in \"/etc/group\":"
  else
    nmrusers=`ypcat group 2>/dev/null | grep '^nmr:' | \
                $awk -F : '{print $4}' | tr ',' ' '`
    numusers=`$echo $nmrusers | $awk '{print NF}'`
    if [ $numusers -ne 0 ]; then
      $echo "  VnmrJ / VNMR users (group \"nmr\")\c"
      $echo " as defined in \"/etc/group\" via NIS/NIS+:"
    fi
  fi
  if [ $numusers -gt 0 ]; then
    $echo "         Name         UID   GID    Shell        HOME"
    for u in $nmrusers; do
      if [ "$u" != acqproc ]; then
        udir=""
        uid=-1
        gid=-1
        ush=""
        uline=`ypcat passwd 2>/dev/null | grep "^$u:"`
        if [ "$uline" != "" ]; then
          uid=`$echo $uline | grep "^$u:" | $awk -F : '{if (NF>2) print $3}'`
          if [ "x$uid" = "x" ]; then
            uid=-1
          fi
          gid=`$echo $uline | grep "^$u:" | $awk -F : '{if (NF>3) print $4}'`
          if [ "x$gid" = "x" ]; then
            gid=-1
          fi
          udir=`$echo $uline | grep "^$u:" | $awk -F : '{if (NF>5) print $6}'`
          ush=`$echo $uline | grep "^$u:" | $awk -F : '{if (NF>6) print $7}'`
        fi
        if [ -r /etc/passwd ]; then
          if [ `grep -c "^$u:" < /etc/passwd` -gt 0 ]; then
            uidl=`grep "^$u:" < /etc/passwd | $awk -F : '{if (NF>2) print $3}'`
            if [ "x$uidl" != "x" -a "x$uidl" != "x+" ]; then
              uid=$uidl
            fi
            gidl=`grep "^$u:" < /etc/passwd | $awk -F : '{if (NF>3) print $4}'`
            if [ "x$gidl" != "x" -a "x$gidl" != "x+" ]; then
              gid=$gidl
            fi
            udirl=`grep "^$u:" < /etc/passwd | $awk -F : '{if (NF>5) print $6}'`
            if [ "x$udirl" != "x+" -a "x$udirl" != "x" ]; then
              udir=$udirl
            fi
            ushl=`grep "^$u:" < /etc/passwd | $awk -F : '{if (NF>6) print $7}'`
            if [ "x$ushl" != "x+" -a "x$ushl" != "x" ]; then
              ush=$ushl
            fi
          fi
        fi
        if [ "$udir" = "" ]; then
          udir=`finger $u | grep '^Directory:' | head -1 | $awk '{print $2}'`
        fi
        $echo $u | $awk '{printf("        %-12s",$1)}'
        info=0
        if [ $uid -ne -1 ]; then
          $echo $uid | $awk '{printf("%5d",$1)}'
          info=1
        else
          $echo "     \c"
        fi
        if [ $gid -ne -1 ]; then
          $echo $gid | $awk '{printf(" %5d",$1)}'
          info=`expr $info + 1`
        else
          $echo "      \c"
        fi
        if [ "x$ush" != x ]; then
          $echo $ush | $awk '{printf("   %-12s",$1)}'
          info=`expr $info + 1`
        else
          $echo "               \c"
        fi
        if [ "$udir" != "" ]; then
          if [ -d $udir/vnmrsys ]; then
            $echo $udir | $awk '{printf(" %s",$1)}'
          fi
          info=`expr $info + 1`
        fi
        if [ $info -eq 0 ]; then
          $echo " no information available."
        else
          $echo ""
        fi
      fi
    done
  else
    $echo "  VnmrJ / VNMR users not listed - entry \"nmr\" in \"/etc/group\""
    $echo "    not readable or not local (NIS / NIS+)"
  fi
  fmt -c -w 79 << %
  NOTE: Users who are NOT (primary or secondary) member of the group "nmr"
    are NOT listed here and should NOT expect to be able to use VnmrJ. As
    $vnmrowner, start "vnmrj adm" and from the "Configure" menu use "Users" ->
    "Update Users" to make VnmrJ usable for these accounts.
%
fi



#==============================================================================
# FILE OWNERSHIP STATISTICS FOR "/vnmr"
#==============================================================================

if [ $numusers -gt 0 ]; then
  cd /vnmr
  cat << %
  Ownership checks for contents of "/vnmr" - this may take a while ...
%
  numvfildir=`find . \! -type l | wc -l`
  numvdir=`find . \! -type l -a -type d | wc -l`
  numvfil=`expr $numvfildir - $numvdir`
  numvsym=`find . -type l | wc -l`
  $echo $numvfildir | $awk '{printf("  %6d",$1)}'
  $echo " Files and directories total, without symbolic links:"
  $echo $numvfil    | $awk '{printf("         %d plain files /",$1)}'
  $echo $numvdir    | $awk '{printf(" %d directories",$1)}'
  $echo $numvsym    | $awk '{printf(" (+ %d symbolic links)\n",$1)}'

  #------------------------------------
  # files and directories with bad GID
  #------------------------------------
  badgid=`find . \! -type l -a \! -group nmr | wc -l`
  if [ $badgid -gt 0 ]; then
    badgiddir=`find . \! -type l -a -type d -a \! -group nmr | wc -l`
    badgidfil=`expr $badgid - $badgiddir`
    if [ $badgidfil -gt 1 ]; then
      $echo $badgidfil  | $awk '{printf("  %6d Plain files",$1)}'
    elif [ $badgidfil -eq 1 ]; then
      $echo $badgidfil  | $awk '{printf("  %6d Plain file",$1)}'
    fi
    if [ $badgiddir -gt 1 ]; then
      if [ $badgidfil -gt 0 ]; then
        $echo " and"
      fi
      $echo $badgiddir  | $awk '{printf("  %6d Directories",$1)}'
    elif [ $badgiddir -eq 1 ]; then
      if [ $badgidfil -gt 0 ]; then
        $echo " and"
      fi
      $echo $badgiddir  | $awk '{printf("  %6d Directory",$1)}'
    fi
    $echo " in \"/vnmr\" NOT owned by the group \"nmr\":"
    $echo "             Perms    Ownership       Size  File"
    ls -ld `find . \! -type l -a \! -group nmr | head -n $vlist` | $awk '
    {
      perm=substr($1,2,9)
      uidgid=sprintf("%s/%s",$3,$4)
      siz=$5
      file=substr($NF,3,length($NF)-2)
      printf("           %s %-12s %8d %s\n",perm,uidgid,siz,file)
    }'
    if [ $badgid -gt $vlist ]; then
      cat << %
               ... (first $vlist files/directories listed only)
         In order to see the complete list use
                find /vnmr/. \! -group nmr
         or
                find /vnmr/. \! -group nmr -exec ls -ld {} \;
%
    fi
  else
    cat << %
    All files and directories in "/vnmr" are owned by the group "nmr"
%
  fi

  #--------------------------------
  # files / directories owned root
  #--------------------------------
  uidroot=`find . \! -type l -a -user root | wc -l`
  if [ $uidroot -gt 0 ]; then
    uidrootdir=`find . \! -type l -a -type d -a -user root | wc -l`
    uidrootfil=`expr $uidroot - $uidrootdir`
    if [ $uidrootfil -gt 1 ]; then
      $echo $uidrootfil  | $awk '{printf("  %6d Plain files",$1)}'
    elif [ $uidrootfil -eq 1 ]; then
      $echo $uidrootfil  | $awk '{printf("  %6d Plain file",$1)}'
    fi
    if [ $uidrootdir -gt 1 ]; then
      if [ $uidrootfil -gt 0 ]; then
        $echo " and"
      fi
      $echo $uidrootdir  | $awk '{printf("  %6d Directories",$1)}'
    elif [ $uidrootdir -eq 1 ]; then
      if [ $uidrootfil -gt 0 ]; then
        $echo " and"
      fi
      $echo $uidrootdir  | $awk '{printf("  %6d Directory",$1)}'
    fi
    $echo " in \"/vnmr\" owned by user ROOT:"
    $echo "             Perms    Ownership       Size  File"
    ls -ld `find . \! -type l -a -user root | head -n $vlist` | $awk '
    {
      perm=substr($1,2,9)
      uidgid=sprintf("%s/%s",$3,$4)
      siz=$5
      file=substr($NF,3,length($NF)-2)
      printf("           %s %-12s %8d %s\n",perm,uidgid,siz,file)
    }'
    if [ $uidroot -gt $vlist ]; then
      cat << %
               ... (first $vlist files/directories listed only)
         In order to see the complete list use
                find /vnmr/. -user root
         or
                find /vnmr/. -user root -exec ls -ld {} \;
%
    fi
  else
    $echo "    No files or directories in \"/vnmr\" are owned by root"
  fi

  #------------------------------------------------------------------------
  # files / directories owned NEITHER by VnmrJ admin user NOR by user root
  #------------------------------------------------------------------------
  baduid=`find . \! -type l -a \! -user root -a \! -user $vnmrowner | \
           wc -l`
  if [ $baduid -gt 0 ]; then
    baduiddir=`find . \! -type l -a -type d -a \! -user root -a \
               \! -user $vnmrowner | wc -l`
    baduidfil=`expr $baduid - $baduiddir`
    if [ $baduidfil -gt 1 ]; then
      $echo $baduidfil  | $awk '{printf("  %6d Plain files",$1)}'
    elif [ $baduidfil -eq 1 ]; then
      $echo $baduidfil  | $awk '{printf("  %6d Plain file",$1)}'
    fi
    if [ $baduiddir -gt 1 ]; then
      if [ $baduidfil -gt 0 ]; then
        $echo " and"
      fi
      $echo $baduiddir  | $awk '{printf("  %6d Directories",$1)}'
    elif [ $baduiddir -eq 1 ]; then
      if [ $baduidfil -gt 0 ]; then
        $echo " and"
      fi
      $echo $baduiddir  | $awk '{printf("  %6d Directory",$1)}'
    fi
    $echo " in \"/vnmr\" NOT owned by user \"$vnmrowner\" or root:"
    $echo "             Perms    Ownership       Size  File"
    ls -ld `find . \! -type l -a \! -user root -a \! -user $vnmrowner | \
        head -n $vlist` | $awk '
    {
      perm=substr($1,2,9)
      uidgid=sprintf("%s/%s",$3,$4)
      siz=$5
      file=substr($NF,3,length($NF)-2)
      printf("           %s %-12s %8d %s\n",perm,uidgid,siz,file)
    }'
    if [ $baduid -gt $vlist ]; then
      cat << %
               ... (first $vlist files/directories listed only)
         In order to see the complete list use
                find /vnmr/. \! -user root -a \! -user $vnmrowner
%
    fi
  else
    cat << %
    All files & directories in "/vnmr" are owned by user "$vnmrowner" or root.
%
  fi

  cd $wd
fi



#==============================================================================
# VnmrJ / LOCATOR DATABASE SERVER RUN STATUS
#==============================================================================

if [ $vnmr -ne 0 -a `$echo $vnmrrev | grep -ic vnmrj` -ne 0 ]; then
  pgsql=`ps -ef | grep pgsql | grep -c postmaster`
  if [ $pgsql -gt 0 ]; then
    $echo "  VnmrJ / Locator database server (PGSQL) running."
    if [ `which managedb | grep -ci 'no managedb in'` -eq 0 ]; then
      sqldate=`date -u '+%Y-%m-%d %H:%M:%S %Z (%a)'`
      $echo "     Database status information for $sqldate:"
      managedb status 2>&1 | $awk '{
	if (($0 ~ /^DEBUG/) && (NF > 5))
	{
	  firstwd=6
	  outs=""
        }
	else if (($0 ~ /^ERROR/) && (NF > 5))
        {
          firstwd=6
          outs="ERROR: "
        }
	else
        {
	  firstwd=1
	  outs=""
	}
	if (NF > 0)
	{
	  for (i = firstwd; i < NF; i++)
	  {
	    outs=outs $i " "
	  }
	  outs=outs $NF
	  printf("%s\n",outs)
	}
      }' | sed 's/^at /   at /
s/^/        /'
      if [ -s $HOME/vnmrsys/ManagedbMsgLog ]; then
        $echo "     In case of problems you may also want to inspect the file"
        $echo "        $HOME/vnmrsys/ManagedbMsgLog"
        $echo "     for logged database maintenance messages."
      fi
    else
      if [ -s $HOME/vnmrsys/ManagedbMsgLog ]; then
        $echo "     In case of problems you may want to inspect the file"
        $echo "        $HOME/vnmrsys/ManagedbMsgLog"
        $echo "     for logged database maintenance messages."
      fi
    fi
  else
    $echo "  VnmrJ / Locator database server currently NOT running."
  fi
fi



#==============================================================================
# VnmrJ / VNMR PRINTER / PLOTTER DEFINITIONS (makePrinter vs. adddevices)
#==============================================================================

dvn=$vnmrsystem/devicenames
if [ $vnmr -ne 0 ]; then
  if [ `grep -cv '^#' < $dvn 2>/dev/null` -gt 0 ]; then
    cat << %

-------------------------------------------------------------------------------
 VnmrJ Printer / Plotter Definitions:
-------------------------------------------------------------------------------
%

    lpstaterr=`lpstat -r 2>&1 1>/dev/null`
    if [ "$lpstaterr" != "" ]; then
      lpstatok=0
      cat << %
  WARNING: "lpstat" fails with error
        $lpstaterr
  Printer reporting below will be PARTIAL ONLY.

%
    fi

    # checking for system default print destination
    ndev=0
    if [ $lpstatok -ne 0 ]; then
      def_printer=`lpstat -d | \
        $awk '{if ($0 ~ /^system default destination/) print $NF}'`
    fi
    for p in `(lpstat -p 2>/dev/null | \
               $awk '{if ($0 ~ /^printer /) print $2}'; \
	       $awk < $dvn '{if ($1 == "Name") print $NF}') | sort -u`; do
      showprinter $p $mkpr
      ndev=`expr $ndev + 1`
    done

    if [ $lpstatok -ne 0 ]; then
      # reporting status of local print server daemon server
      $echo "  print daemon status: \c"
      lpstat -r
    fi

    if [ "$def_printer" = "" -a $lpstatok -ne 0 ]; then
      cat << %
        No default printer defined in Solaris; to facilitate printing from
          "dtmail" and other CDE desktop utilities you may want to define a
          default print destination using the "PrinterAdministrator" utility
          from the CDE toolbar (select a printer, then select "Printer" ->
          "Modify Printer Properties...", check the "Default Printer" option,
          and exit using the "OK" button.
%
    fi
    rm -f $lptmp
  fi
fi



#==============================================================================
# SERIAL / PARALLEL PORT INFORMATION
#==============================================================================

if [ $vnmr -ne 0 ]; then
  $echo
  $echo "Serial / Parallel Port Status:"
  $echo "---------------------------------------\c"
  $echo "----------------------------------------"
  $echo " Port             Permissions     Owner/Group       Remarks"
  if [ -h /dev/term/a ]; then
    showport /dev/term/a
  elif [ -h /dev/ttya ]; then
    showport /dev/ttya
  fi
  if [ -h /dev/term/b ]; then
    showport /dev/term/b
  elif [ -h /dev/ttyb ]; then
    showport /dev/ttyb
  fi
  if [ -h /dev/printers/* ]; then
    for f in /dev/printers/*; do
      showport $f
    done
  fi
  if [ -h /dev/*pp[0-9] ]; then
    for p in /dev/*pp[0-9]; do
      if [ -h $p ]; then
        par=`ls -l $p | $awk '{print $NF}'`
        found=0
        if [ -h /dev/printers/* ]; then
          for f in /dev/printers/*; do
            b=`basename $f`
            prt=`ls -l $f | $awk '{print $NF}' | sed 's/^\.\.\///'`
            if [ "$par" = "$prt" -a $found -eq 0 ]; then
              $echo $p | $awk '{printf("%-17s ",$1)}'
              $echo "(alias pointing to the same port as \"$f\")"
              found=1
            fi
          done
        fi
        if [ $found -eq 0 ]; then
          showport $p
        fi
      fi
    done
  fi
fi


#==============================================================================
# REPORT NETWORKING INFORMATION, IF REQUIRED
#==============================================================================

acqif=""        # acquisition interface name
if [ $shownet -ne 0 ]; then
  $echo
  $echo "Networking / Network Interface:"
  $echo "---------------------------------------\c"
  $echo "----------------------------------------"

  host=`uname -n`
  $echo "  Host name:  $host"
  ip=`expand /etc/hosts | sed 's/[ ]*#.*//' | egrep " $host\$| $host " | \
	$awk '{print $1}'`
  if [ "x$ip" = x ]; then
    ip=`expand /etc/hosts | sed 's/[ ]*#.*//' | grep " $host\." | \
	$awk '{print $1}'`
  fi
  ifnum=10
  if [ "$ip" = 127.0.0.1 ]; then
    ninterf=0
    acqtype=none
  else
    ipx=`$echo $ip | $awk -F '.' '{printf("%02x%02x%02x%02x\n",$1,$2,$3,$4)}'`
    ipd=`$echo $ip | $awk -F '.' '{printf("%d\n",2^24*$1+2^16*$2+2^8*$3+$4)}'`
    $echo "    IP address: $ip\c"
    mac=`$arp $host | $awk '{print $4}'`
    if [ x$mac != xno ]; then
      interface=`grep -lw $host /etc/hostname.* | $awk -F '\.' '{print $2}'`
      baseif=`$echo $interface | $awk '{print substr($1,1,length($1)-1)}'`
      ifnum=`$echo $interface | $awk '{print substr($1,length($1),1)}'`
      ifline=`grep -n "\"$baseif\"" < /etc/path_to_inst | head -1 | \
             tr ':' ' ' | $awk '{printf("%d\n",$1*10)}'`
      if [ "x$ifline" = x ]; then
        ifline=10
      fi
      ifnum=`expr $ifline + $ifnum`
      $echo " on interface \"$interface\" ($mac)"
    else
      $echo " - ERROR:"
      $echo "        \"ARP\" fails - cannot determine interface!"
    fi
    ninterf=1
    $eval_netmask $ip | $awk '
    {
      printf("      network-ID: %s\n", $1);
      printf("      netmask: %s (%s)\n", $2, $3);
      printf("      usable address range:   %s - %s\n", $4, $5);
      printf("      broadcasting addresses: %s / %s\n", $6, $7);
      if ($NF != "OK")
      {
        printf("        ATTENTION: POSSIBLE NETMASK DEFINITION ERROR!\n")
        printf("      minimum netmask:        %s\n",$8);
      }
    }'
    routing=0
    if [ -s /etc/defaultrouter ]; then
      $echo "    Trying to connect to router; this may take a couple seconds ..."
      router=`cat /etc/defaultrouter`
      pingOK=`$ping $router 2>/dev/null | grep -c 'alive$'`
      $echo "      default router: $router\c"
      routing=1
      if [ $pingOK -gt 0 ]; then
        $echo " (reachable)"
        ns=`grep -w 'hosts:' < /etc/nsswitch.conf | sed 's/#.*//'`
        if [ `$echo $ns | grep -wc nisplus` -gt 0 ]; then
          $echo "    Name service: NIS+"
          if [ -s /etc/defaultdomain ]; then
            domain=`cat /etc/defaultdomain`
            $echo "      NIS+ domain name: $domain"
          fi
        elif [ `$echo $ns | grep -wc nis` -gt 0 ]; then
          $echo "    Name service: NIS"
          if [ -s /etc/defaultdomain ]; then
            domain=`cat /etc/defaultdomain`
            $echo "      NIS domain name: $domain"
          fi
        elif [ `$echo $ns | grep -wc dns` -gt 0 ]; then
          $echo "    Name service: DNS"
          if [ -s /etc/resolv.conf ]; then
            domain=`grep '^domain' < /etc/resolv.conf | $awk '{print $NF}'`
            $echo "      domain name: $domain"
            ns=0
            ndns=0
            $echo "    Trying to connect to DNS name server(s) - \c"
            $echo "this may take a while ..."
            for s in `grep '^nameserver' </etc/resolv.conf | $awk '{print $NF}'`
            do
              $echo $s | $awk '{printf("      name server: %-15s",$1)}'
              ns=`expr $ns + 1`
              pingOK=`$ping $s 2>/dev/null | grep -c 'alive$'`
              if [ $pingOK -gt 0 ]; then
                $echo "  reachable."
                ndns=`expr $ndns + 1`
              else
                $echo "  NOT reachable using \"ping\"."
              fi
            done
            if [ $ndns -eq 0 ]; then
              if [ $ns -eq 0 ]; then
                $echo "      NO NAME SERVERS DEFINED IN \"/etc/resolv.conf\""
              else
                $echo "      name servers in \"/etc/resolv.conf\"\c"
                $echo " NOT REACHABLE using \"ping\""
              fi
            fi
          else
            $echo "      NO DNS SETUP IN \"/etc/resolv.conf\""
          fi
        elif [ ! -f /etc/resolv.conf ]; then
          $echo "    Name service: NONE"
        else
          $echo "    Name service: NOT ACTIVATED in \"/etc/nsswitch.conf\""
        fi
      else
        $echo " NOT REACHABLE using \"ping\""
      fi
      if [ `ps -e | grep -c xntpd` -ne 0 ]; then
        if [ -s /etc/inet/ntp.conf ]; then
          ntpserver=`grep '^server' < /etc/inet/ntp.conf | $awk '{print $2}'`
          ntpdrift=`grep '^driftfile' < /etc/inet/ntp.conf | $awk '{print $2}'`
          pingOK=0
          if [ "$ntpserver" != "" ]; then
            pingOK=`$ping $ntpserver 2>/dev/null | grep -c 'alive$'`
          fi
          if [ -h $ntpdrift ]; then
            ntpdrift=`ls -l $ntpdrift | $awk '{print $NF}'`
          fi
          if [ $pingOK -gt 0 ]; then
            $echo "  System time synchronized using NTP (xntpd):"
            $echo "    NTP server used:  $ntpserver"
            if [ -s $ntpdrift ]; then
              ntpm=`ls -l $ntpdrift | $awk '{print $6}'`
              case $ntpm in
                Jan) ntpm=01 ;;
                Feb) ntpm=02 ;;
                Mar) ntpm=03 ;;
                Apr) ntpm=04 ;;
                May) ntpm=05 ;;
                Jun) ntpm=06 ;;
                Jul) ntpm=07 ;;
                Aug) ntpm=08 ;;
                Sep) ntpm=09 ;;
                Oct) ntpm=10 ;;
                Nov) ntpm=11 ;;
                Dec) ntpm=12 ;;
              esac
              ntpd=`ls -l $ntpdrift | $awk '{print $7}'`
              if [ $ntpd -lt 10 ]; then
                ntpd=0$ntpd
              fi
              ntpt=`ls -l $ntpdrift | $awk '{print $8}'`
              ntpy=`date '+%Y'`
              $echo "    last successful synchronization:  \c"
              if [ `$echo $ntpt | grep -c ':'` -eq 0 ]; then
                ntpy=$ntpt
                $echo "$ntpy-$ntpm-$ntpd"
              else
                if [ `date '+%m'` -lt $ntpm ]; then
                  ntpy=`expr $ntpy - 1`
                fi
                $echo "$ntpy-$ntpm-$ntpd $ntpt"
              fi
            fi
          fi
        fi
      fi
    fi
  fi

  #--------------------------------------------------------
  # check for alternative network interfaces / acquisition
  #--------------------------------------------------------
  cd /etc
  procs=0
  ifnum2=20
  hostnames=""
  duplicate_hn=0
  duplicate_names=""
  if [ `ls hostname.* | egrep -vc "hostname\.$interface|\.lo[0-9]|\.xx[0-9]"` \
       -gt 0 ]; then
    for f in `ls hostname.*|egrep -v "hostname.$interface|\.lo[0-9]|\.xx[0-9]"`
    do
      alt=`cat $f`
      if [ "$hostnames" = "" ]; then
        hostnames=$alt
      elif [ `echo $hostnames | grep -wc $alt` -ne 0 ]; then
        duplicate_hn=`expr $duplicate_hn + 1`
        if [ "$duplicate_names" = "" ]; then
          duplicate_names=$alt
        else
          duplicate_names="$duplicate_names $alt"
        fi
      else
        hostnames="$hostnames $alt"
      fi
      a_interf=`$echo $f | $awk -F '\.' '{print $2}'`
      a_ip=`expand hosts | sed 's/#.*//' | egrep " $alt\$| $alt " | \
		$awk '{print $1}'`
      a_ipx=`$echo $a_ip|$awk -F . '{printf("%02x%02x%02x%02x\n",$1,$2,$3,$4)}'`
      a_ipd=`$echo $a_ip|$awk -F . '{printf("%d\n",2^24*$1+2^16*$2+2^8*$3+$4)}'`
      if [ `$arp $alt | grep -c 'no entry$'` -eq 1 ]; then
        a_mac=none
      else
        a_mac=`$arp $alt | $awk '{print $4}'`
      fi
      if [ `expand hosts | sed 's/#.*//' | egrep -c " $alt\$| $alt "` -ne 0 \
           -a "$a_mac" != "none" ]; then
        $echo "  Alternative host name:  $alt"
        $echo "    IP address: $a_ip\c"
        $echo " on interface \"$a_interf\" ($a_mac)"
        $eval_netmask $a_ip | $awk '
        {
          printf("      network-ID: %s\n", $1);
          printf("      netmask: %s (%s)\n", $2, $3);
          printf("      usable address range:   %s - %s\n", $4, $5);
          printf("      broadcasting addresses: %s / %s\n", $6, $7);
        }'
        if [ "$alt" = wormhole ]; then
          if [ "$acqtype" = none ]; then
            acqtype=net
          else
            acqtype=dualnet
          fi
          acqif=$a_interf
          baseif2=`$echo $acqif | $awk '{print substr($1,1,length($1)-1)}'`
          ifnum2=`$echo $acqif | $awk '{print substr($1,length($1),1)}'`
          ifline2=`grep -n "\"$baseif2\"" < /etc/path_to_inst | head -1 | \
                 tr ':' ' ' | $awk '{printf("%d\n",$1*10)}'`
          if [ "x$ifline2" = x ]; then
            ifline2=20
          fi
          ifnum2=`expr $ifline2 + $ifnum2`
        fi
      fi
      ninterf=`expr $ninterf + 1`
    done
    if [ $duplicate_hn -gt 0 ]; then
      cat << %
  ATTENTION: Your system is trying to activate multiple Ethernet interfaces
             with the same hostname:
                       File           Interface    Hostname
%
      for n in $duplicate_names; do
	for f in `grep -wl $n hostname.*`; do
          $echo $f | $awk '{printf("                /etc/%-20s",$1)}'
	  $echo $f | sed 's/hostname\.//'| $awk '{printf("%-10s",$1)}'
          cat $f
        done
      done
      cat << %
             This may have been caused by failures with "setacq" calls before
             installing the current VnmrJ / VNMR patch, then calling "setacq"
             again after the patch installation. We strongly recommend
             REMOVING the extraneous files in "/etc"; then the system should
             be REBOOTED.
             If you don't know which of the above files to remove, you could
             remove ALL files "/etc/hostname.xxx" from the above list, then
             call "setacq" again (and reboot the system).
%
    fi
    if [ $ninterf -gt 1 -a $acq -ne 0 -a ! -f /etc/notrouter ]; then
      cat << %
  ATTENTION: The system has multiple active network interfaces
             and a file "/etc/notrouter" does NOT exist; the system
             may be running the route daemon ("routed") which can
             interfere with the spectrometer host functionality!
%
    fi
  fi
  if [ $routing -ne 0 -a "x$acqtype" = x ]; then
    # check for acquisition access via router
    acq_ip=`expand hosts | sed 's/#.*//' | egrep ' inova$| inova ' | \
		$awk '{print $1}'`
    if [ "x$acq_ip" = x ]; then
      acq_ip=`expand hosts | sed 's/#.*//' | egrep ' gemcon$| gemcon ' | \
		$awk '{print $1}'`
    fi
    loc_ip=`expand hosts | sed 's/#.*//' | egrep " $host\$| $host " | \
		$awk '{print $1}'`
    loc_net=`$eval_netmask $loc_ip | $awk '{print $1}'`
    if [ "x$acq_ip" != x ]; then
      acq_net=`$eval_netmask $acq_ip | $awk '{print $1}'`
      if [ "x$acq_net" = "x$loc_net" ]; then
        acqtype=router
      else
        acqtype=net
      fi
    fi
  else  # no routing
    acq_ip=`expand hosts | sed 's/#.*//' | egrep ' inova$| inova ' | \
		$awk '{print $1}'`
    if [ "x$acq_ip" = x ]; then
      acq_ip=`expand hosts | sed 's/#.*//' | egrep ' gemcon$| gemcon ' | \
		$awk '{print $1}'`
    fi
    if [ "x$acq_ip" != x ]; then
      acqtype=net
    fi
  fi
  case $acqtype in
    "net")
        $echo "  Console communication uses $acqif Ethernet network interface" ;;
    "dualnet")
        if [ $ifnum2 -gt $ifnum ]; then
          $echo "  Console communication uses secondary ($acqif) network\c"
          $echo " interface"
        else
          $echo "  Console communication uses primary ($acqif) network interface"
        fi
        ;;
    "router")
        $echo "  Console communication uses primary network interface\c"
        $echo " via router" ;;
  esac
  if [ "$system" = "UNITY INOVA" -a "$acqtype" != "" ]; then
    bigkernel=0
    bigkernelPPC=0
    if [ `ls -l /vnmr/acq/vxBoot | grep -c small` -eq 0 ]; then
      bigkernel=1
    fi
    if [ `ls -l /vnmr/acq/vxBootPPC | grep -c small` -eq 0 ]; then
      bigkernelPPC=1
    fi
    if [ $bigkernel -eq 1 ]; then
      if [ $bigkernelPPC -eq 1 ]; then
        $echo "  Big VxWorks kernel selected for acquisition CPU"
      else
        $echo "  Big   VxWorks kernel selected for acquisition CPU (68040)"
        $echo "  Small VxWorks kernel selected for acquisition CPU (PPC)"
      fi
    else
      if [ $bigkernelPPC -eq 1 ]; then
        $echo "  Small VxWorks kernel selected for acquisition CPU (68040)"
        $echo "  Big   VxWorks kernel selected for acquisition CPU (PPC)"
      else
        $echo "  Small VxWorks kernel selected for acquisition CPU"
      fi
    fi
  fi
fi



#==============================================================================
# CHECK ACQUISITION NETWORK (SPECTROMETER HOSTS)
#==============================================================================

if [ $acq -ne 0 -a $showacq -ne 0 ]; then
  $echo
  $echo "Acquisition Setup, Interface & Communication:"
  $echo "---------------------------------------\c"
  $echo "----------------------------------------"


  #-------------------------------------
  # Section for HAL-based spectrometers
  #-------------------------------------

  if [ $acq -ne 0 -a "x$acqtype" = x -a -c /dev/rsh0 ]; then
    acqtype=hal
  fi


  #------------------------------------------------------------
  # Report VnmrJ / VNMR spectrometer configuration information
  #------------------------------------------------------------

  if [ $vnmr -ne 0 -a $acq -ne 0 -a -x $vnmrsystem/bin/vconfig ]; then
    if [ $vnmrj -ne 0 ]; then
      $echo "  VnmrJ / VNMR spectrometer configuration:"
    else
      $echo "  VNMR spectrometer configuration:"
    fi
    $vnmrsystem/bin/vconfig display | sed 's/^/        /' | $awk '{
      if (NF > 0) {print}
    }'
  fi


  #------------------------------
  # ping acquisition computer(s)
  #------------------------------
  cd /etc
  procs=0
  if [ "$acqtype" = dualnet ]; then
    $echo "  Console communication via 2nd Ethernet interface \"$acqif\" ..."
  elif [ "$acqtype" = router ]; then
    $echo "  Console communication via external router ..."
  elif [ "$acqtype" = net ]; then
    $echo "  Console communication via Ethernet, spectrometer not networked ..."
  else
    $echo "  Console communication via differential SCSI driver box / HAL board"
  fi
  if [ "$vnmropt" = inova -a "$system" != DirectDrive ]; then
    msrbd=1
  else
    msrbd=0
  fi
  if [ "$system" = DirectDrive ]; then
    for h in inova inovaauto slim master1 rf1 rf2 rf3 rf4 rf5 rf6 rf7 rf8 \
	pfg1 pfg2 grad1 lock1 ddr1 ddr2 ddr3 ddr4 ddr5 ddr6 ddr7 ddr8; do
      if [ -f $vnmrsystem/acqqueue/acqi.init.$h -o \
           -f $vnmrsystem/acqqueue/acqi.ps.$h ]; then
        ex=`expand hosts | sed 's/#.*//' | egrep -c " $h\$| $h "`
        if [ $ex -gt 0 ]; then
          h_ip=`expand hosts | sed 's/#.*//' | egrep " $h\$| $h " | \
		$awk '{print $1}'`
          $echo $h $h_ip | $awk '{printf("        %-9s at %s:",$1,$2)}'
          pingOK=`$ping $h 2>/dev/null | grep -c 'alive$'`
          if [ $pingOK -gt 0 ]; then
            $echo " communication OK"
          else
            $echo " currently NOT reachable"
          fi
        fi
      fi
    done
  elif [ "$acqtype" != hal ]; then
    for h in inova inovaauto gemcon slim; do
      if [ \( "$h" = inovaauto -a $msrbd -eq 1 \) -o "$h" != inovaauto ]; then
        ex=`expand hosts | sed 's/#.*//' | egrep -c " $h\$| $h "`
        if [ $ex -gt 0 ]; then
          h_ip=`expand hosts | sed 's/#.*//' | egrep " $h\$| $h " | \
		$awk '{print $1}'`
          $echo $h $h_ip | $awk '{printf("        %-9s at %s:",$1,$2)}'
          pingOK=`$ping $h 2>/dev/null | grep -c 'alive$'`
          if [ $pingOK -gt 0 ]; then
            $echo " communication OK"
          else
            $echo " currently NOT reachable"
          fi
        fi
      fi
    done
  fi


  #-----------------------------------
  # check for acquisition process(es)
  #-----------------------------------
  procs=`ps -e | grep -c Expproc`
  if [ $procs -gt 0 ]; then

    #-----------------------------------------------
    # Expproc / VxWorks: check big vs. small kernel
    #-----------------------------------------------
    $echo "  Expproc running\c"
    cd $vnmrsystem/acq
    smallk=`ls -l vxBoot vxBootPPC 2>/dev/null | grep -c small`
    if [ "$system" = DirectDrive ]; then
      $echo
    elif [ $smallk -gt 0 ]; then
      $echo ", using small VxWorks kernel."
    else
      $echo ", using big VxWorks kernel."
    fi
  else

    #---------------------------
    # check for running Acqproc
    #---------------------------
    procs=`ps -e | grep -c Acqproc`
    if [ $procs -gt 0 ]; then
      $echo "  Acqproc running."
    fi
  fi


  #---------------------------------
  # show current acquisition status
  #---------------------------------
  if [ $procs -gt 0 -a -x $vnmrsystem/bin/showstat ]; then
    $echo "  Current acquisition status:"
    showstat | sed 's/^/        /' | $awk 'BEGIN {
      getline
      if ($NF == "Idle")
        idle=1
      else
        idle=0
      print
    }
    {
      if (idle == 1)
      {
        if (($1 ~ /^VT/) || ($1 ~ /^[Ss]pin/) || ($1 ~ /^[Ll]ock/) ||
            ($1 ~ /^Air/) || ($1 ~ /^Decoupler/))
          print
      }
      else
        print
    }'
  fi


  #--------------------------------------------------------------------
  # show shims and probe calibration files in /vnmr and ~vnmr1/vnmrsys
  #--------------------------------------------------------------------
  if [ $procs -gt 0 ]; then
    masteruser=`ls -ld $vnmrsystem/bin 2> /dev/null | $awk '{print $3}'`
    masterdir=`csh -c "$echo ~$masteruser" 2>/dev/null`
    masterdir=$masterdir/vnmrsys
    if [ `ls -ld $vnmrsystem/probes/* 2>/dev/null | \
          egrep -vc 'probe.tmplt|safety_levels'` -gt 0 ]; then
      cd $vnmrsystem/probes
      $echo "  Probe calibration data in \"/vnmr/probes\":"
      for f in `ls -d1 * 2>/dev/null | egrep -v 'probe.tmplt|safety_levels'`
      do
        if [ -f $f/$f ]; then
          ls -dgo $f/$f | cut -c 24- | sed 's/^/        /' | \
                $awk '{if (NF > 0) print}'
        else
          ls -dgoF $f | cut -c 24- | sed 's/^/        /' | \
                $awk '{if (NF > 0) print}'
        fi
      done
    fi
    if [ `ls -ld $masterdir/probes/* 2>/dev/null | wc -l` -gt 0 ]; then
      $echo "  Probe calibration data in \"$masterdir/probes\":"
      cd $masterdir/probes
      for f in `ls -d1 * 2>/dev/null`; do
        if [ -f $f/$f ]; then
          ls -dgo $f/$f | cut -c 24- | sed 's/^/        /' | \
                $awk '{if (NF > 0) print}'
        else
          ls -dgoF $f | cut -c 24- | sed 's/^/        /' | \
                $awk '{if (NF > 0) print}'
        fi
      done
    fi
    if [ `ls -ld $vnmrsystem/shims/* 2>/dev/null | grep -vcw 'reg0'` -gt 0 ]
    then
      cd $vnmrsystem/shims
      $echo "  Shim sets stored in \"/vnmr/shims\":"
      ls -go * 2>/dev/null | cut -c 24- | grep -vw 'reg0' | \
                sed 's/^/        /' | $awk '{if (NF > 0) print}'
    fi
    if [ `ls -ld $masterdir/shims/* 2>/dev/null | wc -l` -gt 0 ]; then
      cd $masterdir/shims
      $echo "  Shim sets stored in \"$masterdir/shims\":"
      ls -go * 2>/dev/null | cut -c 24- | sed 's/^/        /' | \
                $awk '{if (NF > 0) print}'
    fi
    if [ `ls -ld $vnmrsystem/gshimlib/shimmaps/*.fid 2>/dev/null | wc -l` \
         -gt 0 ]; then
      cd $vnmrsystem/gshimlib/shimmaps
      $echo "  gradient shim maps stored in \"/vnmr/gshimlib/shimmaps\":"
      ls -gdo *.fid 2>/dev/null | cut -c 24- | grep -vw 'reg0' | \
                sed 's/^/        /' | sed 's/.fid[\/]*$//' | \
                $awk '{if (NF > 0) print}'
    fi
    if [ `ls -ld $masterdir/gshimlib/shimmaps/*.fid 2>/dev/null | wc -l` -gt 0 ]
    then
      cd $masterdir/gshimlib/shimmaps
      $echo "  gradient shim maps stored in \"$masterdir/gshimlib/shimmaps\":"
      ls -gdo *.fid 2>/dev/null | cut -c 24- | grep -vw 'reg0' | \
                sed 's/^/        /' | sed 's/.fid[\/]*$//' | \
                $awk '{if (NF > 0) print}'
    fi
    cd $wd
  fi


  #----------------------------------------------------
  # show console (hardware) information, if available
  # (not for HAL-based systems, GEMINI 2000 & MERCURY)
  #----------------------------------------------------
  if [ $procs -gt 0 ]; then
    if [ `expand /etc/hosts | sed 's/#.*//' | egrep -c ' gemcon$| gemcon '` \
	  -ne 0 -o "$acqtype" = hal ]; then
      $echo "  Console hardware information not available for $system systems."
    elif [ "$system" = DirectDrive ]; then
      $echo "  Console hardware information currently not available for"
      $echo "     Varian NMR / MRI Systems with DirectDrive architecture."
    elif [ -f $vnmrsystem/acqqueue/acq.conf ]; then
      $echo "  Console hardware information:"
      showconsole | $awk '{if (NF > 0) print}' | sed 's/^/        /'
    else
      cat << %
  Console hardware information not available:
        The file "$vnmrsystem/acqqueue/acq.conf" is not present.
        You could stop Expproc with "su acqproc", then reboot the
        console and restart Expproc with "su acqproc", then try
                $wcmd $args
        again to see this information.
%
    fi
  fi
fi



#==============================================================================
# CHECK WHETHER SEQGEN WORKS OK
#==============================================================================

if [ -x /vnmr/bin/seqgen ]; then
  if [ ! -d $vnmruser/psglib ]; then
    mkdir -p $vnmruser/psglib
  fi
  if [ -f /vnmr/psglib/s2pul.c ]; then
    seqname=s2pul
  elif [ -f /vnmr/imaging/psglib/spuls.c ]; then
    seqname=spuls
  fi
  cd $vnmruser/psglib
  if [ "$seqname" != "" -o \
       `find . -name '*.errors' -a \! -size 0 | wc -l` -gt 0 ]; then
    cat << %

-------------------------------------------------------------------------------
 Checking VnmrJ Pulse Sequence Compilation
-------------------------------------------------------------------------------
%
  fi

  #------------------------------------------------------------------
  # reporting "dangling seqgen error files" in the local directories
  #------------------------------------------------------------------
  err_files=0
  lasterrfile=""
  if [ `ls $vnmruser/psglib/*.errors 2>/dev/null | wc -l` -gt 0 ]; then
    for f in `ls $vnmruser/psglib/*.errors`; do
      if [ -s $f ]; then
        if [ "$seqname" != "" ]; then
          if [ `$echo $f | grep -c "/${seqname}.errors"` -eq 0 ]; then
            err_files=`expr $err_files + 1`
            lasterrfile=`basename $f`
          fi
        else
          err_files=`expr $err_files + 1`
          lasterrfile=`basename $f`
        fi
      fi
    done
    if [ $err_files -gt 1 ]; then
      cat << %
  Note: the local "psglib" directory includes $err_files "seqgen" error files:
%
    elif [ $err_files -eq 1 ]; then
      cat << %
  Note: the local "psglib" directory includes a "seqgen" error file:
%
    fi
    if [ $err_files -gt 0 ]; then
      ls -dgo `find * -name '*.errors' -a \! -size 0`
    fi
  fi

  #-------------------------
  # testing "seqgen" itself
  #-------------------------
  seqgenfail=0
  if [ "$seqname" != "" ]; then
    cat << %
  Testing "seqgen $seqname" ...
%
    pbkout=0
    sbkout=0
    stmp=`date '+%Y-%m-%d_%H%M'`
    if [ -f $vnmruser/psglib/${seqname}.c ]; then
      pbkout=1
      mv $vnmruser/psglib/${seqname}.c $vnmruser/psglib/${seqname}.c.bkup.$stmp
    fi
    if [ -x $vnmruser/seqlib/$seqname ]; then
      sbkout=1
      mv $vnmruser/seqlib/$seqname $vnmruser/seqlib/${seqname}.bkup.$stmp
    fi
    if [ -f $vnmruser/seqlib/${seqname}.c ]; then
      mv $vnmruser/seqlib/${seqname}.c $vnmruser/seqlib/${seqname}.c.bkup.$stmp
    fi
    if [ ! -f /vnmr/psglib/${seqname}.c -a \
         -f /vnmr/imaging/psglib/${seqname}.c ]; then
      cp /vnmr/imaging/psglib/${seqname}.c $vnmruser/psglib
    fi
    seqgen $seqname >/dev/null 2>&1
    if [ -x $vnmruser/seqlib/$seqname ]; then
      if [ ! -s $vnmruser/psglib/${seqname}.errors ]; then
        $echo "    ... pulse sequence compilation OK."
      else
        seqgenfail=1
        cat << %
    ... pulse sequence \"$seqname\" compiled with error messages / warnings:
-------------------------------------------------------------------------------
%
        fmt -s -w 79 $vnmruser/psglib/${seqname}.errors | \
            $awk '{ if (NF > 0) print }'
        cat << %
-------------------------------------------------------------------------------
%
      fi
    else
      seqgenfail=2
      if [ ! -s $vnmruser/psglib/${seqname}.errors ]; then
        cat << %
    PULSE SEQUENCE COMPILATION FAILED, NO ERROR LOG FILE; COMMAND FEEDBACK:
-------------------------------------------------------------------------------
%
        seqgen ${seqname} 2>&1 | fmt -s -w 79 | $awk '{ if (NF > 0) print }'
        cat << %
-------------------------------------------------------------------------------
%
      else
        cat << %
    PULSE SEQUENCE \"$seqname\" FAILED TO COMPILE; ERROR MESSAGES / WARNINGS:
-------------------------------------------------------------------------------
%
        fmt -s -w 79 $vnmruser/psglib/${seqname}.errors | \
            $awk '{ if (NF > 0) print }'
        cat << %
-------------------------------------------------------------------------------
%
      fi
    fi
    if [ $pbkout -eq 1 ]; then
      mv $vnmruser/psglib/${seqname}.c.bkup.$stmp $vnmruser/psglib/${seqname}.c
    else
      rm -f $vnmruser/psglib/${seqname}.c
    fi
    if [ $sbkout -eq 1 ]; then
      mv $vnmruser/seqlib/${seqname}.bkup.$stmp $vnmruser/seqlib/$seqname
      if [ -f $vnmruser/seqlib/${seqname}.c.bkup.$stmp ]; then
        mv $vnmruser/seqlib/${seqname}.c.bkup.$stmp \
           $vnmruser/seqlib/${seqname}.c
      fi
    else
      rm -f $vnmruser/seqlib/$seqname $vnmruser/seqlib/${seqname}.c
    fi
  fi
  cd $wd

  if [ $seqgenfail -eq 0 ]; then
    if [ $err_files -gt 1 ]; then
      fmt -w 79 << %
Note: there are several files "seq_name.errors" in your "psglib" directory,
%
    elif [ $err_files -eq 1 ]; then
      fmt -w 79 << %
Note: there is a file "$lasterrfile" in your local "psglib" directory,
%
    fi
    if [ $err_files -gt 0 ]; then
      numrec=`expr $numrec + 1`
      fmt -w 79 << %
"$vnmruser/psglib" (see above), but "$seqname" actually compiles OK,
therefore, such error files are likely
%
      cat << %
 - from pulse sequences with coding errors
 - from "seqgen" compilation attempts prior to the last VnmrJ patch install
 - from "seqgen" compilation attempts under an earlier VnmrJ installation
In the latter two cases such files can safely be discarded.

%
    fi
  elif [ $seqgenfail -eq 1 ]; then
    if [ $err_files -gt 0 ]; then
      numrec=`expr $numrec + 1`
      fmt -w 79 << %
NOTE: "$seqname" COMPILES, BUT WITH ERROR / WARNING MESSAGES (see above for
details). Apart from this, there are error files ("seq_name.errors") from
other pulse sequences in your local "psglib" directory, "$vnmruser/psglib"
(see above); such error files may also be generated due to
%
      cat << %
 - from pulse sequences with coding errors
 - from "seqgen" compilation attempts prior to the last VnmrJ patch install
 - from "seqgen" compilation attempts under an earlier VnmrJ installation
In the latter two cases such files can safely be discarded. NEVERTHELESS, we
STRONGLY RECOMMEND having a closer look at  the compiler error messages /
warnings from "seqgen $seqname".

%
    else
      numrec=`expr $numrec + 1`
      fmt -w 79 << %
NOTE: "$seqname" COMPILES WITH ERROR / WARNING MESSAGES - see above for
details. WE STRONGLY RECOMMEND CHECKING THE CONTENTS OF THE ERROR FILE, and to
correct the underlying issue, as this may affect the functioning of other
commands, such as  "fixpsg", "psggen", "wtgen" and other functions involving
compilation, and this may also prevent the installation of User Library
contributions such as Chempack, BioPack, etc.

%
    fi
  elif [ $seqgenfail -gt 1 ]; then
    numrec=`expr $numrec + 1`
    fmt -w 79 << %
NOTE: "$seqname" FAILS TO COMPILE - see above for details. This is likely a
serious issue in the setup, such as
%
      cat << %
 - the VnmrJ pulse sequence link libraries not being up-to-date, e.g., because
   a VnmrJ patch installation "forgot" to run "fixpsg"; in this case running
   "fixpsg" as vnmr1 may correct the issue;
 - a local "psg" directory ("~/vnmrsys/psg") containing legacy or erroneous /
   incompatible files (in this case, removing / renaming the local "psg"
   directory may help);
 - a serious issue with your VnmrJ software setup;
 - a missing Linux library, i.e., a serious issue in your Linux installation;
 - a missing compiler executable required for "seqgen" to work - likely again
   a serious issue in your Linux installation;
This means that on this workstation you will not be able to compile pulse
sequences, at least not as the current user. If the first two points above
don't provide helpful clues, this may mean that not only "seqgen" may be
non-functional on this system, but also "fixpsg", "psggen", "wtgen" and other
functions involving compilation, and this is likely also to prevent the
installation of User Library contributions such as Chempack, BioPack, etc.
%
    if [ $err_files -gt 0 ]; then
      numrec=`expr $numrec + 1`
      fmt -w 79 << %
In the same context, there are error files ("seq_name.errors") from other
pulse sequences in your "psglib" directory, "~/vnmrsys/psglib" (see above).
This could be legacy files from "seqgen" compilation attempts prior to the
last VnmrJ patch install or under an earlier VnmrJ installation, but most
likely they are indicators for the issue described above.
%
    fi
    $echo
  fi
fi


#==============================================================================
# PRINT VnmrJ USER / OPERTATOR INFORMATION
#==============================================================================

if [ -s /vnmr/adm/users/userlist ]; then
  cd /vnmr/adm/users
  cat << %

-------------------------------------------------------------------------------
 Checking VnmrJ User & Operator Definitions
-------------------------------------------------------------------------------
  List of defined VnmrJ users per "/vnmr/adm/users/userlist":
%
  cat userlist | $awk '{ for (i=1; i<= NF; i++) print $i }' | sort -bdf | \
    $awk 'BEGIN { maxlen=0 }
    {
      user[NR] = $0
      if (length($0) > maxlen)
      {
        maxlen = length($0)
      }
    }
    END {
      linelen = 74
      cols = 1
      width = 4 + maxlen
      while ((cols <= NR) && (width + 2 + maxlen <= linelen))
      {
        width += 2 + maxlen
        cols ++
      }
      rows = ((NR - (NR % cols)) / cols)
      if ((NR % cols) > 0)
        rows++
      for (l = 0; l < rows; l++)
      {
        printf("    ")
        for (t = 1; t <= cols; t++)
        {
          ix = (t - 1)*rows + l + 1
          if (ix <= NR)
          {
            printf("%s", user[ix])
            if ((ix < NR) || (t < cols - 1))
            {
              for (i = length(user[ix]); i <= maxlen + 2; i++)
                printf(" ")
            }
          }
        }
        printf("\n")
      }
    }'
  if [ -s uexist ]; then
    $echo "  Contents of \"/vnmr/adm/users/uexist\":"
    cat uexist | sort -bdf | $awk 'BEGIN {maxlen=0; maxlen2=0} {
      user[NR] = $1
      rem[NR] = $2
      for (i = 3; i < NF; i++)
        rem[NR] = rem[NR] " " $i
      status[NR] = $NF
      if (length($1) > maxlen)
        maxlen=length($1)
      if (length(rem[NR]) > maxlen2)
        maxlen2=length(rem[NR])
    }
    END {
      for (i = 1; i <= NR; i++)
      {
        printf("%s", user[i])
        for (j = length(user[i]); j < maxlen + 2; j++)
          printf(" ")
        printf("%s", rem[i], status[i])
        for (j = length(rem[i]); j < maxlen2 + 2; j++)
          printf(" ")
        printf("%s\n", status[i])
      }
    }' | sed 's/^/    /'
  fi
  if [ -s userDefaults ]; then
    $echo "  Contents of \"/vnmr/adm/users/userDefaults\":"
    $echo "    # Name     Show  Private  Value"
    tail +3 userDefaults | $awk '{
        printf("%-10s %-6s %-6s",$1,$2,$3)
        if (NF > 3)
          printf(" ")
        for (i = 4; i <= NF; i++)
          printf(" %s",$i)
        printf("\n")
      }' | sed 's/^/    /'
  fi
  if [ -d operators ]; then
    cd operators
    if [ -s automation.conf ]; then
      $echo "  Contents of \"/vnmr/adm/users/operators/automation.conf\":"
      start=`expand automation.conf | grep -n 'DayQ Start' | cut -d ':' -f 1`
      tail +$start automation.conf | $awk '{ if (NF > 0) print }' | \
        sed 's/^/    /'
    fi
    if [ -s operatorlist ]; then
      $echo "  Contents of \"/vnmr/adm/users/operators/operatorlist\":"
      head -1 operatorlist | sed 's/ //
        s/^/    /'
      tail +2 operatorlist | sort -bdf | $awk '{
        printf("%-12s", $1)
        for (i = 2; i <= NF; i++)
          printf(" %s",$i)
        printf("\n")
      }' | $awk '{ if (NF > 0) print }' | sed 's/^/    /'
    fi
    if [ -s vjpassword ]; then
      nlines=`wc -l < vjpassword`
      npasswd=`sort -u -k 2,2 < vjpassword | wc -l`
      if [ $nlines -gt $npasswd ]; then
        if [ $npasswd -gt 1 ]; then
          pl=s
        fi
        fmt -c -w 79 << %
  NOTE: There are $nlines defined VnmrJ operator accounts using only $npasswd
  different password${pl}; this can be exploited and defeats the purpose of
  such passwords. If you use an "open / semi-public password convention" we
  recommend using recipes such as "operator_name PLUS a given passphrase".
%
      fi
    fi
  fi
fi
cd $wd



#==============================================================================
# PRINT SUMMARY BLOCK (-all OPTION ONLY)
#==============================================================================

if [ $showsum -ne 0 ]; then
  $echo
  $echo
  $echo "CONFIGURATION SUMMARY:"
  $echo "---------------------------------------\c"
  $echo "----------------------------------------"
  $echo "Workstation: $wstype\c"
  if [ $MHz -ne 0 ]; then
    $echo " ($MHz MHz)\c"
  fi
  if [ $rammb -ne 0 ]; then
    $echo ", $rammb MiB RAM"
  else
    $echo
  fi
  if [ $ndisks -gt 1 ]; then
    $echo "  $ndisks disks, $diskmb MiB total, $nslices UFS slices\c"
  else
    $echo "  1 disk, $diskmb MiB\c"
    if [ $nslices -gt 1 ]; then
      $echo ", $nslices UFS slices\c"
    else
      $echo ", 1 UFS slice\c"
    fi
  fi
  $echo $swapmb | $awk '{printf(", %d MiB swap space\n",$1)}'
  $echo "Operating System: $solversion\c"
  if [ $patched -ne 0 ]; then
    $echo ", patched\c"
    if [ "$patchdate" != "" ]; then
      $echo " ($patchdate)"
    else
      $echo
    fi
  else
    $echo ", NOT PATCHED"
  fi
  if [ $warn_enduser -ne 0 ]; then
    $echo "  End User option only may be installed (no \"make\")"
  fi
  if [ -f $vnmrsystem/vnmrrev ]; then
    $echo "$vnmrrev\c"
    if [ "$system" != "" ]; then
      $echo " for $system architecture\c"
    fi
    if [ $warn_vpatch -eq 0 ]; then
      if [ "x$lastvpatch" != x ]; then
        $echo ", patched ($lastvpatch)"
      else
        $echo ", patched"
      fi
    else
      $echo ", NOT patched"
    fi
    if [ $warn_gnuc -ne 0 ]; then
      $echo "  GNU C not installed as part of VnmrJ / VNMR"
    fi
  fi
fi



#==============================================================================
# PRINT RECOMMENDATIONS (-all / -rec OPTIONS ONLY)
#==============================================================================

if [ $showrecomm -ne 0 ]; then
  revyear=`$echo $revdate | $awk '{print substr($1,1,4)}'`
  revmonth=`$echo $revdate | $awk '{print substr($1,6,2)}'`
  revyear=`expr $revyear \* 12`
  revmonth=`expr $revyear + $revmonth`
  curyear=`date "+%Y"`
  curmonth=`date "+%m"`
  curyear=`expr $curyear \* 12`
  curmonth=`expr $curyear + $curmonth`
  rev_age=`expr $curmonth - $revmonth`


  #-----------------------------------------------
  # DON'T issue recommendations after > 2 years
  #-----------------------------------------------
  if [ $rev_age -gt 24 ]; then
    cat << %

For upgrade recommendations you should download the current
version of "bin/sysprofiler" from the on-line user library at
        http://www.chem.agilent.com/en-US/Support/Pages/default.aspx
%
  else
    cat << %


UPGRADE AND SECURITY RECOMMENDATIONS (status: $revday):
-------------------------------------------------------------------------------
%
    totalrec=0
    upgrade=0


    #-------------------------------
    # catch slow workstation models
    #-------------------------------
    if [ $slowws -gt 3 ]; then
      upgrade=1
      numrec=`expr $numrec + 1`
      cat << %
Compared to even an entry-level modern workstation model, your computer
is underpowered for running current operating systems (such as Solaris 8
or higher, and CDE) and application software. Upgrading to more RAM and
bigger disks might help a bit, but the basic performance and system
reaction time would still be marginal compared to more recent models.
%
      if [ $hal -ne 0 ]; then
        cat << %
We recommend upgrading to a newer (used or "remanufactured") Sun Ultra
workstation, such as
%
      else
        cat << %
We recommend upgrading to a newer Sun workstation, such as
%
      fi
    elif [ $slowws -eq 3 ]; then
      upgrade=1
      numrec=`expr $numrec + 1`
      if [ "$system" = "GEMINI 2000" -o "$system" = "MERCURY" -o \
           $hal -ne 0 ]; then

        cat << %
Compared to even an entry-level modern workstation model, your computer
is fairly slow. It MAY be still acceptable for running current operating
systems (such as Solaris 8 or higher, and CDE) and application software
(VNMR 6.1C), PROVIDED you don't do lots of nD NMR processing, in-line DSP
(dsp='i'), or linear prediction on nD NMR data. Upgrading to more RAM
and bigger disks might help a bit, but the basic performance and system
reaction time would still be marginal compared to more recent models.
%
        if [ $hal -ne 0 ]; then
          cat << %
We recommend upgrading to a newer (used or "remanufactured") Sun Ultra
workstation, such as
%
        else
          cat << %
We recommend upgrading to a newer Sun workstation, such as
%
        fi
      else
        cat << %
Compared to even an entry-level modern workstation model, your computer
is underpowered for running current operating systems (such as Solaris 8
or higher, and CDE) and application software. Upgrading to more RAM and
bigger disks might help a bit, but the basic performance and system
reaction time would still be marginal compared to more recent models.
We recommend upgrading to a newer Sun workstation, such as
%
      fi
    elif [ $slowws -eq 2 ]; then
      numrec=`expr $numrec + 1`
      cat << %
Your workstation may still be OK for running current operating systems
(such as Solaris 8 or 9) and application software (such as the current
VnmrJ or VNMR), PROVIDED it is equipped with enough RAM and disk space
(see below). Alternatively, you may start to consider upgrading to a
more up-to-date workstation model such as
%
    fi
    if [ $slowws -gt 1 ]; then
      if [ $hal -eq 1 ]; then
        if [ $X1032A -eq 0 ]; then
          numrec=`expr $numrec + 1`
          cat << %
 - a Sun Ultra 30,
 - a Sun Ultra 60, or
 - a Sun Ultra 80
With an Ultra 5/400 or Ultra 10/440 you would also need an expensive
X1032A (obsolete), X2222A or X4422A expansion card; the above models
already have a built-in SCSI port. Notes:
%
        else
          numrec=`expr $numrec + 1`
          cat << %
 - a Sun Ultra 5/400 (see below),
 - a Sun Ultra 10/440 (see below),
 - a Sun Ultra 30,
 - a Sun Ultra 60, or
 - a Sun Ultra 80
With an Ultra 5/400 or Ultra 10/440 you need an X1032A (obsolete),
X2222A or X4422A expansion card from your current spectrometer host
to connect with the differential SCSI driver box. Notes:
%
        fi
        cat << %
 - Sun Blade workstations CANNOT be used as spectrometer hosts for
   HAL-Based spectrometers (VXR-S, UNITY, UNITYplus).
 - In order for the HAL driver software to work, Solaris MUST be run
   in 32-bit (not 64-bit) mode.
 - The X2222A and X4422A expansion cards are supported by Solaris 8
   and later ONLY.
%
      else # (non-HAL based systems)
        numrec=`expr $numrec + 1`
        cat << %
 - a $recom_ws1, or
 - a $recom_ws2
%
      fi
    elif [ $slowws -gt 0 ]; then
      numrec=`expr $numrec + 1`
      cat << %
In order to run current operating systems (such as Solaris 8 or
Solaris 9) and application software (such as the current VnmrJ or
VNMR), you should make sure your workstation is equipped with
enough RAM and disk space, see below.
%
    elif [ $recsolnum -gt $solnum -o \
       \( $vnmrj -ne 0 -a `$echo $vnmrrev | grep -ic "$cur_vnmrj"` -eq 0 \) -o \
       \( $vnmrj -eq 0 -a `$echo $vnmrrev | grep -ic "$cur_vnmr"` -eq 0 \) ]
    then
      numrec=`expr $numrec + 1`
      if [ "$maxsolrel" != "" ]; then
        if [ $slowws -lt 0 ]; then
          cat << %
Your workstation model is OK for running current software such as
$maxsolrel and $cur_vnmrj
%
        else
          cat << %
Your workstation model should still be OK for running current software
(e.g., $maxsolrel and $cur_vnmrj).
%
        fi
      else
        if [ $slowws -lt 0 ]; then
          cat << %
Your workstation model is OK for running current software such as
$cursolrel and $cur_vnmrj
%
        else
          cat << %
Your workstation model should still be OK for running current software
(e.g., $cursolrel and $cur_vnmrj).
%
        fi
      fi
    fi


    #----------------------------------------
    # recommendations about minimum RAM size
    #----------------------------------------
    if [ $rammb -lt $minrammb ]; then
      if [ $numrec -gt 0 ]; then
        $echo
      fi
      numrec=`expr $numrec + 1`
      if [ $vnmrj -eq 0 ]; then
        $echo "We recommend having at least $minrammb MiB of RAM."
      elif [ `$echo $vnmrrev | grep -ic vnmrj` -eq 0 ]; then
        $echo "If you consider an upgrade to VnmrJ, we recommend expanding"
        $echo "the workstation memory (RAM) to at least $minrammb MiB."
      else
        $echo "For adequate performance with VnmrJ, your workstation"
        $echo "should be equipped with at least $minrammb MiB of RAM."
      fi
    elif [ $slowws -gt 0 ]; then
      numrec=`expr $numrec + 1`
      $echo "The RAM size ($rammb MiB) of your workstation is OK."
    fi


    #---------------------------------
    # Recommendations about swap size
    #---------------------------------
    if [ $swapmb -lt $minswapwarn ]; then
      if [ $numrec -gt 0 ]; then
        $echo
      fi
      numrec=`expr $numrec + 1`
      $echo "The swap space on your system is MARGINAL OR TOO SMALL!"
    fi
    if [ $minrammb -gt $rammb ]; then
      newram=$minrammb
    else
      newram=$rammb
    fi
    if [ $newram -gt 2048 ]; then
      recswap=$newram
      minswapwarn=`$echo $newram | $awk '{printf("%1.0f\n",0.75*$1)}'`
    elif [ $newram -gt 1024 ]; then
      recswap=$newram
      minswapwarn=$newram
    else
      recswap=`expr $newram \* 2`
      minswapwarn=`$echo $newram | $awk '{printf("%1.0f\n",1.5*$1)}'`
    fi
    if [ $recswap -lt $minswap ]; then
      recswap=$minswap
    fi
    if [ $minswapwarn -lt $minswap ]; then
      minswapwarn=$minswap
    fi
    recswapmb=$recswap
    newswapwarn=$minswapwarn
    newswapmin=$recswap
    if [ $upgrade -eq 0 ]; then
      if [ $swapmb -le $newswapwarn ]; then
        numrec=`expr $numrec + 1`
        $echo "With the installed or minimum recommended RAM size"
        $echo "  you should define a swap space of $newswapmin MiB."
      fi
    elif [ $newswapwarn -ge $swapmb ]; then
      numrec=`expr $numrec + 1`
      if [ $newram -gt $rammb ]; then
        $echo "With the minimum recommended RAM size you should define"
        $echo "  a swap space of $newswapmin MiB."
      else
        cat << %
With $rammb MiB of installed RAM we recommend setting the size of
  the swap space to $recswap MiB when installing Solaris (systems
  with up to 1 GiB or RAM: $minswap MiB or twice the size of the
  RAM, whichever is bigger; on systems with over 1 GiB of RAM the
  swap space should be adjusted to at least the size of the RAM).
%
      fi
    fi


    #---------------------------------------------------------
    # Recommendations about disk size (for computer upgrades)
    #---------------------------------------------------------
    if [ $upgrade -ne 0 -a $mindiskwarn -gt $diskmb ]; then
      numrec=`expr $numrec + 1`
      if [ "$system" = "GEMINI 2000" -o "$system" = "MERCURY" ]; then
        cat << %
Running VNMR 6.1C under Solaris 8 requires AT LEAST 4, better 8
  (or more) GiB of total disk space. Solaris 9 or later cannot
  be used on $system spectrometer hosts.
%
      elif [ $hal -eq 1 ]; then
        cat << %
Running VNMR 6.1C under Solaris 8 or later requires
  AT LEAST 4, better 8 (or more) GiB of total disk space.
%
      else
        cat << %
Running VnmrJ or VNMR 6.1C under Solaris 8 or later requires
  AT LEAST 4, better 8 (or more) GiB of total disk space.
%
      fi
    fi


    #-----------------------------------------------------
    # Recommendations about disk size for existing system
    #-----------------------------------------------------
    if [ $upgrade -eq 0 -a $mindiskwarn -gt $diskmb ]; then
      freedisk=`expr $diskmb - $newswapmin`
      if [ $freedisk -lt 0 ]; then
        numrec=`expr $numrec + 1`
        if [ "$system" = "GEMINI 2000" -o "$system" = "MERCURY" ]; then
          cat << %
The disk size of your workstation is TOO SMALL by current standards:
  running VNMR 6.1C under Solaris 8 requires AT LEAST 4, better 8
  (or more) GiB of total disk space (Solaris 9 or later cannot
  be used on $system spectrometer hosts).
%
        elif [ $hal -eq 1 ]; then
          cat << %
The disk size of your workstation is TOO SMALL by current standards:
  running VNMR 6.1C under Solaris 8 or later requires AT LEAST 4,
  better 8 (or more) GiB of total disk space.
%
        else
          cat << %
The disk size of your workstation is TOO SMALL by current standards:
  running VnmrJ or VNMR 6.1C under Solaris 8 or later requires
  AT LEAST 4, better 8 (or more) GiB of total disk space.
%
        fi
      else
        numrec=`expr $numrec + 1`
        if [ "$system" = "GEMINI 2000" -o "$system" = "MERCURY" ]; then
          cat << %
The disk size of your workstation is MARGINAL OR TOO SMALL by current
  standards:  the swap space requirements leave only $freedisk MiB
  of usable disk space; running VNMR 6.1C under Solaris 8 requires AT
  LEAST 4, better 8 (or more) GiB of total disk space (Solaris 9 or
  later cannot be used on $system spectrometer hosts).
%
        elif [ $hal -eq 1 ]; then
          cat << %
The disk size of your workstation is MARGINAL OR TOO SMALL by current
  standards:  the swap space requirements leave only $freedisk MiB
  of usable disk space; running VNMR 6.1C under Solaris 8 or later
  requires AT LEAST 4, better 8 (or more) GiB of total disk space.
%
        else
          cat << %
The disk size of your workstation is MARGINAL OR TOO SMALL by current
  standards:  the swap space requirements leave only $freedisk MiB
  of usable disk space; running VnmrJ or VNMR 6.1C under Solaris 8 or
  later requires AT LEAST 4, better 8 (or more) GiB of total disk
  space.
%
        fi
      fi
    fi


    #-----------------------------------------
    # Recommendations about disk partitioning
    #-----------------------------------------
    partrecs=0
    if [ \( \( $disk1sizM -lt $slicedsizM -a $disk1sizM -ne $rootsizM \) \
            -o $rootsizM -lt $minrootsizM -o $disk1ufsslices -gt 2 \) \
         -a $ndisks -lt $nslices ]; then
      if [ $numrec -gt 0 ]; then
        $echo
      fi
      numrec=`expr $numrec + 1`
      minslicedgb=`expr $slicedsizM + 511`
      minslicedgb=`expr $minslicedgb / 1024`
      rootsizwarnM=`expr $recrootsizM + $minrootsizM`
      rootsizwarnM=`expr $rootsizwarnM / 2`
      recrootsizG=`expr $recrootsizM + 511`
      recrootsizG=`expr $recrootsizG / 1024`
      rootsizwarnG=`expr $rootsizwarnM + 511`
      rootsizwarnG=`expr $rootsizwarnG / 1024`
      if [ $disk1sizM -lt $slicedsizM ]; then
        numrec=`expr $numrec + 1`
        partrecs=`expr $partrecs + 1`
        cat << %
With disks smaller than $minslicedgb GiB we STRONGLY recommend
NOT TO USE ANY PARTITIONING (apart from a swap slice)!
%
      fi
      if [ $rootsizM -lt $minrootsizM ]; then
        numrec=`expr $numrec + 1`
        partrecs=`expr $partrecs + 1`
        $echo "The size of your root (/) slice is MARGINAL:"
        $echo $rootfreeK $rootsizK | $awk '
        {
          printf("  current free space in \"/\"   ")
          printf(" %5.1f out of %7.1f MiB (%4.1f%% free)\n",
                 $1/1024, $2/1024, 100.0*$1/$2)
        }'
      elif [ $rootsizM -lt $rootsizwarnM -a \
             $disk1sizM -ge $slicedsizM ]; then
        numrec=`expr $numrec + 1`
        partrecs=`expr $partrecs + 1`
        $echo "You currently have a root (/) slice slice of \c"
        $echo $rootsizK | $awk '{printf("%3.1f GiB; our\n",$1/1024)}'
        $echo "   recommendation would be to use a larger root slice of \c"
        $echo "$recrootsizG GiB"
      fi
      if [ $disk1ufsslices -gt 2 ]; then
        nxtra=0
        if [ `df -k | grep -c ' /opt$'` -eq 1 ]; then
          numrec=`expr $numrec + 1`
          partrecs=`expr $partrecs + 1`
          if [ $optfreeK -lt $optminfreeK ]; then
            $echo "The size of the \"/opt\" slice is MARGINAL:"
            $echo $optfreeK $optsizK | $awk '
            {
              printf("  current free space in \"/opt\"")
              printf(" %5.1f out of %7.1f MiB (%4.1f%% free)\n",
                     $1/1024, $2/1024, 100.0*$1/$2)
            }'
          fi
          xtraslices="\"/opt\""
          nxtra=1
        fi
        if [ `df -k | grep -c ' /usr$'` -eq 1 ]; then
          if [ $usrfreeK -lt $usrminfreeK ]; then
            numrec=`expr $numrec + 1`
            partrecs=`expr $partrecs + 1`
            $echo "The size of the \"/usr\" slice is MARGINAL:"
            $echo $usrfreeK $usrsizK | $awk '
            {
              printf("  current free space in \"/usr\"")
              printf(" %5.1f out of %7.1f MiB (%4.1f%% free)\n",
                     $1/1024, $2/1024, 100.0*$1/$2)
            }'
          fi
          if [ "$xtraslices" = "" ]; then
            xtraslices="\"/usr\""
          else
            xtraslices="\"/usr\" and $xtraslices"
          fi
          nxtra=`expr $nxtra + 1`
        fi
        if [ `df -k | grep -c ' /var$'` -eq 1 ]; then
          if [ $varfreeK -lt $varwarnfreeK ]; then
            numrec=`expr $numrec + 1`
            partrecs=`expr $partrecs + 1`
            if [ $varfreeK -lt $varminfreeK ]; then
              $echo "The size of the \"/var\" slice is VERY LIMITED:"
            else
              $echo "The size of the \"/var\" slice is MARGINAL:"
            fi
            $echo $varfreeK $varsizK | $awk '
            {
              printf("  current free space in \"/var\"")
              printf(" %5.1f out of %7.1f MiB (%4.1f%% free)\n",
                     $1/1024, $2/1024, 100.0*$1/$2)
            }'
          fi
          if [ "$xtraslices" = "" ]; then
            xtraslices="\"/var\""
          elif [ $nxtra -eq 1 ]; then
            xtraslices="\"/var\" and $xtraslices"
          else
            xtraslices="\"/var\", $xtraslices"
          fi
          nxtra=`expr $nxtra + 1`
        fi
        if [ $nxtra -gt 1 ]; then
          numrec=`expr $numrec + 1`
          partrecs=`expr $partrecs + 1`
          cat << %
On this system, $xtraslices are set up as extra disk slices.
While on bigger server systems this may be useful and desirable,
if offers little or no benefit, but merely disadvantages on
workstations used for NMR processing and as spectrometer hosts:
%
        elif [ $nxtra -eq 1 ]; then
          numrec=`expr $numrec + 1`
          partrecs=`expr $partrecs + 1`
          cat << %
On this system, $xtraslices is set up as extra disk partition.
While on bigger server systems this may be useful and desirable,
if offers little or no benefit, but merely disadvantages on
workstations used for NMR processing and as spectrometer hosts:
%
        fi
      fi
      numrec=`expr $numrec + 1`
      partrecs=`expr $partrecs + 1`
      cat << %
Sooner or later, systems with a limited root ("/") slice or with
size restrictions in the "/var", "/usr", or "/opt" file systems
may run into problems, in that
 - you may not be able to install Solaris patches at all;
 - you may be able to install patches with the "-nosave" option
   only, and in the case of problems you then CAN'T UNINSTALL
   patches (which might force you to reinstall all software);
 - you may not be able to print, particularly on open access or
   automation (SMS, VAST, LC-NMR, LC-NMR/MS) systems which tend
   to generate lots of output;
 - you may not be able to send messages and NMR data by e-mail;
 - you may not be able to run VnmrJ / VNMR or acquire data.
When installing Solaris next time, please consider the following
recommendations:
%

      if [ $disk1sizM -lt $slicedsizM ]; then
        partrecs=`expr $partrecs + 1`
        cat << %
 - We STRONGLY RECOMMEND NOT TO PARTITION disks with a size of
   $minslicedgb GiB or less, i.e., apart from a separate swap slice
   (recommended: $recswapmb MiB on this system) there should be only
   one partition (root, "/") on that disk.
%
      fi
      bigdiskM=`expr 2 \* $slicedsizM`
      bigdiskG=`expr $bigdiskM + 511`
      bigdiskG=`expr $bigdiskG / 1024`
      if [ $disk1sizM -lt $bigdiskM ]; then
        partrecs=`expr $partrecs + 1`
        cat << %
 - With disks of over $minslicedgb GiB our recommendation is to use one
   of the following two alternatives for the FIRST (main) disk:
     - Set up a root ("/") slice of $rootsizwarnG - $recrootsizG GiB, a swap
       slice (recommended on this system: $recswapmb MiB, see above),
       and define (mount) the remainder of the disk as "/export/home"
       or "/space".
     - Alternatively, apart from a separate swap slice ($recswapmb MiB,
       see above), DON'T PARTITION THAT DISK AT ALL;
%
      else
        partrecs=`expr $partrecs + 1`
        cat << %
 - With disks of over $bigdiskG GiB our recommendation is to
   set up a root ("/") slice of $rootsizwarnG - $recrootsizG GiB, a swap
   slice (recommended on this system: $recswapmb MiB, see above), and
   to define (mount) the remainder of the disk as "/export/home"
   or "/space".
%
      fi
      partrecs=`expr $partrecs + 1`
      numrec=`expr $numrec + 1`
      cat << %
   IMPORTANT: DO NOT USE THE DEFAULT SOLARIS PARTITIONING SCHEME, as it
   will give you a marginal root slice that may later cause the above
   problems. If you have problems adjusting the size of the root slice
   to $recrootsizG GiB, rather DON'T partition the disk at all (apart from
   the swap space) - it is easier to get this option set up correctly.
 - Any additional disks should not be partitioned at all.
%
    fi
    if [ $partrecs -gt 0 ]; then
      numrec=`expr $numrec + 1`
      cat << %
For additional comments on how to lay out disks under Solaris see
Agilent MR News 2004-09-20 and Agilent MR News 2004-10-04.
%
    fi



    #------------------------
    # Solaris recommendation
    #------------------------
    if [ $recsolnum -gt $solnum ]; then
      if [ $numrec -gt 0 ]; then
        $echo
      fi
      numrec=`expr $numrec + 1`
      recsol=`expr $recsolnum / 100`
      $echo "We recommend installing Solaris $recsol (\"Developer Version\"\c"
      $echo " or \"Entire release\")."
      if [ "$system" = "GEMINI 2000" -o "$system" = "MERCURY" ]; then
        numrec=`expr $numrec + 1`
        $echo "Remember: $system spectrometers are NOT compatible with"
        $echo "  Solaris 9 or higher!"
      fi
      if [ $hal -eq 1 ]; then
        numrec=`expr $numrec + 1`
        cat << %
For HAL-Based systems (UNITYplus, UNITY, VXR-S) you MUST
  install / activate the 32-bit version of Solaris, the 64-bit
  mode of Solaris will NOT WORK on these systems! As Sun Blade
  workstations run in 64-bit mode ONLY, they can NOT be used
  as host computer for these spectrometers.
%
      fi
    fi
    if [ $patched -eq 0 -o $warn_oldpatch -ne 0 ]; then
      numrec=`expr $numrec + 1`
      cat << %
We STRONGLY RECOMMEND installing Sun's current Solaris patch
  cluster at regular intervals (1 - 2 times per year AT LEAST).
  Solaris patch clusters can be downloaded from
        http://www.oracle.com/
%
    fi
    if [ $numrec -gt 0 ]; then
      totalrec=`expr $totalrec + $numrec`
      $echo
      numrec=0
    fi


    #--------------------------
    # Security recommendations
    #--------------------------
    if [ $solnum -ge 900 -a $n_wrapwarn -gt 0 ]; then
      if [ $tcp_wrap -eq 0 ]; then
        numrec=`expr $numrec + 1`
        if [ "$wrapline" = "" ]; then
          cat << %
SECURITY WARNING: WE STRONGLY RECOMMEND USING TCP WRAPPING; to
  activate, change the line
        $wrapline
  in the file $inetdef to
        ENABLE_TCPWRAPPERS=YES
  then re-initiate "inetd" with
        pkill -HUP inetd
  For information on setting up the TCP denial and access lists
%
          if [ $h_access_man -ne 0 ]; then
            cat << %
    ("/etc/hosts.deny" and "/etc/hosts.allow") see
            man -s 5 hosts_access
    or Agilent MR News 2004-04-19.
%
          else
            cat << %
    ("/etc/hosts.deny" & "/etc/hosts.allow") see Agilent MR News 2004-04-19."
%
          fi
        elif [ $h_access_man -ne 0 ]; then
          cat << %
SECURITY WARNING: WE STRONGLY RECOMMEND USING TCP WRAPPING;
  for information see Agilent MR News 2004-04-19 or
        man -s 5 hosts_access
%
        else
          cat << %
SECURITY WARNING: WE STRONGLY RECOMMEND USING TCP WRAPPING;
  for information see Agilent MR News 2004-04-19.
%
        fi
      else
        if [ ! -s /etc/hosts.deny ]; then
          numrec=`expr $numrec + 1`
          cat << %
SECURITY WARNING: TCP Wrapping activated, but TCP denial list
  NOT SET UP; we recommend setting up "/etc/hosts.deny" with a
  single line
        ALL: ALL
%
          if [ $h_access_man -ne 0 ]; then
            cat << %
  See Agilent MR News 2004-04-19 for information, or
        man -s 5 hosts_access
%
          else
            $echo "  See Agilent MR News 2004-04-19 for information."
          fi
        fi
      fi
    fi
    if [ $open_hostequiv -ne 0 ]; then
      numrec=`expr $numrec + 1`
      cat << %
SECURITY WARNING: The file "/etc/hosts.equiv" on this system
  treats ALL hosts as trusted, potentially allowing remote
  logins from anywhere without even specifying a password!
  See "man hosts.equiv" for more information.
%
    fi
    if [ -f /.rhosts ]; then
      if [ -r /.rhosts -a -s /.rhosts ]; then
        if [ `grep -v '^-' /.rhosts | wc -w` -gt 0 ]; then
          numrec=`expr $numrec + 1`
          $echo "SECURITY WARNING: using \"/.rhosts\" to allow for remote root"
          $echo "  logins creates a serious security risk!"
        fi
      else
        numrec=`expr $numrec + 1`
        $echo "SECURITY WARNING: we STRONGLY recommend NOT defining \"/.rhosts\""
      fi
    fi
    if [ $not_inetd -lt 6 ]; then
      numrec=`expr $numrec + 1`
      if [ $acq -ne 0 ]; then
        cat << %
SECURITY ADVICE: you can improve the system security by deactivating
  (commenting out) unused services in "/etc/inetd.conf". Note that on
  spectrometers some services (such as TFTP) may be required for the
  acquisition to work - it is best to call "setacq" after restricting
  the services in "/etc/inetd.conf".
%
      else
        cat << %
SECURITY ADVICE: you can improve the system security by deactivating
  (commenting out) unused services in "/etc/inetd.conf".
%
      fi
    elif [ $n_inetd -gt 20 ]; then
      numrec=`expr $numrec + 1`
      cat << %
SECURITY ADVICE: you probably could improve the system security by
  deactivating (commenting out) further unused ports in "/etc/inetd.conf".
%
    fi
    if [ $sec_sadmind -ne 0 ]; then
      numrec=`expr $numrec + 1`
      cat << %
SECURITY WARNING: "/etc/inetd.conf" has "sadmind" (line $sadmline) activated.
  This service has a known security hole; WE STRONGLY RECOMMEND
  DEACTIVATING IT by commenting out line $sadmline in "/etc/inetd.conf".
%
    fi
    if [ $not_servc -lt 10 ]; then
      numrec=`expr $numrec + 1`
      if [ $acq -ne 0 ]; then
        cat << %
SECURITY ADVICE: you can improve the system security by deactivating
  (commenting out) unused services in "/etc/services". Note that on
  spectrometers some services (such as BOOTPC, BOOTPS) may be required
  for the acquisition to work - it is best to call "setacq" after
  restricting the number of active ports in "/etc/services".
%
      else
        cat << %
SECURITY ADVICE: you can improve the system security by deactivating
  (commenting out) unused services in "/etc/services".
%
      fi
    elif [ $n_servc -gt 40 ]; then
      numrec=`expr $numrec + 1`
      cat << %
SECURITY ADVICE: you probably could improve the system security by
  deactivating (commenting out) further unused services in "/etc/services".
%
    fi
    if [ $open_xdmcp -ne 0 ]; then
      numrec=`expr $numrec + 1`
      $echo "This system is open for remote CDE (XDMCP) logins from any host."
    fi
    if [ $bcast_xdmcp -ne 0 ]; then
      numrec=`expr $numrec + 1`
      if [ $open_xdmcp -ne 0 ]; then
        $echo "  Host name shown on the XDMCP chooser list of any remote host."
      else
        $echo "Host name shown on ANY remote CDE login (XDMCP) chooser list."
      fi
    fi
    if [ $open_xdmcp -ne 0 -o $bcast_xdmcp -ne 0 ]; then
      $echo "  Active configuration file: $xdmcpconfig"
      $echo "  (see Agilent MR News 2002-06-03 for more information)"
    fi
    if [ $numrec -gt 0 ]; then
      totalrec=`expr $totalrec + $numrec`
      $echo
      numrec=0
    fi


    #-----------------------------
    # VnmrJ / VNMR recommendation
    #-----------------------------
    if [ $vnmrj -eq 0 ]; then
      if [ `$echo $vnmrrev | grep -ic 6\.1[C-Z]` -eq 0 ]; then
        numrec=`expr $numrec + 1`
        $echo "VnmrJ does not support $system spectrometers. We recommend"
        $echo "  upgrading to the current version of VNMR ($cur_vnmr)."
        if [ "$pending_vnmr" != "" ]; then
          $echo "  $pending_vnmr is to be released around $pending_vnmrdate"
        fi
      fi
      if [ $warn_vpatch -ne 0 ]; then
        numrec=`expr $numrec + 1`
        cat << %
Check the Agilent "VnmrJ / VNMR Patches" Web site at
      http://www.chem.agilent.com/en-US/Support/Pages/default.aspx
  for a patch for your software.
%
      fi
    elif [ -f $vnmrsystem/vnmrrev ]; then
      if [ `$echo $vnmrrev | grep -ic vnmrj` -eq 0 ]; then
        if [ `$echo $vnmrrev | grep -ic 6\.1[C-Z]` -eq 0 ]; then
          numrec=`expr $numrec + 1`
          cat << %
On workstations and $system spectrometer hosts you have the choice of
  running VnmrJ or VNMR. If you decide to stay with, we strongly
  recommend upgrading to the current version of VNMR ($cur_vnmr).
%
        fi
      else
        if [ `$echo $vnmrrev | egrep -ic '1\.1[C-Z]|[2-9]\.[0-9][A-Z]'` -eq 0 ]
        then
          numrec=`expr $numrec + 1`
          $echo "We STRONGLY recommend upgrading to the current version of"
          $echo "  VnmrJ ($cur_vnmrj or later)."
          if [ "$pending_vj" != "" ]; then
            $echo "  $pending_vj is to be released around $pending_vjdate"
          fi
        fi
      fi
      if [ $warn_vpatch -ne 0 ]; then
        numrec=`expr $numrec + 1`
        if [ $vnmrbeta -ne 0 ]; then
          cat << %
Check the Agilent "VnmrJ / VNMR Beta Test" Web site at
      http://www.chem.agilent.com/en-US/Support/Pages/default.aspx
  for a possible patch for your beta version of VnmrJ / VNMR.
%
        else
          cat << %
Check the Agilent "VnmrJ / VNMR Patches" Web site at
      http://www.chem.agilent.com/en-US/Support/Pages/default.aspx
  for a patch for your software.
%
        fi
      fi
    fi


    #-------------------------------------
    # VNMR-related Solaris upgrade issues
    #-------------------------------------
    if [ "$minsolrel" != "" ]; then
      numrec=`expr $numrec + 1`
      if [ $vnmrj -ne 0 ]; then
        cat << %
With the currently installed version of Solaris (Solaris $sol) you
  can NOT upgrade to $cur_vnmr with the latest patch or to VnmrJ;
  you should upgrade to $minsolrel AT LEAST
%
      else
        cat << %
With the currently installed version of Solaris (Solaris $sol) you
  can NOT upgrade to $cur_vnmr with the latest patch; you should
  upgrade to $minsolrel AT LEAST
%
      fi
    fi
    if [ "$maxsolrel" != "" ]; then
      numrec=`expr $numrec + 1`
      cat << %
Note that $maxsolrel is the LAST Solaris release that is compatible with
  $system spectrometers; newer Solaris versions CANNOT be used.
%
    fi
    if [ $hal -ne 0 ]; then
      if [ $bit64on -eq 1 ]; then
        numrec=`expr $numrec + 1`
        if [ `$echo $wstype | grep -ci Blade` -gt 0 ]; then
          cat << %
WARNING: The installed VNMR version is for HAL-based systems, but this is
  a Blade workstation which always runs with the 64-bit mode turned on.
  You will NOT be able to use this workstation as host computer for a
  $system spectrometer!
%
        else
          cat << %
WARNING: The installed VNMR version is for HAL-based systems, but Solaris is
installed with the 64-bit mode turned on - you will NOT be able to use this
workstation as host computer for a $system spectrometer unless you
disable the 64-bit mode:
 - check whether you have a file "/platform/sun4u/kernel/unix";
 - if this file is missing you need to REINSTALL Solaris in 32-bit mode
 - if this file is present, run the system down to monitor mode, using
   "init 0"; then, at the "ok" prompt, type
        setenv boot-file kernel/unix
   and boot the system. After this, "isainfo -v" should report
        32-bit sparc applications
   ONLY.
%
        fi
      fi
    fi


    #----------------------------------
    # catch case of no recommendations
    #----------------------------------
    totalrec=`expr $totalrec + $numrec`
    if [ $totalrec -eq 0 ]; then
      $echo "No recommendations available for this system / configuration."
      $echo
    elif [ $numrec -gt 0 ]; then
      $echo
      numrec=0
    fi


    #---------------------------------------------------
    # after > 12 months recommend using current version
    #---------------------------------------------------
    if [ $rev_age -gt 12 ]; then
      numrec=`expr $numrec + 1`
      totalrec=`expr $totalrec + 1`
      cat << %
For more accurate / up-to-date recommendations you may want to
try the current version of "bin/sysprofiler" from the on-line
user library at
        http://www.chem.agilent.com/en-US/Support/Pages/default.aspx
or contact Agilent directly; the "$wcmd" information above
helps Agilent assisting you in finding an upgrade solution.

%
    fi


    #--------------------------------------------------
    # legal notice in case recommendations were issued
    #--------------------------------------------------
    if [ $totalrec -gt 0 ]; then
      cat << %
-------------------------------------------------------------------------------
IMPORTANT NOTE: Even though these recommendations are in close agreement with
what is stated in Agilent MR News and with the very latest version of our
software installation manuals, they are the author's PERSONAL guidelines for
configuring or upgrading a Sun workstation to run current VnmrJ / VNMR
software in a recent operating environment, i.e., the output above does NOT
constitute Agilent's official point-of-view, nor a condition or a requirement
for getting support for your system, nor can we guarantee that the above
recommendations are sufficient or adequate for running the current Solaris
and VnmrJ or VNMR software in your environment.
THESE RECOMMENDATIONS ARE PROVIDED AS IS - NO LEGAL OR OTHER LIABILITY CAN
BE DERIVED FROM THE OUTPUT OF THIS SOFTWARE.
%
    fi
    if [ $showpatches -ne 0 -o $showsecurity -ne 0 ]; then
      if [ $totalrec -eq 0 ]; then
        cat << %
-------------------------------------------------------------------------------
IMPORTANT NOTE: "$wcmd" does NOT perform a comprehensive security check -
the information above is only meant to assist in optimizing the security of a
Sun workstation. You may want to check our "Sun / Solaris Security FAQ" at
        http://www.varianinc.com/products/nmr/apps/usergroup/faq.html
for further security advice.
%
      else
        cat << %

"$wcmd" does NOT perform a comprehensive security check - the information
above is only meant to assist in optimizing the security of a workstation. You
may want to check our "Sun / Solaris Security FAQ" at
        http://www.varianinc.com/products/nmr/apps/usergroup/faq.html
for further security advice.
%
      fi
    fi
    if [ $showsecurity -ne 0 ]; then
      cat << %

WARNING: The "$wcmd" output is provided for your personal use and/or
to assist a Agilent service or support representative in determining the
soft- and hardware status of your system; the above information can be
abused to acquire knowledge about security holes that may be present in
your software setup!
%
    fi
  fi
fi



#==============================================================================
# OUTPUT TRAILER
#==============================================================================

if [ $showversion -gt 0 ]; then

  #------------------------------------------------
  # prompt user to update sysprofiler, if necessary
  #------------------------------------------------
  $echo
  $echo "---------------------------------------\c"
  $echo "----------------------------------------"
  revy=`$echo $revdate | cut -c 3-4`
  revm=`$echo $revdate | cut -c 6-7`
  revy=`expr $revy \* 12`
  revm=`expr $revm + $revy`
  cury=`date '+%y'`
  curm=`date '+%m'`
  cury=`expr $cury \* 12`
  curm=`expr $curm + $cury`
  sysprofiler_age_m=`expr $curm - $revm`
  if [ $sysprofiler_age_m -ge 5 ]; then
    $echo "We STRONGLY recommend using\c"
  elif [ $sysprofiler_age_m -ge 2 ]; then
    $echo "For best results make sure you use\c"
  else
    $echo "Make sure you always use\c"
  fi
  $echo " an up-to-date version of \"bin/sysprofiler\"."
  $echo "The current version can be downloaded from Agilent's On-Line NMR / MRI"
  $echo "User Library at"
  $echo "        \c"
  $echo "http://www.chem.agilent.com/en-US/Support/Pages/default.aspx

  #------------------------
  # report program version
  #------------------------
  $echo "---------------------------------------\c"
  $echo "----------------------------------------"
  upperwrap=`$echo $wcmd | tr '[a-z]' '[A-Z]'`
  $echo "$upperwrap module \"$cmd\" version $version ($revdate)" | \
        $awk '{printf("%79s\n",$0)}'
  $echo "Author:  $author" | $awk '{printf("%79s\n",$0)}'
  $echo "Feedback:  $authoraddr" | $awk '{printf("%79s\n\n",$0)}'
fi

rm -f $tmp $patchtmp
exit 0

#==============================================================================
# REVISION HISTORY (all revisions by rk):
#------------------------------------------------------------------------------
# 2003-09-20, 1.0:  first version, as posted in Agilent MR News 2003-09-20
# 2003-09-25, 2.1:  added Solaris patch reporting, refined / expanded
# 2003-10-09, 2.3:  added warnings for "End User" Solaris installs or
#                   if the GNU C compiler is not installed with VNMR.
# 2003-10-17, 2.4:  added device name with UFS disk partitions
# 2003-11-03, 3.1:  added networking information
# 2003-11-07, 3.2:  added explicit recommendations for patch installations
# 2003-11-10, 4.1:  added summary / recommendations
# 2003-11-13, 4.2:  added showconsole output, where available
# 2004-03-06, 4.3:  added Chempack / BioPack info (sugg. R.Machinek),
#                   added VNMR / VnmrJ spectrometer configuration information
#                   added VNMR printer / plotter definition information
# 2004-03-07, 5.1:  added makePrinter information (sugg. R.Machinek)
#                   banner title with host name and time stamp
#                   added information about VNMR / VnmrJ users
# 2004-03-08, 5.2:  minor change to deal with the fact that NIS/NIS+ is NOT
#                   used for output on VNMR/VnmrJ users. Users shown with
#                   "-all" option only.
# 2004-03-09, 5.3:  fixed bug with "vconfig" call on MERCURY & GEMINI 2000
#                   suppressed check for "inovaauto" on non-INOVA systems
# 2004-03-15, 6.1:  avoids error if "/etc/group" inaccessible (report
#                   R.McKay  NANUC)  VNMR / VnmrJ user info includes UID /
#                   GID if available  some rearrangements in output order
#                   new "-r" option  limit "showstat" output, list probe
#                   calibration files in "/vnmr/probes" and shims in
#                   "/vnmr/shims"  prompt for contribution updates, added
#                   (rudimentary) security info (suggestions by R.Machinek)
# 2004-03-17, 6.2:  added (limited) security warning to recommendations.
# 2004-03-18, 6.3:  improved listing of shims & probe calibrations; also
#                   lists vnmr1's shims & probe calibrations & various bug
#                   fixes and enhancements (suggested / reported by
#                   R.Machinek)  list shim maps in /vnmr and ~vnmr1/vnmrsys.
# 2004-03-18, 6.4:  user "acqproc" not shown.
# 2004-03-18, 6.6:  added "-a" / "-acq" option.
# 2004-03-21, 6.7:  enhanced security checks (/etc/inetd.conf, /etc/services)
# 2004-03-23, 6.8:  adjusted "sadmind" security check for latest info
# 2004-03-25, 6.10: suppress security information with "-p" option
# 2004-04-19, 6.11: check for TCP wrapper in Solaris 9 & up, more detailed
#                   analysis of "/etc/services" and "/etc/inetd.conf"
# 2004-05-03, 6.12: suppress "ping" errors, fixed VNMR patch detection
# 2004-05-19, 6.13: print UFS dump dates, if available
# 2004-05-21, 6.14: improved output for local UFS partitions
# 2004-05-23, 6.15: correction in output for local disk space
# 2004-06-09, 6.16: adjustments for calls from within VNMR; limit execution
#                   to Solaris / SPARC systems (compatibility check)
# 2004-06-10, 7.1:  added info about VnmrJ installation path & options
# 2004-06-13, 7.2:  minimal Solaris release for current VNMR / VnmrJ
# 2004-06-16, 7.3:  info about user library install history into "/vnmr"
# 2004-06-30, 7.4.2:  added login shell to info about VNMR/VnmrJ users
# 2004-07-06, 7.4.5:  added hostid, minor cleanup, VnmrJ 1.1D released
# 2004-07-08, 7.4.9:  printer output improved, fixed duplicate output word
# 2004-08-12, 7.5.1:  corrections in output wording about swap space;
#                     improvements in VNMR/VnmrJ printer/plotter listing  bug
#                     fixes in VNMR/VnmrJ user listing (/etc/group not local)
#                     bug fixes in acquisition communication checks
# 2004-08-13, 7.5.2:  improved wording for dummy plotter definitions
# 2004-08-17, 7.5.3:  added Java, C compiler & sendmail version information
#                     added NTP information  if present (-> networking)
#                     list available graphics controllers  show last reboot
#                     list recent network logins
# 2004-08-31, 7.6.1:  fixed bug with XVR-100 graphics controller output.
# 2004-09-07, 7.6.3:  minor correction with boot date output
# 2004-09-12, 7.7.1:  report acquisition kernel selection for UNITY INOVA
# 2004-09-13, 7.7.2:  adjustments in recommendations, expanded compatibility
# 2004-09-15, 7.8.6:  updated disk partitioning recommendations, for VnmrJ
#                     check whether Locator database server is running
# 2004-09-21, 7.8.7:  improvements in remote access statistics
# 2004-09-22, 7.8.9:  corrected swap space warning threshold (R.Machinek)
# 2004-09-23, 7.8.10: adjusted slow workstation response (R.Machinek)
# 2004-09-24, 7.8.11: suppress color depth output if depth not available
# 2004-09-26, 7.8.12: more improvements in remote access statistics
# 2004-09-27, 7.8.13: enhancements in parallel port listing
# 2004-10-02, 7.9.1:  further adjustments in partitioning recommendations;
# 2004-10-02, 7.9.2:  suppress Acq. kernel selection if not spectrometer
# 2004-10-05, 7.9.3:  adjusted minimum swap size from 384 to 512 MiB
# 2004-10-06, 7.9.4:  report file system logging
# 2004-10-08, 7.9.6:  fixed XVR-100 graphics color depth output
# 2004-10-08, 7.9.7:  fixed bug with output about parallel port
# 2004-09-10, 7.9.8:  improved reboot statistics, enhanced remote access
#                     report (shows date and time of last access)
# 2004-10-14, 7.9.9:  adjusted wording for most recent patch install
# 2004-10-20, 7.9.10: adjustments for VnmrJ_LX
# 2004-10-22, 7.9.11: patch analysis to indicate irreversible patches;
#                     Suppress "man" pointer if manual not available.
# 2004-10-22, 7.9.12: improved recognition of network interfaces;
#                     Refined SW recommendations for fast workstations
#                     Corrected disk size calculation & slice count
# 2004-10-23, 7.10.1: fixed problems for systems without VNMR/VnmrJ;
#                     fixed problems with incomplete path definition
# 2004-10-23, 7.10.2: added pointer to disk partitioning articles in VNN
# 2004-12-08, 7.13.1: expanded printer/plotter checks / output
# 2004-12-09, 7.13.2: suppress output about PGSQL in case of VNMR software
# 2004-12-18, 7.13.3: indicate VNMR/VnmrJ patch installation date/time
# 2004-12-18, 7.13.4: more specific feedback with other OS environments
# 2004-12-18, 7.13.5: report 64-bit mode, check for clash with HAL systems
# 2004-12-23, 7.13.7: minor mods in print queue status report
# 2004-12-23, 7.13.8: added Solaris default printer recommendation
# 2004-12-25, 7.14.1: added check for extraneous files "/etc/hostname.*"
# 2005-01-08, 7.14.3: relaxed swap space recommendations for large RAM
# 2005-02-08, 7.14.5: access statictics now chronological, by last access
# 2005-03-02, 7.14.6: bug fixes & minor improvements for Solaris up to 2.6
# 2005-03-17, 7.14.7: suppress access statistics for Solaris 7 as well
# 2005-03-24, 7.15.1: limited support for DirectDrive architecture
# 2005-03-28, 7.15.2: fixed minor issue with VnmrJ installation options
# 2005-04-18, 7.15.4: several fixes for DirectDrive architecture
# 2005-04-24, 7.15.6: more adjustments for DirectDrive architecture
# 2005-06-21, 7.16.3: show swap space information and status
# 2005-06-27, 7.16.6: started expansions for Linux / MacOS X
# 2005-06-29,       7.17.1:  contribution restructured to use install script
# 2005-09-15,       7.17.2:  added locale settings info, minor refinement
# 2005-12-03_12:41, 7.17.4:  secured against string comparison errors
# 2006-01-16,       7.17.5:  amendments for VnmrJ 2.1B
# 2006-01-24,       7.17.6:  locator database info; print queue output cleanup
# 2006-01-28,       7.17.7:  added pointer to local database mainenance logs;
#                            enhancement in report on Locale settings
# 2006-01-30_01:16, 7.17.9:  minor adjustments for VnmrJ 2.1B
# 2006-10-15_00:24, 7.17.10: minor adjustments (excess line length in output)
# 2007-01-24_00:16, 7.17.11: renamed from "showconfig" to "sysprofiler"
# 2007-02-23,       7.17.12: output reworded for NMR / MRI, Agilent MR News
# 2007-11-08,       7.17.13: minor adjustments in output wording
# 2007-11-09,       7.17.14: minor adjustments in output wording; renamed from
#                            "sysprofiler" (now a wrapper) to "sysprof.sol"
# 2008-01-04_09:44, 7.17.15: minor amendment for wrapper script calls
# 2008-10-03,       7.17.16: improved test syntax for VnmrJ patch report,
#                            fixed minor formatting issue with printer report
# 2008-10-04,       7.17.17: enhanced / corrected VnmrJ patch checking
# 2008-11-07,       7.17.18: added support for Linux long argument syntax
# 2008-11-07_18:20, 7.17.20
# 2008-11-12_17:24, 7.17.24
# 2008-11-28_13:43, 7.17.27
# 2009-01-09_21:03, 7.17.28: revision history rearranged
# 2009-01-17_23:53, 7.17.29
# 2009-01-18_18:39, 7.17.30: added history argument (internal/debugging only)
# 2009-01-23_15:42, 7.17.31: adopted printer reporting enhancements from Linux
# 2009-01-23_15:52, 7.17.32: fix for VNMR-only printer definitions
# 2009-01-23_16:12, 7.17.33: additional fixes / enhancements
# 2009-02-01_19:10, 7.18.0:  cleanup, coordinated VnmrJ part w/ Linux version
# 2009-02-01_22:36, 7.18.1:  minor correction in printer output
# 2009-02-01_22:48, 7.18.2:  minor amendment
# 2009-02-09_08:12, 7.18.3:  removed unused Linux sections (streamlined)
# 2009-02-11_13:33, 7.18.4
# 2009-03-02_15:15, 7.19.0:  reports SSH version / activities
# 2009-03-20_11:46, 7.20.0:  added seqgen test, VnmrJ operator info
# 2009-03-20_11:52, 7.20.1:  bug fixes
# 2009-03-20_15:59, 7.20.2:  minor addition in text output
# 2009-03-27_11:06, 7.20.3:  corrected bug with inexistent fbconfig program
# 2009-03-27_11:10, 7.20.4
# 2009-04-21_08:32, 7.20.5:  protected against lpstat failures
# 2009-05-27_15:49, 7.21.0:  check file ownership in "/vnmr"
# 2009-05-27_16:11, 7.21.1
# 2009-05-28_09:26, 7.21.2:  output text enhancements
# 2009-05-28_09:39, 7.21.3
# 2009-05-28_18:33, 7.22.0:  retrofitted header features from Linux version
# 2009-05-28_19:00, 7.22.1:  made file listings in ownership checks more robust
# 2009-05-28_19:09, 7.22.2
# 2009-05-29_13:43, 7.22.3:  minor output header addition
# 2009-06-05_09:26, 7.22.4:  corrections in printer reporting
# 2009-06-05_09:48, 7.22.5
# 2009-06-05_20:29, 7.22.6:  added check for erroneous netmask
# 2009-06-05_21:13, 7.22.7
# 2009-07-10_12:32, 7.23.0:  changes for binary size units
# 2009-07-10_14:54, 7.23.1
# 2009-07-10_15:01, 7.23.2:  better disk / partition size reporting
# 2009-07-10_15:13, 7.23.3
# 2009-08-03_19:11, 7.23.4:  corrected column label in disk usage report
# 2010-02-22_16:15, 7.23.5:  fixed 2 potential bugs with older Solaris versions
# 2010-07-17_18:26, 7.23.6:  enhanced arg logic, more coherent with Linux vers.
# 2010-09-13_09:25, 7.24.0:  avoid endless loops in reading configuration files
# 2010-12-23_01:58, 7.24.1:  corrected Web addresses / URLs
#==============================================================================
# END OF SCRIPT
#==============================================================================
