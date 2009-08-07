#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/time.h>
#include <sys/resource.h>

#define TRUE  1
#define FALSE 0

#define ERR(fmt, args...) fprintf(stderr, "Encode Error: " fmt, ## args)

#define BUFSIZE 1024 * 1024

#define WRITELIMIT 10 * 1024 * 1024

#define PAUSE 4

#define WRITEFILE "writetest"

typedef struct CtrlEnv {
    int numReadThreads;
    int numWriteThreads;
    int prio;
} CtrlEnv;

int quit = FALSE;
char *fileName;

void *writeTestFxn(void *arg)
{
    int fd;
    int threadId = (int) arg;
    char buf[BUFSIZE];
    int numBytes;
    char writeFile[sizeof(WRITEFILE) + 4]; // max 9999 threads
    int totalBytes = 0;

    printf("Started write thread %d\n", threadId);

    sprintf(writeFile, WRITEFILE "%d", threadId);

    fd = open(writeFile, O_WRONLY | O_CREAT | O_TRUNC);

    if (fd == -1) {
        ERR("Thread %d: Failed to open %s for writing\n", threadId, writeFile);
        exit(-1);
    }

    while (!quit) {
        numBytes = write(fd, buf, BUFSIZE);

        if (numBytes == -1) {
            ERR("Failed to write to %s\n", writeFile);
            exit(-1);
        }

        totalBytes += numBytes;

        if (totalBytes > WRITELIMIT) {
            if (lseek(fd, 0, SEEK_SET) == -1) {
                ERR("Failed to start over on %s\n", fileName);
                exit(-1);
            }

            totalBytes = 0;
        }

        fprintf(stderr, "w%d ", threadId);
        usleep(PAUSE);
    }

    close(fd);

    return NULL;
}

void *readTestFxn(void *arg)
{
    int fd;
    int threadId = (int) arg;
    char buf[BUFSIZE];
    int numBytes;

    printf("Started read thread %d\n", threadId);

    fd = open(fileName, O_RDONLY);

    if (fd == -1) {
        ERR("Thread %d: Failed to open %s for reading\n", threadId, fileName);
        exit(-1);
    }

    while (!quit) {
        numBytes = read(fd, buf, BUFSIZE);

        if (numBytes == -1) {
            ERR("Thread %d: Failed to read from %s\n", threadId, fileName);
            exit(-1);
        }

        if (numBytes == 0) {
            if (lseek(fd, 0, SEEK_SET) == -1) {
                ERR("Failed to start over on %s\n", fileName);
                exit(-1);
            }
        }

        fprintf(stderr, "r%d ", threadId);
        usleep(PAUSE);
    }

    close(fd);

    return NULL;
}

void *ctrlFxn(void *arg)
{
    CtrlEnv *envp = (CtrlEnv *) arg;
    pthread_attr_t attr;
    pthread_t *readTestThreads;
    pthread_t *writeTestThreads;
    struct sched_param schedParam;
    int i;

    printf("Started control thread\n");

    writeTestThreads = (pthread_t *)
            malloc(sizeof(pthread_t) * envp->numWriteThreads);

    if (writeTestThreads == NULL) {
        ERR("Failed to allocate space for test threads\n");
        exit(-1);
    }

    readTestThreads = (pthread_t *)
            malloc(sizeof(pthread_t) * envp->numReadThreads);

    if (readTestThreads == NULL) {
        ERR("Failed to allocate space for test threads\n");
        exit(-1);
    }

    if (pthread_attr_init(&attr)) {
        ERR("Failed to initialize thread attrs\n");
        exit(-1);
    }

    if (envp->prio) {
        if (pthread_attr_setinheritsched(&attr, PTHREAD_EXPLICIT_SCHED)) {
            ERR("Failed to set schedule inheritance attribute\n");
            exit(-1);
        }

        if (pthread_attr_setschedpolicy(&attr, SCHED_FIFO)) {
            ERR("Failed to set FIFO scheduling policy\n");
            exit(-1);
        }

        schedParam.sched_priority = sched_get_priority_max(SCHED_FIFO) - 1;
        if (pthread_attr_setschedparam(&attr, &schedParam)) {
            ERR("Failed to set scheduler parameters\n");
            exit(-1);
        }
    }

    for (i=0; i<envp->numReadThreads; i++) {
        if (pthread_create(&readTestThreads[i], &attr, readTestFxn,
                           (void *) i)) {
            ERR("Failed to create read thread\n");
            exit(-1);
        }
    }


    for (i=0; i<envp->numWriteThreads; i++) {
        if (pthread_create(&writeTestThreads[i], &attr, writeTestFxn,
                           (void *) i)) {
            ERR("Failed to create write thread\n");
            exit(-1);
        }
    }

    getchar();

    quit = TRUE;

    for (i=0; i<envp->numReadThreads; i++) {
        pthread_join(readTestThreads[i], NULL);
        printf("\nJoined read thread %d\n", i);
    }

    for (i=0; i<envp->numWriteThreads; i++) {
        pthread_join(writeTestThreads[i], NULL);
        printf("\nJoined write thread %d\n", i);
    }

    free(readTestThreads);
    free(writeTestThreads);

    return NULL;
}

int main(int argc, char *argv[])
{
    int prio = FALSE;
    int numReadThreads = 1;
    int numWriteThreads = 1;
    pthread_t ctrlThread;
    pthread_attr_t ctrlAttr;
    struct sched_param schedParam;
    CtrlEnv env;

    if (argc > 1) {
        fileName = argv[1]; 
    }
    else {
        printf("\nUsage: hdtest <readfile> [read threads] [write threads] "
               "[prio]\n\n");
        exit(0);
    }

    printf("Reading from file: %s\n", fileName);

    if (argc > 2) {
        numReadThreads = atoi(argv[2]);
    }

    printf("Starting %d read threads\n", numReadThreads);

    if (argc > 3) {
        numWriteThreads = atoi(argv[3]);
    }

    printf("Starting %d write threads\n", numWriteThreads);

    if (argc > 4) {
        if (strcmp(argv[4], "prio") == 0) {  
            prio = TRUE;
        }
    }

    if (prio) {
        printf("Thread priorities turned on\n");
    }
    else {
        printf("Thread priorities turned off\n");
    }

    setpriority(PRIO_PROCESS, 0, -20);

    if (pthread_attr_init(&ctrlAttr)) {
        ERR("Failed to initialize thread attrs\n");
        exit(-1);
    }

    if (prio) {
        if (pthread_attr_setinheritsched(&ctrlAttr, PTHREAD_EXPLICIT_SCHED)) {
            ERR("Failed to set schedule inheritance attribute\n");
            exit(-1);
        }

        if (pthread_attr_setschedpolicy(&ctrlAttr, SCHED_FIFO)) {
            ERR("Failed to set FIFO scheduling policy\n");
            exit(-1);
        }

        schedParam.sched_priority = sched_get_priority_max(SCHED_FIFO);
        if (pthread_attr_setschedparam(&ctrlAttr, &schedParam)) {
            ERR("Failed to set scheduler parameters\n");
            exit(-1);
        }
    }

    env.prio = prio;
    env.numReadThreads = numReadThreads;
    env.numWriteThreads = numWriteThreads;

    if (pthread_create(&ctrlThread, &ctrlAttr, ctrlFxn, &env)) {
        ERR("Failed to create ctrl thread\n");
        exit(-1);
    }

    pthread_join(ctrlThread, NULL);
    printf("\nJoined control thread\n");

    exit(0);
}

