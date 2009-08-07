#include "st_common.h"
#include "st_fstests.h"
/* Macros defined */

#define MMC_MAX_FILESIZE 104857600
#define ATA_MAX_FILESIZE 1073741824
#define NAND_MAX_FILESIZE 104857600
#define NOR_MAX_FILESIZE 104857600
#define MAX_FILES_LIMIT	100
#define BUFFER_SIZE 1048576 //(1MB)
#define NO_OF_BLOCKS 1024
#define NAND_100MB_FILESIZE 104857600
#define NAND_1GB_FILESIZE 1073741824.0
#define NAND_2GB_FILESIZE 2040109400 /* This is nearly 1.89GB. Bcos thats what is available */


extern Uint32 ST_Total_Time;  /* 1073741824 - 1GB, 1048576- 1MB*/ 
extern Uint32 Elapsed_Time;
extern Uint32 ST_BuffSize;

/* LinuxFILE I/O Perfromance Function  */
void ST_BLK_Linuxfile_Pfmnce();


/***************************************************************************
 * Function		- ST_BLK_Linuxfile_Pfmnce
 * Functionality	- Test user Interface and perfromance File I/O  funcitonality on different block devices  
 * Input Params	- None
 * Return Value	- None
 * Note			- Nonest_automation_io.c
 ****************************************************************************/
void ST_BLK_Linuxfile_Pfmnce(void)
{

 Uint32 	     arr[1]={
 			//	102400, /*100KB */
			//	256000, /*250KB*/
			//	512000, /*500KB*/
				1048576, /*1MB*/
			    };
				//5242880, /*5MB */
				//52428800 /*50MB */					
 			   //};  /* Array to define the different Buffer Sizes */
 char  SrcName[30]="/hd/test1";
 //Uint32 size=0;
 float size=0.0;
 Uint32 count=0;
 Uint32 loop=0;
 Uint32 toggle=0;
 Uint32 limit=0;
 Uint32 dev=0;
 float RDWRSIZE=0.0;

		printTerminalf("Enter Block Device ID : 0=ATA 1=NAND 2=MMC/SD 3=NOR\r\n");
		scanTerminalf("%d",&dev);			


		switch(dev)
		{
			case 0 :
				printTerminalf("Switch between 1=%d and 0=%d  of %d files =0\r\n",
						 ATA_MAX_FILESIZE, (ATA_MAX_FILESIZE/MAX_FILES_LIMIT), MAX_FILES_LIMIT);
				scanTerminalf("%d",&toggle);
	
				if(toggle==1)
				{
				  size=ATA_MAX_FILESIZE;	
		     		  limit=1;
				}
				else
				{
				  size=(ATA_MAX_FILESIZE/MAX_FILES_LIMIT);
				  limit=MAX_FILES_LIMIT;
				}
				break;
			case 1 :
                            /* printTerminalf("Enter Read/Write size in GB (use steps of 0.1)\n");
                             scanf("%f",&RDWRSIZE);
                             printf("File RDWRSIZE size is %lf GBytes\n",RDWRSIZE);
                             calclulate read/write size in bytes */
  
			/*	printTerminalf("Switch between 1=%d or 2=%d(1GB) or 3=%d(2GB) and 0= %d  of %d files =0\r\n",
						 NAND_MAX_FILESIZE, 
						 NAND_1GB_FILESIZE, 
						 NAND_2GB_FILESIZE, (NAND_MAX_FILESIZE/MAX_FILES_LIMIT), MAX_FILES_LIMIT);
						 
				scanTerminalf("%d",&toggle);
	
				if(toggle==1)
				{
				  size=NAND_MAX_FILESIZE;	
		     		  limit=1;
				}
				else if (toggle==2)
				{
				 size=NAND_1GB_FILESIZE;
				 limit=1;
				}
				else if (toggle==3)
				{
				 size=NAND_2GB_FILESIZE;
				 limit=1;
				} 
				else
				{
				  size=(NAND_MAX_FILESIZE/MAX_FILES_LIMIT);
				  limit=MAX_FILES_LIMIT;
				}*/

				//strcpy(SrcName,"/nand/test1");
				strcpy(SrcName,"test1");
			   	
				break;
			case 2 : 
				printTerminalf("Switch between 1=%d and 0=%d  of %d files =0\r\n",
						 MMC_MAX_FILESIZE, (MMC_MAX_FILESIZE/MAX_FILES_LIMIT), MAX_FILES_LIMIT);
				scanTerminalf("%d",&toggle);
	
				if(toggle==1)
				{
				  size=MMC_MAX_FILESIZE;	
		     		  limit=1;
				}
				else
				{
				  size=(MMC_MAX_FILESIZE/MAX_FILES_LIMIT);
				  limit=MAX_FILES_LIMIT;
				}

				strcpy(SrcName,"/mmc/test1");
				break;
				
			case 3 : 
				printTerminalf("Switch between 1=%d and 0=%d  of %d files =0\r\n",
						 NOR_MAX_FILESIZE, (NOR_MAX_FILESIZE/MAX_FILES_LIMIT), MAX_FILES_LIMIT);
				scanTerminalf("%d",&toggle);
	
				if(toggle==1)
				{
				  size=NOR_MAX_FILESIZE;	
		     		  limit=1;
				}
				else
				{
				  size=(NOR_MAX_FILESIZE/MAX_FILES_LIMIT);
				  limit=MAX_FILES_LIMIT;
				}

				strcpy(SrcName,"/nor/test1");
				break;

			default :
				printTerminalf("No Block Device is selected\r\n");
		}






	 	//printTerminalf( "Iam HEre\n"); 	

		while(count<1)
		{
				
				ST_BuffSize=arr[count];
                            size=(0.1*NAND_1GB_FILESIZE);
                            //size=(0.1*NAND_100MB_FILESIZE);
                     
				//ST_BuffSize=BUFFER_SIZE;
                            //limit=1;

                 while (size < (NAND_2GB_FILESIZE))
                 //while (size < (1.1*NAND_100MB_FILESIZE))
                 {
                             printf("File size is %lf Bytes\n",size);
			//if(limit == 1);
                     
				//ST_BuffSize=BUFFER_SIZE;
                            limit=1; 

			if(limit == 1)

			{
					itoa(count,&SrcName[8]);
					ST_WriteToFile(SrcName,size,0);
					printTerminalf("Write Data, Buffer Size Used =%d\n",ST_BuffSize);				         			     	     
					printTerminalf("Write Data,  Transfer Elapsed Time  =%ds\n",Elapsed_Time);						
					printTerminalf("\n");
			}
			else
			{
				/* Iteration is for the N=limit no.of files I/O feature */				
				for(loop=1;loop<=limit;loop++)
				{
					itoa(loop,&SrcName[8]);
					ST_WriteToFile(SrcName,size,0);
					printTerminalf("Write Data, Buffer Size Used =%d\n",ST_BuffSize);				         			     	     
					printTerminalf("Write Data,  Transfer Elapsed Time  =%ds\n",Elapsed_Time);						
					printTerminalf("\n");
				}
			}
          
			/*count++;
        	}  end of while count < 1*/
			
		//count =0;

		/*while(count<1)
		{

			ST_BuffSize=arr[count]; */
			if(limit == 1)
			{
					itoa(count,&SrcName[8]);
					ST_ReadFromFile(SrcName);
					printTerminalf("Read Data Buffer Size Used =%d\n",ST_BuffSize);				    	 			     		     
					printTerminalf("Read Data Transfer Elapsed Time =%ds\n",Elapsed_Time);					
					//ST_FileRemove(SrcName);
					printTerminalf("\n");
			}
			else
			{
				/* Iteration is for the N=limit no.of files I/O feature */				
        			for(loop=1;loop<=limit;loop++)
				{
					itoa(loop,&SrcName[8]);
					ST_ReadFromFile(SrcName);
					printTerminalf("Read Data Buffer Size Used =%d\n",ST_BuffSize);				    	 			     		     
					printTerminalf("Read Data Transfer Elapsed Time =%ds\n",Elapsed_Time);					
					//ST_FileRemove(SrcName);
					printTerminalf("\n");
				}
				}
               printf("removing file test1\n");
                       //system("rm -f ./test1");
           
		ST_FileRemove("test1");
			/*count++;
        	} end of while count < 1 */
                   size = size + (0.1*NAND_1GB_FILESIZE);
                } // end of while size <
			count++;
        	} //end of while count < 4 

		printTerminalf("Block Performance completed\r\n");

}







