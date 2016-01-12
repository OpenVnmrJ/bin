/* bruspec2var - create datdir/phasefile, datdir/data from Bruker 1D spectrum */

/*
 Syntax:      bruspec2var <-d> <-noswap|-swap> Bruker_dir <targetpath>
	      bruspec2var -v

 Description: "bruspec2var" creates a 1D VnmrJ / VNMR "datdir/data" and
	      "datdir/phasefile" from transformed Bruker dataset. The
	      resulting phasefile can be imported into VNMR / VnmrJ using the
	      macro "bruspec2var".

 Arguments:   "Bruker_dir": path to a directory containing a transformed
	      Bruker 1D spectrum ("1r" and "1i" component files). If the
	      imaginary component is missing, the spectrum is read as real-only
	      (imaginary component = real component).
	      "source/bruspec2var.c" is a C program that can be compiled with
               		cc -O -o /vnmr/bin/bruspec2var bruspec2var.c
	      or (for a local installation)
               		cc -O -o ~/bin/bruspec2var bruspec2var.c

	      "targetpath": Optional path to a directory in which the files
	      "data" and "phasefile" are created, that can afterwards be
	      imported into VNMR / VnmrJ using "bruspec2var"; ideally,
	      "targetpath" is the subdirectory "datdir" in the target
	      (current) VnmrJ / VNMR experiment. If no target path is
	      specified, these two will be created in the directory with the
	      Bruker 1D spectrum files (if writable).

	      On Sun / SPARC and Mac / PowerPC architectures, the program
	      assumes that the Bruker data need to be byte-swapped; the
	      "-noswap" option suppresses the byte swapping, in case the
	      Bruker data are delivered byte-swapped already.
	      Conversely, on PC / Linux architectures, the program assumes
	      that byte-swapping is not required - however, on these systems
	      byte-swapping can be enforced with the "-swap" argument.

	      The "-d" or "-debug" option is for debugging ONLY and produces
	      VERY VERBOSE output about the conversion process.

	      The "-v" option causes "bruspec2var" to print out the version
	      number / data and exit.

 Examples:    bruspec2var 1/pdata/1 $vnmruser/exp3/datdir
              bruspec2var 1/pdata/1 $HOME/vnmrsys/exp3/datdir
              bruspec2var 1/pdata/1 $HOME/vnmrsys/exp3/datdir
              bruspec2var 1/pdata/1
              bruspec2var -noswap 1/pdata/1 $vnmruser/exp3/datdir
              bruspec2var -d -swap 1/pdata/1 $vnmruser/exp3/datdir
              bruspec2var -v


 Related: bruspec2var - Read Bruker 1D spectrum  (M)

 Revision history:
   2005-01-22 - r.kyburz, first version
   2005-10-05 - r.kyburz, minor syntax issues fixed
   2005-10-06 - r.kyburz, adjusted for real-only spectra
   2006-02-12 - r.kyburz, adjusted for PC/Linux and PowerPC/MacOS X
   2006-02-24 - r.kyburz, fixed RHEL 4 and MacOS X compiler issues
   2006-03-10 - r.kyburz, fixed bug for MacOS X version
   2006-03-11 - r.kyburz, fixed more bugs (rep. by Pascal Mercier, Chenomx)
   2006-05-04 - r.kyburz, improved architecture recognition
   2008-07-08 - r.kyburz, avoids Solaris 8 compiler warning
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/utsname.h>

static char rev[] =     "bruspec2var.c 3.8";
static char revdate[] = "2010-11-06_19:55";

#define FNMIN 32
#define MAX   256

#define S_DATA		0x1		/* 0 = no data, 1 = data */
#define S_SPEC		0x2		/* 0 = FID, 1 = spectrum */
#define S_32		0x4		/* 0 = 16-bit, 1 = 32-bit */
#define S_FLOAT		0x8		/* 0 = integer, 1 = floating point */
#define S_COMPLEX	0x10		/* 0 = real, 1 = complex */
#define S_HYPERCOMPLEX	0x20		/* 1 = hypercomplex */

#define S_ACQPAR	0x80		/* 0 = not Acqpar, 1 = Acqpar */
#define S_SECND 	0x100		/* 0 = first FT, 1 = second FT */
#define S_TRANSF	0x200		/* 0 = regular, 1 = transposed */
#define S_NP    	0x800		/* 1 = np dimension is active */
#define S_NF    	0x1000		/* 1 = nf dimension is active */
#define S_NI    	0x2000		/* 1 = ni dimension is active */
#define S_NI2    	0x4000		/* 1 = ni2 dimension is active */

#define MORE_BLOCKS	0x80		/* 0 = absent, 1 = present */
#define NP_CMPLX	0x100		/* 0 = real, 1 = complex */
#define NF_CMPLX	0x200		/* 0 = real, 1 = complex */
#define NI_CMPLX	0x400		/* 0 = real, 1 = complex */
#define NI2_CMPLX	0x800		/* 0 = real, 1 = complex */

/*--------------------+
| defining structures |
+--------------------*/
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

FILE *real, *imag, *phfil, *datafil;
int debug = 0;



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



long fsize(char *name)
{
  long siz = 0;
  FILE *tmp;
  tmp = fopen(name, "r");
  while (fgetc(tmp) != EOF) siz++;
  (void) fclose(tmp);
  return(siz);
}




int main (argc, argv)
  int argc;
  char *argv[];
{

  /*------------+
  | Definitions |
  +------------*/

  /* defining variables */
  struct fileHeader fheader;
  struct blockHeader bheader;
  char realname[MAX], imagname[MAX], ext[MAX], phfname[MAX], datname[MAX];
  int i, j, len, ok, error = 0;
  int farg = 1, swap = -1, bruswap = -1;
  int *brudata;
  long rlen = 0, ilen = 0, fn, max;
  float *spectrum, *cspectrum, scale;
  char cmd[MAX], dcmd[MAX];
  struct utsname *s_uname;

  len = strlen(argv[0]);
  i = len;
  while ((argv[0][i-1] != '/') && (i > 0))
  {
    i--;
  }
  j = 0;
  for (; i < len; i++)
  {
    cmd[j] = argv[0][i];
    j++;
  }
  cmd[j] = '\0';
  len = strlen(cmd);
  for (i = 0; i < len; i++)
    dcmd[i] = ' ';
  dcmd[i] = '\0';



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

  i = 1;
  farg = 1;
  while ((i < argc) && (argv[i][0] == '-'))
  {
    if (!strcasecmp(argv[i], "-noswap"))
    {
      if (debug)
        (void) printf("Byte-swapping for Bruker data suppressed\n");
      bruswap = 0;
      farg++;
    }
    else if (!strcasecmp(argv[i], "-swap"))
    {
      if (debug)
        (void) printf("Byte-swapping for Bruker data enforced\n");
      bruswap = 1;
      farg++;
    }
    else if ((!strcasecmp(argv[i], "-d")) || (!strcasecmp(argv[i], "-debug")))
    {
      debug = 1;
      farg++;
    }
    i++;
  }

  /* check for presence of file argument, one extra argument maximum */
  if ((argc == i) || (argc > i + 2))
  {
    (void) fprintf(stderr,
	"Usage:  %s <-d> <-noswap|-swap> bruker_dir <targetpath>\n", cmd);
    return(1);
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
      (void) printf("\nExtracted \"uname\" information:\n");
      (void) printf("   s_uname->sysname:   %s\n", s_uname->sysname);
      (void) printf("   s_uname->nodename:  %s\n", s_uname->nodename);
      (void) printf("   s_uname->release:   %s\n", s_uname->release);
      (void) printf("   s_uname->version:   %s\n", s_uname->version);
      (void) printf("   s_uname->machine:   %s\n", s_uname->machine);
    }

    /* PC / Linux or Mac / Intel / MacOS X architecture */
    if ((char *) strstr(s_uname->machine, "86") != (char *) NULL)
    {
      if (debug)
      {
        (void) printf("   Intel x86 architecture:");
      }
      swap = 1;
      if (bruswap == -1)
      {
        bruswap = 0;
        if (debug)
        {
          (void) printf(" Bruker data NOT byte-swapped by default\n");
          (void) printf("        ");
	}
      }
    }

    /* Sun / SPARC architecture */
    else if (!strncasecmp(s_uname->machine, "sun", 3))
    {
      if (debug)
      {
        (void) printf("   \"%s\" (Sun SPARC) architecture:", s_uname->machine);
      }
      swap = 0;
      if (bruswap == -1)
      {
        bruswap = 1;
        if (debug)
        {
          (void) printf(" Bruker data byte-swapped by default\n");
          (void) printf("        ");
	}
      }
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
      if (bruswap == -1)
      {
        bruswap = 1;
        if (debug)
        {
          (void) printf(" Bruker data byte-swapped by default\n");
          (void) printf("        ");
	}
      }
    }

    /* OTHER ARCHITECTURES */
    else
    {
      if (debug)
      {
        (void) printf("   \"%s\" architecture:", s_uname->machine);
      }
      swap = 1;
      if (bruswap == -1)
      {
        bruswap = 0;
        if (debug)
        {
          (void) printf(" Bruker data NOT byte-swapped by default\n");
          (void) printf("        ");
	}
      }
    }

    if (debug)
    {
      if (swap)
      {
        (void) printf("  SWAPPING BYTES on Varian data\n");
      }
      else
      {
        (void) printf("  NOT swapping bytes on Varian data\n");
      }
    }
  }
  else
  {
    (void) fprintf(stderr,
        "%s:  unable to determine system architecture, aborting.\n", cmd);
    exit(1);
  }



  /*-----------------------------------------------+
  | first file name arg: Bruker directory or       |
  | real component of Bruker spectrum (XXX/[0-9]r) |
  +-----------------------------------------------*/
  (void) strcpy(realname, argv[farg]);
  len = strlen(realname);
  i = len;
  while ((realname[i-1] != '/') && (i > 0))
  {
    i--;
  }
  if (i == 0)
  {
    strcpy(imagname, "./");
    strcat(imagname, realname);
    len += 2;
    i = 2;
    strcpy(realname, imagname);
  }
  strncpy(phfname, realname, i);
  j = 0;
  for (; i < len; i++)
  {
    ext[j] = realname[i];
    j++;
  }
  ext[j] = '\0';
  if ((strcmp(ext,"1r")) && (strcmp(ext,"2r")) && (strcmp(ext,"3r")) &&
      (strcmp(ext,"4r")) && (strcmp(ext,"5r")) && (strcmp(ext,"6r")) &&
      (strcmp(ext,"7r")) && (strcmp(ext,"8r")) && (strcmp(ext,"9r")))
  {
    if (realname[len-1] != '/')
    {
      (void) strcat(realname,"/");
    }
    strcpy(imagname, realname);
    strcat(realname, "1r");
    strcat(imagname, "1i");
  }
  else
  {
    strcpy(imagname, realname);
    imagname[len-1] = 'i';
  }

  real = fopen(realname, "r");
  if (real == NULL)
  {
    (void) fprintf(stderr,
	"%s:  Unable to open Bruker spectrum (real component)\n", cmd);
    (void) fprintf(stderr, "%s       %s\n", dcmd, realname);
    error++;
  }
  else
    rlen = fsize(realname);

  imag = fopen(imagname, "r");
  if (imag == NULL)
  {
    if (real != NULL)
    {
      imag = fopen(realname, "r");
      if (imag != NULL) 
      {
        (void) printf("Spectrum imported as real-only\n");
        (void) printf("        file \"%s\" not found\n", imagname);
        strcpy(imagname, realname);
        ilen = rlen;
      }
      else
      {
        if (error > 0)
          (void) fprintf(stderr, "%s   ", dcmd);
        else
          (void) fprintf(stderr, "%s:  ", cmd);
        (void) fprintf(stderr,
	    "Unable to open Bruker spectrum (imaginary = real component)\n");
        (void) fprintf(stderr, "%s        %s\n", dcmd, imagname);
        error++;
      }
    }
    else
    {
      if (error > 0)
        (void) fprintf(stderr, "%s   ", dcmd);
      else
        (void) fprintf(stderr, "%s:  ", cmd);
      (void) fprintf(stderr,
        "Unable to open Bruker spectrum (imaginary component)\n");
      (void) fprintf(stderr, "%s        %s\n", dcmd, imagname);
      error++;
    }
  }
  else
    ilen = fsize(imagname);

  if ((real == NULL) && (imag == NULL)) 
  {
    if (error > 0)
      (void) fprintf(stderr, "%s   ", dcmd);
    else
      (void) fprintf(stderr, "%s:  ", cmd);
    (void) fprintf(stderr,
	"First argument must be either a Bruker spectrum\n");
    (void) fprintf(stderr,
	"%s   (real component, \"*/[1-9]r\"), or a directory with\n", dcmd);
    (void) fprintf(stderr,
	"%s   Bruker real and imaginary components (\"1r\", \"1i\")\n", dcmd);
    error++;
  }


  /*---------------------------------------+
  | second file name arg: target directory |
  +---------------------------------------*/
  if (argc > farg + 1)
  {
    (void) strcpy(phfname, argv[farg + 1]);
    (void) strcpy(datname, argv[farg + 1]);
  }
  else
  {
    (void) strcpy(datname, phfname);
  }
  len = strlen(phfname);
  if (phfname[len - 1] != '/')
  {
    (void) strcat(phfname, "/");
    (void) strcat(datname, "/");
  }
  (void) strcat(phfname, "phasefile");
  (void) strcat(datname, "data");



  if (ilen != rlen)
  {
    (void) fprintf(stderr,
	"%s:  real and imaginary components must be same size!\n", cmd);
    return(1);
  }
  fn = 2 * rlen / 4;

  if (debug)
  {
    (void) printf("REAL file:  %s\n", realname);
    (void) printf("IMAG file:  %s\n", imagname);
    (void) printf("phasefile:  %s\n", phfname);
    (void) printf("data file:  %s\n", datname);
    (void) printf("size of input data components: %ld Bytes each\n", rlen);
    (void) printf("fn = %ld\n", fn);
  }

  if (error > 0)
  {
    return(1);
  }



  /*--------------------------------+
  | allocate memory for binary data |
  +--------------------------------*/
  spectrum = (float *) calloc(fn / 2, sizeof(float));
  if (spectrum == NULL)
  {
    (void) fprintf(stderr,
	"%s:  allocating memory for phasefile failed\n", cmd);
    (void) fclose(real);
    (void) fclose(imag);
    return(1);
  }
  cspectrum = (float *) calloc(fn, sizeof(float));
  if (cspectrum == NULL)
  {
    (void) fprintf(stderr,
	"%s:  allocating memory for complex data failed\n", cmd);
    (void) fclose(real);
    (void) fclose(imag);
    return(1);
  }
  brudata = (int *) calloc(fn / 2, sizeof(int));
  if (brudata == NULL)
  {
    (void) fprintf(stderr,
	"%s:  allocating memory for Bruker data failed\n", cmd);
    (void) fclose(real);
    (void) fclose(imag);
    return(1);
  }

  /*--------------------------------+
  | Read Bruker spectrum, real part |
  +--------------------------------*/
  (void) fread(brudata, sizeof(int), fn/2, real);
  (void) fclose(real);
  max = 0;
  for (i = 0; i < fn/2; i++)
  {
    if (bruswap)
    {
      if (debug) printf("val = %08lx   -   ", brudata[i]);
      swapbytes(&brudata[i], sizeof(int), 1);
      if (debug) printf("swapval = %08lx\n", brudata[i]);
    }
    if (brudata[i] > max)
      max = brudata[i];
  }
  scale = 1.0 / (float) max;
  for (i = 0; i < fn/2; i++)
  {
    spectrum[i] = (float) (brudata[i]) * scale;
  }

  /*--------------------------------+
  | construct phasefile file header |
  +--------------------------------*/
  fheader.nblocks       = (int)  1;
  fheader.ntraces       = (int)  1;
  fheader.np            = (int)  fn / 2;
  fheader.ebytes        = (int)  4;
  fheader.tbytes        = (int)  (fheader.np * fheader.ebytes);
  fheader.bbytes        = (int)  (fheader.tbytes + sizeof(bheader));
  fheader.vers_id       = (short) 0xc1;	/* (taken from example) */
  fheader.status        = (short) (S_DATA + S_SPEC + S_FLOAT + S_NP);
  fheader.nblockheaders = (int)  1;
  

  /*---------------------------------+
  | construct phasefile block header |
  +---------------------------------*/
  bheader.scale   = (short) 0;
  bheader.status  = (short) (S_DATA + S_SPEC + S_FLOAT);
  bheader.index   = (short) 0;
  bheader.mode    = (short) S_DATA;
  bheader.ctcount = (int)  0;
  bheader.lpval   = (float) 0.0;
  bheader.rpval   = (float) 0.0;
  bheader.lvl     = (float) 0.0;
  bheader.tlt     = (float) 0.0;

  
  /*-----------------------------+
  | try to open phasefile & data |
  +-----------------------------*/
  phfil = fopen(phfname, "w");
  if (phfil == NULL)
  {
    (void) fprintf(stderr, "%s:  problem opening phasefile\n", cmd);
    (void) fprintf(stderr, "%s:      %s\n", dcmd, phfname);
    (void) fclose(imag);
    return(1);
  }


  /*================+
  | WRITE PHASEFILE |
  +================*/
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

    swapbytes(&bheader.scale,         sizeof(short), 1);
    swapbytes(&bheader.status,        sizeof(short), 1);
    swapbytes(&bheader.index,         sizeof(short), 1);
    swapbytes(&bheader.mode,          sizeof(short), 1);
    swapbytes(&bheader.ctcount,       sizeof(int),   1);
    swapbytes(&bheader.lpval,         sizeof(float), 1);
    swapbytes(&bheader.rpval,         sizeof(float), 1);
    swapbytes(&bheader.lvl,           sizeof(float), 1);
    swapbytes(&bheader.tlt,           sizeof(float), 1);

    swapbytes(spectrum,               sizeof(float), fn/2);
  }
  (void) fwrite(&fheader, sizeof(fheader), 1, phfil);
  (void) fwrite(&bheader, sizeof(bheader), 1, phfil);
  (void) fwrite(spectrum, sizeof(float), fn/2, phfil);
  (void) fclose(phfil);
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

    swapbytes(&bheader.scale,         sizeof(short), 1);
    swapbytes(&bheader.status,        sizeof(short), 1);
    swapbytes(&bheader.index,         sizeof(short), 1);
    swapbytes(&bheader.mode,          sizeof(short), 1);
    swapbytes(&bheader.ctcount,       sizeof(int),   1);
    swapbytes(&bheader.lpval,         sizeof(float), 1);
    swapbytes(&bheader.rpval,         sizeof(float), 1);
    swapbytes(&bheader.lvl,           sizeof(float), 1);
    swapbytes(&bheader.tlt,           sizeof(float), 1);

    swapbytes(spectrum,               sizeof(float), fn/2);
  }



  /*-----------------------------+
  | Adjust headers for data file |
  +-----------------------------*/
  fheader.np *= 2;
  fheader.tbytes        = (int)  (fheader.np * fheader.ebytes);
  fheader.bbytes        = (int)  (fheader.tbytes + sizeof(bheader));
  fheader.vers_id       = (short) 0x78c1; /* (taken from example) */
  fheader.status += S_COMPLEX;

  bheader.status += (S_COMPLEX + NP_CMPLX);

  
  /*-------------------+
  | try to open "data" |
  +-------------------*/
  datafil = fopen(datname, "w");
  if (datafil == NULL)
  {
    (void) fprintf(stderr, "%s:  problem opening datdir/data file\n", cmd);
    (void) fprintf(stderr, "%s:      %s\n", dcmd, datname);
    (void) fclose(phfil);
    (void) fclose(imag);
    return(1);
  }


  /*-----------------------+
  | build complex spectrum |
  +-----------------------*/
  j = 0;
  for (i = 0; i < fn/2; i++)
  {
    cspectrum[j] = spectrum[i];
    j += 2;
  }
  (void) fread(brudata, sizeof(int), fn/2, imag);
  (void) fclose(imag);
  j = 1;
  for (i = 0; i < fn/2; i++)
  {
    if (bruswap)
      swapbytes(&brudata[i], sizeof(int), 1);
    spectrum[i] = (float) (brudata[i]) * scale;
    cspectrum[j] = spectrum[i];
    j += 2;
  }


  /*=============+
  | WRITE "DATA" |
  +=============*/
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

    swapbytes(&bheader.scale,         sizeof(short), 1);
    swapbytes(&bheader.status,        sizeof(short), 1);
    swapbytes(&bheader.index,         sizeof(short), 1);
    swapbytes(&bheader.mode,          sizeof(short), 1);
    swapbytes(&bheader.ctcount,       sizeof(int),   1);
    swapbytes(&bheader.lpval,         sizeof(float), 1);
    swapbytes(&bheader.rpval,         sizeof(float), 1);
    swapbytes(&bheader.lvl,           sizeof(float), 1);
    swapbytes(&bheader.tlt,           sizeof(float), 1);

    swapbytes(cspectrum,              sizeof(float), fn);
  }
  (void) fwrite(&fheader, sizeof(fheader), 1, datafil);
  (void) fwrite(&bheader, sizeof(bheader), 1, datafil);
  (void) fwrite(cspectrum, sizeof(float), fn, datafil);
  (void) fclose(datafil);


  /* generate standard output */
  (void) printf("Generated data \"%s\"\n", datname);
  (void) printf("Generated phasefile \"%s\"\n", phfname);
  return(0);
}

