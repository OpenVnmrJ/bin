/* rephasefid - rephase (parts of) 2D fids */

/* syntax:  rephasefid 2Dfid_file degrees start_trace <end_trace <spacing>> */

/*	rephasefid allows to rephase 1D/2D fids or parts thereof by altering
		the (zero-order) phase of specified fids in a data set. 

	potential applications:
		- fixing problems with phase instabilities on single fids
		- "repairing" problems from erroneous phase cycling, e.g.,
		  to make a data set compatible with the 'wft2da' macro.

	rephasefid generates a temporary file rephasefid.tmp in /vnmr/tmp.

	compilation with
		cc -o rephasefid rephasefid.c -lm

	1991-12-10 - r.kyburz, Started
	2006-02-10 - r.kyburz, Expansions for PC/Linux (& Mac) architecture;
		               Added compatibility with floating point FIDs
	2006-02-11 - r.kyburz, Fixed minor issues with argument checking
	2008-07-08 - r.kyburz, Avoids compiler warning under Solaris 8
        
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <sys/utsname.h>
#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

static char rev[] =     "rephasefid.c 3.5";
static char revdate[] = "2010-11-06_20:06";

static char cmd[] = "rephasefid";
static int swap = 0;
static int debug = 0;

/*--------------------+
| defining structures |
+--------------------*/

struct fileHeader
{
  unsigned int nblocks, ntraces, np, ebytes, tbytes, bbytes;
  unsigned short vers_id, status;
  unsigned int nblockheaders;
};
struct blockHeader
{
  unsigned short scale, status, index, mode;
  unsigned int ctcount;
  float lpval, rpval, lvl, tlt;
};
struct pair
{
  int p1, p2;
};
struct shortpair
{
  short p1, p2;
};
struct doublepair
{
  double p1, p2;
};
struct floatpair
{
  float p1, p2;
};


/*-------------------+
| defining variables |
+-------------------*/

static struct fileHeader fheader;
static struct blockHeader bheader;
static struct pair point;
static struct shortpair spoint;
static struct floatpair fpoint;
static struct doublepair tpoint, dpoint;


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

  /*------------+
  | Definitions |
  +------------*/

  /* defining variables */
  int i, j, ok,
      arg, fidarg, minargc, maxargc,
      start = 1,
      end = 2147483647,
      spacing = 1;
  double degree;
  int idegree, deg90, tmp;
  float ftmp;
  short stmp;
  char *name, tmpname[256];
  FILE *file, *tmpfile;
  struct utsname *s_uname;


  /*-------------------+
  | checking arguments |
  +-------------------*/

  if (argc >= 2)
  {
    if ((!strcasecmp(argv[1], "-v")) || (!strcasecmp(argv[1], "-version")))
    {
      (void) printf("%s (%s)\n", rev, revdate);
      exit(0);
    }
  }

  if (argc >= 2)
  {
    if ((!strcasecmp(argv[1], "-d")) || (!strcasecmp(argv[1], "-debug")))
    {
      debug = 1;
      fidarg = 2;
      minargc = 4;
      maxargc = 7;
    }
    else
    {
      fidarg = 1;
      minargc = 3;
      maxargc = 6;
    }
  }


  /* number of arguments: 2 at least, 5 maximum */
  if ((argc < minargc) || (argc > maxargc))
  {
    (void) fprintf(stderr, "Usage:\n");
    (void) fprintf(stderr, "  rephasefid <-d<ebug>> file degrees");
    (void) fprintf(stderr, " <start_trace <end_trace <spacing>>>\n");
    exit(1);
  }
  name = argv[fidarg];

  /* arg2: rotation angle in degrees */
  ok = sscanf(argv[fidarg + 1], "%lf", &degree);
  idegree = (int) (degree / 90.0);
  if (!ok)
  {
    (void) fprintf(stderr, "rephasefid:  argument #%d must be numeric\n",
	fidarg + 1);
    exit(1);
  }
  deg90 = (degree == (double) (idegree * 90));

  /* arg3: starting trace (optional - default: trace #1) */
  if (argc > fidarg + 2)
    ok = sscanf(argv[fidarg + 2], "%d", &start);
  if (!ok) 
  {  
    (void) fprintf(stderr, "rephasefid:  argument #%d must be numeric\n",
	fidarg + 2); 
    exit(1);
  }  

  /* arg4: end trace (optional - default: last trace) */
  if (argc > fidarg + 3)
    ok = sscanf(argv[fidarg + 3], "%d", &end);
  if (!ok)
  {
    (void) fprintf(stderr, "rephasefid:  argument #%d must be numeric\n",
	fidarg + 3);
    exit(1);
  }

  /* arg5: spacing (optional - default: 1) */
  if (argc > fidarg + 4)
    ok = sscanf(argv[fidarg + 4], "%d", &spacing);
  if (!ok)
  {
    (void) fprintf(stderr, "rephasefid:  argument #%d must be numeric\n",
	fidarg + 4);
    exit(1);
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


  /*---------------------------------------+
  | check file access, reading file header |
  +---------------------------------------*/

  /* open fid file */
  file = fopen(name, "r+");
  if (file == NULL)
  {
    (void) fprintf(stderr, "rephasefid: problem opening file %s\n", name);
    exit(1);
  }

  /* try to open temporary file */
  tmpname[0] = '\0';
  strcpy(tmpname, "/vnmr/tmp/rephasefid.tmp");
  tmpfile = fopen(tmpname, "w+");
  if (tmpfile == NULL)
  {
    (void) fprintf(stderr,
	"rephasefid: problem opening temporary file %s\n", tmpname);
    fclose(file);
    exit(1);
  }


  /*-----------------+
  | debugging output |
  +-----------------*/

  if (debug)
  {
    (void) printf("\nArguments & Parameters:\n");
    (void) printf("   FID being rephased:    %s\n", name);
    (void) printf("   temporary file:        %s\n", tmpname);
    (void) printf("   phase rotation:        %8.1f", degree);
    if (deg90)
      (void) printf(" (multiples of 90 degrees)\n");
    else
      (void) printf(" (arbitrary phase rotation)\n");
    (void) printf("   starting trace:        %8ld\n", start);
    (void) printf("   ending trace:          %8ld\n", end);
    (void) printf("   trace increment:       %8ld\n", spacing);
  }


  /*--------------------+
  | reading file header |
  +--------------------*/
  if (debug)
  {
    (void) printf("\nReading FID file header (%d bytes) -\n", sizeof(fheader));
  }
  fread(&fheader, sizeof(fheader), 1, file);
  if (swap)
  {
    swapbytes(&fheader.nblocks,       sizeof(int),   1);
    swapbytes(&fheader.ntraces,       sizeof(int),   1);
    swapbytes(&fheader.np,            sizeof(int),   1);
    swapbytes(&fheader.ebytes,        sizeof(int),   1);
    swapbytes(&fheader.tbytes,        sizeof(int),   1);
    swapbytes(&fheader.bbytes,        sizeof(int),   1);
    swapbytes(&fheader.vers_id,       sizeof(short), 1);
    swapbytes(&fheader.status,        sizeof(short), 1);
    swapbytes(&fheader.nblockheaders, sizeof(int),   1);
  }


  /*-----------------+
  | debugging output |
  +-----------------*/

  if (debug)
  {
    (void) printf("\nFID file header information:\n");
    (void) printf("   fheader->nblocks:        %8ld\n", fheader.nblocks);
    (void) printf("   fheader->ntraces:        %8ld\n", fheader.ntraces);
    (void) printf("   fheader->np:             %8ld\n", fheader.np);
    (void) printf("   fheader->ebytes:         %8ld\n", fheader.ebytes);
    (void) printf("   fheader->tbytes:         %8ld\n", fheader.tbytes);
    (void) printf("   fheader->bbytes:         %8ld\n", fheader.bbytes);
    (void) printf("   fheader->vers_id:        %8d\n",  fheader.vers_id);
    (void) printf("   fheader->status:         %8x\n",  fheader.status);
    (void) printf("   fheader->nblockheaders:  %8ld\n", fheader.nblockheaders);
  }


  /*=================+
  ||  REPHASE FIDS  ||
  +=================*/

  for (i = start - 1; ((i < fheader.nblocks) && (i < end)); i += spacing)
  {
    /* set file pointers */
    fseek(file, sizeof(fheader) + i * fheader.bbytes + sizeof(bheader), 0);
    fseek(tmpfile, 0, 0);


    /*---------------------------------------------------------+
    | DO THE SUBTRACTION (operate in batches of complex pairs) |
    +---------------------------------------------------------*/

    for (j = 0; j < fheader.np / 2; j++)
    {

      /*---------------------------+
      | 32-bit floating point data |
      +---------------------------*/

      if ((fheader.status & 0x8) != 0)
      {
	/* read one complex point */
        fread(&fpoint, sizeof(fpoint), 1, file);
        if (swap)
        {
          swapbytes(&fpoint, fheader.ebytes, 2);
        }

	/** for phase shifts in 90 degrees steps use simple calculations **/
        if ((deg90) && (idegree > -4) && (idegree < 4))
        {
	  if ((idegree == -3) || (idegree == 1))	/* 90, -270 degrees */
          {
	    tmp = fpoint.p1;
	    fpoint.p1 = fpoint.p2;
	    fpoint.p2 = -tmp;
          }
          else if ((idegree == -2) || (idegree == 2))	/* +/- 180 degrees */
          {
	    fpoint.p1 = -fpoint.p1;
	    fpoint.p2 = -fpoint.p2;
          }
          else if ((idegree == -1) || (idegree == 3))	/* 270, -90 degrees */
          {
	    tmp = fpoint.p1;
	    fpoint.p1 = -fpoint.p2;
	    fpoint.p2 = tmp;
          }			/* (no change for 0, 360 and -360 degrees) */
        }
        else						/** other angles **/
        {
          tpoint.p1 = (double) (cos(degree/180.0*M_PI)*fpoint.p1 +
		                sin(degree/180.0*M_PI)*fpoint.p2);
          tpoint.p2 = (double) (cos(degree/180.0*M_PI)*fpoint.p2 -
          	                sin(degree/180.0*M_PI)*fpoint.p1);
          fpoint.p1 = (float) tpoint.p1;
          fpoint.p2 = (float) tpoint.p2;
        }

	/* write corrected complex point into temporary file */
        if (swap)
        {
          swapbytes(&fpoint, fheader.ebytes, 2);
        }
        fwrite(&fpoint, sizeof(fpoint), 1, tmpfile);
      }


      /*----------------+
      | dp='y' (32-bit) |
      +----------------*/

      else if (fheader.ebytes == 4)
      {
	/* read one complex point */
        fread(&point, sizeof(point), 1, file);
        if (swap)
        {
          swapbytes(&point, fheader.ebytes, 2);
        }

	/** for phase shifts in 90 degrees steps use simple calculations **/
        if ((deg90) && (idegree > -4) && (idegree < 4))
        {
	  if ((idegree == -3) || (idegree == 1))	/* 90, -270 degrees */
          {
	    tmp = point.p1;
	    point.p1 = point.p2;
	    point.p2 = -tmp;
          }
          else if ((idegree == -2) || (idegree == 2))	/* +/- 180 degrees */
          {
	    point.p1 = -point.p1;
	    point.p2 = -point.p2;
          }
          else if ((idegree == -1) || (idegree == 3))	/* 270, -90 degrees */
          {
	    tmp = point.p1;
	    point.p1 = -point.p2;
	    point.p2 = tmp;
          }			/* (no change for 0, 360 and -360 degrees) */
        }
        else						/** other angles **/
        {
          dpoint.p1 = (double) point.p1;
          dpoint.p2 = (double) point.p2;
          tpoint.p1 = cos(degree/180.0*M_PI)*dpoint.p1 +
		      sin(degree/180.0*M_PI)*dpoint.p2;
          tpoint.p2 = cos(degree/180.0*M_PI)*dpoint.p2 -
          	      sin(degree/180.0*M_PI)*dpoint.p1;
          point.p1 = (int) tpoint.p1;
          point.p2 = (int) tpoint.p2;
        }

	/* write corrected complex point into temporary file */
        if (swap)
        {
          swapbytes(&point, fheader.ebytes, 2);
        }
        fwrite(&point, sizeof(point), 1, tmpfile);
      }


      /*----------------+
      | dp='n' (16-bit) |
      +----------------*/

      else
      {
	/* read one complex point */
        fread(&spoint, sizeof(spoint), 1, file);
        if (swap)
        {
          swapbytes(&spoint, fheader.ebytes, 2);
        }

	/** for phase shifts in 90 degrees steps use simple calculations **/
        if ((deg90) && (idegree > -4) && (idegree < 4))
        {
          if ((idegree == -3) || (idegree == 1))        /* 90, -270 degrees */
          {
            stmp = spoint.p1; 
            spoint.p1 = spoint.p2; 
            spoint.p2 = -stmp; 
          } 
          else if ((idegree == -2) || (idegree == 2))   /* +/- 180 degrees */
          { 
            spoint.p1 = -spoint.p1;
            spoint.p2 = -spoint.p2;
          } 
          else if ((idegree == -1) || (idegree == 3))	/* 270, -90 degrees */
          { 
            stmp = spoint.p1;
            spoint.p1 = -spoint.p2;
            spoint.p2 = stmp;
          }			/* (no change for 0, 360 and -360 degrees) */
        }  
        else						/** other angles **/
        {   
          dpoint.p1 = (double) spoint.p1;
          dpoint.p2 = (double) spoint.p2;
          tpoint.p1 = cos(degree/180.0*M_PI)*dpoint.p1 +
                      sin(degree/180.0*M_PI)*dpoint.p2;
          tpoint.p2 = cos(degree/180.0*M_PI)*dpoint.p2 -
                      sin(degree/180.0*M_PI)*dpoint.p1;
          spoint.p1 = (short) tpoint.p1;
          spoint.p2 = (short) tpoint.p2;
        }

	/* write corrected complex point into temporary file */
        if (swap)
        {
          swapbytes(&spoint, fheader.ebytes, 2);
        }
        fwrite(&spoint, sizeof(spoint), 1, tmpfile);
      }
    }

    /* update fid file */
    fseek(tmpfile, 0, 0);
    fseek(file, sizeof(fheader) + i * fheader.bbytes + sizeof(bheader), 0);
    for (j = 0; j < fheader.tbytes; j++)
      putc(getc(tmpfile),file);
  }

  /* close files */
  fclose(file);
  fclose(tmpfile);
  (void) unlink(tmpname);
  return(0);
}
