/*******************************************************************************
**+--------------------------------------------------------------------------+**
**|                            ****                                          |**
**|                            ****                                          |**
**|                            ******o***                                    |**
**|                      ********_///_****                                   |**
**|                      ***** /_//_/ ****                                   |**
**|                       ** ** (__/ ****                                    |**
**|                           *********                                      |**
**|                            ****                                          |**
**|                            ***                                           |**
**|                                                                          |**
**|         Copyright (c) 1998-2005 Texas Instruments Incorporated           |**
**|                        ALL RIGHTS RESERVED                               |**
**|                                                                          |**
**| Permission is hereby granted to licensees of Texas Instruments           |**
**| Incorporated (TI) products to use this computer program for the sole     |**
**| purpose of implementing a licensee product based on TI products.         |**
**| No other rights to reproduce, use, or disseminate this computer          |**
**| program, whether in part or in whole, are granted.                       |**
**|                                                                          |**
**| TI makes no representation or warranties with respect to the             |**
**| performance of this computer program, and specifically disclaims         |**
**| any responsibility for any damages, special or consequential,            |**
**| connected with the use of this program.                                  |**
**|                                                                          |**
**+--------------------------------------------------------------------------+**
*******************************************************************************/

/** \file   ST_Automation_IO.c
    \brief  ST Test UART based IO wrappers for automation

    (C) Copyright 2005, Texas Instruments, Inc

    @author     Shivanand Pujar, Aniruddha, Anand, Baalaaji
    @version    0.1 	01-Aug-2005	- Created
                
 */

//#define USER_INTERACTION
#include "st_automation_io.h"
int ST_fd;
extern char **opts;     /* string array for arguments */

void ST_Open_UART(void)
{

 			//ST_mknod("/dev/ttyS0",S_IFCHR,52228);
			ST_fd=open("/dev/console",O_RDWR);
			printTerminalf("%d\n",ST_fd);		 						
			if(ST_fd<0)
			{	
				ST_LinuxDevErrnum("Open:");		
				exit(1);	
					 
			}

}

void ST_Close_UART(void)
{
	close(ST_fd);
}

int st_atoi(char * s)
{
    int value = 0;
    int base =10;
    int digit;

    if(*s == '0')
    { 
        s++;
        if(*s == 'x')
        {
            s++;
            base = 16;
        }
        if(isspace(*s))
        {
            s++;
            return 0;
        }
    }
     
    value = *s++ - '0';

    while(!isspace(*s))
    {
        digit = *s - '0';
        value = (value*base) + digit;
        s++;
    }

    return value;
}


#ifdef USER_INTERACTION
void readString(char *cmd)
{
	char input[1];
	char * temp;
	int val = 10;	
	char NL[1];
	char ch;
	
	temp = cmd;
	
	NL[0] = val;
	
	while(1)
    {
		read(ST_fd, input, 1);
		write(ST_fd, input, 1);

		if(input[0] == 13) {
			write(ST_fd, NL, 1);
		}
		
		if(isspace((char)input[0])) 
			break;
			
		ch = (char) input[0];
		
		*temp++ = ch;
   }
   *temp = '\0';
}

#else
void readString(char *cmd)
{
	char *temp;
	char ch;

	temp = cmd;
	ch = **opts;
	//printTerminalf("this character is: %d\n", ch);
	while (ch != '\0')
	{
		//printTerminalf("I am in while loop waiting for end of string\n");
		*temp++ = ch;
		*opts = *opts + 1;
		ch = **opts;
		//printTerminalf("this character is: %d\n", ch);
	}
	*temp = '\0';
}
#endif

int isspace(char space)
{
    switch(space)
    {
        case ' ' : /* Space Character */
        case '\f': /* Form Feed */
        case '\n': /* New Line */
        case '\r': /* Carriage Return */
        case '\t': /* Horizontal Tab */
        case '\v': /* Vertical Tab */
        case '\0': /* NULL */
              return 1;
        default:
              return 0;
    }
}

void itoa(int n, char * s)
{
	int i = 0, j = 0, c;
	int is_negative;

	if(n<0)
	{
	    is_negative = 1;
	    n=abs(n);
	}
	else is_negative = 0;
	
	do
	{
         s[i++] = n % 10 + '0';
    } while ((n /= 10) > 0);

    if(is_negative)
        s[i++] = '-';

    s[i] = 0;

    for (i = 0, j = strlen(s) - 1; i < j; i++, j--) 
    {
        c = s[i];
        s[i] = s[j];
        s[j] = c;
    }
    return;
}

void itox(unsigned int x, char * s)
{
	int i = 0, j = 0, c;
	
	do
	{
	 c =  x % 16;
	 if(c > 9) 
	  c += 7;
         s[i++] = c + '0';
    	} while ((x /= 16) > 0);

	s[i++] = 'x'; s[i++] = '0';
    	s[i] = 0;

    for (i = 0, j = strlen(s) - 1; i < j; i++, j--) 
    {
        c = s[i];
        s[i] = s[j];
        s[j] = c;
    }
    return;
}

char readChar(void)
{
	char input[2]; 

		read(ST_fd, input, 1);
		return (input[0]);
		
}

void printTerminalf(const char *fmt, ...)
{
    va_list ap;
    int d;
    unsigned int x;
    char * s;
    char digit[20];
    char ch[1];
    char * temp;
    int val = 13;	
    char CR[1];

    CR[0] = val;

    va_start(ap, fmt);
    while (*fmt)
    {
        if('%' == *fmt)
        {
            fmt++;
            switch(*fmt)
            {
                case 's': /* string */
                    s = va_arg(ap, char *);
					printf("%s", s);
                    break;
                    
                case 'd': /* int */
                    d = va_arg(ap, int);
					printf("%d", d);
                    break;

                case 'x': /* unsigned int */
					x = va_arg(ap, unsigned int);
					printf("%x", x);
					break;
            }
        }
		else
		{
			printf("%c", *fmt);
		}
        fmt++;
    } //end of while
    va_end(ap);
    return;
}

void scanTerminalf(const char *fmt, ...)
{
    va_list ap;
    int * d;
    char * s;
    char digit[20];
    char *c;	

#ifndef USER_INTERACTION
	*opts++;
	//printTerminalf("the current argument is: %s\n\n", *opts);
#endif
    va_start(ap, fmt);
    while (*fmt)
    {
        if('%' == *fmt)
        {
            fmt++;
            switch(*fmt)
            {
                case 's': /* string */
                          s = va_arg(ap, char *);
                          readString(s); 
                    break;
                case 'd': /* int */
                          d = va_arg(ap, int *);
                          readString(digit);
                          *d = st_atoi(digit);
                    break;					
                case 'c': /* int */
                          c = va_arg(ap, char *);
 	                   *c= readChar();
                    break;
					
             }
        }
        fmt++;
    }
    va_end(ap);
    return;
}
