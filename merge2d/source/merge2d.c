/* merge2d - merge two 2D files */
/*

Syntax:		merge2d fulldataset newdataset <start_increment>
                merge2d -v

Description:    merge2d copies the data part (not the headers) of a single or
		arrayed 1D fid ("newdataset") into a complete 2D fid
		("fulldataset"), starting at a given trace number
		("start_increment").

		Arguments:
		  - fulldataset, newdataset: fid files (*.fid/fid or
		    ~/vnmrsys/expn/acqfil/fid, NOT *.fid!)
		  - start_increment: trace number from which fid replace-
		    ment starts. Default: 1
		  - "-v" prints the version of the program and exits (no
		    action is performed, so other arguments are ignored).

		Note that "merge2d" permanently modifies a data set - it
		is advisable to keep backup of the original data.

Compilation:	cc -O -o /vnmr/bin/merge2d merge2d.c

Revision history:
  1989-11-17 - S.L.Patt, first version
  2006-03-04 - r.kyburz, added MacOS X and Linux compatibility
  2006-03-04 - r.kyburz, added MacOS X and Linux compatibility
  2008-07-08 - r.kyburz, enhanced PC/Linux architecture detection
*/

#include <stdio.h>
#include <stdlib.h>
#include <sys/utsname.h>

static char rev[] =     "merge2d.c 2.3";
static char revdate[] = "2010-11-06_20:05";


static char cmd[] = "merge2d";
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

main (argc,argv)
  int argc;
  char *argv[];

{
  /* defining structures and variables */
  struct fileHeader
  {
    int nblocks, ntraces, np,  ebytes, tbytes, bbytes;
    short vers_id, status;
    int nblockheaders;
  };
  struct blockHeader
  {
    short scale, status, index, mode;
    int ctcount;
    float lpval, rpval, lvl, tlt;
  };
  struct fileHeader shortheader, longheader;
  int i, j, ok, farg1, maxargc, offset = 1;
  char *shortfilename, *longfilename, arch[64];
  FILE *shortfile, *longfile;
  struct utsname *s_uname;




  /*-------------------+
  | checking arguments |
  +-------------------*/

  if (argc < 2)
  {
    (void) fprintf(stderr,
        "Usage:  %s <-d> fulldataset newdataset <start_increment>\n", cmd);
    exit(1);
  }

  i = 1;
  farg1 = 1;
  maxargc = 4;
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
    else if (argv[i][0] == '-')
    {
      (void) fprintf(stderr,
        "Usage:  %s <-d> fulldataset newdataset <start_increment>\n", cmd);
      return(1);
    }
    i++;
  }
  if ((argc > maxargc) || (argc < farg1 + 2))
  {
    fprintf(stderr,
        "Usage:  %s <-d> fulldataset newdataset <start_increment>\n", cmd);
    exit(1);
  }

  longfilename = argv[1];
  shortfilename = argv[2];
  if (argc == maxargc)
  {
    ok = sscanf(argv[3],"%d",&offset);
    if ((!ok) || (offset < 1))
    {
      (void) fprintf(stderr,
	"%s:  third argument must be a positive integer\n", cmd);
      exit(1);
    }
  }




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

  longfile = fopen(longfilename, "r+");
  if (longfile == NULL)
  {
    fprintf(stderr, "merge2d: problem opening file %s\n", longfilename);
    exit(1);
  }
  fread(&longheader, sizeof(longheader), 1, longfile);

  shortfile = fopen(shortfilename, "r+");
  if (shortfile == NULL)
  {
    fprintf(stderr, "merge2d: problem opening file %s\n", shortfilename);
    exit(1);
  }
  fread(&shortheader, sizeof(shortheader), 1, shortfile);

  if (swap)
  {
    swapbytes(&longheader.nblocks,        sizeof(int),   1);
    swapbytes(&longheader.ntraces,        sizeof(int),   1);
    swapbytes(&longheader.np,             sizeof(int),   1);
    swapbytes(&longheader.ebytes,         sizeof(int),   1);
    swapbytes(&longheader.tbytes,         sizeof(int),   1);
    swapbytes(&longheader.bbytes,         sizeof(int),   1);
    swapbytes(&longheader.vers_id,        sizeof(short), 1);
    swapbytes(&longheader.status,         sizeof(short), 1);
    swapbytes(&longheader.nblockheaders,  sizeof(int),   1);

    swapbytes(&shortheader.nblocks,       sizeof(int),   1);
    swapbytes(&shortheader.ntraces,       sizeof(int),   1);
    swapbytes(&shortheader.np,            sizeof(int),   1);
    swapbytes(&shortheader.ebytes,        sizeof(int),   1);
    swapbytes(&shortheader.tbytes,        sizeof(int),   1);
    swapbytes(&shortheader.bbytes,        sizeof(int),   1);
    swapbytes(&shortheader.vers_id,       sizeof(short), 1);
    swapbytes(&shortheader.status,        sizeof(short), 1);
    swapbytes(&shortheader.nblockheaders, sizeof(int),   1);
  }

  if (longheader.bbytes != shortheader.bbytes)
  {
    fprintf(stderr, "merge2d: FID sizes are not the same\n");
    fclose(shortfile);
    fclose(longfile);
    exit(1);
  }

  /* skip over first offset-1 files */
  fseek(longfile, (offset - 1)*longheader.bbytes, 1);

  /* now for each new increment copy it in */
  for (i = 0;
       (i < shortheader.nblocks) && (offset <= longheader.nblocks);
       i++, offset++)
  {
    /* use block headers from the original file */
    fseek(shortfile, sizeof(struct blockHeader), 1);
    fseek(longfile, sizeof(struct blockHeader), 1);
    for (j = 0; j < longheader.tbytes * longheader.ntraces; j++)
      putc(getc(shortfile),longfile);
  }

  /* and close both files */
  fclose(shortfile);
  fclose(longfile);
}
