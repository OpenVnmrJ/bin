/*----------------------------------------------------------------------+
|      JEOLTOVAR  -  converts JEOL data to VARIAN format		|
|									|
|      Since the Jeol data and Varian data are both 32-bit words	|
|      acquired simultaneously, the only thing to do is to swap		|
|      the bytes around because VAX and SPARC orderings are different	|
|      in the case SAMPO is smaller than POINT, we only want to convert	|
|      SAMPO points and skip the zeroes up to POINT in each trace	|
|									|
|      JEOLTOVAR2 (alias)  - converts phase-sensitive (States et al.)	|
|			     JEOL data to VARIAN format			|
|									|
| Usage: jeoltovar input_file output_file nblocks np <points>		|
|									|
|	 argv[1]: input file, *.gxd or *.GXD fid data file		|
|	 argv[2]: VNMR fid file to be constructed			|
|			($vnmruser/expn/acqfil/fid or *.fid/fid)	|
|	 argv[3]: number of blocks (traces, 1 in case of 1D data)	|
|	 argv[4]: number of points (np/SAMPO) to be converted per trace	|
|	 argv[5]: (optional) number of points per JEOL fid trace; if	|
|			this argument is omitted, POINT is assumed to	|
|			be equal to SAMPO or the next higher powre of 2	|
|									|
| Usage: jeoltovar2 in_file1 in_file2 output_file nblocks np <points>	|
|	 argv[1]: 1st input file ("phase=1")				|
|	 argv[2]: 2nd input file ("phase=2")				|
|	 argv[3] - argv[6] correspond to argv[2] - argv[5] in jeoltovar	| 
|									|
| Compilation:   cc -O4 -o /vnmr/bin/jeoltovar jeoltovar.c		|
|		 ln -s /vnmr/bin/jeoltovar /vnmr/bin/jeoltovar2		|
|	for more runtime output use					|
|		 cc -O4 -o /vnmr/bin/jeoltovar jeoltovar.c -DDEBUG	|
|									|
|      David S. Stephenson                    Munich, November 1992	|
|      r.kyburz  93-02-16  updated header structure to current standard	|
|			   fixed status fields				|
|			   only convert SAMPO points, skip zeroes in	|
|				2D data sets				|
+----------------------------------------------------------------------*/

#include <stdio.h>
#include <string.h>

#define MAXSTR 1024

#define S_DATA		 0x1
#define S_32		 0x4
#define S_COMPLEX	0x10
#define S_HYPERCOMPLEX	0x20

/*****************/
struct datafilehead
/*****************/
/* Used at the beginning of each data file (fid's, spectra, 2D)  */
{
  long nblocks;        /* number of blocks in file     */
  long ntraces;        /* number of traces per block   */
  long np;             /* number of elements per trace */
  long ebytes;         /* number of bytes per element  */
  long tbytes;         /* number of bytes per trace    */
  long bbytes;         /* number of bytes per block    */
  short vers_id;       /* transposed storage flag      */
  short status;        /* status of whole file         */
  long nblockheaders;  /* reserved for future use      */
};

/******************/
struct datablockhead
/******************/
/* Each file block contains the following header       */
{
  short scale;         /* scaling factor               */
  short status;        /* status of data in block      */
  short index;         /* block index                  */
  short mode;          /* reserved for future use      */
  long  ctcount;       /* completed transients in fids */
  float lpval;         /* left phase in phasefile      */
  float rpval;         /* right phase in phasefile     */
  float lvl;           /* level drift correction       */
  float tlt;           /* tilt drift correction        */
};

main(argc,argv)
   int argc;
   char *argv[];
{
   struct datafilehead  *file_head;
   struct datablockhead *block_head;

   FILE *infile, *infile2, *outfile, *fopen();
   unsigned char *buffer,swap;
   char command[MAXSTR];
   char *cmdname;
   int i,j,nfids,nblocks,np,points,fstatus,bstatus,ph2d=0;
   void error();

   /* convert input parameters */
   cmdname = strstr(argv[0],"jeoltovar");
   fstatus = bstatus = S_DATA + S_32 + S_COMPLEX;
   ph2d = strcmp(cmdname,"jeoltovar");
   if (ph2d)
   {
      if (argc < 6)
      { 
         fprintf(stderr,
"Usage: jeoltovar2 in_file1 in_file2 out_file nblocks np <points>\n");
         error();
      }
      nblocks = atoi(argv[4]);
      np      = atoi(argv[5]);
      if (argc > 6)
         points = atoi(argv[6]);
      else
      {
         for (points = 2; points < np; points *= 2);
      }
      fstatus += S_HYPERCOMPLEX;
      nfids = 2 * nblocks;
   }
   else
   {
      if (argc < 5)
      {
         fprintf(stderr,
"Usage: jeoltovar in_file out_file nblocks np <points>\n");
         error();
      }
      nblocks = atoi(argv[3]);
      np      = atoi(argv[4]);
      if (argc > 5)
         points = atoi(argv[5]);
      else
         for (points = 2; points < np; points *= 2);
      nfids = nblocks;
   }

#ifdef DEBUG
   printf("in_file  = %s\n", argv[1]);
   if (ph2d)
   {
      printf("in_file2 = %s\n", argv[2]);
      printf("out_file = %s\n", argv[3]);
   }
   else
   {
      printf("out_file = %s\n", argv[2]);
   }
   printf("nblocks  = %d", nblocks);
   if (ph2d) printf(" x 2\n"); else putchar('\n');
   printf("np       = %d\n", np);
   printf("points   = %d\n", points);
#endif

   /* open files */
   if((infile  = fopen(argv[1],"r")) == NULL)
   {
      fprintf(stderr,"%s: can't open input file\n", argv[0]);
      error();
   }
   if (ph2d)
   {
      if((infile2  = fopen(argv[2],"r")) == NULL)
      {
         fprintf(stderr,"jeoltovar2: can't open second input file\n");
	 fclose(infile);
         error();
      }
      if((outfile = fopen(argv[3],"w")) == NULL)
      {
         fprintf(stderr,"jeoltovar2: can't open output file\n");
	 fclose(infile);
	 fclose(infile2);
         error();
      }
   }
   else
   {
      if((outfile = fopen(argv[2],"w")) == NULL)
      {
         fprintf(stderr,"jeoltovar: can't open output file\n");
	 fclose(infile);
         error();
      }
   }

   /* allocate buffers and fill in headers */
   file_head = (struct datafilehead *)
      calloc(1,sizeof(struct datafilehead));
   block_head = (struct datablockhead *) 
      calloc(1,sizeof(struct datablockhead));

   file_head->nblocks = nfids;
   file_head->ntraces = 1;
   file_head->np      = np;
   file_head->ebytes  = 4;
   file_head->tbytes  = file_head->np*file_head->ebytes;
   file_head->bbytes  = file_head->tbytes + 
                        sizeof(struct datablockhead);
   file_head->vers_id = 65;
   file_head->status  = fstatus;
   file_head->nblockheaders = 1;

   block_head->scale  = 0;
   block_head->status = bstatus;
   block_head->index  = 1;
   block_head->mode   = 0;
   block_head->ctcount= 1;
   block_head->lpval  = 0;
   block_head->rpval  = 0;
   block_head->lvl    = 0;
   block_head->tlt    = 0;

   buffer = (unsigned char *) 
      calloc(np,sizeof(unsigned long));

   /* write fileheader to outfile */
   if (fwrite(file_head,sizeof(struct datafilehead),1,outfile) < 1)
   {
      fprintf(stderr,"%s: write error\n",argv[0]);
      fclose(infile);
      fclose(infile2);
      fclose(outfile);
      error();
   }

   /* loop over blocks until all points are written out */
   for(j=0;j<nblocks;j++)
   {

      /* write blockheader to outfile */
      if(fwrite(block_head,sizeof(struct datablockhead),1,outfile) < 1)
      {
         fprintf(stderr,"%s: write error\n",argv[0]);
         fclose(infile);
         fclose(infile2);
         fclose(outfile);
         error();
      }
      block_head->index++;

      /* read in block, swap the bytes and write it out */
      if (fread(buffer,sizeof(unsigned long),np,infile) < np)
      {
         fprintf(stderr,"%s: %s read error\n",argv[0],argv[1]);
         fclose(infile);
         fclose(infile2);
         fclose(outfile);
   	 cfree(buffer);
         error();
      }
      for (i=0;i<file_head->tbytes;i+=4)
      {
         swap          = *(buffer+i);
         *(buffer+i)   = *(buffer+i+3);
         *(buffer+i+3) = swap;
         swap          = *(buffer+i+1);
         *(buffer+i+1)   = *(buffer+i+2);
         *(buffer+i+2) = swap;
      }
      fseek(infile,(points-np)*sizeof(unsigned long),1);

      if (fwrite(buffer,sizeof(unsigned long),np,outfile) < np)
      {
         fprintf(stderr,"%s: write error\n",argv[0]);
         fclose(infile);
         fclose(infile2);
         fclose(outfile);
   	 cfree(buffer);
         error();
      }

      if (ph2d)
      {
         /* write blockheader to outfile */
         if(fwrite(block_head,sizeof(struct datablockhead),1,outfile) < 1)
         {
            fprintf(stderr,"%s: write error\n",argv[0]);
            fclose(infile);
            fclose(infile2);
            fclose(outfile);
            error();
         }
         block_head->index++;

         /* read in block, swap the bytes and write it out */
         if (fread(buffer,sizeof(unsigned long),np,infile2) < np)
         {
            fprintf(stderr,"%s: %s read error\n",argv[0],argv[2]);
            fclose(infile);
            fclose(infile2);
            fclose(outfile);
   	    cfree(buffer);
            error();   
         }
         for (i=0;i<file_head->tbytes;i+=4)
         {
            swap          = *(buffer+i);
            *(buffer+i)   = *(buffer+i+3);
            *(buffer+i+3) = swap;
            swap          = *(buffer+i+1);
            *(buffer+i+1)   = *(buffer+i+2);
            *(buffer+i+2) = swap;
         }
         fseek(infile2,(points-np)*sizeof(unsigned long),1);
    
         if (fwrite(buffer,sizeof(unsigned long),np,outfile) < np)
         {
            fprintf(stderr,"%s: write error\n",argv[0]);
            fclose(infile);
            fclose(infile2);
            fclose(outfile);
   	    cfree(buffer);
            error();
         }
      }
   }

/* tidy it all up                                                     */
   fclose(infile);
   if (ph2d)
      fclose(infile2);
   fclose(outfile);
   cfree(buffer);

}

void
error()
{
   exit();
}
