/* arm_v5t_le-gcc -o itimer_test itimer_test.c */
/* 
 * test itimer 
 */ 


#include <stdlib.h> 
#include <stdio.h> 


#include <unistd.h> 
#include <signal.h> 
#include <sys/time.h> 
#include <time.h> 


#define TEST_INTERVAL_SEC 5 


static inline void 
tv_sub(struct timeval* ptv1, struct timeval* ptv2) 
{ 
    ptv1->tv_sec -= ptv2->tv_sec; 
    ptv1->tv_usec -= ptv2->tv_usec; 
    while (ptv1->tv_usec < 0) 
    { 
        ptv1->tv_sec--; 
        ptv1->tv_usec += 1000*1000; 
    } 
} 


static uint g_ticks; 
static uint g_interval; 
static struct timeval g_now; 
static struct itimerval g_resolution; 


void 
itimer_handler(int sig) 
{ 
    g_ticks++; 
    // g_now.tv_usec += g_interval*1000; 
    g_now.tv_usec += g_resolution.it_interval.tv_usec; 
    while (g_now.tv_usec > 1000*1000) 
    { 
        g_now.tv_usec -= 1000*1000; 
        g_now.tv_sec++; 
    } 
} 


void 
start_itimer(uint ms) 
{ 
    struct timeval tv; 
    struct itimerval val; 


    tv.tv_sec = ms/1000; 
    tv.tv_usec = (ms%1000)*1000; 


    val.it_interval = tv; 
    val.it_value = tv; 


    signal(SIGALRM, itimer_handler); 
    g_ticks = 0; 
    g_interval = ms; 
    gettimeofday(&g_now, NULL); 
    setitimer(ITIMER_REAL, &val, NULL); 
    setitimer(ITIMER_REAL, &val, &g_resolution); 
} 


void 
stop_itimer(void) 
{ 
    struct timeval tv; 
    struct itimerval val; 


    tv.tv_sec = tv.tv_usec = 0; 
    val.it_interval = tv; 
    val.it_value = tv; 


    setitimer(ITIMER_REAL, &val, NULL); 
    signal(SIGALRM, SIG_DFL); 
} 


int 
main(void) 
{ 
    int i; 
    struct timeval tv_start; 
    struct timeval tv_now; 


    char drift_sign; 
    struct timeval tv_drift; 
    struct timeval tv_elapsed; 


    for (i = 10; i <= 50; i += 10) 
    { 
        gettimeofday(&tv_start, NULL); 
        start_itimer(i); 
        printf("resolution: asked for %dus, got %dus\n", i * 1000, 
               (int)g_resolution.it_interval.tv_usec); 
        do 
        { 
            usleep(1000*1000); 
            gettimeofday(&tv_now, NULL); 
            tv_elapsed = tv_now; 
            tv_sub(&tv_elapsed, &tv_start); 
        } while (tv_elapsed.tv_sec < TEST_INTERVAL_SEC); 
        stop_itimer(); 


        if (g_now.tv_sec > tv_now.tv_sec || 
            (g_now.tv_sec == tv_now.tv_sec && 
             g_now.tv_usec > tv_now.tv_usec)) 
        { 
            drift_sign = '+'; 
            tv_drift = g_now; 
            tv_sub(&tv_drift, &tv_now); 
        } 
        else 
        { 
            drift_sign='-'; 
            tv_drift = tv_now; 
            tv_sub(&tv_drift, &g_now); 
        } 
        printf("i=%d, ticks=%u (expected %u ,real %u), elapsed=%ld.%06ld, drift=%c%ld.%06ld\n", 
               i, g_ticks, (TEST_INTERVAL_SEC*1000/i), 
               (TEST_INTERVAL_SEC*1000*1000 / 
                (int)g_resolution.it_interval.tv_usec), 
                tv_elapsed.tv_sec, tv_elapsed.tv_usec, 
                drift_sign, tv_drift.tv_sec, tv_drift.tv_usec); 
    } 
    return 0; 
} 

