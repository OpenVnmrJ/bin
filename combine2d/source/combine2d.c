/* combine2d - add or subtract 2D fids */

/* 
   Syntax:      combine2d <-d<ebug>> <-f<loat>> source1_fid source2 _fid \
                        target_fid <multiplier>
                combine2d -v<ersion>

   Description: The program is located in "/vnmr/bin". It takes the following
                arguments:
                 -version / -v  prints the source version and release date,
                                and exits (no action taken)
                 -debug / -d    optional argument, meant for debugging ONLY;
                                switches on verbose output during processing
                 -float / -f    optional, produces FID in "float" format,
                                irrespective of the format of the source FIDs
                 source1_fid    source FID #1 (first "operand FID")
                 source2_fid    source FID #2 (second "operand FID")
                 target_fid     target FID (resulting FID), cannot be
                                identical with one of the source FIDs
                 multiplier     optional, applied to "source2_fid" before
                                adding to "source1_fid"; default value: -1
                All three FID arguments must be FID files ("*.fid/fid" or
                "~/vnmrsys/expN/acqfil/fid"). The source FIDs (i.e.: the
                file headers) are checked for compatibility, and the target
                will be written with the file structure of "source1_fid" -
                EXCEPTIONS:
                 - if the source FIDs are 16-bit integer, the result will be
                   in 32-bit integer format
                 - if the "-float" argument or a fractional multiplier is
                   specified, the result will be in 32-bit floating point
                   ("float") format, irrespective of the format of the source
                   FIDs.
                "combine2d" checks whether the target is identical to one of
                the source files, and aborts, if necessary. The multiplier
                applies to "source2_fid". The default multiplier is -1.0,
                i.e., subtracting "source2_fid" from "source1_fid"); any real
                number is permitted (see above).
                Integer or floating point math will be applied, as appropriate
                (1.0 and -1.0 are recognized as integer multipliers).
                The C program "combine2d" does NOT deal with parameter and
                text files - it therefore is mandatory to create the target
                file ("*.fid" or an experiment file) first (usually done by
                copying one of the source files, or by calling "combine2d"
                through the associated macro).

                To recompile this program use
			cc -O -o ../bin/combine2d combine2d.c
	 	for a local installation use
			cc -O -o ~/bin/combine2d combine2d.c

   Revision history:
     1991-12-04 - r.kyburz, started
     2006-02-24 - r.kyburz, added MacOS X & Linux compatibility,
		  	support for floating point format
     2006-03-03 - r.kyburz, fixed size calculation bug
     2006-05-05 - r.kyburz, improved PC/Linux & MacOS X compatibility
     2008-07-08 - r.kyburz, line 251 avoids compiler warning under Solaris 8
*/

#include <stdio.h>
#include <stdlib.h>
#include <sys/utsname.h>


static char rev[] =     "combine2d.c 3.5";
static char revdate[] = "2010-11-06_19:56";


static char cmd[] = "combine2d";
static int  debug = 0;
static int  swap  = 0;


/*-----------------------------------------------------------------+
| swapbytes - Byte swapping for big-endian vs. little-endian issue |
+-----------------------------------------------------------------*/

void swapbytes(void *data, int size, int num)
{
  unsigned char *c, cs;
  int i, j;
  c = (unsigned char *) data;
  for (j = 0; j < num; j++)
  {
    for (i = 0; i < size/2; i++)
    {
      cs = c[size * j + i];
      c[size * j + i] = c[size * j + (size - (i + 1))];
      c[size * j + (size - (i + 1))] = cs;
    }
  }
}



/*--------------+
| ============= |
| MAIN FUNCTION |
| ============= |
+--------------*/

main (argc, argv)
  int argc;
  char *argv[];

{
  /* defining structures */
  struct fileHeader
  {
    int nblocks, ntraces, np, ebytes, tbytes, bbytes;
    short vers_id, status;
    int nblockheaders;
  };
  struct blockHeader
  {
    short scale, status, index, mode;
    int ctcount;
    float lpval, rpval, lvl, tlt;
  };
  struct icomplex
  {
    int p1, p2;
  };
  struct scomplex
  {
    short p1, p2;
  };
  struct fcomplex
  {
    float p1, p2;
  };
  struct dcomplex
  {
    double p1, p2;
  };

  /* defining variables */
  struct fileHeader s1fhd, s2fhd, tfhd;
  struct blockHeader s1bhd, s2bhd, tbhd;
  struct icomplex s1ipair, s2ipair;
  struct scomplex s1spair, s2spair;
  struct fcomplex s1fpair, s2fpair;
  struct dcomplex s1dpair, s2dpair;
  int i, j, ok, icalc, farg1, maxargc;
  int shift1 = 0, shift2 = 0;
  int expand = 0, tofloat = 0, floatfid = 0;
  register int iscale;
  register double rval1, rval2;
  double scale;
  char *s1name, *s2name, *tname;
  FILE *s1file, *s2file, *tfile;
  struct utsname *s_uname;



  /*-------------------+
  | checking arguments |
  +-------------------*/

  if (argc < 2)
  {
    (void) fprintf(stderr,
	"Usage:  %s source1 source2 target <multiplier>\n", cmd);
    exit(1);
  }

  i = 1;
  farg1 = 1;
  maxargc = 5;
  while ((i < argc) && (argv[i][0] == '-'))
  {
    /* -v / -version option prints version and exits, ignoring other args */
    if ((!strcasecmp(argv[i], "-v")) || (!strcasecmp(argv[i], "-version")))
    {
      (void) printf("%s (%s)\n", rev, revdate);
      exit(0);
    }

    if ((!strcasecmp(argv[i],"-debug")) || (!strcasecmp(argv[i],"-d")))
    {
      debug = 1;
      farg1++;
      maxargc++;
    }
    else if ((!strcasecmp(argv[i],"-f")) || (!strcasecmp(argv[i],"-float")))
    {
      expand = 1;
    }
    else if (argv[i][0] == '-')
    {
      (void) fprintf(stderr,
        "Usage:  %s source1 source2 target <multiplier>\n", cmd);
      return(1);
    }
    i++;
  }
  if ((argc > maxargc) || (argc < farg1 + 3))
  {
    fprintf(stderr,
	"Usage:  %s source1 source2 target <multiplier>\n", cmd);
    exit(1);
  }

  s1name = argv[farg1];
  s2name = argv[farg1 + 1];
  tname = argv[farg1 + 2];

  if (argc == maxargc)
  {
    ok = sscanf(argv[farg1 + 3], "%lf", &scale);
    iscale = (int) scale;
  }
  else
  {
    ok = 1;
    scale = -1.0;
    iscale = -1;
  }
  if (!ok)
  {
    fprintf(stderr,
	"%s:  argument #%d (optional) must be numeric\n", cmd, farg1 + 3);
    exit(1);
  }
  icalc = (scale == (double) iscale);
  if (!icalc)
    tofloat = 1;




  /*------------------------------------------------------+
  | check current system architecture (for byte swapping) |
  +------------------------------------------------------*/

  s_uname = (struct utsname *) malloc(sizeof(struct utsname));
  ok = uname(s_uname);
  if (ok >= 0)
  {
    if (debug)
    {
      (void) fprintf(stderr, "\nExtracted \"uname\" information:\n");
      (void) fprintf(stderr, "   s_uname->sysname:   %s\n", s_uname->sysname);
      (void) fprintf(stderr, "   s_uname->nodename:  %s\n", s_uname->nodename);
      (void) fprintf(stderr, "   s_uname->release:   %s\n", s_uname->release);
      (void) fprintf(stderr, "   s_uname->version:   %s\n", s_uname->version);
      (void) fprintf(stderr, "   s_uname->machine:   %s\n", s_uname->machine);
    }

    /* PC / Linux or Mac / Intel / MacOS X marchitecture */
    if ((char *) strstr(s_uname->machine, "86") != (char *) NULL)
    {
      if (debug)
      {
        (void) fprintf(stderr, "   Intel x86 architecture:");
      }
      swap = 1;
    }

    /* Sun / SPARC architecture */
    else if (!strncasecmp(s_uname->machine, "sun", 3))
    {
      if (debug)
      {
        (void) fprintf(stderr,
                "   \"%s\" (Sun SPARC) architecture:", s_uname->machine);
      }
      swap = 0;
    }

    /* PowerMac / MacOS X */
    else if (!strncasecmp(s_uname->machine, "power macintosh", 15))
    {
      if (debug)
      {
        (void) printf("   \"%s\" architecture (PowerPC / MacOS X):",
                s_uname->machine);
      }
      swap = 0;
    }

    /* OTHER ARCHITECTURES */
    else
    {
      if (debug)
      {
        (void) fprintf(stderr, "   \"%s\" architecture:", s_uname->machine);
      }
      swap = 1;
    }

    if (debug)
    {
      if (swap)
      {
        (void) fprintf(stderr, "  SWAPPING BYTES on Varian data\n");
      }
      else
      {
        (void) fprintf(stderr, "  NOT swapping bytes on Varian data\n");
      }
    }
  }
  else
  {
    (void) fprintf(stderr,
        "%s:  unable to determine system architecture, aborting.\n", cmd);
    exit(1);
  }



  /*-------------------------+
  | opening / checking files |
  +-------------------------*/

  /* open 2D source file #1 */
  s1file = fopen(s1name, "r");
  if (s1file == NULL)
  {
    fprintf(stderr, "%s: problem opening source file %s\n", cmd, s1name);
    fclose(s1file);
    exit(1);
  }

  /* open 2D source file #2 */
  s2file = fopen(s2name, "r");
  if (s2file == NULL)
  {
    fprintf(stderr, "%s: problem opening source file %s\n", cmd, s2name);
    fclose(s1file);
    fclose(s2file);
    exit(1);
  }

  /* open 2D target file and write file header */
  tfile = fopen(tname, "r+");
  if (tfile == NULL)
  {
    fprintf(stderr, "%s: problem opening target file %s\n", cmd, tname);
    fclose(s1file);
    fclose(s2file);
    fclose(tfile);
    exit(1);
  }

  /* make sure target file is not identical with one of the source files */
  if ((!strcmp(s1name,tname)) || (!strcmp(s2name,tname)))
  {
    fprintf(stderr,
	"%s: target file cannot be identical with one of the source files!\n",
	cmd);
    fclose(s1file);
    fclose(s2file);
    exit(1);
  }

  /* read source file headers */
  fread(&s1fhd, sizeof(s1fhd), 1, s1file);
  fread(&s2fhd, sizeof(s2fhd), 1, s2file);
  if (swap)
  {
    swapbytes(&s1fhd.nblocks,       sizeof(int),   1);
    swapbytes(&s1fhd.ntraces,       sizeof(int),   1);
    swapbytes(&s1fhd.np,            sizeof(int),   1);
    swapbytes(&s1fhd.ebytes,        sizeof(int),   1);
    swapbytes(&s1fhd.tbytes,        sizeof(int),   1);
    swapbytes(&s1fhd.bbytes,        sizeof(int),   1);
    swapbytes(&s1fhd.vers_id,       sizeof(short), 1);
    swapbytes(&s1fhd.status,        sizeof(short), 1);
    swapbytes(&s1fhd.nblockheaders, sizeof(int),   1);

    swapbytes(&s2fhd.nblocks,       sizeof(int),   1);
    swapbytes(&s2fhd.ntraces,       sizeof(int),   1);
    swapbytes(&s2fhd.np,            sizeof(int),   1);
    swapbytes(&s2fhd.ebytes,        sizeof(int),   1);
    swapbytes(&s2fhd.tbytes,        sizeof(int),   1);
    swapbytes(&s2fhd.bbytes,        sizeof(int),   1);
    swapbytes(&s2fhd.vers_id,       sizeof(short), 1);
    swapbytes(&s2fhd.status,        sizeof(short), 1);
    swapbytes(&s2fhd.nblockheaders, sizeof(int),   1);
  }


  /* check for source file compatibility */
  if ((s1fhd.nblocks       != s2fhd.nblocks) ||
      (s1fhd.ntraces       != s2fhd.ntraces) ||
      (s1fhd.np            != s2fhd.np) ||
      (s1fhd.ebytes        != s2fhd.ebytes) ||
      (s1fhd.tbytes        != s2fhd.tbytes) ||
      (s1fhd.bbytes        != s2fhd.bbytes) ||
/*    (s1fhd.vers_id       != s2fhd.vers_id) ||  */
      (s1fhd.status        != s2fhd.status) ||
      (s1fhd.nblockheaders != s2fhd.nblockheaders))
  {
    fprintf(stderr,
	"%s: the source files %s and %s are incompatible\n",
	cmd, s1name, s2name);
    fclose(s1file);
    fclose(s2file);
    exit(1);
  }

  tfhd.nblocks =       s1fhd.nblocks;
  tfhd.ntraces =       s1fhd.ntraces;
  tfhd.np =            s1fhd.np;
  tfhd.ebytes =        s1fhd.ebytes;
  tfhd.tbytes =        s1fhd.tbytes;
  tfhd.bbytes =        s1fhd.bbytes;
  tfhd.vers_id =       s1fhd.vers_id;
  tfhd.status =        s1fhd.status;
  tfhd.nblockheaders = s1fhd.nblockheaders;

  /* check for single precision or compressed data */
  if ((s1fhd.ebytes == 2) && ((s1fhd.status & 0x8) == 0))
  { 
    tfhd.ebytes = 4;
    tfhd.tbytes = tfhd.ebytes * tfhd.np;
    tfhd.bbytes = sizeof(tbhd) + tfhd.ntraces * tfhd.tbytes;
    printf("%s: target file expanded to double precision format\n", cmd);
    expand = 1;
  }
  if (tofloat)
  {
    tfhd.status |= 0x12;
    icalc = 0;
  }

  /* check for data structure (nblockheaders) */
  if (s1fhd.nblockheaders > 1)
  {
    fprintf(stderr, "%s does not work for 3D data!\n", cmd);
    fclose(s1file);
    fclose(s2file);
    exit(1);
  }


  /* report math type */
  if ((tfhd.status & 0x8) != 0)
  {
    printf("%s: using floating point math\n", cmd);
    tofloat = 1;
    icalc = 0;
  }
  else if (icalc)
    printf("%s: using integer math\n", cmd);
  else
    printf("%s: using double-precision floating point math\n", cmd);

  /* open 2D target file and write file header */
  tfile = fopen(tname, "w+");
  if (swap)
  {
    swapbytes(&tfhd.nblocks,       sizeof(int),   1);
    swapbytes(&tfhd.ntraces,       sizeof(int),   1);
    swapbytes(&tfhd.np,            sizeof(int),   1);
    swapbytes(&tfhd.ebytes,        sizeof(int),   1);
    swapbytes(&tfhd.tbytes,        sizeof(int),   1);
    swapbytes(&tfhd.bbytes,        sizeof(int),   1);
    swapbytes(&tfhd.vers_id,       sizeof(short), 1);
    swapbytes(&tfhd.status,        sizeof(short), 1);
    swapbytes(&tfhd.nblockheaders, sizeof(int),   1);
  }
  fwrite(&tfhd, sizeof(tfhd), 1, tfile);

  /* now combine equivalent traces and write the target file */
  for (i = 0; i < s2fhd.nblocks; i++)
  {
    /* read source (#1) block header */
    fread(&s1bhd, sizeof(s1bhd), 1, s1file);
    if (swap)
    {
      swapbytes(&s1bhd.scale,   sizeof(short), 1);
      swapbytes(&s1bhd.status,  sizeof(short), 1);
      swapbytes(&s1bhd.index,   sizeof(short), 1);
      swapbytes(&s1bhd.mode,    sizeof(short), 1);
      swapbytes(&s1bhd.ctcount, sizeof(int),   1);
      swapbytes(&s1bhd.lpval,   sizeof(float), 1);
      swapbytes(&s1bhd.rpval,   sizeof(float), 1);
      swapbytes(&s1bhd.lvl,     sizeof(float), 1);
      swapbytes(&s1bhd.tlt,     sizeof(float), 1);
    }
    tbhd.scale =   s1bhd.scale;
    tbhd.status =  s1bhd.status;
    tbhd.index =   s1bhd.index;
    tbhd.mode =    s1bhd.mode;
    tbhd.ctcount = s1bhd.ctcount;
    tbhd.lpval =   s1bhd.lpval;
    tbhd.rpval =   s1bhd.rpval;
    tbhd.lvl =     s1bhd.lvl;
    tbhd.tlt =     s1bhd.tlt;
    shift1 = s1bhd.scale;

    if (expand)
    {
      tbhd.status |= 0x4;
    }
    if (tofloat)
    {
      tbhd.status |= 0x8;
    }
    if (swap)
    {
      swapbytes(&tbhd.scale,   sizeof(short), 1);
      swapbytes(&tbhd.status,  sizeof(short), 1);
      swapbytes(&tbhd.index,   sizeof(short), 1);
      swapbytes(&tbhd.mode,    sizeof(short), 1);
      swapbytes(&tbhd.ctcount, sizeof(int),   1);
      swapbytes(&tbhd.lpval,   sizeof(float), 1);
      swapbytes(&tbhd.rpval,   sizeof(float), 1);
      swapbytes(&tbhd.lvl,     sizeof(float), 1);
      swapbytes(&tbhd.tlt,     sizeof(float), 1);
    }

    /* advance pointer in source file #2 */
    fread(&s2bhd, sizeof(s2bhd), 1, s2file);
    if (swap)
    {
      swapbytes(&s2bhd.scale, sizeof(short), 1);
    }
    shift2 = s2bhd.scale;

    /* write target block header */
    fwrite(&s1bhd, sizeof(s1bhd), 1, tfile);


    /* do the linear combination (operate in batches of complex pairs) */
    for (j = 0; j < s2fhd.np / 2; j++)
    {

      if ((s1fhd.status & 0x8) != 0)
      {
        fread(&s1fpair, sizeof(s1fpair), 1, s1file);
        fread(&s2fpair, sizeof(s2fpair), 1, s2file);
	if (swap)
	{
	  swapbytes(&s1fpair, sizeof(float), 2);
	  swapbytes(&s2fpair, sizeof(float), 2);
	}
	s1dpair.p1 = (double) s1fpair.p1;
	s1dpair.p2 = (double) s1fpair.p2;
	s2dpair.p1 = (double) s2fpair.p1;
	s2dpair.p2 = (double) s2fpair.p2;
      }
      else if (s1fhd.ebytes == 2)
      {
        fread(&s1spair, sizeof(s1spair), 1, s1file);
        fread(&s2spair, sizeof(s2spair), 1, s2file);
	if (swap)
	{
	  swapbytes(&s1spair, sizeof(short), 2);
	  swapbytes(&s2spair, sizeof(short), 2);
	}
	if ((tofloat) || (!icalc))
	{
	  s1dpair.p1 = (double) ((int) s1spair.p1 << shift1);
	  s1dpair.p2 = (double) ((int) s1spair.p2 << shift1);
	  s2dpair.p1 = (double) ((int) s2spair.p1 << shift2);
	  s2dpair.p2 = (double) ((int) s2spair.p2 << shift2);
	}
	else  /* data are expanded to 32-bit format anyway */
	{
	  s1ipair.p1 = (int) s1spair.p1 << shift1;
	  s1ipair.p2 = (int) s1spair.p2 << shift1;
	  s2ipair.p1 = (int) s2spair.p1 << shift2;
	  s2ipair.p2 = (int) s2spair.p2 << shift2;
	}
      }
      else
      {
        fread(&s1ipair, sizeof(s1ipair), 1, s1file);
        fread(&s2ipair, sizeof(s2ipair), 1, s2file);
	if (swap)
	{
	  swapbytes(&s1ipair, sizeof(int), 2);
	  swapbytes(&s2ipair, sizeof(int), 2);
	}
	if ((tofloat) || (!icalc))
	{
	  s1dpair.p1 = (double) ((long) s1ipair.p1 << shift1);
	  s1dpair.p2 = (double) ((long) s1ipair.p2 << shift1);
	  s2dpair.p1 = (double) ((long) s2ipair.p1 << shift2);
	  s2dpair.p2 = (double) ((long) s2ipair.p2 << shift2);
	}
	else
	{
	  /* scaling NOT applied for dp='y' integer format */
	  /*
	  s1ipair.p1 = (int) s1ipair.p1 << shift1;
	  s1ipair.p2 = (int) s1ipair.p2 << shift1;
	  s2ipair.p1 = (int) s2ipair.p1 << shift2;
	  s2ipair.p2 = (int) s2ipair.p2 << shift2;
          */
	}
      }

      
      if (icalc)
      {
	s2ipair.p1 *= iscale;
	s1ipair.p1 += s2ipair.p1;
	s2ipair.p2 *= iscale;
	s1ipair.p2 += s2ipair.p2;
        if (swap)
	  swapbytes(&s1ipair, sizeof(int), 2);
        fwrite(&s1ipair, sizeof(s1ipair), 1, tfile);
      }
      else
      {
	s2dpair.p1 *= scale;
	s1dpair.p1 += s2dpair.p1;
        s1fpair.p1 = (float) s1dpair.p1;
	s2dpair.p2 *= scale;
	s1dpair.p2 += s2dpair.p2;
        s1fpair.p2 = (float) s1dpair.p2;
        if (swap)
	  swapbytes(&s1fpair, sizeof(float), 2);
        fwrite(&s1fpair, sizeof(s1fpair), 1, tfile);
      }
    }
  }
  fclose(s1file);
  fclose(s2file);
  fclose(tfile);
  return(0);
}
