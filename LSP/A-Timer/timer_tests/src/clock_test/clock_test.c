/*********************************************************************
arm_v5t_le-gcc -lpthread -lrt -o clock_test clock_test.c
********************************************************************/
/*********************************************************************
    Program to exercise the posix time subsystem of Linux

    Copyright (C) 2004 Silicon Graphics, Inc. All rights reserved

    Christoph Lameter <christoph@lameter.com>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

********************************************************************/

#define POSIX_SOURCE 1
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <time.h>
#include <errno.h>
#include <asm/unistd.h>
#include <pthread.h>
#include <strings.h>
#include <sys/time.h>
#include <getopt.h>
#include <string.h>

extern int errno;



#define VERSION "0.2"

/* Default program options */
int verbose = 0;
int clockid = CLOCK_REALTIME;
int interval = 1234567;
int count = 5;
int use_glibc = 0;
int busywait = 0;

#define PID_MAX_LIMIT (sizeof(long) > 4 ? 4*1024*1024 : 0x8000)

/* We need to be able to redirect these calls to bypass glibc since
 * there are old version of glibc around that do not support all these calls.
 */

int t_clock_getres(int clk_id, struct timespec *res) {
	if (use_glibc)
		return clock_getres(clk_id,res);
	else
		return syscall(__NR_clock_getres, clk_id, res);
}

int t_clock_gettime(int clk_id, struct timespec *tp) {
	if (use_glibc)
		return clock_gettime(clk_id, tp);
	else
		return syscall(__NR_clock_gettime, clk_id, tp);
}

int t_clock_settime(int clk_id, struct timespec *tp) {
	if (use_glibc)
		return clock_settime(clk_id, tp);
	else
		return syscall(__NR_clock_settime, clk_id, tp);
}

int t_clock_getcpuclockid(int pid, int *clock) {
	if (use_glibc)
		return clock_getcpuclockid(pid,clock);

	*clock = ((pid == 0) ? CLOCK_PROCESS_CPUTIME_ID : -pid);
	return 0;
}

int t_timer_create(int clockid, struct sigevent *evp,
	timer_t *t) {

	if (use_glibc)
		return timer_create(clockid, evp, t);
	else
		return syscall(__NR_timer_create, clockid, evp, t);
}

int t_timer_gettime(timer_t t,struct itimerspec *value) {
	if (use_glibc)
		return timer_gettime(t,value);
	else
		return syscall(__NR_clock_gettime, t, value);
}

int t_timer_settime(timer_t t,int flags,
	const struct itimerspec *value, struct itimerspec *ovalue) {
	if (use_glibc)
		return timer_settime(t, flags, value, ovalue);
	else
		return syscall(__NR_timer_settime, t, flags, value, ovalue);
}

int t_timer_delete(timer_t t) {
	if (use_glibc)
		return timer_delete(t);
	else
		return syscall(__NR_timer_delete, t);
}

int t_timer_getoverrun(timer_t t) {
	if (use_glibc)
		return timer_getoverrun(t);
	else
		return syscall(__NR_timer_getoverrun, t);
}

char *clockstr [] = {
	/* 0-3 Standard POSIX Clocks */
	"REALTIME","MONOTONIC","PROCESS_CPUTIME_ID","THREAD_CPUTIME_ID",
	/* 4-5 Unused clocks mentioned in linux 2.6.9 source code */
	"REALTIME_HR","MONOTONIC_HR",
	/* 6-9 spacer */
	"6","7","8","9",
	/* 10- Driver specific clocks */
	"SGI_CYCLE",
	NULL
};

int clockstr_to_id(char *s) {
	char **p;

	if (isdigit(*s)) return atoi(s);
	if (strncmp(s,"CLOCK_",6) ==0) s+=6;

	for(p= clockstr;*p;*p++) if (strcasecmp(s,*p)==0) return p-clockstr;
	return -1;
}

char *clockid_to_str(int n) {
	static char buffer[40];

	if (n<0) {
		n = -n;
		if (n < (8 << 20))
			sprintf(buffer, "CLOCK_PROCESS(%d)", n);
		else {
			n -= (8 << 20);
			sprintf(buffer, "CLOCK_THREAD(%d)", n);
		}
	} else
	if (n < sizeof(clockstr) / sizeof(char *))
		sprintf(buffer, "CLOCK_%s", clockstr[n]);
	else
		sprintf(buffer, "CLOCK(%d)", n);
out:
	return buffer;
}

unsigned long long time_diff(const struct timespec *t1, const struct timespec *t2) {
	return t2->tv_nsec - t1->tv_nsec + (t2->tv_sec - t1->tv_sec) * 1000000000LL;
}

void pr(int clock)
{
	struct timespec tv = {1,2};
	struct timespec res = {3,4};
	int rc;

	rc=t_clock_getres(clock,&res);
	if (rc) {
		printf("getres return code on %s=%d errno=%d\n",clockid_to_str(clock),rc,errno);
	}
	rc=t_clock_gettime(clock,&tv);
	if (rc) {
		printf("gettime return code on %s=%d errno=%d\n",clockid_to_str(clock),rc, errno);
	}
	else
	printf("%25s=% 11ld.%09ld resolution=% 2ld.%09ld\n",clockid_to_str(clock),tv.tv_sec,tv.tv_nsec,res.tv_sec,res.tv_nsec);
}

void fourclocks(void) {
	int i;

	for(i=0; i<4; i++) pr(i);
}


int y;

void kx(long long x) {
	y=x;
};

void single_thread(void) {
	int i;

	/* Waste some time */
	printf("\nSingle Thread Testing\n--------------------\n");
	fourclocks();
	printf("10,000,000 divisions ...\n");
	for(i=1;i<10000000;i++) kx(1000000000000LL/i);
	fourclocks();
}

struct timespec zero;

pthread_t thread[10];

struct tinfo {
	int i;
	struct timespec ttime,ptime;
} tinf[10];

void *thread_function(void *x) {
	struct tinfo *t=x;
	int i;

	for(i=1;i< t->i;i++) kx(1000000000000LL/i);
	t_clock_gettime(CLOCK_THREAD_CPUTIME_ID,&t->ttime);
	t_clock_gettime(CLOCK_PROCESS_CPUTIME_ID,&t->ptime);
	return NULL;
}

void multi_thread(void) {
	int i;
	int initpclock;
	int selftclock;

	/* Waste some more time in threads */
	printf("\nMulti Thread Testing\n----------------------\n");
	fourclocks();
	printf("Starting Thread:");
	for(i=0;i<10;i++) {
		tinf[i].i=i*1000000;
		if (pthread_create(&thread[i], NULL, thread_function, tinf+i))
			perror("thread");
		else
			printf(" %d",i);
	}
	printf("\n Joining Thread:");
	for(i=0;i<10;i++)
		if (pthread_join( thread[i], NULL))
			perror("join");
		else
			printf(" %d",i);
	printf("\n");
	for(i=0;i<10;i++) {
		printf("%d Cycles=%7d Thread=% 3ld.%09ldns Process=% 3ld.%09ldns\n",i,tinf[i].i,tinf[i].ttime.tv_sec,tinf[i].ttime.tv_nsec,tinf[i].ptime.tv_sec,tinf[i].ptime.tv_nsec);
	}
	if (t_clock_getcpuclockid(1,&initpclock))
		printf("clock_getcpuclockid failed\n");
	if (pthread_getcpuclockid(pthread_self(),&selftclock))
		printf("pthread_getcpuclockid failed\n");
	pr(initpclock);
	pr(selftclock);
	printf("process clock of init (1) = %d. My own threadclock =%d\n",initpclock,selftclock);
	fourclocks();
}

static volatile sig_atomic_t timer_tick = 0;
#define MAX_STEPS 1000

struct timespec ev[MAX_STEPS];
int overruns[MAX_STEPS];
int soverruns[MAX_STEPS];

int g_nsteps;
timer_t timer_id;

void sigalarm(int signo, siginfo_t *si, void *x)
{
printf("si = 0x%x", si);
//	soverruns[timer_tick] = si->si_overrun;
	overruns[timer_tick] = t_timer_getoverrun(timer_id);
	t_clock_gettime(CLOCK_REALTIME,ev + timer_tick++ );

	if (timer_tick == g_nsteps) {
		struct itimerspec ts;

		/* Disarm timer */
		ts.it_interval = zero;
		ts.it_value = zero;
		t_timer_settime(timer_id, 0, &ts, NULL);
	}
	printf(".");
//    fflush(stdout);
}


int timer_test(int clockid, int nanosec, int nsteps) {
	struct itimerspec ts;
	struct sigevent se;
	struct sigaction act;
	struct timespec time0,time1;
	int i;
	int signum = SIGRTMAX;
	int status;

	if (nsteps > MAX_STEPS) {
		printf("Maximum number of steps is %d\n",MAX_STEPS);
		exit(1);
	}

	g_nsteps = nsteps;

	timer_tick = 0;
	/* Set up signal handler: */
	sigfillset(&act.sa_mask);
	act.sa_flags = 0;
	act.sa_sigaction = sigalarm;
	sigaction(signum, &act, NULL);

	/* Set up timer: */
	memset(&se, 0, sizeof(se));
	se.sigev_notify = SIGEV_SIGNAL;
	se.sigev_signo = signum;
	se.sigev_value.sival_int = 0;
	status = t_timer_create(clockid, &se, &timer_id);
	if (status < 0) {
		perror("timer_create");
		return -1;
	}
	/* Start timer: */
	ts.it_interval.tv_sec = nanosec / 1000000000;
	ts.it_interval.tv_nsec = (nanosec % 1000000000);
	ts.it_value = ts.it_interval;
	/* Tick */
	t_clock_gettime(CLOCK_REALTIME,&time0);
	printf("Receiving signals: ");
//	fflush(stdout);
	status = t_timer_settime(timer_id, 0, &ts, NULL);
	if (status < 0) {
		perror("timer_settime");
		t_timer_delete(timer_id);
		return -1;
	}

	/* Loop: */
	if (busywait) {
		while (timer_tick < nsteps)	;
	} else {
		while (timer_tick < nsteps)
			sched_yield();
	}
	/* Tock */
	ts.it_interval = zero;
	ts.it_value = zero;
	t_timer_settime(timer_id, 0, &ts, NULL);
	t_clock_gettime(CLOCK_REALTIME, &time1);
//	printf("\nOverruns: %d\n", t_timer_getoverrun(timer_id));
	t_timer_delete(timer_id);
	printf("\nTotal time=%luns\n", time1.tv_nsec - time0.tv_nsec + (time1.tv_sec - time0.tv_sec)*1000000000LL);

	printf("Events (%d in an interval of %dns)\n",nsteps, nanosec);
	for(i=0; i < nsteps; i++) {
		long ns = ev[i].tv_nsec - time0.tv_nsec + (ev[i].tv_sec - time0.tv_sec)*1000000000LL;
		printf("Signal #%d received in %luns. Overruns=%d/%d Target was=%ld Diff=%d\n",i+1,ns,overruns[i],soverruns[i],(i+1)*interval,ns-(i+1)*interval);
	}

	return 0;
}

void standard_timer_test(void) {
	printf("\nTest %s signal scheduling:\n"
		"----------------------------------------------\n",clockid_to_str(clockid));
	timer_test(clockid,interval,count);
}

void other_processes_clocks_test(void) {
	int i;

	printf("\nTest other processes clocks:\n------------------------------\n");
	for(i=1 ; i< 100; i+=10) {
		printf("Process %d:\n",i);
		pr(-i);
		pr(-i - PID_MAX_LIMIT);
	}
	printf("\n");
}

void clock_scan(void) {
	int i;
	int n = 0;
	struct timespec t;
	int status;

	printf("Scan for available clocks:\n");
	printf("--------------------------\n");

	if (use_glibc) {
		/* Test for broken posix behavior */
		struct timespec t;

		printf("Using glibc function calls for posix time\n");
		if (clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &t)==0) {
			struct timespec t2;

			sleep(1);
			clock_gettime(CLOCK_PROCESS_CPUTIME_ID,&t2);
			if (time_diff(&t,&t2) >100000000LL)
				printf("\nPOSIX violation: real time returns instead of cpu time for CLOCK_*_CPUTIME_ID!\n\n");
		}
	}

	if ((status = t_clock_gettime(-1, &t)) == 0)
		printf("Process clocks available.\n");
	else if (verbose)
		printf("Process Clock Error = %d %d\n", status, errno);
	if ((status = t_clock_gettime(-PID_MAX_LIMIT -1, &t)) == 0)
		printf("Thread clocks available.\n");
	else if (verbose)
		printf("Thread Clock Error = %d %d\n", status, errno);

	printf("\n");
	for(i=0; i < 100; i++) {
		status = t_clock_gettime(i, &t);

		if (verbose && status)
			printf("Status for %s = %d %d\n", clockid_to_str(i), status, errno);

		if (!status) {
			printf("%s\n",clockid_to_str(i));
			n++;
		}
	}
	printf("\n%d clocks found.\n",n);

}

int test_single_thread, test_multi_thread, test_other_process_clocks, test_timer,
    test_clock_status, do_scan, showclock;

static struct option ct_options[] = {
	{ "single-thread", 0, &test_single_thread, 1 },
	{ "multi-thread", 0, &test_multi_thread, 1 },
	{ "process-clocks", 0, &test_other_process_clocks, 1 },
	{ "timer", 0, &test_timer, 1 },
	{ "clock-status", 0, &test_clock_status, 1 },
	{ "scan", 0, &do_scan, 1 },
	{ "show", 0, NULL, 's' },
	{ "glibc", 0, NULL, 'g' },
	{ "kernel", 0, NULL, 'k' },
	{ "clock", 1, NULL, 'c' },
	{ "interval", 1, NULL, 'i' },
	{ "count", 1, NULL, 'n' },
	{ "verbose", 0, NULL, 'v' },
	{ "help", 0, NULL, 'h' },
	{ "version", 0, NULL, 'V' },
	{ "busywait", 0, NULL, 'b' },
	{ 0, 0, NULL, 0}
};

void usage(char *cmd) {
	printf("clocktest comes with ABSOLUTELY NO WARRANTY. This is free software which may\n"
	"be redistributed under the terms of the GNU General Public License. See the\n"
	"sourcecode for details. Written by Christoph Lameter <christoph@lameter.com>\n\n"
	);
	printf("Copyright (C) 2004 Silicon Graphics Inc (http://www.sgi.com).\n\n");

	printf("usage: %s [OPTIONS]... \n", cmd);

	printf( "-h, --help\t\tdisplay this help and exit\n"
                "-V, --version\t\toutput version information and exit\n"
		"--single-thread\t\ttest process/thread clocks for single thread\n"
		"--multi-thread\t\ttest process/thread clocks for multi threads\n"
		"--process-clocks\ttest process clocks for other processes\n"
		"--timer\t\t\tdo a posix interval timer test\n"
		"--scan\t\t\tscan for available clocks\n"
		"--clock-status\t\tdisplay clock status (default)\n"
		"-s,--show\t\tShow single clock status\n"
		"-c,--clock=N\t\tUse specified clockid instead of CLOCK_REALTIME\n"
		"-g,--glibc\t\tUse glibc functions for testing\n"
		"-k,--kernel\t\tUse system calls bypassing glibc (default)\n"
		"-i,--interval=ns\tUse the specified interval instead of 1234567ns\n"
		"-n,--count=N\t\tRepeat timer signal N times instead of 5 times\n"
		"-b,--busywait\t\tUse a busy loop for waiting instead of suspending the process\n"
	);
}

int main(int argc, char *argv[])
{
	int c;

	while ((c=getopt_long(argc, argv, "bkgvsVhc:i:n:", ct_options, 0)) != -1) switch (c) {
		case 0 : break;

		case 'b' : busywait = 1;
			  break;

		case 'c' : clockid = clockstr_to_id(optarg);
			   if (clockid <0) {
				   fprintf(stderr,"Unknown clock:%s\n",optarg);
				   exit(2);
			   }
			   break;

		case 'i' : interval = atoi(optarg);
			   break;

		case 'n' : count = atoi(optarg);
			   break;

		case 'v' : verbose++;
			break;

		case 'g' : use_glibc = 1;
			break;

		case 'k' : use_glibc = 0;
			break;

		case 's' :
			   showclock = 1;
			break;
		case 'V' :
			printf("clock_test version " VERSION "Christoph Lameter\n");
			exit(0);

		case 'h' :
			usage(argv[0]);
			exit(0);

		default:
			fprintf(stderr, "Unknown command %c\n",c);
			usage(argv[0]);
			exit(1);
	}

	if (showclock) pr(clockid); else
	if (do_scan) clock_scan(); else
	if (test_single_thread) single_thread(); else
	if (test_multi_thread) multi_thread(); else
	if (test_other_process_clocks) other_processes_clocks_test(); else
	if (test_timer) standard_timer_test(); else
	{
		struct timespec tv;

		gettimeofday((struct timeval *)&tv, NULL);
		tv.tv_nsec = tv.tv_nsec*1000;
		printf("Current values of POSIX clocks:"
		     "\n-------------------------------\n");
		fourclocks();

		printf("          Gettimeofday() =% 11ld.%09ld\n",tv.tv_sec,tv.tv_nsec);
	}
	return 0;
}

