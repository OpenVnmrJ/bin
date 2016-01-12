/* trsub - subtract a trace from all other traces in array or 2D experment */

/* syntax:   trsub data_file <referencetrace <f1|f2>>

	data_file is a data file (expn/datdir/data or expn/datdir/phasefile)
	referencetrace: the trace that will be subtracted from all other
		traces (default: 1)
	f2 is a keyword that causes trsub to work on f2 part

	compilation:	cc -O -o trsub trsub.c

	started  93/07/15 - r.kyburz
	finished 93/08/23 - r.kyburz
*/

#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>
#include <sys/utsname.h>

char *sname;
char tname[1024];
FILE *source, *target;

static char rev[] =     "trsub.c 3.5";
static char revdate[] = "2010-11-06_20:10";


static char cmd[] = "trsub";
static int  debug = 0;
static int  swap  = 0;


void
close_n_quit()
{
  fclose(source);
  fclose(target);
  unlink(tname);
  exit(1);
}


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


main (argc, argv)
  int argc;
  char *argv[];

{
  /***********************/
  /* defining structures */
  /***********************/
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
  struct utsname *s_uname;

  /**********************/
  /* defining variables */
  /**********************/
  struct fileHeader fhd;
  struct blockHeader bhd;
  float curnum;
  float *reftrace;
  long i, j, k, blocksiz, nitems, ref;
  int ok;
  int f2mode = 0;
  int mode2d = 0;
  char c;


  /**********************/
  /* checking arguments */
  /**********************/

  if (argc >= 2)
  {
    if ((!strcasecmp(argv[1], "-v")) || (!strcasecmp(argv[1], "-version")))
    {
      (void) printf("%s (%s)\n", rev, revdate);
      exit(0);
    }
  }

  /* checking argument number */
  if ((argc < 2) || (argc > 4))
  {
    fprintf(stderr, "Usage:  trsub data_file <reference_trace <f2mode>>\n");
    exit(1);
  }

  /* checking argument 1, constructing filenames */
  sname = argv[1];
  strcpy(tname,sname);
  strcat(tname,".mod");

  /* checking argument 2 (numeric) */
  if (argc >= 3)
  {
    ok = sscanf(argv[2], "%ld", &ref);
  }
  else
  {
    ok = 1;
    ref = 1;
  }
  if (!ok)
  {
    fprintf(stderr, "trsub:  argument #2 (optional) must be numeric\n");
    exit(1);
  }

  /* checking argument 3 */
  if (argc == 4)
  {
    mode2d = 1;
    f2mode = (strcmp(argv[3], "f2") ? 0 : 1);
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


  /*---------------------------------------------+
  |  open source file and check header / format  |
  +---------------------------------------------*/

  /* open file */
  source = fopen(sname, "r");
  if (source == NULL)
  {
    fprintf(stderr, "trsub: problem opening data file %s\n", sname);
    exit(1);
  }

  /* initialize header structure */
  fhd.nblocks = 0;
  fhd.ntraces = 0;
  fhd.np = 0;
  fhd.ebytes = 0;
  fhd.status = 0;

  /* read file header */
  fread(&fhd, sizeof(fhd), 1, source);
  if (swap)
  {
    swapbytes(&fhd.nblocks,       sizeof(int),   1);
    swapbytes(&fhd.ntraces,       sizeof(int),   1);
    swapbytes(&fhd.np,            sizeof(int),   1);
    swapbytes(&fhd.ebytes,        sizeof(int),   1);
    swapbytes(&fhd.tbytes,        sizeof(int),   1);
    swapbytes(&fhd.bbytes,        sizeof(int),   1);
    swapbytes(&fhd.vers_id,       sizeof(short), 1);
    swapbytes(&fhd.status,        sizeof(short), 1);
    swapbytes(&fhd.nblockheaders, sizeof(int),   1);
  }


  /* check source data header */
  if ((fhd.status & 1) == 0)
  { 
    fprintf(stderr, "trsub: no data present in %s\n",sname);
    fclose(source);
    exit(1);
  }
  if (fhd.nblocks*fhd.ntraces <= 1)
  { 
    fprintf(stderr, "trsub: multi-trace data file required\n");
    fclose(source);
    exit(1);
  }
  if ((fhd.status & 8) == 0)
  { 
    fprintf(stderr, "trsub: incorrect data format in %s\n",sname);
    fclose(source);
    exit(1);
  }

  /**********************************************************************/
  /* in case of f2 mode calculate data structure parameters for f2 part */
  /**********************************************************************/
  if (f2mode == 1)
  {
    blocksiz = fhd.np * fhd.ntraces;
    fhd.np = fhd.nblocks * fhd.ntraces;
    fhd.ntraces = blocksiz / fhd.np;
  }


  /*****************************************/
  /* allocating memory for reference trace */
  /*****************************************/
  reftrace = (float *) malloc(fhd.np*fhd.ebytes);
  if (reftrace == NULL)
  {
    fprintf(stderr, "trsub: problem allocating space for reference trace.\n");
    fclose(source);
    exit(1);
  }


  /********************/
  /* open target file */
  /********************/
  target = fopen(tname, "w+");
  if (target == NULL)
  {
    fprintf(stderr, "trsub: problem opening target file %s\n", tname);
    fclose(source);
    exit(1);
  }


  /*****************************************/
  /* read reference trace from source file */
  /*****************************************/

  /* skip to reference trace */
  fseek(source, sizeof(bhd), 1);
  if (f2mode == 1)
    fseek(source, fhd.nblocks*fhd.bbytes, 1);
  for (i = 1; i < ref; i++)
  {
    j = i % fhd.ntraces;
    if (j == 0) fseek(source, sizeof(bhd), 1);
    fseek(source, fhd.np*fhd.ebytes, 1);
  }

  /* read refcerence trace into allocated memory */
  nitems = (long) fread(reftrace, sizeof(float), fhd.np, source);
  if ( fhd.np > nitems )
  {
    if (f2mode == 1)
      fprintf(stderr, "trsub: problem reading reference trace (f2 part)\n");
    else
      fprintf(stderr, "trsub: problem reading reference trace\n");
    close_n_quit();
  }
  if (swap)
  {
    swapbytes(&reftrace, fhd.ebytes, fhd.np);
  }


  /******************************/
  /* now create the target file */
  /******************************/

  /* jump to point after source file header */
  fseek(source, sizeof(fhd), 0);

  /* write target file header */
  if (swap)
  {
    swapbytes(&fhd.nblocks,       sizeof(int),   1);
    swapbytes(&fhd.ntraces,       sizeof(int),   1);
    swapbytes(&fhd.np,            sizeof(int),   1);
    swapbytes(&fhd.ebytes,        sizeof(int),   1);
    swapbytes(&fhd.tbytes,        sizeof(int),   1);
    swapbytes(&fhd.bbytes,        sizeof(int),   1);
    swapbytes(&fhd.vers_id,       sizeof(short), 1);
    swapbytes(&fhd.status,        sizeof(short), 1);
    swapbytes(&fhd.nblockheaders, sizeof(int),   1);
  }
  fwrite(&fhd, sizeof(fhd), 1, target);
  if (swap)
  {
    swapbytes(&fhd.nblocks,       sizeof(int),   1);
    swapbytes(&fhd.ntraces,       sizeof(int),   1);
    swapbytes(&fhd.np,            sizeof(int),   1);
    swapbytes(&fhd.ebytes,        sizeof(int),   1);
    swapbytes(&fhd.tbytes,        sizeof(int),   1);
    swapbytes(&fhd.bbytes,        sizeof(int),   1);
    swapbytes(&fhd.vers_id,       sizeof(short), 1);
    swapbytes(&fhd.status,        sizeof(short), 1);
    swapbytes(&fhd.nblockheaders, sizeof(int),   1);
  }

  /* in case of f2 mode copy f1 part 1 : 1 */
  if (f2mode == 1)
  {
    for (i = 0; i < fhd.nblocks * fhd.bbytes; i++)
      putc(getc(source),target);
  }

  /* now calculate differences and modify data file */
  for (i = 0; i < fhd.nblocks*fhd.ntraces; i++)
  {
    j = i % fhd.ntraces;
    if (j == 0)
    {
      for (k = 0; k < fhd.nblockheaders; k++)
      {
        nitems = fread(&bhd, sizeof(bhd), 1, source);
        if ( nitems == 0 )
        {
          if (f2mode == 1)
            fprintf(stderr, "trsub: problem reading f2 part\n");
          else
            fprintf(stderr, "trsub: problem reading %s\n", sname);
          close_n_quit();
        }
        (void) fwrite(&bhd, sizeof(bhd), 1, target);
        if (swap)
        {
          swapbytes(&bhd.scale,   sizeof(short), 1);
          swapbytes(&bhd.status,  sizeof(short), 1);
          swapbytes(&bhd.index,   sizeof(short), 1);
          swapbytes(&bhd.mode,    sizeof(short), 1);
          swapbytes(&bhd.ctcount, sizeof(int),   1);
          swapbytes(&bhd.lpval,   sizeof(float), 1);
          swapbytes(&bhd.rpval,   sizeof(float), 1);
          swapbytes(&bhd.lvl,     sizeof(float), 1);
          swapbytes(&bhd.tlt,     sizeof(float), 1);
        }
      }
    }
    if (((i == ref - 1) && (mode2d == 0)) || ((bhd.status & 9) != 9))
    {
      for (j = 0; j < fhd.np; j++)
      {
        fread(&curnum, sizeof(float), 1, source);
        if ( nitems == 0 )
        {
          fprintf(stderr, "trsub: problem reading %s\n", sname);
          close_n_quit();
        }
        fwrite(&curnum, sizeof(float), 1, target);
      }
    }
    else
    {
      for (j = 0; j < fhd.np; j++)
      {
        fread(&curnum, sizeof(float), 1, source);
        if ( nitems == 0 )
        {
          if (f2mode == 1)
            fprintf(stderr, "trsub: problem reading f2 part\n");
          else
            fprintf(stderr, "trsub: problem reading %s\n", sname);
          close_n_quit();
        }
        if (swap)
          swapbytes(&curnum, sizeof(float), 1);
	curnum -= reftrace[j];
        if (swap)
          swapbytes(&curnum, sizeof(float), 1);
        fwrite(&curnum, sizeof(float), 1, target);
      }
    }
  }
  fclose(source);
  fclose(target);
  unlink(sname);
  link(tname,sname);
  unlink(tname);
  return(0);
}
