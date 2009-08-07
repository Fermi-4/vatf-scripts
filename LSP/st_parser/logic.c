
#include<stdio.h>

main()
{
 unsigned int a=0xffff;
 unsigned int b=0x0;
 int i=0;
#if 0
	{
		b=0x0;
		printf("a=0x%x, b=0x%x\n",a,b);
		//b|=(1<<i);  
		a&=(~(1<<2));
		printf("a=0x%x, b=0x%x\n",a);
	}
#endif
#if 0
	for(i=0;i<20;i++)
	{
		printf("a=0x%x\n",b);
		b=(a%2)?1:0;
		a++;
	}
#endif
	
	for(i=0;i<20;i++)
	{
		printf("a=0x%x\n",a);
		a=!a;
	}

 }		
 		

