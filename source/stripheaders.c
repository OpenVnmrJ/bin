/* stripheaders - strip headers from binary VNMR data files */

/* Syntax:   	stripheaders VNMR_binary_datafile

   Description: "stripheaders" is meant to help exporting VNMR data for
                third party software that expects data files without
                file and block headers.

                "stripheaders" creates the following output files from a
                binary VNMR data file:
                 - <filename>.bin: the binary VNMR file without the file
                                   and block headers
                 - <filename>.hdr: the collected headers from the binary
                                   VNMR file, WITHOUT the data segments
                 - <filename>.txt: text file describing the contents of
                                   the file (header)
                The original file is NOT altered by "stripheaders"!
                All data are collected in *.bin, the headers are collected
                in *.hdr, and *.txt contains readable information that should
                allow the user to determine what the new files contain (note
                that without *.hdr and *.txt the structure of *.bin is not
                known!

                For 2D data (processed in 2D mode, NOT with 'wft', the
                output files from processing expn/datdir/phasefile are
                named f1traces.bin, f1traces.hdr, f2traces.bin, f2traces.hdr
                and phasefile.txt. Either the F1 files or the F2 files can
                be missing, depending on whether in VNMR a dcon/dconi was
                done with trace='f1' or trace='f2', or both.
                Known limitation / restriction: For 2D data (processed in
                2D mode, NOT with 'wft', the file datdir/data (complex 2D
                data) CANNOT be processed with "stripheaders".
                "phasefile" and "data" are recognized by name - you should
                NOT rename these files before calling "stripheaders" on them!

                Make sure you type
                        flush
                in VNMR before processing data in the current experiment!

   Examples:	stripheaders ~/vnmrsys/exp3/acqfil/fid
                stripheaders ~/vnmrsys/exp3/datdir/data
                stripheaders ~/vnmrsys/exp3/datdir/phasefile
		stripheaders myfid.fid/fid

   Compilation: cc -O -o stripheaders stripheaders.c

   started 1999-06-19	r.kyburz
*/

#include <stdio.h>
#include <stdlib.h>

#define MAXSTR 256
#define debug 0

main (argc, argv)
  int argc;
  char *argv[];

{
  /* defining structures */
  struct fileHeader
  {
    long nblocks, ntraces, np, ebytes, tbytes, bbytes;
    short vers_id, status;
    long nbheaders;
  };
  struct blockHeader
  {
    short scale, status, index, mode;
    long ctcount;
    float lpval, rpval, lvl, tlt;
  };

  /* defining variables */
  struct fileHeader sfhd;
  struct blockHeader sbhd;
  long int i, j, bufsiz, init, f1blocks, ok;
  int len, phasefile = 0, data = 0, setnbh = 0;
  char *sourcename, stripname[MAXSTR], headername[MAXSTR], textname[MAXSTR];
  char stripname2[MAXSTR], headername2[MAXSTR];
  char *buffer, *buf0;
  char subname[MAXSTR], cmd[1024];
  FILE *sourcefile, *stripfile, *headerfile, *txtfil;
  FILE *stripfile2, *headerfile2;

  /* checking arguments */
  if (argc != 2)
  {
    fprintf(stderr, "Usage:  stripheaders binary_data_file\n");
    exit(1);
  }

  /* set file names */
  sourcename = argv[1];
  len = strlen(sourcename);
  if (len >= 9)
  {
    if (debug) printf("checking whether fils is \"phasefile\"\n");
    j = 0;
    for (i = len - 9; i < len; i++, j++)
      subname[j] = sourcename[i];
    subname[j] = '\0';
    phasefile = !strcmp(subname, "phasefile");
    if ((debug) && (phasefile)) printf("file is phasefile\n");
  }
  if (len >= 4)
  {
    if (debug) printf("checking whether file is \"data\"\n");
    j = 0;
    for (i = len - 4; i < len; i++, j++)
      subname[j] = sourcename[i];
    subname[j] = '\0';
    data = !strcmp(subname, "data");
    if ((len > 4) && (data))
    {
      if (debug) printf("checking whether file is \"*/data\"\n");
      if (sourcename[len - 5] != '/')
      {
        if (debug) printf("file is not \"*/data\"\n");
        data = 0;
      }
    }
  }

  /* open source file */
  sourcefile = fopen(sourcename, "r");
  if (sourcefile == NULL)
  {
    fprintf(stderr, "stripheaders: problem opening source file %s\n",
	            sourcename);
    exit(1);
  }

  /* read source file header */
  fread(&sfhd, sizeof(sfhd), 1, sourcefile);

  /* correct erroneous file header entry */
  if (sfhd.nbheaders == 0)
  {
    sfhd.nbheaders++;
    setnbh = 1;
  }

  /* do some sanity checks on input file */
  if (sfhd.nbheaders > 2)
  {
    fprintf(stderr, "stripheaders: does not work with %ld block headsers!\n",
		    sfhd.nbheaders);
    fclose(sourcefile);
    exit(1);
  }
  if (sfhd.tbytes != (sfhd.np * sfhd.ebytes))
  {
    fprintf(stderr, "stripheaders: specified file is not a VNMR data file:\n");
    fprintf(stderr, "        np = %ld; %ld bytes per element;\n",
		     sfhd.np, sfhd.ebytes);
    fprintf(stderr, "        File header states %ld bytes per trace!\n",
		     sfhd.tbytes);
    fclose(sourcefile);
    exit(1);
  }
  if (sfhd.bbytes != (sfhd.ntraces * sfhd.tbytes +
		      sizeof(sbhd) * sfhd.nbheaders))
  {
    fprintf(stderr, "stripheaders: specified file is not a VNMR data file:\n");
    fprintf(stderr, "        %ld bytes per trace; %ld traces per block;\n",
		     sfhd.tbytes, sfhd.ntraces);
    fprintf(stderr, "        %ld block headers of %d bytes each;\n",
		     sfhd.nbheaders, sizeof(sbhd));
    fprintf(stderr, "        File header states %ld bytes per block!\n",
		     sfhd.bbytes);
    fclose(sourcefile);
    exit(1);
  }

  /* if ((data) && (sfhd.status & 0x7000) && (sfhd.status > 1)) */
  if ((data) && (sfhd.status & 0x7000))
  {
    fprintf(stderr, "stripheaders: cannot split nD \"data\" files!\n");
    fclose(sourcefile);
    exit(1);
  }

  if ((phasefile) && (sfhd.status & 0x7000))
  {
    len = strlen(sourcename);
    strcpy(subname, sourcename);
    subname[len - 9] = '\0';
    strcpy(stripname, subname); strcat(stripname, "f1traces");
    strcpy(headername, stripname);
    strcpy(stripname2, subname); strcat(stripname2, "f2traces");
    strcpy(headername2, stripname2);
    strcat(stripname, ".bin");
    strcat(stripname2, ".bin");
    strcat(headername, ".hdr");
    strcat(headername2, ".hdr");
    strcpy(textname, sourcename);   strcat(textname, ".txt");
  }
  else
  {
    strcpy(stripname, sourcename);  strcat(stripname, ".bin");
    strcpy(headername, sourcename); strcat(headername, ".hdr");
    strcpy(textname, sourcename);   strcat(textname, ".txt");
  }

  /* open target files */
  stripfile = fopen(stripname, "w");
  if (stripfile == NULL)
  {
    fprintf(stderr, "stripheaders: problem opening target file %s\n",
	stripname);
    fclose(sourcefile);
    exit(1);
  }
  headerfile = fopen(headername, "w");
  if (headerfile == NULL)
  {
    fprintf(stderr, "stripheaders: problem opening target file %s\n",
	headername);
    fclose(sourcefile);
    fclose(stripfile);
    exit(1);
  }
  txtfil = fopen(textname, "w");
  if (txtfil == NULL)
  {
    fprintf(stderr, "stripheaders: problem opening target file %s\n",
	textname);
    fclose(sourcefile);
    fclose(stripfile);
    fclose(headerfile);
    exit(1);
  }

  /* write file header information into text file */
  fprintf(txtfil, "Header information for file \"%s\"\n", sourcename);
  fprintf(txtfil, "==============================");
  j = strlen(sourcename);
  if (j < 17) j = 17;
  for (i = 0; i < j; i++) putc((int) '=', txtfil);
  putc((int) '\n', txtfil);
  fprintf(txtfil, "number of blocks (nblocks):           %9ld\n", sfhd.nblocks);
  fprintf(txtfil, "number of traces per block (ntraces): %9ld\n", sfhd.ntraces);
  fprintf(txtfil, "number of points per trace (np):      %9ld\n", sfhd.np);
  fprintf(txtfil, "number of bytes per element (ebytes): %9ld\n", sfhd.ebytes);
  fprintf(txtfil, "number of bytes per trace (tbytes):   %9ld\n", sfhd.tbytes);
  fprintf(txtfil, "number of bytes per block (bbytes):   %9ld\n", sfhd.bbytes);
  fprintf(txtfil, "version-ID (vers_id):                 %9d\n", sfhd.vers_id);
  fprintf(txtfil, "status information (status):          %9d\n", sfhd.status);
  fprintf(txtfil, "   bit#   hex  meaning         value\n");
  if (sfhd.status & 0x1)
    fprintf(txtfil, "     0     0x1 S_DATA          1: data\n");
  else
    fprintf(txtfil, "     0     0x1 S_DATA          0: no data\n");
  if (sfhd.status & 0x2)
    fprintf(txtfil, "     1     0x2 S_SPEC          1: spectrum\n");
  else
    fprintf(txtfil, "     1     0x2 S_SPEC          0: FID\n");
  if (sfhd.status & 0x8)
  {
    fprintf(txtfil, "     2     0x4 S_32            %d (ignored)\n",
		    sfhd.status & 0x4);
    fprintf(txtfil, "     3     0x8 S_FLOAT         1: floating point\n");
  }
  else
  {
    if (sfhd.status & 0x4)
      fprintf(txtfil, "     2     0x4 S_32            1: 32 bits\n");
    else
      fprintf(txtfil, "     2     0x4 S_32            0: 16 bits\n");
    fprintf(txtfil, "     3     0x8 S_FLOAT         0: integer\n");
  }
  if (sfhd.status & 0x10)
    fprintf(txtfil, "     4    0x10 S_COMPLEX       1: complex\n");
  else
    fprintf(txtfil, "     4    0x10 S_COMPLEX       0: real\n");
  if (sfhd.status & 0x20)
    fprintf(txtfil, "     5    0x20 S_HYPERCOMPLEX  1: hypercomplex\n");
  if (sfhd.status & 0x40)
    fprintf(txtfil, "     6    0x40                 1: (unused)\n");
  if (sfhd.status & 0x80)
    fprintf(txtfil, "     7    0x80 S_ACQPAR        1: Acqpar\n");
  if (sfhd.status & 0x100)
    fprintf(txtfil, "     8   0x100 S_SECND         1: second FT\n");
  if (sfhd.status & 0x200)
    fprintf(txtfil, "     9   0x200 S_TRANSF        1: transposed\n");
  if (sfhd.status & 0x400)
    fprintf(txtfil, "    10   0x400                 1: (unused)\n");
  if (sfhd.status & 0x800)
    fprintf(txtfil, "    11   0x800 S_NP            1: np dimension active\n");
  if (sfhd.status & 0x1000)
    fprintf(txtfil, "    12  0x1000 S_NF            1: nf dimension active\n");
  if (sfhd.status & 0x2000)
    fprintf(txtfil, "    13  0x2000 S_NI            1: ni dimension active\n");
  if (sfhd.status & 0x4000)
    fprintf(txtfil, "    14  0x4000 S_NI2           1: ni2 dimension active\n");
  if (sfhd.status & 0x8000)
    fprintf(txtfil, "    15  0x8000                 1: (unused)\n");
  if (setnbh)
    fprintf(txtfil, "number of block headers (nbheaders):  0 -> %ld\n\n",
		     sfhd.nbheaders);
  else
    fprintf(txtfil, "number of block headers (nbheaders):  %9ld\n\n",
		     sfhd.nbheaders);
  
  /* write file header into header file */
  if (debug) printf("writing file header\n");
  ok = fwrite(&sfhd, sizeof(sfhd), 1, headerfile);
  if (!ok)
  {
    fprintf(stderr, "stripheaders: problem writing file header to file %s\n",
		    headername);
    fclose(sourcefile);
    fclose(stripfile);
    fclose(headerfile);
    fclose(txtfil);
    exit(1);
  }

  /* allocate memory for transfer buffer */
  bufsiz = sfhd.bbytes - sizeof(sbhd) * sfhd.nbheaders;
  buffer = (char *) malloc(bufsiz);
  buf0 = buffer;
  if (buffer == NULL)
  {
    fprintf(stderr, "stripheaders: problem allocating buffer memory\n");
    fclose(sourcefile);
    fclose(stripfile);
    fclose(headerfile);
    fclose(txtfil);
    exit(1);
  }
  if (debug) printf("Allocated %ld bytes of buffer memory\n", bufsiz);

  /*---------------------------------------+
  | now process source file block by block |
  +---------------------------------------*/
  ok = 1;
  f1blocks = 0;
  for (i = 0; (i < sfhd.nblocks) && (ok); i++)
  {

    /*----------------------------+
    | first extract block headers |
    +----------------------------*/
    if (debug) printf("processing block %ld out of %ld\n", i+1, sfhd.nblocks);
    for (j = 0; j < sfhd.nbheaders; j++)
    {
      /* read source block header */
      if (debug)
        printf("reading block header %ld of %ld\n", j+1, sfhd.nbheaders);
      ok = fread(&sbhd, sizeof(sbhd), 1, sourcefile);
      if ((j == 0) && (sbhd.status != 0))
         f1blocks++;

      /* write block header into header file */
      if (ok)
      {
        if (debug)
	  printf("writing block header %ld of %ld\n", j+1, sfhd.nbheaders);
        ok = fwrite(&sbhd, sizeof(sbhd), 1, headerfile);
        if (!ok)
        {
          fprintf(stderr, "stripheaders: problem writing block header to %s\n",
	                  headername);
          fclose(sourcefile);
          fclose(stripfile);
          fclose(headerfile);
          fclose(txtfil);
          exit(1);
        }
      }
    }

    if (ok)
    {
      /* read one source data block */
      if (debug) printf("reading data block\n");
      ok = fread(buffer, bufsiz, 1, sourcefile);

      if (ok)
      {
        /* write one data block into stripped binary file */
        if (debug) printf("writing data block\n");
        ok = fwrite(buffer, bufsiz, 1, stripfile);

        if (!ok)
        {
          fprintf(stderr, "stripheaders: problem writing data block to %s\n",
	                  stripname);
          fclose(sourcefile);
          fclose(stripfile);
          fclose(headerfile);
          fclose(txtfil);
          exit(1);
        }
      }
    }
    buffer = buf0;
  }
  fclose(stripfile);
  fclose(headerfile);
  if (!ok) i--;
  if ((phasefile) && (sfhd.status & 0x7000))
  {
    if (f1blocks)
    {
      fprintf(txtfil,
	      "data and headers from %ld F1 block(s) written to the files\n",
	      i);
      fprintf(txtfil, "        %s and %s\n", stripname, headername);
      printf("%ld F1 blocks processed\n", i);
    }
    else
    {
      strcpy(cmd, "rm -f ");
      strcat(cmd, stripname);
      strcat(cmd, " ");
      strcat(cmd, headername);
      (void) system(cmd);
      printf("0 F1 blocks processed\n");
    }
  }
  else
  {
    fprintf(txtfil,
            "number of block(s) written into stripped file:  %ld\n\n", i);
    printf("%ld blocks processed\n", i);
  }

  /*--------------------------------------------------------+
  | for 2D phasefiles process second (f2) block, if present |
  +--------------------------------------------------------*/
  init = 1;
  if ((phasefile) && (sfhd.status & 0x7000))
  {
    /* open new set of target files */
    stripfile2 = fopen(stripname2, "w");
    if (stripfile2 == NULL)
    {
      fprintf(stderr, "stripheaders: problem opening target file %s\n",
	  stripname2);
      fclose(sourcefile);
      fclose(txtfil);
      exit(1);
    }
    headerfile2 = fopen(headername2, "w");
    if (headerfile2 == NULL)
    {
      fprintf(stderr, "stripheaders: problem opening target file %s\n",
	  headername2);
      fclose(sourcefile);
      fclose(stripfile2);
      fclose(txtfil);
      exit(1);
    }
    ok = 1;
    for (i = 0; i < sfhd.nblocks; i++)
    {
  
      /*----------------------------+
      | first extract block headers |
      +----------------------------*/
      if (debug) printf("processing block %ld out of %ld\n", i+1, sfhd.nblocks);
      for (j = 0; (j < sfhd.nbheaders) && (ok); j++)
      {
        /* read source block header */
        if (debug)
          printf("reading block header %ld of %ld\n", j+1, sfhd.nbheaders);
        ok = fread(&sbhd, sizeof(sbhd), 1, sourcefile);
  
        /* write block header into header file */
        if (ok)
        {
          if (init)
          {
  	    if (debug) printf("writing file header\n");
  	    ok = fwrite(&sfhd, sizeof(sfhd), 1, headerfile2);
            if (!ok)
            {
              fprintf(stderr,
	              "stripheaders: problem writing file header to %s\n",
	              headername2);
              fclose(sourcefile);
              fclose(stripfile2);
              fclose(headerfile2);
              fclose(txtfil);
              exit(1);
            }
 	    init = 0;
          }
          if (debug)
	    printf("writing block header %ld of %ld\n", j+1, sfhd.nbheaders);
          ok = fwrite(&sbhd, sizeof(sbhd), 1, headerfile2);
          if (!ok)
          {
            fprintf(stderr,
	            "stripheaders: problem writing block header to %s\n",
	            headername2);
            fclose(sourcefile);
            fclose(stripfile2);
            fclose(headerfile2);
            fclose(txtfil);
            exit(1);
          }
        }
      }
  
      if (ok)
      {
        /* read one source data block */
        if (debug) printf("reading data block\n");
        ok = fread(buffer, bufsiz, 1, sourcefile);
  
        if (ok)
        {
          /* write one data block into stripped binary file */
          if (debug) printf("writing data block\n");
          ok = fwrite(buffer, bufsiz, 1, stripfile2);
  
          if (!ok)
          {
            fprintf(stderr, "stripheaders: problem writing data block to %s\n",
	                    stripname2);
            fclose(sourcefile);
            fclose(stripfile2);
            fclose(headerfile2);
            fclose(txtfil);
            exit(1);
          }
        }
      }
      buffer = buf0;
    }
    fclose(stripfile2);
    fclose(headerfile2);
    if (!ok) i--;
    if (i > 0)
    {
      fprintf(txtfil,
              "data and headers from %ld F2 block(s) written to the files\n",
	      i);
      fprintf(txtfil, "        %s and %s\n\n", stripname2, headername2);
    }
    else
    {
      strcpy(cmd, "rm -f ");
      strcat(cmd, stripname2);
      strcat(cmd, " ");
      strcat(cmd, headername2);
      (void) system(cmd);
    }
    printf("%ld F2 blocks processed\n", i);
  }

  free(buffer);

   
  fclose(sourcefile);
  fclose(txtfil);
  return(0);
}
