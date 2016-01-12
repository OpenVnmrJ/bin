/* eval_netmask.c - return network info with nmetmask */
static char version_id[] = "@(#)eval_netmask.c 1.5 2009-06-05_20:07";

/* Compilation instruction:
	cc -O -o ../bin/eval_netmask eval_netmask.c
*/

#include <stdio.h>
#include <string.h>

#ifdef DEBUG
#define debug 1
#else
#define debug 0
#endif

main (argc, argv)
  int argc;
  char *argv[];
{
  FILE *maskfile;
  int c;
  char line[256];
  int i, ix = 0;
  unsigned long ip, minmask, tmpmask;
  unsigned long match, bestmatch = 0, net, mask, c_net, c_mask, l1, l2;
  int i1 = 0, i2 = 0, i3 = 0, i4 = 0;
  int a1 = 0, a2 = 0, a3 = 0, a4 = 0;
  int m1 = 0, m2 = 0, m3 = 0, m4 = 0;
  
  /*--------------+
  | Evaluate args |
  +--------------*/
  if ((argc < 2) || (argc > 3))
  {
    fprintf(stderr, "Usage:  eval_mask IP_address <netmask>\n");
    return(1);
  }
  else if ((!strcasecmp(argv[1],"-version")) || 
           (!strcasecmp(argv[1],"--version")))
  {
    printf("%s\n", strstr(version_id,"eval"));
    return(0);
  }
  sscanf(argv[1], "%d.%d.%d.%d", &i1, &i2, &i3, &i4);
  ip = 256*256*256*i1 + 256*256*i2 + 256*i3 + i4;
  if (debug)
    fprintf(stderr, "IP address = %lx\n", ip);

  /*----------------------------------+
  | determine minimum networking part |
  +----------------------------------*/
  i1 = (int) ((ip & 0xff000000) >> 24);
  if (i1 < 128)
    minmask = 0xff000000;
  else if (i1 < 192)
    minmask = 0xffff0000;
  else
    minmask = 0xffffff00;

  /*----------------------------------------------------+
  | check for presence and readability of /etc/netmasks |
  +----------------------------------------------------*/
  if (argc == 2)
  {
    maskfile = fopen("/etc/netmasks","ro");
    if (maskfile == 0)
    {
      if (debug)
        fprintf(stderr,
	  "\"/etc/netmasks\" not readable or empty, use default netmask\n");
      if (i1 < 128)
      {
        printf("%d", i1);
        printf(" 255.0.0.0 ff.0.0.0");
        printf(" %d.0.0.1 %d.255.255.254", i1, i1);
        printf(" %d.0.0.0 %d.255.255.255\n", i1, i1);
      }
      else if (i1 < 192)
      {
        i2 = (int) ((ip & 0xff0000) >> 16);
        printf("%d.%d", i1, i2);
        printf(" 255.255.0.0 ff.ff.0.0");
        printf(" %d.%d.0.1 %d.%d.255.254", i1, i2, i1, i2);
        printf(" %d.%d.0.0 %d.%d.255.255\n", i1, i2, i1, i2);
      }
      else
      {
        i2 = (int) ((ip & 0xff0000) >> 16);
        i3 = (int) ((ip & 0xff00) >> 8);
        printf("%d.%d.%d", i1, i2, i3);
        printf(" 255.255.255.0 ff.ff.ff.0");
        printf(" %d.%d.%d.1 %d.%d.%d.254", i1, i2, i3, i1, i2, i3);
        printf(" %d.%d.%d.0 %d.%d.%d.255\n", i1, i2, i3, i1, i2, i3);
      }
      return(0);
    }

    /*-----------------------------------------------+
    | match IP address with network in /etc/netmasks |
    +-----------------------------------------------*/
    c = getc(maskfile);
    fseek(maskfile, -1, SEEK_CUR);
    while (c != EOF)
    {
      if (debug)
        fprintf(stderr, "reading line #%d\n",ix + 1);
      i = 0;
      while ((c != '#') && (c != '\n') && (c != EOF))
      {
        c = getc(maskfile);
        line[i++] = (char) c;
      }
      line[i-1] = '\0';
      if (debug)
        fprintf(stderr, "line = %s\n", line);
      if (c == '#')
      {
        if (debug)
          fprintf(stderr, "skipping to EOL or EOF\n");
        while ((c != '\n') && (c != EOF))
          c = getc(maskfile);
      }
      if (sscanf(line, "%d.%d.%d.%d %d.%d.%d.%d",
		  &a1, &a2, &a3, &a4, &m1, &m2, &m3, &m4) == 8)
      {
        c_net = 256*256*256*a1 + 256*256*a2 + 256*a3 + a4;
        c_mask = 256*256*256*m1 + 256*256*m2 + 256*m3 + m4;
        if (debug)
          fprintf(stderr, "net-ID: %lx  - netmask: %lx\n", c_net, c_mask);
     /* match = (ip & c_net);
        match = (match & c_mask);  /* may not be necessary */
        match = (ip & c_mask);
        if (debug)
          fprintf(stderr, "match = %lx\n", match);
        if ((match > bestmatch) &&
            ((minmask & ip) == (minmask & c_net)))
        {
          bestmatch = match;
          net = c_net;
          mask = c_mask;
        }
      }
      else
      {
        if (debug)
          fprintf(stderr, "line \"%s\" discarded.\n",line);
      }
      ix++;
      if (c != EOF)
      {
        c = getc(maskfile);
        fseek(maskfile, -1, SEEK_CUR);
      }
    }
    fclose(maskfile);

    /*--------------------------------+
    | no match found in /etc/netmasks |
    +--------------------------------*/
    if (bestmatch == 0)
    {
      if (debug)
        fprintf(stderr,
	        " no match found in \"/etc/netmasks\", use default netmask\n");
      if (i1 < 128)
        mask = 0xff000000;
      else if (i1 < 192)
        mask = 0xffff0000;
      else
        mask = 0xffffff00;
      net = (ip & mask);
    }
  }
  else
  {
    sscanf(argv[2], "%d.%d.%d.%d", &m1, &m2, &m3, &m4);
    mask = 256*256*256*m1 + 256*256*m2 + 256*m3 + m4;
    if (mask == 0)
    {
      if (i1 < 128)
        mask = 0xff000000;
      else if (i1 < 192)
        mask = 0xffff0000;
      else
        mask = 0xffffff00;
    }
    if (debug)
      fprintf(stderr, "netmask = %lx\n", mask);
    net = (ip & mask);
  }
  
  /*------------------+
  | report network ID |
  +------------------*/
  a1 = (int) ((net & 0xff000000) >> 24);
  a2 = (int) ((net & 0xff0000) >> 16);
  a3 = (int) ((net & 0xff00) >> 8);
  a4 = (int) (net & 0xff);
  printf("%d.%d.%d.%d", a1, a2, a3, a4);

  /*----------------------------------------+
  | report netmask (decimal & hex notation) |
  +----------------------------------------*/
  m1 = (int) ((mask & 0xff000000) >> 24);
  m2 = (int) ((mask & 0xff0000) >> 16);
  m3 = (int) ((mask & 0xff00) >> 8);
  m4 = (int) (mask & 0xff);
  printf(" %d.%d.%d.%d %x.%x.%x.%x", m1, m2, m3, m4, m1, m2, m3, m4);

  /*-----------------------------------------------+
  | report usable address range (decimal notation) |
  +-----------------------------------------------*/
  printf(" %d.%d.%d.%d", a1, a2, a3, a4+1);
  l1 = (net | ~mask);
  l2 = l1 - 1;
  m1 = (int) ((l2 & 0xff000000) >> 24);
  m2 = (int) ((l2 & 0xff0000) >> 16);
  m3 = (int) ((l2 & 0xff00) >> 8);
  m4 = (int) (l2 & 0xff);
  printf(" %d.%d.%d.%d", m1, m2, m3, m4);
  
  /*-------------------------------------------------+
  | report broadcasting addresses (decimal notation) |
  +-------------------------------------------------*/
  printf(" %d.%d.%d.%d", a1, a2, a3, a4);
  m1 = (int) ((l1 & 0xff000000) >> 24);
  m2 = (int) ((l1 & 0xff0000) >> 16);
  m3 = (int) ((l1 & 0xff00) >> 8);
  m4 = (int) (l1 & 0xff);
  printf(" %d.%d.%d.%d", m1, m2, m3, m4);

  /*-------------------------+
  | check for "undermasking" |
  +-------------------------*/
  tmpmask = (mask & minmask);
  if (tmpmask != minmask)
  {
    m1 = (int) ((minmask & 0xff000000) >> 24);
    m2 = (int) ((minmask & 0xff0000) >> 16);
    m3 = (int) ((minmask & 0xff00) >> 8);
    m4 = (int) (minmask & 0xff);
    printf(" %d.%d.%d.%d\n", m1, m2, m3, m4);
  }
  else
  {
    printf(" OK\n");
  }
  return(0);
}

