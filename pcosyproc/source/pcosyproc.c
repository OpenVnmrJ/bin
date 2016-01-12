/* pcosyproc - process P.COSY data */

/* syntax:   pcosyproc 2Dfid_file 1Dfid_file	*/

/*	pcosyproc subtracts np(2D) points of the 1D fid from each trace
	of the 2D fid; for every dwell time the subtraction vector is right-
	shifted by one pair of numbers within the 1D fid (i.e., the 1D
	fid is left-shifted by one complex point with every dwell time).
	If the 1D fid is shorter than np(2D)+ni points it is automatically
	zerofilled. The 1D fid is scaled to the same number of ct, in case
	the number of transients is different from the 2D spectrum.
	Note that the 2D fid is modified permanently by this program - it is
	the responsibility of the calling program to make a backup copy of
	the 2D data set.  pcosyproc generates a temporary file pcosyproc.tmp
	in /vnmr/tmp.

        Compilation for an installation in "/vnmr":
		cc -O -o ../bin/pcosyproc pcosyproc.c
        compilation for a local installation:
		cc -O -o ~/bin/pcosyproc pcosyproc.c

   Revision history:
     1991-12-03 - r.kyburz, started
     1991-12-09 - r.kyburz, first complete version
     1991-12-12 - r.kyburz, added scaling
     2006-02-24 - r.kyburz, added MacOS X & Linux compatibility
*/

#include <stdio.h>
#include <stdlib.h>
#include <sys/utsname.h>

static char rev[] =     "pcosyproc.c 3.5";
static char revdate[] = "2010-11-06_20:05";


static char cmd[] = "pcosyproc";
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

  /*------------+
  | Definitions |
  +------------*/

  /* defining structures */
  struct fileHeader
  {
    long nblocks, ntraces, np, ebytes, tbytes, bbytes;
    short vers_id, status;
    long nblockheaders;
  };
  struct blockHeader
  {
    short scale, status, index, mode;
    long ctcount;
    float lpval, rpval, lvl, tlt;
  };
  struct pair
  {
    int p1, p2;
  };

  /* defining variables */
  struct fileHeader fh1D, fh2D;
  struct blockHeader bh1D, bh2D;
  struct pair pair1D, pair2D;
  int i, j, k, ok, offset;
  register int sflag = 0;
  register double scale;
  char *name1D, *name2D, tmpname[256];
  FILE *file1D, *file2D, *tmpfile;
  struct utsname *s_uname;


  /*-------+
  | Checks |
  +-------*/

  if (argc >= 2)
  {
    if ((!strcasecmp(argv[1], "-v")) || (!strcasecmp(argv[1], "-version")))
    {
      (void) printf("%s (%s)\n", rev, revdate);
      exit(0);
    }
  }

  /* checking arguments */
  if (argc < 3)
  {
    fprintf(stderr, "Usage: pcosyproc 2Dfid 1Dfid\n");
    exit(1);
  }
  name2D = argv[1];
  name1D = argv[2];


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

  /* open 2D file and read file headers */
  file2D = fopen(name2D, "r+");
  if (file2D == NULL)
  {
    fprintf(stderr, "pcosyproc: problem opening file %s\n", name2D);
    fclose(file2D);
    exit(1);
  }
  fread(&fh2D, sizeof(fh2D), 1, file2D);
  fread(&bh2D, sizeof(bh2D), 1, file2D);
  if (swap)
  {
    swapbytes(&fh2D.nblocks,       sizeof(int),   1);
    swapbytes(&fh2D.ntraces,       sizeof(int),   1);
    swapbytes(&fh2D.np,            sizeof(int),   1);
    swapbytes(&fh2D.ebytes,        sizeof(int),   1);
    swapbytes(&fh2D.tbytes,        sizeof(int),   1);
    swapbytes(&fh2D.bbytes,        sizeof(int),   1);
    swapbytes(&fh2D.vers_id,       sizeof(short), 1);
    swapbytes(&fh2D.status,        sizeof(short), 1);
    swapbytes(&fh2D.nblockheaders, sizeof(int),   1);

    swapbytes(&bh2D.scale,         sizeof(short), 1);
    swapbytes(&bh2D.status,        sizeof(short), 1);
    swapbytes(&bh2D.index,         sizeof(short), 1);
    swapbytes(&bh2D.mode,          sizeof(short), 1);
    swapbytes(&bh2D.ctcount,       sizeof(int),   1);
    swapbytes(&bh2D.lpval,         sizeof(float), 1);
    swapbytes(&bh2D.rpval,         sizeof(float), 1);
    swapbytes(&bh2D.lvl,           sizeof(float), 1);
    swapbytes(&bh2D.tlt,           sizeof(float), 1);
  }

  /* open 1D file and read file headers */
  file1D = fopen(name1D, "r");
  if (file1D == NULL)
  {
    fprintf(stderr, "pcosyproc: problem opening file %s\n", name1D);
    fclose(file2D);
    fclose(file1D);
    exit(1);
  }
  fread(&fh1D, sizeof(fh1D), 1, file1D);
  fread(&bh1D, sizeof(bh1D), 1, file1D);
  if (swap)
  {
    swapbytes(&fh1D.nblocks,       sizeof(int),   1);
    swapbytes(&fh1D.ntraces,       sizeof(int),   1);
    swapbytes(&fh1D.np,            sizeof(int),   1);
    swapbytes(&fh1D.ebytes,        sizeof(int),   1);
    swapbytes(&fh1D.tbytes,        sizeof(int),   1);
    swapbytes(&fh1D.bbytes,        sizeof(int),   1);
    swapbytes(&fh1D.vers_id,       sizeof(short), 1);
    swapbytes(&fh1D.status,        sizeof(short), 1);
    swapbytes(&fh1D.nblockheaders, sizeof(int),   1);

    swapbytes(&bh1D.scale,         sizeof(short), 1);
    swapbytes(&bh1D.status,        sizeof(short), 1);
    swapbytes(&bh1D.index,         sizeof(short), 1);
    swapbytes(&bh1D.mode,          sizeof(short), 1);
    swapbytes(&bh1D.ctcount,       sizeof(int),   1);
    swapbytes(&bh1D.lpval,         sizeof(float), 1);
    swapbytes(&bh1D.rpval,         sizeof(float), 1);
    swapbytes(&bh1D.lvl,           sizeof(float), 1);
    swapbytes(&bh1D.tlt,           sizeof(float), 1);
  }

  /* try to open temporary file */
  tmpname[0] = '\0';
  strcpy(tmpname, "/vnmr/tmp/pcosyproc.tmp");
  tmpfile = fopen(tmpname, "w+");
  if (tmpfile == NULL)
  {
    fprintf(stderr, "pcosyproc: problem opening temporary file %s\n", tmpname);
    fclose(file2D);
    fclose(file1D);
    fclose(tmpfile);
    exit(1);
  }

  /* check for double precision data */
  if ((fh1D.ebytes != 4) || (fh2D.ebytes != 4))
  { 
    fprintf(stderr, "pcosyproc: double precision data required!\n");
    exit(1);
  }

  /* evaluate scaling factor */
  sflag = (bh1D.ctcount != bh2D.ctcount);
  scale = (double) bh1D.ctcount / (double) bh2D.ctcount;
  


  /*======================+
  ||  P.COSY processing  ||
  +======================*/

  /* now for each new increment subtract the relevant part of the 1D fid
     from the 2D trace (one complex point offset per dwell time) */
  k = 0; /* cycled through 0 .. array-1 */
  for (i = 0; i < fh2D.nblocks; i++)
  {

    /*-------------------------------+
    | calculate offset, set pointers |
    +-------------------------------*/
    /* calculate offset function */
    offset = i % fh1D.nblocks;
    offset = (i - offset) / fh1D.nblocks;
    offset *= 2;	/* shifting by complex numbers */
    
    /* set pointer in 1D file:
       skip file header, k blocks, block header and offset */
    fseek(file1D, sizeof(fh1D) + k * fh1D.bbytes +
		  sizeof(bh1D) + offset * fh2D.ebytes, 0);

    /* set pointer in 2D file:
       skip file header, i blocks and block header */
    fseek(file2D, sizeof(fh2D) + i * fh2D.bbytes + sizeof(bh2D), 0);

    /* set pointer in temporary file back to start */
    fseek(tmpfile, 0, 0);


    /*------------------------+
    | subtraction for one fid |
    +------------------------*/

    /* do the subtraction (operate in batches of complex pairs) */
    for (j = 0; j < fh2D.np / 2; j++)
    {
      fread(&pair2D, sizeof(pair2D), 1, file2D);
      if (swap)
        swapbytes(&pair2D, sizeof(int), 2);
      if (j * 2 + offset >= fh1D.np)
      {
	pair1D.p1 = 0;
	pair1D.p2 = 0;
      }
      else
      {
	fread(&pair1D, sizeof(pair1D), 1, file1D);
        if (swap)
          swapbytes(&pair1D, sizeof(int), 2);
      }
      if (sflag)	/* scale 1D fid, if ct is different from the 2D */
      {
        pair2D.p1 -= (int) (((double) pair1D.p1) / scale);
        pair2D.p2 -= (int) (((double) pair1D.p2) / scale);
      }
      else		/* no scaling required */
      {
        pair2D.p1 -= pair1D.p1;
        pair2D.p2 -= pair1D.p2;
      }
      if (swap)
        swapbytes(&pair2D, sizeof(int), 2);
      fwrite(&pair2D, sizeof(pair2D), 1, tmpfile);
    }


    /*---------------+
    | update 2D file |
    +---------------*/

    /* set pointer in temporary file back to start */
    fseek(tmpfile, 0, 0);

    /* reset pointer to the start of the current fid */
    fseek(file2D, sizeof(fh2D) + i * fh2D.bbytes + sizeof(bh2D), 0);

    /* transfer data from tmpfile to 2D fid */
    for (j = 0; j < fh2D.tbytes; j++)
      putc(getc(tmpfile),file2D);

    /* set (1D) array index */
    k++;
    if (k == fh1D.nblocks)
      k = 0;
  }

  /* close all files */
  fclose(file2D);
  fclose(file1D);
  fclose(tmpfile);
  return(0);
}
