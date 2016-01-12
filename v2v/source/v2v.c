/* v2v.c - Varian to Varian data converter
           converts Varian FID files to double precision integer, 
           single precision integer and floating point formats.
           
           Usage : v2v filename.fid -format
           -----
           where format is one of the following output options :
           d - double precision, 
           s - single precision, 
           f - floating point and
           r - restores the original data.
           The default output format is -d.
   Written by E. Kupce, 5th July 2002.
   2007-06-04 - R. Kyburz, expanded for byte swapping with Intel architectures
   2007-06-06 - E. Kupce, corrected to include scaling for floating point
		input data and restored the usage function.
   2007-06-07 - E. Kupce, fixed a bug
*/

#include <stdio.h>
#include <stdlib.h>
#include <sys/utsname.h>


static char rev[] =     "v2v.c 2.4";
static char revdate[] = "2010-11-06_20:10";


static char cmd[] = "v2v";
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

main(argc, argv)
int argc;
char *argv[];
{
  FILE *src, *trg;
  char fn1[1024], fn2[1024], df, of;
  int i, j, k, ok, verbose;
  short st;
  float max;
  void usage();

  /* defining data structures */
  struct fileheader
  {
    int  nblocks,		/* # of blocks in file, ni */
         ntraces,		/* # of traces per block, usually 1 */
         np,			/* # of points per trace */
         ebytes,		/* # of bytes per point, 2 - short, 4 - int */
         tbytes,		/* # of bytes per trace = np*ebytes */
         bbytes;		/* # of bytes per block = ntraces*tbytes +
				   nbheaders*sizeof(block header = 28)   */
    short vers_id,		/* software version & file id */
          status;		/* status of whole file */
    int  nbheaders;		/* # of block headers */
  };

  struct blockheader
  {
    short scale,		/* scaling factor */
          status,		/* status of data in block */
          iblock,		/* block index, ix */
          mode;			/* mode of data in block */
    int  ct;			/* ct counter value for fid */
    float lp,			/* left phase in f1 */
          rp,			/* right phase in f1 */
          lvl,			/* level drift correction */
          tlt;			/* tilt drift correction */
  };

  struct hyperbheader
  {
    short spare1,		/* spare */
          status,		/* status for block header */
          spare2,		/* spare */
          spare3;		/* spare */
    int  lspare;		/* spare */
    float lp,			/* left phase in f2 */
          rp,			/* right phase in f2 */
          fspare1,		/* spare */
          fspare2;		/* spare */
  };

  struct fileheader sfhd, sfhd2;
  struct blockheader sbhd, sbhd2;
  struct hyperbheader hbhd, hbhd2;
  struct utsname *s_uname;


  typedef struct		/* single precision data */
  {
    short int re, im;
  }
  SPFID;

  typedef struct		/* double precision data */
  {
    int  re, im;
  }
  DPFID;

  typedef struct		/* floating point data */
  {
    float re, im;
  }
  FPFID;

  SPFID sfid;
  FPFID ffid;
  DPFID dfid, *buf, **fid;

  if (argc < 2)
  {
    usage();
  }

  if ((argc > 1) && (!strcasecmp(argv[1], "-version")))
  {
    (void) printf("%s (%s)\n", rev, revdate);
    exit(0);
  }


  sprintf(fn1, "%s/fid", argv[1]);
  sprintf(fn2, "%s/fid.orig", argv[1]);

  if (argc < 3)
    of = 'd';

  else if (((argv[2][0] == '-') && (argv[2][1] == 'r'))
	   || (argv[2][1] == 'r'))
  {
    if (access(fn2, 0) != 0)
      printf("\nv2v: cannot access %s\n\n", fn2);
    else if (rename(fn2, fn1) != 0)
      printf("\nv2v: cannot rename %s\n\n", fn2);
    exit(0);
  }
  else if (((argv[2][0] == '-') && (argv[2][1] == 's'))
	   || (argv[2][1] == 's'))
    of = 's';
  else if (((argv[2][0] == '-') && (argv[2][1] == 'd'))
	   || (argv[2][1] == 'd'))
    of = 'd';
  else if (((argv[2][0] == '-') && (argv[2][1] == 'f'))
	   || (argv[2][1] == 'f'))
    of = 'f';
  else
    usage();

  if ((argc > 3) && ((argv[3][0] == '-') && (argv[3][1] == 'v')))
    verbose = 1;
  else
    verbose = 0;

  if (rename(fn1, fn2) != 0)
  {
    printf("\nv2v: cannot rename %s\n\n", fn1);
    exit(0);
  }

  if ((trg = fopen(fn1, "w")) == NULL)
  {
    printf("\nv2v: cannot open %s\n\n", fn1);
    exit(0);
  }

  if ((src = fopen(fn2, "r")) == NULL)	/* open 2D source file */
  {
    printf("\nv2v: cannot open %s\n\n", fn2);
    exit(0);
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


  /* read source file header */
  fread(&sfhd, sizeof(sfhd), 1, src);

  if (swap)
  {
    swapbytes(&sfhd.nblocks,   sizeof(int),   1);
    swapbytes(&sfhd.ntraces,   sizeof(int),   1);
    swapbytes(&sfhd.np,        sizeof(int),   1);
    swapbytes(&sfhd.ebytes,    sizeof(int),   1);
    swapbytes(&sfhd.tbytes,    sizeof(int),   1);
    swapbytes(&sfhd.bbytes,    sizeof(int),   1);
    swapbytes(&sfhd.vers_id,   sizeof(short), 1);
    swapbytes(&sfhd.status,    sizeof(short), 1);
    swapbytes(&sfhd.nbheaders, sizeof(int),   1);
  }

  if (verbose)
  {
    st = sfhd.status;
    if (st & 64)
      st = st ^ 64, st = st ^ 16;	/* align with Vnmr */
    printf("\nORIGINAL FID FILE HEADER: \n");
    printf(" status  = %8d,    nbheaders       = %8d\n", st, sfhd.nbheaders);
    printf(" nblocks = %8d     bytes per block = %8d\n", sfhd.nblocks,
	   sfhd.bbytes);
    printf(" ntraces = %8d     bytes per trace = %8d\n", sfhd.ntraces,
	   sfhd.tbytes);
    printf(" npoints = %8d     bytes per point = %8d\n", sfhd.np,
	   sfhd.ebytes);
    printf(" vers_id = %8d \n", sfhd.vers_id);
  }

  if ((sfhd.status & 1) == 0)
  {
    printf("\nData file appears to be empty. Abort\n\n");
    fclose(src);
    fclose(trg);
    if (rename(fn2, fn1) != 0)
      printf("\nv2v: cannot rename %s\n\n", fn2);
    exit(0);
  }

  if (sfhd.status & 8)
  {
    if (of == 'f')
    {
      printf("\nOutput and input formats are equal. File unchanged.\n\n");
      fclose(src);
      fclose(trg);
      if (rename(fn2, fn1) != 0)
	printf("\nv2v: cannot rename %s\n\n", fn2);
      exit(0);
    }
    else if (of == 'd')
    {
      df = 'F';			/* input fp output dp */
      if (!(sfhd.status & 4))
	sfhd.status = sfhd.status ^ 4;
    }
    else
    {
      df = 'f';			/* input fp output sp */
      if (sfhd.status & 4)
	sfhd.status = sfhd.status ^ 4;
      sfhd.ebytes = 2;
      sfhd.tbytes = sfhd.np * sfhd.ebytes;
      sfhd.bbytes = sfhd.ntraces * sfhd.tbytes;
      sfhd.bbytes += sfhd.nbheaders * sizeof(struct blockheader);
    }
    sfhd.status = sfhd.status ^ 8;
  }
  else
  {
    if (sfhd.status & 4)
    {
      if (of == 'd')
      {
	printf("\nOutput and input formats are equal. File unchanged.\n\n");
	fclose(src);
	fclose(trg);
	if (rename(fn2, fn1) != 0)
	  printf("\nv2v: cannot rename %s\n\n", fn2);
	exit(0);
      }
      else if (of == 'f')
      {
	df = 'D';		/* input dp output fp */
	sfhd.status = sfhd.status ^ 8;
	sfhd.status = sfhd.status ^ 4;	/* fix status */
      }
      else
      {
	df = 'd';		/* input dp output sp */
	sfhd.status = sfhd.status ^ 4;
	sfhd.ebytes = 2;
	sfhd.tbytes = sfhd.np * sfhd.ebytes;
	sfhd.bbytes = sfhd.ntraces * sfhd.tbytes;
	sfhd.bbytes += sfhd.nbheaders * sizeof(struct blockheader);
      }
    }
    else
    {
      if (of == 's')
      {
	printf("\nOutput and input formats are equal. File unchanged.\n\n");
	fclose(src);
	fclose(trg);
	if (rename(fn2, fn1) != 0)
	  printf("\nv2v: cannot rename %s\n\n", fn2);
	exit(0);
      }
      else if (of == 'f')
      {
	df = 'S';		/* input sp output fp */
	sfhd.status = sfhd.status ^ 8;
      }
      else
      {
	df = 's';		/* input sp output dp */
	sfhd.status = sfhd.status ^ 4;
      }

      sfhd.ebytes = 4;
      sfhd.tbytes = sfhd.np * sfhd.ebytes;
      sfhd.bbytes = sfhd.ntraces * sfhd.tbytes;
      sfhd.bbytes += sfhd.nbheaders * sizeof(struct blockheader);
    }
  }

  if (swap)
  {
    swapbytes(&sfhd.nblocks,   sizeof(int),   1);
    swapbytes(&sfhd.ntraces,   sizeof(int),   1);
    swapbytes(&sfhd.np,        sizeof(int),   1);
    swapbytes(&sfhd.ebytes,    sizeof(int),   1);
    swapbytes(&sfhd.tbytes,    sizeof(int),   1);
    swapbytes(&sfhd.bbytes,    sizeof(int),   1);
    swapbytes(&sfhd.vers_id,   sizeof(short), 1);
    swapbytes(&sfhd.status,    sizeof(short), 1);
    swapbytes(&sfhd.nbheaders, sizeof(int),   1);
  }
  fwrite(&sfhd, sizeof(sfhd), 1, trg);
  if (swap)
  {
    swapbytes(&sfhd.nblocks,   sizeof(int),   1);
    swapbytes(&sfhd.ntraces,   sizeof(int),   1);
    swapbytes(&sfhd.np,        sizeof(int),   1);
    swapbytes(&sfhd.ebytes,    sizeof(int),   1);
    swapbytes(&sfhd.tbytes,    sizeof(int),   1);
    swapbytes(&sfhd.bbytes,    sizeof(int),   1);
    swapbytes(&sfhd.vers_id,   sizeof(short), 1);
    swapbytes(&sfhd.status,    sizeof(short), 1);
    swapbytes(&sfhd.nbheaders, sizeof(int),   1);
  }

  if (verbose)
  {
    st = sfhd.status;
    if (st & 64)
      st = st ^ 64, st = st ^ 16;	/* align with Vnmr */
    printf("\nOUTPUT FID FILE HEADER: \n");
    printf(" status  = %8d,    nbheaders       = %8d\n", st, sfhd.nbheaders);
    printf(" nblocks = %8d     bytes per block = %8d\n", sfhd.nblocks,
	   sfhd.bbytes);
    printf(" ntraces = %8d     bytes per trace = %8d\n", sfhd.ntraces,
	   sfhd.tbytes);
    printf(" npoints = %8d     bytes per point = %8d\n", sfhd.np,
	   sfhd.ebytes);
    printf(" vers_id = %8d \n", sfhd.vers_id);
  }

  switch (df)
  {
	  case 'd':		/* input dp output sp */

	    for (i = 0; i < sfhd.nblocks; i++)
	    {
	      printf("blocks processed\r%-4d ", i + 1);
	      fread(&sbhd, sizeof(sbhd), 1, src);
              if (swap)
              {
                swapbytes(&sbhd.scale,  sizeof(short), 1);
                swapbytes(&sbhd.status, sizeof(short), 1);
                swapbytes(&sbhd.iblock, sizeof(short), 1);
                swapbytes(&sbhd.mode,   sizeof(short), 1);
                swapbytes(&sbhd.ct,     sizeof(int),   1);
                swapbytes(&sbhd.lp,     sizeof(float), 1);
                swapbytes(&sbhd.rp,     sizeof(float), 1);
                swapbytes(&sbhd.lvl,    sizeof(float), 1);
                swapbytes(&sbhd.tlt,    sizeof(float), 1);
              }
	      sbhd.status = sbhd.status ^ 4;	/* fix status */
              if (swap)
              {
                swapbytes(&sbhd.scale,  sizeof(short), 1);
                swapbytes(&sbhd.status, sizeof(short), 1);
                swapbytes(&sbhd.iblock, sizeof(short), 1);
                swapbytes(&sbhd.mode,   sizeof(short), 1);
                swapbytes(&sbhd.ct,     sizeof(int),   1);
                swapbytes(&sbhd.lp,     sizeof(float), 1);
                swapbytes(&sbhd.rp,     sizeof(float), 1);
                swapbytes(&sbhd.lvl,    sizeof(float), 1);
                swapbytes(&sbhd.tlt,    sizeof(float), 1);
              }
	      fwrite(&sbhd, sizeof(sbhd), 1, trg);
	      if (sfhd.nbheaders > 1)
	      {
		fread(&hbhd, sizeof(hbhd), 1, src);
                if (swap)
                {
                  swapbytes(&hbhd.spare1,  sizeof(short), 1);
                  swapbytes(&hbhd.status,  sizeof(short), 1);
                  swapbytes(&hbhd.spare2,  sizeof(short), 1);
                  swapbytes(&hbhd.spare3,  sizeof(short), 1);
                  swapbytes(&hbhd.lspare,  sizeof(int),   1);
                  swapbytes(&hbhd.lp,      sizeof(float), 1);
                  swapbytes(&hbhd.rp,      sizeof(float), 1);
                  swapbytes(&hbhd.fspare1, sizeof(float), 1);
                  swapbytes(&hbhd.fspare2, sizeof(float), 1);
                }
		hbhd.status = hbhd.status ^ 4;
                if (swap)
                {
                  swapbytes(&hbhd.spare1,  sizeof(short), 1);
                  swapbytes(&hbhd.status,  sizeof(short), 1);
                  swapbytes(&hbhd.spare2,  sizeof(short), 1);
                  swapbytes(&hbhd.spare3,  sizeof(short), 1);
                  swapbytes(&hbhd.lspare,  sizeof(int),   1);
                  swapbytes(&hbhd.lp,      sizeof(float), 1);
                  swapbytes(&hbhd.rp,      sizeof(float), 1);
                  swapbytes(&hbhd.fspare1, sizeof(float), 1);
                  swapbytes(&hbhd.fspare2, sizeof(float), 1);
                }
		fwrite(&hbhd, sizeof(hbhd), 1, trg);
	      }
	      for (k = 0; k < sfhd.ntraces; k++)
	      {
		for (j = 0; j < sfhd.np / 2; j++)	/* read dp-FID */
		{
		  fread(&dfid, sizeof(DPFID), 1, src);
		  if (swap)
                  {
                    swapbytes(&dfid.re,  sizeof(int), 1);
                    swapbytes(&dfid.im,  sizeof(int), 1);
		  }
		  sfid.re = (short) dfid.re;	/* dp to sp convert */
		  sfid.im = (short) dfid.im;	/* ideally would need scaling */
		  if (swap)
                  {
                    swapbytes(&sfid.re,  sizeof(short), 1);
                    swapbytes(&sfid.im,  sizeof(short), 1);
		  }
		  fwrite(&sfid, sizeof(SPFID), 1, trg);
		}
	      }
	    }
	    printf("blocks processed");
	    break;

	  case 'D':		/* input dp output fp */
	    for (i = 0; i < sfhd.nblocks; i++)
	    {
	      printf("blocks processed\r%-4d ", i + 1);
	      fread(&sbhd, sizeof(sbhd), 1, src);
              if (swap)
              {
                swapbytes(&sbhd.scale,  sizeof(short), 1);
                swapbytes(&sbhd.status, sizeof(short), 1);
                swapbytes(&sbhd.iblock, sizeof(short), 1);
                swapbytes(&sbhd.mode,   sizeof(short), 1);
                swapbytes(&sbhd.ct,     sizeof(int),   1);
                swapbytes(&sbhd.lp,     sizeof(float), 1);
                swapbytes(&sbhd.rp,     sizeof(float), 1);
                swapbytes(&sbhd.lvl,    sizeof(float), 1);
                swapbytes(&sbhd.tlt,    sizeof(float), 1);
              }
	      sbhd.status = sbhd.status ^ 8;	/* fix status */
	      sbhd.status = sbhd.status ^ 4;
              if (swap)
              {
                swapbytes(&sbhd.scale,  sizeof(short), 1);
                swapbytes(&sbhd.status, sizeof(short), 1);
                swapbytes(&sbhd.iblock, sizeof(short), 1);
                swapbytes(&sbhd.mode,   sizeof(short), 1);
                swapbytes(&sbhd.ct,     sizeof(int),   1);
                swapbytes(&sbhd.lp,     sizeof(float), 1);
                swapbytes(&sbhd.rp,     sizeof(float), 1);
                swapbytes(&sbhd.lvl,    sizeof(float), 1);
                swapbytes(&sbhd.tlt,    sizeof(float), 1);
              }
	      fwrite(&sbhd, sizeof(sbhd), 1, trg);
	      if (sfhd.nbheaders > 1)
	      {
		fread(&hbhd, sizeof(hbhd), 1, src);
                if (swap)
                {
                  swapbytes(&hbhd.spare1,  sizeof(short), 1);
                  swapbytes(&hbhd.status,  sizeof(short), 1);
                  swapbytes(&hbhd.spare2,  sizeof(short), 1);
                  swapbytes(&hbhd.spare3,  sizeof(short), 1);
                  swapbytes(&hbhd.lspare,  sizeof(int),   1);
                  swapbytes(&hbhd.lp,      sizeof(float), 1);
                  swapbytes(&hbhd.rp,      sizeof(float), 1);
                  swapbytes(&hbhd.fspare1, sizeof(float), 1);
                  swapbytes(&hbhd.fspare2, sizeof(float), 1);
                }
		hbhd.status = hbhd.status ^ 8;
		hbhd.status = hbhd.status ^ 4;
                if (swap)
                {
                  swapbytes(&hbhd.spare1,  sizeof(short), 1);
                  swapbytes(&hbhd.status,  sizeof(short), 1);
                  swapbytes(&hbhd.spare2,  sizeof(short), 1);
                  swapbytes(&hbhd.spare3,  sizeof(short), 1);
                  swapbytes(&hbhd.lspare,  sizeof(int),   1);
                  swapbytes(&hbhd.lp,      sizeof(float), 1);
                  swapbytes(&hbhd.rp,      sizeof(float), 1);
                  swapbytes(&hbhd.fspare1, sizeof(float), 1);
                  swapbytes(&hbhd.fspare2, sizeof(float), 1);
                }
		fwrite(&hbhd, sizeof(hbhd), 1, trg);
	      }
	      for (k = 0; k < sfhd.ntraces; k++)
	      {
		for (j = 0; j < sfhd.np / 2; j++)	/* read dp-FID */
		{
		  fread(&dfid, sizeof(DPFID), 1, src);
		  if (swap)
                  {
                    swapbytes(&dfid.re,  sizeof(int), 1);
                    swapbytes(&dfid.im,  sizeof(int), 1);
		  }
		  ffid.re = (float) dfid.re;	/* dp to fp convert */
		  ffid.im = (float) dfid.im;
		  if (swap)
                  {
                    swapbytes(&ffid.re,  sizeof(float), 1);
                    swapbytes(&ffid.im,  sizeof(float), 1);
		  }
		  fwrite(&ffid, sizeof(FPFID), 1, trg);
		}
	      }
	    }
	    printf("blocks processed");
	    break;

	  case 's':		/* input sp output dp */
	    for (i = 0; i < sfhd.nblocks; i++)
	    {
	      printf("blocks processed\r%-4d ", i + 1);
	      fread(&sbhd, sizeof(sbhd), 1, src);
              if (swap)
              {
                swapbytes(&sbhd.scale,  sizeof(short), 1);
                swapbytes(&sbhd.status, sizeof(short), 1);
                swapbytes(&sbhd.iblock, sizeof(short), 1);
                swapbytes(&sbhd.mode,   sizeof(short), 1);
                swapbytes(&sbhd.ct,     sizeof(int),   1);
                swapbytes(&sbhd.lp,     sizeof(float), 1);
                swapbytes(&sbhd.rp,     sizeof(float), 1);
                swapbytes(&sbhd.lvl,    sizeof(float), 1);
                swapbytes(&sbhd.tlt,    sizeof(float), 1);
              }
	      sbhd.status = sbhd.status ^ 4;	/* fix status */
              if (swap)
              {
                swapbytes(&sbhd.scale,  sizeof(short), 1);
                swapbytes(&sbhd.status, sizeof(short), 1);
                swapbytes(&sbhd.iblock, sizeof(short), 1);
                swapbytes(&sbhd.mode,   sizeof(short), 1);
                swapbytes(&sbhd.ct,     sizeof(int),   1);
                swapbytes(&sbhd.lp,     sizeof(float), 1);
                swapbytes(&sbhd.rp,     sizeof(float), 1);
                swapbytes(&sbhd.lvl,    sizeof(float), 1);
                swapbytes(&sbhd.tlt,    sizeof(float), 1);
              }
	      fwrite(&sbhd, sizeof(sbhd), 1, trg);
	      if (sfhd.nbheaders > 1)
	      {
		fread(&hbhd, sizeof(hbhd), 1, src);
                if (swap)
                {
                  swapbytes(&hbhd.spare1,  sizeof(short), 1);
                  swapbytes(&hbhd.status,  sizeof(short), 1);
                  swapbytes(&hbhd.spare2,  sizeof(short), 1);
                  swapbytes(&hbhd.spare3,  sizeof(short), 1);
                  swapbytes(&hbhd.lspare,  sizeof(int),   1);
                  swapbytes(&hbhd.lp,      sizeof(float), 1);
                  swapbytes(&hbhd.rp,      sizeof(float), 1);
                  swapbytes(&hbhd.fspare1, sizeof(float), 1);
                  swapbytes(&hbhd.fspare2, sizeof(float), 1);
                }
		hbhd.status = hbhd.status ^ 4;
                if (swap)
                {
                  swapbytes(&hbhd.spare1,  sizeof(short), 1);
                  swapbytes(&hbhd.status,  sizeof(short), 1);
                  swapbytes(&hbhd.spare2,  sizeof(short), 1);
                  swapbytes(&hbhd.spare3,  sizeof(short), 1);
                  swapbytes(&hbhd.lspare,  sizeof(int),   1);
                  swapbytes(&hbhd.lp,      sizeof(float), 1);
                  swapbytes(&hbhd.rp,      sizeof(float), 1);
                  swapbytes(&hbhd.fspare1, sizeof(float), 1);
                  swapbytes(&hbhd.fspare2, sizeof(float), 1);
                }
		fwrite(&hbhd, sizeof(hbhd), 1, trg);
	      }
	      for (k = 0; k < sfhd.ntraces; k++)
	      {
		for (j = 0; j < sfhd.np / 2; j++)	/* read sp-FID */
		{
		  fread(&sfid, sizeof(SPFID), 1, src);
		  if (swap)
                  {
                    swapbytes(&sfid.re,  sizeof(short), 1);
                    swapbytes(&sfid.im,  sizeof(short), 1);
		  }
		  dfid.re = (int) sfid.re;	/* sp to dp convert */
		  dfid.im = (int) sfid.im;
		  if (swap)
                  {
                    swapbytes(&dfid.re,  sizeof(int), 1);
                    swapbytes(&dfid.im,  sizeof(int), 1);
		  }
		  fwrite(&dfid, sizeof(DPFID), 1, trg);
		}
	      }
	    }
	    printf("blocks processed");
	    break;

	  case 'S':		/* input sp output fp */
	    for (i = 0; i < sfhd.nblocks; i++)
	    {
	      printf("blocks processed\r%-4d ", i + 1);
	      fread(&sbhd, sizeof(sbhd), 1, src);
              if (swap)
              {
                swapbytes(&sbhd.scale,  sizeof(short), 1);
                swapbytes(&sbhd.status, sizeof(short), 1);
                swapbytes(&sbhd.iblock, sizeof(short), 1);
                swapbytes(&sbhd.mode,   sizeof(short), 1);
                swapbytes(&sbhd.ct,     sizeof(int),   1);
                swapbytes(&sbhd.lp,     sizeof(float), 1);
                swapbytes(&sbhd.rp,     sizeof(float), 1);
                swapbytes(&sbhd.lvl,    sizeof(float), 1);
                swapbytes(&sbhd.tlt,    sizeof(float), 1);
              }
	      sbhd.status = sbhd.status ^ 8;	/* fix status */
              if (swap)
              {
                swapbytes(&sbhd.scale,  sizeof(short), 1);
                swapbytes(&sbhd.status, sizeof(short), 1);
                swapbytes(&sbhd.iblock, sizeof(short), 1);
                swapbytes(&sbhd.mode,   sizeof(short), 1);
                swapbytes(&sbhd.ct,     sizeof(int),   1);
                swapbytes(&sbhd.lp,     sizeof(float), 1);
                swapbytes(&sbhd.rp,     sizeof(float), 1);
                swapbytes(&sbhd.lvl,    sizeof(float), 1);
                swapbytes(&sbhd.tlt,    sizeof(float), 1);
              }
	      fwrite(&sbhd, sizeof(sbhd), 1, trg);
	      if (sfhd.nbheaders > 1)
	      {
		fread(&hbhd, sizeof(hbhd), 1, src);
                if (swap)
                {
                  swapbytes(&hbhd.spare1,  sizeof(short), 1);
                  swapbytes(&hbhd.status,  sizeof(short), 1);
                  swapbytes(&hbhd.spare2,  sizeof(short), 1);
                  swapbytes(&hbhd.spare3,  sizeof(short), 1);
                  swapbytes(&hbhd.lspare,  sizeof(int),   1);
                  swapbytes(&hbhd.lp,      sizeof(float), 1);
                  swapbytes(&hbhd.rp,      sizeof(float), 1);
                  swapbytes(&hbhd.fspare1, sizeof(float), 1);
                  swapbytes(&hbhd.fspare2, sizeof(float), 1);
                }
		hbhd.status = hbhd.status ^ 8;
                if (swap)
                {
                  swapbytes(&hbhd.spare1,  sizeof(short), 1);
                  swapbytes(&hbhd.status,  sizeof(short), 1);
                  swapbytes(&hbhd.spare2,  sizeof(short), 1);
                  swapbytes(&hbhd.spare3,  sizeof(short), 1);
                  swapbytes(&hbhd.lspare,  sizeof(int),   1);
                  swapbytes(&hbhd.lp,      sizeof(float), 1);
                  swapbytes(&hbhd.rp,      sizeof(float), 1);
                  swapbytes(&hbhd.fspare1, sizeof(float), 1);
                  swapbytes(&hbhd.fspare2, sizeof(float), 1);
                }
		fwrite(&hbhd, sizeof(hbhd), 1, trg);
	      }
	      for (k = 0; k < sfhd.ntraces; k++)
	      {
		for (j = 0; j < sfhd.np / 2; j++)	/* read sp-FID */
		{
		  fread(&sfid, sizeof(SPFID), 1, src);
		  if (swap)
                  {
                    swapbytes(&sfid.re,  sizeof(short), 1);
                    swapbytes(&sfid.im,  sizeof(short), 1);
		  }
		  ffid.re = (float) sfid.re;	/* sp to fp convert */
		  ffid.im = (float) sfid.im;
		  if (swap)
                  {
                    swapbytes(&ffid.re,  sizeof(float), 1);
                    swapbytes(&ffid.im,  sizeof(float), 1);
		  }
		  fwrite(&ffid, sizeof(FPFID), 1, trg);
		}
	      }
	    }
	    printf("blocks processed");
	    break;

	  case 'f':		/* input fp output sp */
	  
            max = 0.0;
	    printf("checking data... ");
	    	    
	    for (i = 0; i < sfhd.nblocks; i++)
	    {
	      fread(&sbhd, sizeof(sbhd), 1, src);
	      if (sfhd.nbheaders > 1)
		fread(&hbhd, sizeof(hbhd), 1, src);
	    
	      for (k = 0; k < sfhd.ntraces; k++)
	      {
		for (j = 0; j < sfhd.np / 2; j++)	
		{
		  fread(&ffid, sizeof(FPFID), 1, src);
		  if (swap)
                  {
                    swapbytes(&ffid.re,  sizeof(float), 1);
                    swapbytes(&ffid.im,  sizeof(float), 1);
		  }
		  ffid.re = (ffid.re > 0.0) ? ffid.re : -ffid.re;
		  ffid.im = (ffid.im > 0.0) ? ffid.im : -ffid.im;
		  max = (max > ffid.re) ? max : ffid.re;
		  max = (max > ffid.im) ? max : ffid.im;
		}
	      }
	    }
	    printf("\n");
	    if (verbose) printf("maxval = %d\n", max);
	    max = 32000.0/max;

            fseek(src,0,0);
            fread(&sfhd2, sizeof(sfhd), 1, src);
	  	  
	    for (i = 0; i < sfhd.nblocks; i++)
	    {
	      printf("blocks processed\r%-4d ", i + 1);
	      fread(&sbhd, sizeof(sbhd), 1, src);
              if (swap)
              {
                swapbytes(&sbhd.scale,  sizeof(short), 1);
                swapbytes(&sbhd.status, sizeof(short), 1);
                swapbytes(&sbhd.iblock, sizeof(short), 1);
                swapbytes(&sbhd.mode,   sizeof(short), 1);
                swapbytes(&sbhd.ct,     sizeof(int),   1);
                swapbytes(&sbhd.lp,     sizeof(float), 1);
                swapbytes(&sbhd.rp,     sizeof(float), 1);
                swapbytes(&sbhd.lvl,    sizeof(float), 1);
                swapbytes(&sbhd.tlt,    sizeof(float), 1);
              }
	      sbhd.status = sbhd.status ^ 8;	/* fix status */
	      if (sbhd.status & 4)
		sbhd.status = sbhd.status ^ 4;
              if (swap)
              {
                swapbytes(&sbhd.scale,  sizeof(short), 1);
                swapbytes(&sbhd.status, sizeof(short), 1);
                swapbytes(&sbhd.iblock, sizeof(short), 1);
                swapbytes(&sbhd.mode,   sizeof(short), 1);
                swapbytes(&sbhd.ct,     sizeof(int),   1);
                swapbytes(&sbhd.lp,     sizeof(float), 1);
                swapbytes(&sbhd.rp,     sizeof(float), 1);
                swapbytes(&sbhd.lvl,    sizeof(float), 1);
                swapbytes(&sbhd.tlt,    sizeof(float), 1);
              }
	      fwrite(&sbhd, sizeof(sbhd), 1, trg);
	      if (sfhd.nbheaders > 1)
	      {
		fread(&hbhd, sizeof(hbhd), 1, src);
                if (swap)
                {
                  swapbytes(&hbhd.spare1,  sizeof(short), 1);
                  swapbytes(&hbhd.status,  sizeof(short), 1);
                  swapbytes(&hbhd.spare2,  sizeof(short), 1);
                  swapbytes(&hbhd.spare3,  sizeof(short), 1);
                  swapbytes(&hbhd.lspare,  sizeof(int),   1);
                  swapbytes(&hbhd.lp,      sizeof(float), 1);
                  swapbytes(&hbhd.rp,      sizeof(float), 1);
                  swapbytes(&hbhd.fspare1, sizeof(float), 1);
                  swapbytes(&hbhd.fspare2, sizeof(float), 1);
                }
		hbhd.status = hbhd.status ^ 8;	/* fix status */
		if (hbhd.status & 4)
		  hbhd.status = hbhd.status ^ 4;
                if (swap)
                {
                  swapbytes(&hbhd.spare1,  sizeof(short), 1);
                  swapbytes(&hbhd.status,  sizeof(short), 1);
                  swapbytes(&hbhd.spare2,  sizeof(short), 1);
                  swapbytes(&hbhd.spare3,  sizeof(short), 1);
                  swapbytes(&hbhd.lspare,  sizeof(int),   1);
                  swapbytes(&hbhd.lp,      sizeof(float), 1);
                  swapbytes(&hbhd.rp,      sizeof(float), 1);
                  swapbytes(&hbhd.fspare1, sizeof(float), 1);
                  swapbytes(&hbhd.fspare2, sizeof(float), 1);
                }
		fwrite(&hbhd, sizeof(hbhd), 1, trg);
	      }
	      for (k = 0; k < sfhd.ntraces; k++)
	      {
		for (j = 0; j < sfhd.np / 2; j++)	/* read dp-FID */
		{
		  fread(&ffid, sizeof(FPFID), 1, src);
		  if (swap)
                  {
                    swapbytes(&ffid.re,  sizeof(float), 1);
                    swapbytes(&ffid.im,  sizeof(float), 1);
		  }
		  sfid.re = (short) (max*ffid.re);	/* dp to sp convert */
		  sfid.im = (short) (max*ffid.im);	
		  if (swap)
                  {
                    swapbytes(&sfid.re,  sizeof(short), 1);
                    swapbytes(&sfid.im,  sizeof(short), 1);
		  }
		  fwrite(&sfid, sizeof(SPFID), 1, trg);
		}
	      }
	    }
	    printf("blocks processed");
	    break;

	  case 'F':		/* input fp output dp */
	  
            max = 0.0;
	    printf("checking data... ");
	    	    
	    for (i = 0; i < sfhd.nblocks; i++)
	    {
	      fread(&sbhd, sizeof(sbhd), 1, src);
	      if (sfhd.nbheaders > 1)
		fread(&hbhd, sizeof(hbhd), 1, src);
	    
	      for (k = 0; k < sfhd.ntraces; k++)
	      {
		for (j = 0; j < sfhd.np / 2; j++)	/* read dp-FID */
		{
		  fread(&ffid, sizeof(FPFID), 1, src);
		  if (swap)
                  {
                    swapbytes(&ffid.re,  sizeof(float), 1);
                    swapbytes(&ffid.im,  sizeof(float), 1);
		  }
		  ffid.re = (ffid.re > 0.0) ? ffid.re : -ffid.re;
		  ffid.im = (ffid.im > 0.0) ? ffid.im : -ffid.im;
		  max = (max > ffid.re) ? max : ffid.re;
		  max = (max > ffid.im) ? max : ffid.im;
		}
	      }
	    }
	    printf("\n");
	    if (verbose) printf("maxval = %d\n", max);
	    max = 32000.0/max;

            fseek(src,0,0);
            fread(&sfhd2, sizeof(sfhd), 1, src);
	  
	    for (i = 0; i < sfhd.nblocks; i++)
	    {
	      printf("blocks processed\r%-4d ", i + 1);
	      fread(&sbhd, sizeof(sbhd), 1, src);
              if (swap)
              {
                swapbytes(&sbhd.scale,  sizeof(short), 1);
                swapbytes(&sbhd.status, sizeof(short), 1);
                swapbytes(&sbhd.iblock, sizeof(short), 1);
                swapbytes(&sbhd.mode,   sizeof(short), 1);
                swapbytes(&sbhd.ct,     sizeof(int),   1);
                swapbytes(&sbhd.lp,     sizeof(float), 1);
                swapbytes(&sbhd.rp,     sizeof(float), 1);
                swapbytes(&sbhd.lvl,    sizeof(float), 1);
                swapbytes(&sbhd.tlt,    sizeof(float), 1);
              }
	      sbhd.status = sbhd.status ^ 8;
	      if (!(sbhd.status & 4))
		sbhd.status = sbhd.status ^ 4;	/* fix status */
              if (swap)
              {
                swapbytes(&sbhd.scale,  sizeof(short), 1);
                swapbytes(&sbhd.status, sizeof(short), 1);
                swapbytes(&sbhd.iblock, sizeof(short), 1);
                swapbytes(&sbhd.mode,   sizeof(short), 1);
                swapbytes(&sbhd.ct,     sizeof(int),   1);
                swapbytes(&sbhd.lp,     sizeof(float), 1);
                swapbytes(&sbhd.rp,     sizeof(float), 1);
                swapbytes(&sbhd.lvl,    sizeof(float), 1);
                swapbytes(&sbhd.tlt,    sizeof(float), 1);
              }
	      fwrite(&sbhd, sizeof(sbhd), 1, trg);
	      if (sfhd.nbheaders > 1)
	      {
		fread(&hbhd, sizeof(hbhd), 1, src);
                if (swap)
                {
                  swapbytes(&hbhd.spare1,  sizeof(short), 1);
                  swapbytes(&hbhd.status,  sizeof(short), 1);
                  swapbytes(&hbhd.spare2,  sizeof(short), 1);
                  swapbytes(&hbhd.spare3,  sizeof(short), 1);
                  swapbytes(&hbhd.lspare,  sizeof(int),   1);
                  swapbytes(&hbhd.lp,      sizeof(float), 1);
                  swapbytes(&hbhd.rp,      sizeof(float), 1);
                  swapbytes(&hbhd.fspare1, sizeof(float), 1);
                  swapbytes(&hbhd.fspare2, sizeof(float), 1);
                }
		hbhd.status = hbhd.status ^ 8;
		if (!(hbhd.status & 4))
		  hbhd.status = hbhd.status ^ 4;
                if (swap)
                {
                  swapbytes(&hbhd.spare1,  sizeof(short), 1);
                  swapbytes(&hbhd.status,  sizeof(short), 1);
                  swapbytes(&hbhd.spare2,  sizeof(short), 1);
                  swapbytes(&hbhd.spare3,  sizeof(short), 1);
                  swapbytes(&hbhd.lspare,  sizeof(int),   1);
                  swapbytes(&hbhd.lp,      sizeof(float), 1);
                  swapbytes(&hbhd.rp,      sizeof(float), 1);
                  swapbytes(&hbhd.fspare1, sizeof(float), 1);
                  swapbytes(&hbhd.fspare2, sizeof(float), 1);
                }
		fwrite(&hbhd, sizeof(hbhd), 1, trg);
	      }
	      for (k = 0; k < sfhd.ntraces; k++)
	      {
		for (j = 0; j < sfhd.np / 2; j++)	/* read fp-FID */
		{
		  fread(&ffid, sizeof(FPFID), 1, src);
		  if (swap)
                  {
                    swapbytes(&ffid.re,  sizeof(float), 1);
                    swapbytes(&ffid.im,  sizeof(float), 1);
		  }
		  dfid.re = (int) (max*ffid.re);	/* fp to dp convert */
		  dfid.im = (int) (max*ffid.re);     
		  if (swap)
                  {
                    swapbytes(&dfid.re,  sizeof(int), 1);
                    swapbytes(&dfid.im,  sizeof(int), 1);
		  }
		  fwrite(&dfid, sizeof(DPFID), 1, trg);
		}
	      }
	    }
	    printf("blocks processed");
	    break;

	  default:
	    printf("\nUnexpected data format. Abort.\n\n");
	    fclose(src);
	    fclose(trg);
	    i = rename(fn2, fn1);
	    exit(0);
  }
  fclose(trg);
  fclose(src);

  printf("\nDone.\n");
}

void usage()
{
  printf("\nUsage : v2v filename.fid <-format> \n");
  printf("\nformat - Output format; \nAvailable format options are : \n");
  printf("d - double precision integer (default),\n");
  printf("s - single precision integer or\n");
  printf("f - floating point data.\n");
  printf("r - restores the original data.\n");
  exit(0);
}
