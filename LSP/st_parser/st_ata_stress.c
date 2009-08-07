/* A program to put stress on a POSIX system (stress).
 *
 * Copyright (C) 2001, 2002 Amos Waterland <awaterl@yahoo.com>
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation; either version 2 of the License, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc., 59
 * Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#include <ctype.h>
#include <errno.h>
#include <libgen.h>
#include <math.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <signal.h>
#include <time.h>
#include <unistd.h>
#include <sys/wait.h>

/* By default, print all messages of severity info and above.  */
static int global_debug = 2;


/* Name of this program */
static char *global_progname = "STRESS";

/* Implemention of runtime-selectable severity message printing.  */
#define dbg if (global_debug >= 3) \
            fprintf (stdout, "%s: debug: (%d) ", global_progname, __LINE__), \
            fprintf
#define out if (global_debug >= 2) \
            fprintf (stdout, "%s: info: ", global_progname), \
            fprintf
#define wrn if (global_debug >= 1) \
            fprintf (stderr, "%s: warn: (%d) ", global_progname, __LINE__), \
            fprintf
#define err if (global_debug >= 0) \
            fprintf (stderr, "%s: error: (%d) ", global_progname, __LINE__), \
            fprintf

/* Implementation of check for option argument correctness.  */
#define assert_arg(A) \
          if (++i == argc || ((arg = argv[i])[0] == '-' && \
              !isdigit ((int)arg[1]) )) \
            { \
              err (stderr, "missing argument to option '%s'\n", A); \
              exit (1); \
            }

/* Prototypes for utility functions.  */

static int usage (int status);
#if 0
static int version (int status);
static long long atoll_s (const char *nptr);
static long long atoll_b (const char *nptr);
#endif 
/* Prototypes for worker functions.  */
static int hogcpu (void);
static int hogio (void);
static int hogvm (long long bytes, int hang);
static int hoghdd (long long bytes, int clean);
//int  Stress_main ( long long do_hdd, long long do_hdd_bytes, long long do_timeout, long long do_io, int dbg);



int ST_Davinci_ATA_stress(long long do_hdd, long long do_hdd_bytes, long long do_timeout, long long do_io)
{
  int  pid, children = 0, retval = 0;
  long starttime, stoptime, runtime, forks;


  /* Variables that indicate which options have been selected.  */
  int do_dryrun = 0;
  long long do_backoff = 3000;
  long long do_cpu = 0;
  long long do_vm = 0;
  long long do_vm_bytes = 256 * 1024 * 1024;
  int do_vm_hang = 0;
  int do_hdd_clean = 0;
  int dbg_flg	= 3;			

 /* Default Values for Input Variables */
  
//  do_timeout    = 8*3600;	/* The Tests will run for duration of 8 Hours */
//  do_io         = 5;		/* 5 Tasks for Sync() operation */
//  do_hdd        = 25;  		/* 25 Tasks Performing the HDD I/O Operation */ 
//  do_hdd_bytes  = 10737418240; /* 10MB Size of File */

  

  
  /* Record our start time.  */
  if ((starttime = time (NULL)) == -1)
    {
      err (stderr, "failed to acquire current time\n");
      exit (1);
    }

 /* SuSv3 does not define any error conditions for this function.  */
 // global_progname = basename (argv[0]);

  /* For portability, parse command line options without getopt_long.  */

	global_debug=dbg_flg;
  

 #if 0 /* Concerned to Command Line Input for Main */
 
  for (i = 1; i < argc; i++)
    {
      char *arg = argv[i];

      if (strcmp (arg, "--help") == 0 || strcmp (arg, "-?") == 0)
        {
          usage (0);
        }
      else if (strcmp (arg, "--version") == 0)
        {
          version (0);
        }
      else if (strcmp (arg, "--verbose") == 0 || strcmp (arg, "-v") == 0)
        {
          global_debug = 3;
        }
      else if (strcmp (arg, "--quiet") == 0 || strcmp (arg, "-q") == 0)
        {
          global_debug = 0;
        }
      else if (strcmp (arg, "--dry-run") == 0 || strcmp (arg, "-n") == 0)
        {
          do_dryrun = 1;
        }
      else if (strcmp (arg, "--backoff") == 0)
        {
          assert_arg ("--backoff");
          if (sscanf (arg, "%lli", &do_backoff ) != 1)
            {
              err (stderr, "invalid number: %s\n", arg);
              exit (1);
            }
          if (do_backoff < 0)
            {
              err (stderr, "invalid backoff factor: %lli\n", do_backoff);
              exit (1);
            }
          dbg (stdout, "setting backoff coeffient to %llius\n", do_backoff);
        }
      else if (strcmp (arg, "--timeout") == 0 || strcmp (arg, "-t") == 0)
        {
          assert_arg ("--timeout");
          do_timeout = atoll_s (arg);
          if (do_timeout <= 0)
            {
              err (stderr, "invalid timeout value: %llis\n", do_timeout);
              exit (1);
            }
        }
      else if (strcmp (arg, "--cpu") == 0 || strcmp (arg, "-c") == 0)
        {
          assert_arg ("--cpu");
          do_cpu = atoll_b (arg);
          if (do_cpu <= 0)
            {
              err (stderr, "invalid number of cpu hogs: %lli\n", do_cpu);
              exit (1);
            }
        }
      else if (strcmp (arg, "--io") == 0 || strcmp (arg, "-i") == 0)
        {
          assert_arg ("--io");
          do_io = atoll_b (arg);
          if (do_io <= 0)
            {
              err (stderr, "invalid number of io hogs: %lli\n", do_io);
              exit (1);
            }
        }
      else if (strcmp (arg, "--vm") == 0 || strcmp (arg, "-m") == 0)
        {
          assert_arg ("--vm");
          do_vm = atoll_b (arg);
          if (do_vm <= 0)
            {
              err (stderr, "invalid number of vm hogs: %lli\n", do_vm);
              exit (1);
            }
        }
      else if (strcmp (arg, "--vm-bytes") == 0)
        {
          assert_arg ("--vm-bytes");
          do_vm_bytes = atoll_b (arg);
          if (do_vm_bytes <= 0)
            {
              err (stderr, "invalid vm byte value: %lli\n", do_vm_bytes);
              exit (1);
            }
        }
      else if (strcmp (arg, "--vm-hang") == 0)
        {
          do_vm_hang = 1;
        }
      else if (strcmp (arg, "--hdd") == 0 || strcmp (arg, "-d") == 0)
        {
          assert_arg ("--hdd");
          do_hdd = atoll_b (arg);
          if (do_hdd <= 0)
            {
              err (stderr, "invalid number of hdd hogs: %lli\n", do_hdd);
              exit (1);
            }
        }
      else if (strcmp (arg, "--hdd-noclean") == 0)
        {
          do_hdd_clean = 2;
        }
      else if (strcmp (arg, "--hdd-bytes") == 0)
        {
          assert_arg ("--hdd-bytes");
          do_hdd_bytes = atoll_b (arg);
          if (do_hdd_bytes <= 0)
            {
              err (stderr, "invalid hdd byte value: %lli\n", do_hdd_bytes);
              exit (1);
            }
        }
      else
        {
          err (stderr, "unrecognized option: %s\n", arg);
          exit (1);
        }
    }

  #endif 









  /* Print startup message if we have work to do, bail otherwise.  */
  if (do_cpu + do_io + do_vm + do_hdd)
    {
      out (stdout, "dispatching %lli cpu hogs, %lli io hogs, %lli vm hogs, "
           "%lli hdd hogs\n", do_cpu, do_io, do_vm, do_hdd);
    }
  else
    usage (0);

  /* Round robin dispatch our worker processes.  */
  while ((forks = (do_cpu + do_io + do_vm + do_hdd)))
    {
      long long backoff, timeout = 0;

      /* Calculate the backoff value so we get good fork throughput.  */
      backoff = do_backoff * forks;
      dbg (stdout, "using backoff sleep of %llius\n", backoff);

      /* If we are supposed to respect a timeout, calculate it.  */
      if (do_timeout)
        {
          long long currenttime;

          /* Acquire current time.  */
          if ((currenttime = time (NULL)) == -1)
            {
              perror ("error acquiring current time");
              exit (1);
            }

          /* Calculate timeout based on current time.  */
          timeout = do_timeout - (currenttime - starttime);

          if (timeout)
            {
              dbg (stdout, "setting timeout to %llis\n", timeout);
            }
          else
            {
              dbg (stdout, "used up time before all workers dispatched\n");
              break;
            }
        }

      if (do_cpu)
        {
          switch (pid = fork ())
            {
            case 0:            /* child */
              alarm (timeout);
              usleep (backoff);
              if (do_dryrun)
                exit (0);
              exit (hogcpu ());
            case -1:           /* error */
              err (stderr, "fork failed\n");
              break;
            default:           /* parent */
              dbg (stdout, "--> hogcpu worker %i forked\n", pid);
              ++children;
            }
          --do_cpu;
        }

      if (do_io)
        {
          switch (pid = fork ())
            {
            case 0:            /* child */
              alarm (timeout);
              usleep (backoff);
              if (do_dryrun)
                exit (0);
              exit (hogio ());
            case -1:           /* error */
              err (stderr, "fork failed\n");
              break;
            default:           /* parent */
              dbg (stdout, "--> hogio worker %i forked\n", pid);
              ++children;
            }
          --do_io;
        }

      if (do_vm)
        {
          switch (pid = fork ())
            {
            case 0:            /* child */
              alarm (timeout);
              usleep (backoff);
              if (do_dryrun)
                exit (0);
              exit (hogvm (do_vm_bytes, do_vm_hang));
            case -1:           /* error */
              err (stderr, "fork failed\n");
              break;
            default:           /* parent */
              dbg (stdout, "--> hogvm worker %i forked\n", pid);
              ++children;
            }
          --do_vm;
        }

      if (do_hdd)
        {
          switch (pid = fork ())
            {
            case 0:            /* child */
              alarm (timeout);
              usleep (backoff);
              if (do_dryrun)
                exit (0);
              exit (hoghdd (do_hdd_bytes, do_hdd_clean));
            case -1:           /* error */
              err (stderr, "fork failed\n");
              break;
            default:           /* parent */
              dbg (stdout, "--> hoghdd worker %i forked\n", pid);
              ++children;
            }
          --do_hdd;
        }
    }

  /* Wait for our children to exit.  */
  while (children)
    {
      int status, ret;

      if ((pid = wait (&status)) > 0)
        {
          --children;

          if (WIFEXITED (status))
            {
              if ((ret = WEXITSTATUS (status)) == 0)
                {
                  dbg (stdout, "<-- worker %i returned normally\n", pid);
                }
              else
                {
                  err (stderr, "<** worker %i returned error %i\n", pid, ret);
                  ++retval;
                }
            }
          else if (WIFSIGNALED (status))
            {
              if ((ret = WTERMSIG (status)) == SIGALRM)
                {
                  dbg (stdout, "<-- worker %i signalled normally\n", pid);
                }
              else
                {
                  err (stderr, "<** worker %i got signal %i\n", pid, ret);
                  ++retval;
                }
            }
          else
            {
              err (stderr, "<** worker %i exited abnormally\n", pid);
              ++retval;
            }
        }
      else
        {
          err (stderr, "error waiting for worker: %s\n", strerror (errno));
          ++retval;
          break;
        }
    }

  /* Record our stop time.  */
  if ((stoptime = time (NULL)) == -1)
    {
      err (stderr, "failed to acquire current time\n");
      exit (1);
    }

  /* Calculate our runtime.  */
  runtime = stoptime - starttime;

  /* Print final status message.  */
  if (retval)
    {
      err (stderr, "failed run completed in %lis\n", runtime);
    }
  else
    {
      out (stdout, "successful run completed in %lis\n", runtime);
     // out (stdout,"Stress Completed \n");
    }

//  exit (retval);
    return(retval);   	
}

#if 1
int
hogcpu (void)
{
  while (1)
    //sqrt (rand ());

  return 0;
}

#endif 
int
hogio ()
{
  while (1)
    sync ();

  return 0;
}

int
hogvm (long long bytes, int hang)
{
  long long i;
  char *ptr;

  while (1)
    {
      if ((ptr = (char *) malloc (bytes * sizeof (char))))
        {
          for (i = 0; i < bytes; i++)
            ptr[i] = 'Z';       /* Ensure that COW happens.  */
          dbg (stdout, "hogvm worker malloced %lli bytes\n", i);
        }
      else
        {
          err (stderr, "hogvm malloc failed: %s\n", strerror (errno));
          return 1;
        }

      if (hang)
        {
          dbg (stdout, "sleeping forever with allocated memory\n");
          while (1)
            sleep (1024);
        }

      free (ptr);
    }

  return 0;
}



int
hoghdd (long long bytes, int clean)
{
  long long i, j;
  int fd;
  int chunk = (1024 * 1024) - 1;        /* Minimize slow writing.  */
  char buff[chunk];

  /* Initialize buffer with some random ASCII data.  */
  dbg (stdout, "seeding buffer with random data\n");
  for (i = 0; i < chunk - 1; i++)
    {
      j = rand ();
      j = (j < 0) ? -j : j;
      j %= 95;
      j += 32;
      buff[i] = j;
    }

  buff[i] = '\n';

  while (1)
    {
      char  name[]="/hd/stress.XXXXXX";

      if ((fd = mkstemp (name)) < 0)
        {
          err (stderr, "mkstemp failed: %s\n", strerror (errno));
          return 1;
        }

      if (clean == 0)
        {
          dbg (stdout, "unlinking %s\n", name);
          if (unlink (name))
            {
              err (stderr, "unlink failed\n");
              return 1;
            }
        }

      dbg (stdout, "fast writing to %s\n", name);
      for (j = 0; bytes == 0 || j + chunk < bytes; j += chunk)
        {
          if (write (fd, buff, chunk) != chunk)
            {
              err (stderr, "write failed\n");
              return 1;
            }
        }

      dbg (stdout, "slow writing to %s\n", name);
      for (; bytes == 0 || j < bytes - 1; j++)
        {
          if (write (fd, "Z", 1) != 1)
            {
              err (stderr, "write failed\n");
              return 1;
            }
        }
      if (write (fd, "\n", 1) != 1)
        {
          err (stderr, "write failed\n");
          return 1;
        }
      ++j;

      dbg (stdout, "closing %s after writing %lli bytes\n", name, j);
      close (fd);

      if (clean == 1)
        {
          if (unlink (name))
            {
              err (stderr, "unlink failed\n");
              return 1;
            }
        }
    }

  return 0;
}

#if 0
/* Convert a string representation of a number with an optional size suffix
 * to a long long.
 */
long long
atoll_b (const char *nptr)
{
  int pos;
  char suffix;
  long long factor = 0;
  long long value;

  if ((pos = strlen (nptr) - 1) < 0)
    {
      err (stderr, "invalid string\n");
      exit (1);
    }

  switch (suffix = nptr[pos])
    {
    case 'b':
    case 'B':
      factor = 0;
      break;
    case 'k':
    case 'K':
      factor = 10;
      break;
    case 'm':
    case 'M':
      factor = 20;
      break;
    case 'g':
    case 'G':
      factor = 30;
      break;
    default:
      if (suffix < '0' || suffix > '9')
        {
          err (stderr, "unrecognized suffix: %c\n", suffix);
          exit (1);
        }
    }

  if (sscanf (nptr, "%lli", &value) != 1)
    {
      err (stderr, "invalid number: %s\n", nptr);
      exit (1);
    }

  value = value << factor;

  return value;
}


/* Convert a string representation of a number with an optional time suffix
 * to a long long.
 */
long long
atoll_s (const char *nptr)
{
  int pos;
  char suffix;
  long long factor = 1;
  long long value;

  if ((pos = strlen (nptr) - 1) < 0)
    {
      err (stderr, "invalid string\n");
      exit (1);
    }

  switch (suffix = nptr[pos])
    {
    case 's':
    case 'S':
      factor = 1;
      break;
    case 'm':
    case 'M':
      factor = 60;
      break;
    case 'h':
    case 'H':
      factor = 60 * 60;
      break;
    case 'd':
    case 'D':
      factor = 60 * 60 * 24;
      break;
    case 'y':
    case 'Y':
      factor = 60 * 60 * 24 * 360;
      break;
    default:
      if (suffix < '0' || suffix > '9')
        {
          err (stderr, "unrecognized suffix: %c\n", suffix);
          exit (1);
        }
    }

  if (sscanf (nptr, "%lli", &value) != 1)
    {
      err (stderr, "invalid number: %s\n", nptr);
      exit (1);
    }

  value = value * factor;

  return value;
}

#endif 

#if 0
int
version (int status)
{
  char *mesg = "%s %s\n";

  fprintf (stdout, mesg, global_progname, VERSION);

  if (status <= 0)
    exit (-1 * status);

  return 0;
}

#endif 

static int
usage (int status)
{
  char *mesg =
    "`%s' imposes certain types of compute stress on your system\n\n"
    "Usage: %s [OPTION [ARG]] ...\n"
    " -?, --help            show this help statement\n"
    "     --version         show version statement\n"
    " -v, --verbose         be verbose\n"
    " -q, --quiet           be quiet\n"
    " -n, --dry-run         show what would have been done\n"
    " -t, --timeout n       timeout after n seconds\n"
    "     --backoff n       wait for factor of n us before starting work\n"
    " -c, --cpu n           spawn n workers spinning on sqrt()\n"
    " -i, --io n            spawn n workers spinning on sync()\n"
    " -m, --vm n            spawn n workers spinning on malloc()\n"
    "     --vm-bytes b      malloc b bytes (default is 256MB)\n"
    "     --vm-hang         go to sleep after memory allocated\n"
    " -d, --hdd n           spawn n workers spinning on write()\n"
    "     --hdd-bytes b     write b bytes of random data (default is 1GB)\n"
    "     --hdd-noclean     do not unlink file to which random data written\n\n"
    "Example: %s --cpu 8 --io 4 --vm 2 --vm-bytes 128M --timeout 10s\n\n"
    "Notes: Suffixes may be s,m,h,d,y (time) or k,m,g (size).\n";

  fprintf (stdout, mesg, global_progname, global_progname, global_progname);

  if (status <= 0)
    exit (-1 * status);

  return 0;
}

