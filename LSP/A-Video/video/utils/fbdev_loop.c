/*
 * The main file for FBDEV loopback:
 *
 * Steps:
 *
 * 1. Initialize framebuffer device nodes.
 * 2. Initializes displays by reading sysfs
 * 3. Initializes capture
 * 4. parses input arguments
 * 5. Initialize output window settings
 * 6. Starts the loopback
 * 7. Close the windows and exit
 */

#include "fbdev_display.h"

/* main function */
int
main (int argc, char *argv[])
{

  
  // Initialise FB device nodes.
  initDevNodes();

   if (argc == 1){
                usage();
                return 0;
                }

	if(parseArgs(argc, argv) < 0){
 return -1;
 }
 
  if(initDisplay() < 0) return -1;

  Initialize_Capture();

  
// Initialize the required windows and mmap them here.

  if (init_mmap_win() < 0){
       printf("init_and_mmap Failed\n");
       return -1;
       }

 StartLoop();

 printf("Finished loop\n");

 if (unmap_and_close() < 0)
 {
   printf("Unmap and close Failed\n");
   return -1;
 }
 
 //Initializing display settings again.This will not resize the windows,
 //simply reinitialize them
 initDisplay();

 printf("loopback test was a success\n");
    return 0;
}
