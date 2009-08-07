#!/usr/bin/perl

use strict ;
use Switch;
if ($ARGV[0] eq "performance")
{
require ('perfTestCfg.opt');
}
elsif ($ARGV[0] eq "psp")
{
require ('pspTestCfg.opt');
}
elsif ($ARGV[0] eq "functional")
{
require ('funcTestCfg.opt');
}
#   ============================================================================
#   Define constants
#   ============================================================================
my $OS_WINDOWS              = 'WINDOWS' ;
my $MENU_ROOTDIR            = "ROOT-DIR" ;
my $OS_LINUX                = 'LINUX' ;
my $MENU_PLATFORM 	    	= "PLATFORM";
my $MENU_TEST				= "TEST";
my $MENU_FUNCTIONAL			= "FUNCTIONAL";
my $MENU_PRODUCT			= "PRODUCT-MENU";
my $MENU_PERFORMANCE	    = "PERFORMANCE-MENU";
my $MENU_DEVICES		    = "DEVICES-MENU";
my $MENU_THROUGHPUT		    = "THROUGHPUT";	
my $CFGFILE                 = "CURRENTCFG.MK" ;
my $HEADERFILE				= "config.h";
my $TRUE                    = 1 ;
my $FALSE                   = 0 ;
my $ENABLE					= 1 ;
my $DISABLE					= 0 ;
my $THROUGHPUT				= "T";
my $FUNCTIONALTEST			= "F";
my $PERFORMANCETEST			= "P";
my $FS 						= "F";
my $I2C						= "I";
my $V4L2					= "V";
my $VDCE					= "D";
my $FBDEV					= "B";
my $OSS						= "O";
my $ALSA					= "A";
my $VLYNQ					= "L";
my $EDMA					= "E";
my $SPI						= "S";
my $USBVIDEO				= "U";


#   ============================================================================
#   Global Variables
#   ============================================================================
my $TheOS           = "" ;
my $Var_ChgRootDir  = 0  ;
my $Var_Date        = 0  ;
my $Var_RootDir     = "" ;
my $Var_Platform	  = "" ;
my $Var_DavinciVariant     = "" ;
my $Var_OmapVariant  = "";
my $Var_Productmenu	 = "";
my $Var_Product		 = "" ;
my $Var_Device     = "" ;
my $Var_Test		 = ""; 
my @Var_Cfg;
my @Var_CfgTest;
my $Var_Performance = "";
my $Var_FunctionalTest	= "";
my $Var_PerformanceTest = "";
my $Var_Throughput	= $FALSE;
my $Var_EnableThroughput = $FALSE;
my $Var_EnableFunctional = $FALSE;
my $Var_EnablePerformance = $FALSE;
my $Var_InterrptLatency = $FALSE;
my $Var_ThroughputFS  = $FALSE;
my $Var_ThroughputI2C 	= $FALSE;
my $Var_ThroughputSPI = $FALSE;
my $Var_ThroughputV4L2 = $FALSE;
my $Var_ThroughputFBDEV = $FALSE;
my $Var_ThroughputOSS = $FALSE;
my $Var_ThroughputUSBVideo = $FALSE;
my $Var_ThroughputEDMA = $FALSE;
my $Var_ThroughputVLYNQ = $FALSE;
my $Var_ThroughputVDCE = $FALSE;
my $Var_ThroughputALSA = $FALSE;
my $Var_ThroughputUser = $FALSE;
my $Var_ThroughputKernel=$FALSE;
my $Var_FunctionalFS  = $FALSE;
my $Var_FunctionalI2C 	= $FALSE;
my $Var_FunctionalSPI = $FALSE;
my $Var_FunctionalV4L2 = $FALSE;
my $Var_FunctionalFBDEV = $FALSE;
my $Var_FunctionalOSS = $FALSE;
my $Var_FunctionalUSBVideo = $FALSE;
my $Var_FunctionalEDMA = $FALSE;
my $Var_FunctionalVLYNQ = $FALSE;
my $Var_FunctionalVDCE = $FALSE;
my $Var_FunctionalALSA = $FALSE;
my $Var_FunctionalUser = $FALSE;
my $Var_FunctionalKernel=$FALSE;
#   ============================================================================
#   Error strings
#   ============================================================================
my $ERR_OS      = "\n  !! ERROR !! Could not identify the native OS!\n" ;
my $ERR_ROOT    = "\n  !! ERROR !! Environment variable PSP_TEST_HOME is not defined!\n" ;
my $ERR_PATH    = "\n  !! ERROR !! Invalid path assigned to PSP_TEST_HOME!\n" ;
my $ERR_DIRS    = "\n  Could not find following directories:\n" ;

#   ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#   START PROCESSING
#   ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
&main () ;

#   ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#   Main
#   ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
sub main ()
{
#   ========================================================================
#   Identify the native operating system
#   ========================================================================
	if    ($ENV {'COMSPEC'} ne "")
	{
		if ($ENV {'CYGWIN'} ne "")
		{
			$TheOS = $OS_LINUX ;
		}
		else
		{
			$TheOS = $OS_WINDOWS ;
		}
	}
	elsif ($ENV {'SHELL'} ne "")
	{
		$TheOS = $OS_LINUX ;
	}
	else
	{
		die $ERR_OS ;
	}

#   ========================================================================
#   Check for envi$ronment variable PSP_TEST_HOME
#   ========================================================================
	if ($ENV {'PSP_TEST_HOME'} eq "")
	{
		die $ERR_ROOT ;
	}

#   ========================================================================
#   Get current date & time
#   ========================================================================
	$Var_Date = &GetDateString () ;

#   ========================================================================
#   Get user inputs
#   ========================================================================
	&ShowMenu ($MENU_ROOTDIR) ;

	if ($Var_ChgRootDir == 1)
	{
		&ShowAbort () ;
	}
	else {
		&ShowMenu ($MENU_PRODUCT);


		&ShowMenu ($MENU_PLATFORM) ;
		&ShowMenu ($MENU_TEST);

				for (my $j = 0 ; $j < @Var_CfgTest ; $j++)
		{

			switch ($Var_CfgTest[$j])
			{
				case "$FUNCTIONALTEST"
				{ 
					&ShowMenu ($MENU_FUNCTIONAL);
					
				}
				case "$PERFORMANCETEST"
				{
					&ShowMenu ($MENU_PERFORMANCE) ;

					for (my $i = 0 ; $i < @Var_Cfg ; $i++)
		{

			switch ($Var_Cfg[$i])
			{
				case "$THROUGHPUT"
				{ 
					&ShowMenu($MENU_THROUGHPUT);
				}
			}
		}
				}
			}
		}


		

		





#  --------------------------------------------------------------------
#   Generate command file/ shell script to set variables
#   --------------------------------------------------------------------
		&WriteCurrentConfig () ;
		&WriteHeaderFile();

		&ShowComplete () ;

	}
}

#   ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#   SUBROUTINES
#   ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

#   ============================================================================
#   func    ShowMenu
#
#   desc    Show the menu
#   ============================================================================
sub ShowMenu
{
	my ($menu)  = @_ ;

	my ($done)  = $FALSE  ;
	my ($text)  = "" ;
	my ($device)= "";
	my ($num_cfg)="";

	do {

		&ClearScreen () ;

		&MenuHeader  () ;

		switch ($menu)
		{

			case "$MENU_ROOTDIR"
			{
				&MenuRootDir () ;
			} 
			case "$MENU_PRODUCT"
			{
				&MenuProduct () ;
			}
			case "$MENU_PLATFORM"
			{
				&MenuPlatform () ;
			}
			case "$MENU_TEST"
			{
				&MenuTest ();
			}
			case "$MENU_FUNCTIONAL"
			{
				&MenuFunctional ();
			}
			case "$MENU_PERFORMANCE"
			{
				&MenuPerformance ();
			}
			case "$MENU_THROUGHPUT"
			{
				&MenuThroughput () ;
			}

		}
		&MenuFooter  () ;

		$text = &ReadInput  () ;

		$done = &IsValid ($menu, $text) ;
	}while ($done == $FALSE);       


}
#   ============================================================================
#   func    MenuRootDir
#
#   desc    Show menu : RootDir
#   ============================================================================
sub MenuRootDir
{
	my ($str) = "" ;
	my ($err) = "" ;

	my $dir = $ENV {'PSP_TEST_HOME'} ;

	$str .= "  PSP_TEST_HOME is currently defined as:\n" ;
	$str .= "\n" ;
	$str .= "  " . $dir . "\n" ;
	$str .= "\n" ;

#   ------------------------------------------------------------------------
#   Check if the directory referred by environment variable PSP_TEST_HOME
#   actually exists.
#   ------------------------------------------------------------------------
	if (-d $dir)
	{
		my @subdirs = () ;

#   --------------------------------------------------------------------
#   Check if ncessary sub-directories actually exist.
#   --------------------------------------------------------------------
		if ($TheOS eq $OS_WINDOWS)
		{
			@subdirs = (
					"\\config",
					"\\config\\bin"
				   ) ;
		}
		else
		{
			@subdirs = (
					"/config",
					"/config/bin"
				   ) ;
		}

		foreach my $subdir (@subdirs)
		{
			my ($path) = $dir . $subdir ;

			if (!(-d $path))
			{
				$err .= "  $path\n" ;
			}
		}
	}
	else
	{
		$err .= "  $dir\n" ;
	}

	if ($err ne "")
	{
		$str .= $ERR_PATH ;
		$str .= $ERR_DIRS ;
		$str .= $err ;
		$str .= "\n" ;
	}

	$str .= "  1.   Continue.\n" ;
	$str .= "\n" ;
	$str .= "  2.   Quit to change.\n" ;
	$str .= "\n" ;

	print $str ;
}

#   ============================================================================
#   func    MenuProduct
#
#   desc    Show menu : Product
#   ============================================================================
sub MenuProduct
{
	my ($str) = "" ;
	my $i = 0;
	$str .= "  Choose the Product to Customize\n" ;
	$str .= "\n" ;
	for $i (0..$#pspTestCfgOpt::OPT_MENU)
	{
		$str .= sprintf "  %d.   %s\n", ($i+1), $pspTestCfgOpt::OPT_MENU[$i] ;
		$str .= "\n" ;
	}

	print $str ;
}

#   ============================================================================
#   func    MenuPlatform
#
#   desc    Show menu : Platform
#   ============================================================================
sub MenuPlatform
{   

	my ($Platform) = "";
	my ($str) = "" ;
	my $i = 1;
	my $j = 0;


	$str .= "  Choose the Platform to Customize\n" ;
	$str .= "\n" ;
	foreach $Platform (keys %$Var_Product)
	{   
		$str .= sprintf "  %d.   %s\n", ($i), $Platform ;
		$str .= "\n" ;
		$i++;
	}

	print $str ;
}

#   ============================================================================
#   func    MenuTest
#
#   desc    Show menu : Platform
#   ============================================================================
sub MenuTest
{   

	my ($Test) = "";
	my ($str) = "" ;


	$str .= "  Choose the Tests to Customize\n" ;
	$str .= "  To select press the characters in []\n" ;
	$str .= "\n" ;
	foreach $Test (keys %{$$Var_Product{$Var_Platform}})
	{   
		$str .= sprintf " \t %s\n", $Test ;
		$str .= "\n" ;

	}

	print $str ;
}

#   ============================================================================
#   func    MenuPerformance
#
#   desc    Show menu : Performance Vectors
#   ============================================================================
sub MenuPerformance
{   

	my ($Performance) = "";
	my ($str) = "" ;

	$str .= "  Choose the Performance vectors to Customize\n" ;
	$str .= "  To select press the characters in []\n" ;
	$str .= "  Multiple vectors can be selected at the same time\n" ;
	$str .= "  for example to choose  [T]HROUGHPUT\n" ;
	$str .= "  type t or T\n" ;
       $str .= "  selecting throughput will also select cpu load functionality\n";       
	$str .= "\n";
	$str .= "\n";
	$str .= "\n";


	foreach $Performance (keys %{$$Var_Product{$Var_Platform}{$Var_PerformanceTest}})
	{   
		$str .= sprintf "\t %s\n", $Performance ;
		$str .= "\n" ;
	}

	print $str ;
}

#   ============================================================================
#   func    MenuFuntional
#
#   desc    Show menu : Functional Tests
#   ============================================================================
sub MenuFunctional
{   

	my ($Functional) = "";
	my ($str) = "" ;
	my $i = 0;
	
	$str .= "  Choose the Devices to Customize for Functional Tests\n" ;
	$str .= "  To select press the characters in []\n" ;
	$str .= "\n";
	
	foreach $i ( 0 .. $#{$$Var_Product{$Var_Platform}{$Var_FunctionalTest}})
	{   
		$str .= sprintf "\t %s\n", $$Var_Product{$Var_Platform}{$Var_FunctionalTest}[$i] ;
		$str .= "\n" ;
		$i++;
	}

	print $str ;
}

#   ============================================================================
#   func    MenuThroughput
#
#   desc    Show menu : Throughput
#   ============================================================================
sub MenuThroughput
{   

	my ($str) = "" ;
	my $i = 0;


	$str .= "  Choose the Devices to Customize for Throughput\n" ;
	$str .= "  To select press the characters in []\n" ;
	$str .= "  Multiple devices can be selected at the same time\n" ;
	$str .= "  for example to choose [F]S and [O]SS\n" ;
	$str .= "  type fo or of or FO or OF" ;
	$str .= "\n";
	$str .= "\n";
	$str .= "\n";
	foreach $i ( 0 .. $#{$$Var_Product{$Var_Platform}{$Var_PerformanceTest}{$Var_Throughput}}) 
	{
		$str .= sprintf "\t %s\n", $$Var_Product{$Var_Platform}{$Var_PerformanceTest}{$Var_Throughput}[$i];
		$str .= "\n" ;
		$i++;
	}

	print $str ;

}


#   ============================================================================
#   func    MenuFooter
#
#   desc    Show footer of the menu
#   ============================================================================
sub MenuFooter
{
	my ($str) = "" ;

	$str .= "  ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::\n" ;
	$str .= "\n" ;
	$str .= "  YOUR CHOICE : " ;

	print $str ;
}

#   ============================================================================
#   func    MenuHeader
#
#   desc    Show header of the menu
#   ============================================================================
sub MenuHeader
{
	my ($str) = "" ;

	$str .= "\n" ;
	$str .= "  ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::\n" ;
	$str .= "             PSP Test Bench Configuration Tool\n" ;
	$str .= "  ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::\n" ;
	$str .= "\n" ;

	print $str ;
}

#   ============================================================================
#   func    ShowAbort
#
#   desc    Show the abort message
#   ============================================================================
sub ShowAbort
{
	my ($text)  = "" ;

	&ClearScreen () ;

	&MenuHeader  () ;

	$text .= "\n" ;
	$text .= "  Configuration was aborted.\n" ;
	$text .= "\n" ;
	$text .= "  ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::\n" ;

	print $text ;
}

#   ============================================================================
#   func    ReadInput
#
#   desc    Reads the user inout from standard input
#   ============================================================================
sub ReadInput
{
	my ($str) ;

	$str = <STDIN> ;

	chomp $str ;

	return $str ;
}

#   ============================================================================
#   func    ClearScreen
#
#   desc    Clears the screen
#   ============================================================================
sub ClearScreen
{
	if    ($TheOS eq $OS_WINDOWS)
	{
		system ("cls") ;
	}
	else
	{
		system ("clear") ;
	}
}

#   ============================================================================
#   func    GetDateString
#
#   desc    Returns the date string
#   ============================================================================
sub GetDateString
{
	my (@date)      = (localtime)[0..5] ;

	my (@month)     = ("JAN", "FEB", "MAR", "APR", "MAY", "JUN",
			"JUL", "AUG", "SEP", "OCT", "NOV", "DEC") ;

	my ($datestr)   = $month [$date [4]] . " "  .
		$date [3]          . ", " .
		($date [5] + 1900) . "  " .
		$date [2]          . ":"  .
		$date [1]          . ":"  ;

	if ($date [0] < 10)
	{
		$datestr .= "0" ;
	}

	$datestr .= $date [0] ;

	return $datestr ;
}

sub IsValid
{
	my ($menu)  = shift (@_) ;
	my ($text)  = @_ ;
	my $i=0;
	my $platform = "";
	my ($valid) = $FALSE ;

#   ------------------------------------------------------------------------
#   Remove extra spaces before and after the text entered on command-line.
#   ------------------------------------------------------------------------
# $text  =~ s/^\s*(.*?)\s*$/$1/ ;

#   ------------------------------------------------------------------------
#   Menu : Root directory
#   ------------------------------------------------------------------------
	if   ($menu eq $MENU_ROOTDIR)
	{
		if    (   ($text =~ m/\d/)
				&& ($text >  0)
				&& ($text <= 2))
		{
			$Var_RootDir = $ENV {'PSP_TEST_HOME'} ;

			if ($text == 2)
			{
				$Var_ChgRootDir = 1 ;
			}

			$valid = $TRUE ;
		}
	}
#   ------------------------------------------------------------------------
#   Menu : Product
#   ------------------------------------------------------------------------
	elsif ($menu eq $MENU_PRODUCT)
	{
		if    (($text =~ m/\d/)
				&& ($text >  0)
				&& ($text <= (scalar(@pspTestCfgOpt::OPT_MENU))))
		{
			$Var_Productmenu = $pspTestCfgOpt::OPT_MENU[(($text)-1)];
			for ($i=0;$i <= (scalar(@pspTestCfgOpt::OPT_MENU));$i++)
			{			
				if ($Var_Productmenu eq $pspTestCfgOpt::OPT_MENU[$i])
				{
					$Var_Product = $pspTestCfgOpt::OPT_PRODUCT[$i];
				}				}
				$valid = $TRUE ;
		}
	}
#   ------------------------------------------------------------------------
#   Menu : Platform 
#   ------------------------------------------------------------------------
	elsif ($menu eq $MENU_PLATFORM)
	{    
		if    (($text =~ m/\d/)
				&& ($text >  0)
				&& ($text <= (scalar keys %$Var_Product)))
		{
			foreach $platform ( keys %$Var_Product ) {
				if ($i == ($text-1))
				{
					$Var_Platform = $platform;
				}
				$i++;
			}
			$valid = $TRUE ;
		}
	}
#   ------------------------------------------------------------------------
#   Menu : Tests 
#   ------------------------------------------------------------------------
	elsif ($menu eq $MENU_TEST)
	{    
		if  ( (   length($text) != 0) &&
				(   ($text =~ /[^fFpP]/g == 0)))
		{
		# Convert input to upper case.
			my $uctext  = uc ($text) ;
			@Var_CfgTest     = split(undef, $uctext) ;
			
			for (my $i = 0 ; $i < @Var_CfgTest ; $i++)
			{

				if ($Var_CfgTest[$i] eq $PERFORMANCETEST)
				{
					$Var_PerformanceTest = $pspTestCfgOpt::OPT_CFGTEST{$PERFORMANCETEST};
					
					$Var_EnablePerformance = $TRUE;
				}
				elsif($Var_CfgTest[$i] eq $FUNCTIONALTEST)
				{
					$Var_FunctionalTest = $pspTestCfgOpt::OPT_CFGTEST{$FUNCTIONALTEST};
					$Var_EnableFunctional = $TRUE;
				}

			}
			$valid = $TRUE ;
		}
	}
#   ------------------------------------------------------------------------
#   Menu : Performance Variant
#   ------------------------------------------------------------------------
	elsif ($menu eq $MENU_PERFORMANCE)
	{
		if  ( (   length($text) != 0) &&
				(   ($text =~ /[^tTcC]/g == 0)))

		{
# Convert input to upper case.
			my $uctext  = uc ($text) ;
			@Var_Cfg     = split(undef, $uctext) ;

			for (my $i = 0 ; $i < @Var_Cfg ; $i++)
			{

				if ($Var_Cfg[$i] eq $THROUGHPUT)
				{
					$Var_Throughput = $pspTestCfgOpt::OPT_CFGPERFORMANCE{$THROUGHPUT};
					$Var_EnableThroughput = $TRUE;
				}
				
			}
			$valid = $TRUE ;
		}
	}
	elsif ($menu eq $MENU_THROUGHPUT)
	{

		if  ( (   length($text) != 0) &&
				(   ($text =~ /[^fFiIsSvVbBoOuUeElLdDaA]/g == 0)))

		{
# Convert input to upper case.
			my $uctext  = uc ($text) ;
			my @Throughput = split(undef, $uctext) ;
			for (my $i = 0 ; $i < @Throughput ; $i++)
			{

				switch ($Throughput[$i])
				{

					case "$FS"
					{
						$Var_ThroughputFS = $TRUE;
					}
					case "$I2C"
					{
						$Var_ThroughputI2C = $TRUE;
					}
					case "$SPI"
					{
						$Var_ThroughputSPI = $TRUE;
					}
					case "$V4L2"
					{
						$Var_ThroughputV4L2 = $TRUE;
					}
					case "$FBDEV"
					{
						$Var_ThroughputFBDEV = $TRUE;
					}
					case "$OSS"
					{
						$Var_ThroughputOSS = $TRUE;
					}
					case "$USBVIDEO"
					{
						$Var_ThroughputUSBVideo = $TRUE;
					}
					case "$EDMA"
					{
						$Var_ThroughputEDMA = $TRUE;
					}
					case "$VLYNQ"
					{
						$Var_ThroughputVLYNQ = $TRUE;
					}
					case "$VDCE"
					{
						$Var_ThroughputVDCE = $TRUE;
					}
					case "$ALSA"
					{
						$Var_ThroughputALSA = $TRUE;
					}
				}
			}
		}
	if (($Var_ThroughputALSA == $TRUE)||($Var_ThroughputVDCE == $TRUE)||($Var_ThroughputUSBVideo == $TRUE)||($Var_ThroughputOSS == $TRUE)||($Var_ThroughputFBDEV == $TRUE)||($Var_ThroughputV4L2 == $TRUE)||($Var_ThroughputSPI== $TRUE)||($Var_ThroughputI2C == $TRUE)||($Var_ThroughputFS == $TRUE))
{
$Var_ThroughputUser=$TRUE;
}
if (($Var_ThroughputVLYNQ == $TRUE)||($Var_ThroughputEDMA == $TRUE))
{
$Var_ThroughputKernel=$TRUE;
}	
	$valid = $TRUE;
	}

elsif ($menu eq $MENU_FUNCTIONAL)
	{

		if  ( (   length($text) != 0) &&
				(   ($text =~ /[^fFiIsSvVbBoOuUeElLdDaA]/g == 0)))

		{
# Convert input to upper case.
			my $uctext  = uc ($text) ;
			my @Functional = split(undef, $uctext) ;
			for (my $i = 0 ; $i < @Functional ; $i++)
			{

				switch ($Functional[$i])
				{

					case "$FS"
					{
						$Var_FunctionalFS = $TRUE;
					}
					case "$I2C"
					{
						$Var_FunctionalI2C = $TRUE;
					}
					case "$SPI"
					{
						$Var_FunctionalSPI = $TRUE;
					}
					case "$V4L2"
					{
						$Var_FunctionalV4L2 = $TRUE;
					}
					case "$FBDEV"
					{
						$Var_FunctionalFBDEV = $TRUE;
					}
					case "$OSS"
					{
						$Var_FunctionalOSS = $TRUE;
					}
					case "$USBVIDEO"
					{
						$Var_FunctionalUSBVideo = $TRUE;
					}
					case "$EDMA"
					{
						$Var_FunctionalEDMA = $TRUE;
					}
					case "$VLYNQ"
					{
						$Var_FunctionalVLYNQ = $TRUE;
					}
					case "$VDCE"
					{
						$Var_FunctionalVDCE = $TRUE;
					}
					case "$ALSA"
					{
						$Var_FunctionalALSA = $TRUE;
					}
				}
			}
		}
	if (($Var_FunctionalALSA == $TRUE)||($Var_FunctionalVDCE == $TRUE)||($Var_FunctionalUSBVideo == $TRUE)||($Var_FunctionalOSS == $TRUE)||($Var_FunctionalFBDEV == $TRUE)||($Var_FunctionalV4L2 == $TRUE)||($Var_FunctionalSPI== $TRUE)||($Var_FunctionalI2C == $TRUE)||($Var_FunctionalFS == $TRUE))
{
$Var_FunctionalUser=$TRUE;
}
if (($Var_FunctionalVLYNQ == $TRUE)||($Var_FunctionalEDMA == $TRUE))
{
$Var_FunctionalKernel=$TRUE;
}	
	$valid = $TRUE;
	}

	return $valid ;
}


#   ============================================================================
#   func    ShowComplete
#
#   desc    Show the completion message
#   ============================================================================
sub ShowComplete
{
	my ($text)  = "" ;

	&ClearScreen () ;

	&MenuHeader  () ;

	$text .= "\n" ;
	$text .= "  Configuration complete.\n" ;
	$text .= "\n" ;
	$text .= "  See: " . &GetCfgFile ($CFGFILE) . "\n" ;
	$text .= "\n" ;
	$text .= "  ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::\n" ;
	$text .= "  The selected configuration is: \n\n" ;

	$text .= "  PRODUCT                       = " . $Var_Productmenu              . "\n" ;
	$text .= "  PLATFORM                      = " . $Var_Platform                 . "\n" ;


	$text .= "  \n" ;
	$text .= "#   =========================================================\n" ;
	$text .= "#   Setting Compilation Options.\n" ;
	$text .= "#   =========================================================\n" ;
	if ($ARGV[0] ne "functional")
	{
	$text .= "  USE_PT                        = " . $Var_EnablePerformance        . "\n" ;
	$text .= "  USE_TP                        = " . $Var_EnableThroughput         . "\n" ;
	$text .= "  USE_TP_USER                   = " . $Var_ThroughputUser           . "\n" ;
  	$text .= "  USE_TP_I2C                    = " . $Var_ThroughputI2C            . "\n" ;
	$text .= "  USE_TP_SPI                    = " . $Var_ThroughputSPI            . "\n" ;
	$text .= "  USE_TP_V4L2                   = " . $Var_ThroughputV4L2           . "\n" ;
	$text .= "  USE_TP_VDCE                   = " . $Var_ThroughputVDCE           . "\n" ;
	$text .= "  USE_TP_USBVIDEO               = " . $Var_ThroughputUSBVideo       . "\n" ;
	$text .= "  USE_TP_FBDEV                  = " . $Var_ThroughputFBDEV          . "\n" ;
	$text .= "  USE_TP_FS                     = " . $Var_ThroughputFS             . "\n" ;
	$text .= "  USE_TP_OSS                    = " . $Var_ThroughputOSS            . "\n" ;
	$text .= "  USE_TP_ALSA                   = " . $Var_ThroughputALSA           . "\n" ;
	$text .= "  USE_TP_KERNEL                 = " . $Var_ThroughputKernel         . "\n" ;
	$text .= "  USE_TP_VLYNQ                  = " . $Var_ThroughputVLYNQ          . "\n" ;
	$text .= "  USE_TP_EDMA                   = " . $Var_ThroughputEDMA           . "\n" ;
	}
	if ($ARGV[0] ne "performance")
	{
	$text .= "  USE_FN                        = " . $Var_EnableFunctional         . "\n" ;
	$text .= "  USE_FN_USER                   = " . $Var_FunctionalUser           . "\n" ;
	$text .= "  USE_FN_I2C                    = " . $Var_FunctionalI2C            . "\n" ;
	$text .= "  USE_FN_SPI                    = " . $Var_FunctionalSPI            . "\n" ;
	$text .= "  USE_FN_V4L2                   = " . $Var_FunctionalV4L2           . "\n" ;
	$text .= "  USE_FN_VDCE                   = " . $Var_FunctionalVDCE           . "\n" ;
	$text .= "  USE_FN_USBVIDEO               = " . $Var_FunctionalUSBVideo       . "\n" ;
	$text .= "  USE_FN_FBDEV                  = " . $Var_FunctionalFBDEV          . "\n" ;
	$text .= "  USE_FN_FS                     = " . $Var_FunctionalFS             . "\n" ;
	$text .= "  USE_FN_OSS                    = " . $Var_FunctionalOSS            . "\n" ;
	$text .= "  USE_FN_ALSA                   = " . $Var_FunctionalALSA           . "\n" ;
	$text .= "  USE_FN_KERNEL                 = " . $Var_FunctionalKernel         . "\n" ;
	$text .= "  USE_FN_VLYNQ                  = " . $Var_FunctionalVLYNQ          . "\n" ;
	$text .= "  USE_FN_EDMA                   = " . $Var_FunctionalEDMA           . "\n" ;
	}
	$text .= "  ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::\n" ;


	print $text ;
}

#   ============================================================================
#   func    WriteCurrentConfig
#
#   desc    Write the current build configuration
#   ============================================================================
sub WriteCurrentConfig
{
	my ($cfgfile)   = &GetCfgFile ($CFGFILE) ;
	my ($text)      = "" ;

	my ($filehandle) ;

	open ($filehandle, ">$cfgfile") || die "!! Couldn't open file: $cfgfile\n" ;

	$text .= "#   =========================================================\n" ;
	$text .= "#   PSP TEST BENCH Configuration file.\n" ;
	$text .= "#\n" ;
	$text .= "#   CAUTION! This is a generated file.\n" ;
	$text .= "#            All changes will be lost.\n" ;
	$text .= "#\n" ;
	$text .= "#   This file was generated on " . $Var_Date . "\n" ;
	$text .= "#   =========================================================\n" ;
	$text .= "\n" ;
	$text .= "\n" ;

	$text .= "#   =========================================================\n" ;
	$text .= "#   When this file was created.\n" ;
	$text .= "#   =========================================================\n" ;
	$text .= "export  CFGDATE                       = " . $Var_Date                     . "\n" ;
	$text .= "\n" ;
	$text .= "\n" ;


	$text .= "\n" ;
	$text .= "\n" ;


	$text .= "export  PRODUCT                       = " . $Var_Productmenu              . "\n" ;
	$text .= "export  PLATFORM                      = " . $Var_Platform                 . "\n" ;



	$text .= "\n" ;
	$text .= "#   =========================================================\n" ;
	$text .= "#   Setting Compilation Options.\n" ;
	$text .= "#   =========================================================\n" ;
		if ($ARGV[0] ne "functional")
	{
	$text .= "export  USE_PT                        = " . $Var_EnablePerformance        . "\n" ;
	$text .= "export  USE_TP                        = " . $Var_EnableThroughput         . "\n" ;
	$text .= "export  USE_TP_USER                   = " . $Var_ThroughputUser           . "\n" ;
  	$text .= "export  USE_TP_I2C                    = " . $Var_ThroughputI2C            . "\n" ;
	$text .= "export  USE_TP_SPI                    = " . $Var_ThroughputSPI            . "\n" ;
	$text .= "export  USE_TP_V4L2                   = " . $Var_ThroughputV4L2           . "\n" ;
	$text .= "export  USE_TP_VDCE                   = " . $Var_ThroughputVDCE           . "\n" ;
	$text .= "export  USE_TP_USBVIDEO               = " . $Var_ThroughputUSBVideo       . "\n" ;
	$text .= "export  USE_TP_FBDEV                  = " . $Var_ThroughputFBDEV          . "\n" ;
	$text .= "export  USE_TP_FS                     = " . $Var_ThroughputFS             . "\n" ;
	$text .= "export  USE_TP_OSS                    = " . $Var_ThroughputOSS            . "\n" ;
	$text .= "export  USE_TP_ALSA                   = " . $Var_ThroughputALSA           . "\n" ;
	$text .= "export  USE_TP_KERNEL                 = " . $Var_ThroughputKernel         . "\n" ;
	$text .= "export  USE_TP_VLYNQ                  = " . $Var_ThroughputVLYNQ          . "\n" ;
	$text .= "export  USE_TP_EDMA                   = " . $Var_ThroughputEDMA           . "\n" ;
	}
	if ($ARGV[0] ne "performance")
	{
	$text .= "export  USE_FN                        = " . $Var_EnableFunctional         . "\n" ;
	$text .= "export  USE_FN_USER                   = " . $Var_FunctionalUser           . "\n" ;
	$text .= "export  USE_FN_I2C                    = " . $Var_FunctionalI2C            . "\n" ;
	$text .= "export  USE_FN_SPI                    = " . $Var_FunctionalSPI            . "\n" ;
	$text .= "export  USE_FN_V4L2                   = " . $Var_FunctionalV4L2           . "\n" ;
	$text .= "export  USE_FN_VDCE                   = " . $Var_FunctionalVDCE           . "\n" ;
	$text .= "export  USE_FN_USBVIDEO               = " . $Var_FunctionalUSBVideo       . "\n" ;
	$text .= "export  USE_FN_FBDEV                  = " . $Var_FunctionalFBDEV          . "\n" ;
	$text .= "export  USE_FN_FS                     = " . $Var_FunctionalFS             . "\n" ;
	$text .= "export  USE_FN_OSS                    = " . $Var_FunctionalOSS            . "\n" ;
	$text .= "export  USE_FN_ALSA                   = " . $Var_FunctionalALSA           . "\n" ;
	$text .= "export  USE_FN_KERNEL                 = " . $Var_FunctionalKernel         . "\n" ;
	$text .= "export  USE_FN_VLYNQ                  = " . $Var_FunctionalVLYNQ          . "\n" ;
	$text .= "export  USE_FN_EDMA                   = " . $Var_FunctionalEDMA           . "\n" ;
	}
	$text .= "\n" ;
	$text .= "\n" ;


	print $filehandle $text ;

	close ($filehandle) ;
}

#   ============================================================================
#   func    WriteHeaderFile
#
#   desc    Write the current build configuration in to a Header file
#   ============================================================================
sub WriteHeaderFile
{
	my ($headerfile)   = &GetCfgFile ($HEADERFILE) ;
	my ($text)      = "" ;

	my ($filehandle) ;

	open ($filehandle, ">$headerfile") || die "!! Couldn't open file: $headerfile\n" ;

	$text .= "/*  =========================================================\n" ;
	$text .= "    PSP TEST BENCH Configuration file.\n" ;
	$text .= " \n" ;
	$text .= "    CAUTION! This is a generated file.\n" ;
	$text .= "             All changes will be lost.\n" ;
	$text .= " \n" ;
	$text .= "    This file was generated on " . $Var_Date . "\n" ;
	$text .= "    =========================================================\n */" ;
	$text .= "\n" ;
	$text .= "\n" ;
	$text .= "\n" ;
	$text .= "\n" ;
	$text .= "#ifndef __CONFIG_H__ \n" ;
	$text .= "#define __CONFIG_H__ \n" ;
	$text .= "\n" ;
	$text .= "\n" ;


	if ($Var_EnablePerformance == $TRUE)
	{
		$text .= "#define USE_PT\n" ;
	}
	if ($Var_EnableThroughput == $TRUE)
	{
		$text .= "#define USE_TP\n" ;
	}
	if ($Var_ThroughputI2C == $TRUE)
	{
		$text .= "#define USE_TP_I2C\n" ;
	}
	if ($Var_ThroughputSPI == $TRUE)
	{
		$text .= "#define USE_TP_SPI\n" ;
	}
	if ($Var_ThroughputV4L2 == $TRUE)
	{
		$text .= "#define USE_TP_V4L2\n" ;
	}
	if ($Var_ThroughputVDCE == $TRUE)
	{
		$text .= "#define USE_TP_VDCE\n" ;
	}
	if ($Var_ThroughputUSBVideo == $TRUE)
	{
		$text .= "#define USE_TP_USBVIDEO\n";
	}
	if ($Var_ThroughputFBDEV == $TRUE)
	{
		$text .= "#define USE_TP_FBDEV\n" ;
	}
	if ($Var_ThroughputFS == $TRUE)
	{
		$text .= "#define USE_TP_FS\n" ;
	}
	if ($Var_ThroughputOSS == $TRUE)
	{
		$text .= "#define USE_TP_OSS\n" ;
	}
	if ($Var_ThroughputALSA == $TRUE)
	{
		$text .= "#define USE_TP_ALSA\n" ;
	}
	if ($Var_ThroughputEDMA  == $TRUE)
	{
		$text .= "#define USE_TP_EDMA\n" ;
	}
	if ($Var_ThroughputVLYNQ == $TRUE)
	{
		$text .= "#define USE_TP_VLYNQ\n" ;
	}
	if ($Var_EnableFunctional == $TRUE)
	{
		$text .= "#define USE_FN\n" ;
	}
	if ($Var_FunctionalI2C == $TRUE)
	{
		$text .= "#define USE_FN_I2C\n" ;
	}
	if ($Var_FunctionalSPI == $TRUE)
	{
		$text .= "#define USE_FN_SPI\n" ;
	}
	if ($Var_FunctionalV4L2 == $TRUE)
	{
		$text .= "#define USE_FN_V4L2\n" ;
	}
	if ($Var_FunctionalVDCE == $TRUE)
	{
		$text .= "#define USE_FN_VDCE\n" ;
	}
	if ($Var_FunctionalUSBVideo == $TRUE)
	{
		$text .= "#define USE_FN_USBVIDEO\n";
	}
	if ($Var_FunctionalFBDEV == $TRUE)
	{
		$text .= "#define USE_FN_FBDEV\n" ;
	}
	if ($Var_FunctionalFS == $TRUE)
	{
		$text .= "#define USE_FN_FS\n" ;
	}
	if ($Var_FunctionalOSS == $TRUE)
	{
		$text .= "#define USE_FN_OSS\n" ;
	}
	if ($Var_FunctionalALSA == $TRUE)
	{
		$text .= "#define USE_FN_ALSA\n" ;
	}
	if ($Var_FunctionalEDMA  == $TRUE)
	{
		$text .= "#define USE_FN_EDMA\n" ;
	}
	if ($Var_FunctionalVLYNQ == $TRUE)
	{
		$text .= "#define USE_FN_VLYNQ\n" ;
	}
	$text .= "\n" ;
	$text .= "\n" ;
	$text .= "#endif\n";

	print $filehandle $text ;

	close ($filehandle) ;
}
#   ============================================================================
#   func    GetCfgFile
#
#   desc    Returns the full path to configuration file
#   ============================================================================
sub GetCfgFile
{
	my ($file)  = shift (@_) ;
	my ($str) ;

	if    ($TheOS eq $OS_WINDOWS)
	{
		$str = $Var_RootDir . "\\config\\" . $file ;
	}
	else
	{
		$str = $Var_RootDir . "/config/" . $file ;
	}

	return $str ;
}

