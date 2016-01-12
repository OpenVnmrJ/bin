/* fixmsl.c				*/
/* Remove last 1024 bytes of file       */
/* Usage fixmsl inputfile <outputfile>  */
/*  (If outputfile is omitted, output   */
/*   is to inputfile.short              */
/*		19 July 1995		*/
/*		S.L.Patt, Varian	*/

#include <stdio.h>

main(argc,argv)
  int argc; char *argv[];
{
  char inbuf, inname[256], outname[256];
  int i,len;
  FILE *fopen(), *fin, *fout;

  /* Check input arguments */

  if (argc == 1)
    { printf("Usage: fixmsl filename or fixmsl inputfile outputfile\n");
      return(0);
    }
  strcpy(inname, argv[1]);
  if (argc == 2)
    { strcpy(outname, inname);
      strcat(outname,".short");
    }
  else strcpy(outname, argv[2]);
  if (strcmp(outname,inname) == 0)
    { printf("Output filename and input filename must be different\n");
      return(0);
    }

  /* Check ability to read input file and write output file */

  if ((fin=fopen(inname,"r")) == 0)
    { printf("Could not find or read the file \"%s\"\n", inname); return(0); }
  if ((fout=fopen(outname,"w")) == 0)
    { printf("Not able to write the file \"%s\"\n", outname); return(0); }

  /* Determine length of input file */

  len=0; while (getc(fin) != EOF) len=len+1;
  fclose(fin);
  if (len <= 1024)
    { printf("File must be greater than 1024 bytes long!\n"); return(0); }

  /* Read input file, write out all but last 1024 bytes to output */
  fin=fopen(inname,"r");
  for (i=0; i<len-1024; i++)
    { inbuf = getc(fin);
      fputc(inbuf,fout);
    }
  fclose(fin); fclose(fout);
}
