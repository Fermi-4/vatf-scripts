/**
 * @main.js - This script mimics Texas Instruments' load6x stand-alone
 * simulator base functionality but will work with any TI target (HW or
 * Simulator) that is supported by Debug Server Scripting.
 */

/*
 * Modified by CCW to run multicore projects (version 1.1)
*/

// Run loadti.
testEnv = {};
debugSession = [];
perCoreOutFiles = [];
cpuName = "*";
run();

/**
 * Wait the number of milliseconds specified.
 * @param {milliseconds} Number of milliseconds to wait.
 */
function wait(milliseconds)
{
	var exitTime = (new Date()).getTime() + milliseconds;
	while((new Date()).getTime() < exitTime){};
}

/**
 * Send message to the console and log (if logging is enabled)
 * @param {String} The string to output to the console/log.
 */
function printTrace(string)
{
    if (!testEnv.quietMode)
	{
        dssScriptEnv.traceWrite(string);
    }
}

/**
 * Get error code from the given exception.
 * @param {exception} The exception from which to get the error code.
 */
function getErrorCode(exception)
{
	var ex2 = exception.javaException;
	if (ex2 instanceof Packages.com.ti.ccstudio.scripting.environment.ScriptingException) {
		return ex2.getErrorID();
	}
	return 0;
}

/**
 * This function is called to perform some clean up before exiting (or
 * aborting) the script. It assumes that the the scripting environment and
 * debug and profile servers have been created.
 */
function quit(retVal)
{

    if (isDebugSession)
	{
		printTrace("Terminating debug session...");
        for (var core = 0; core < testEnv.coresToRun; ++core)
        {
            // Close debug sessions.
			printTrace(" Core " + core + ": " + debugSession[core].getCPUName() + "...");
            debugSession[core].terminate();
			wait(500)
        }
    }

    if (isDebugServer)
	{
		debugServer.stop();
    }

    date = new Date();
    printTrace("\nEND: " + date.toTimeString());

    if (testEnv.logFile != null)
	{
        // Close log.
		dssScriptEnv.traceEnd();
    }

    delete testEnv;

    // Terminate JVM and return main return value.
    java.lang.System.exit(retVal);
}

function nothing()
{
	//does nothing.
}

/*
 * Main function.
 */
function run()
{
    var inst;

    var errCode = 0;
    var retVal = 0;
    var date = 0;
    var defaultTimeout = -1;

    isDebugServer = false;
    isDebugSession = false;

    load(java.lang.System.getenv("LOADTI_PATH") + "/getArgs.js");

    getArgs();

    // Create base scripting environment.
    dssScriptEnv = Packages.com.ti.ccstudio.scripting.environment.ScriptingEnvironment.instance();

    // Set overall script timeout value.
    dssScriptEnv.setScriptTimeout(defaultTimeout);

    // Enable logging to a file if specified.
    if (testEnv.logFile != null)
    {
        // NOTE: Log output folder must already exist.
        try
		{
            dssScriptEnv.traceBegin(testEnv.logFile, java.lang.System.getenv("LOADTI_PATH").replace("\\", "/") +
					"/DefaultStylesheet.xsl");
            dssScriptEnv.traceSetFileLevel(Packages.com.ti.ccstudio.scripting.environment.TraceLevel.ALL);
        }
		catch (ex)
		{
			errCode = getErrorCode(ex);
            dssScriptEnv.traceWrite("Error code #" + errCode + ", failed to enable logging for " + testEnv.logFile +
					"\nLogging disabled!");
            testEnv.logFile = null;
        }
    }

    // Set console verbosity.
    if (testEnv.verboseMode)
	{
        dssScriptEnv.traceSetConsoleLevel(Packages.com.ti.ccstudio.scripting.environment.TraceLevel.ALL);
    }

    printTrace("\n***** DSS Generic Loader *****\n");

    date = new Date();
    printTrace("START: " + date.toTimeString() + "\n");

    // Configure the Debug Server.
    if (testEnv.setupCfgFile != null)
    {
        printTrace("Configuring Debug Server for specified target...");

        load(java.lang.System.getenv("LOADTI_PATH") + "/dsSetup.js");

        errCode = configureDebugServer(testEnv.setupCfgFile, dssScriptEnv);
        if (errCode != 0)
        {
            quit(errCode);
        }

        printTrace("Done");

		// There's no more to do if no outfiles have been provided.
		if (testEnv.outFiles == null)
		{
			quit(0);
		}
    }
	else
	{
        if (java.lang.System.getProperty("os.name").contains("Linux"))
        {
            dssScriptEnv.traceWrite("No target setup configuration file specified. Aborting!");
            quit(1);
        }

        printTrace("No target setup configuration file specified. Using existing setup");
    }

    // Open Debug Server session.
    if (!isDebugServer)
    {
        debugServer = dssScriptEnv.getServer("DebugServer.1");
        isDebugServer = true;
    }

	printTrace("Opening debug session...");
    for (var core = 0; core < testEnv.coresToRun; ++core)
    {
        // Open debug sessions.
        debugSession[core] = debugServer.openSession("*", cpuName);
		cpuPrefix = debugSession[core].getCPUName().split("_",2)[0]
		cpuInst = parseInt(debugSession[core].getCPUName().split("_",2)[1])
        cpuName = cpuPrefix + "_" + cpuInst;
		printTrace(" Core " + core + ": " + cpuName)
        cpuName = cpuPrefix + "_" + (cpuInst + 1);
		wait(500)
    }
    isDebugSession = true;

	printTrace("TARGET BOARD...");
    for (var core = 0; core < testEnv.coresToRun; ++core)
    {
		printTrace(" Core " + core + ": " + debugSession[core].getBoardName());
	}

    if (testEnv.resetSystem)
    {
        printTrace("Resetting system...");
        // Reset system.
        try
		{
			//debugSession.expression.evaluate('GEL_LoadGel("C:/myGELfile.gel")');
			debugSession[0].expression.evaluate('GEL_AdvancedReset("System Reset")');
			wait(5000);
        }
		catch (ex)
		{
			errCode = getErrorCode(ex);
            dssScriptEnv.traceWrite("Error code #" + errCode + ", could not reset system!\nAborting!");
            quit(errCode != 0 ? errCode : 1);
        }
        printTrace("Resetting system complete...");
    }
	
    if (testEnv.gelFilesToLoad.length != 0)
    {
		var arrayIndex = 0;
        printTrace("Loading GEL Files...");

        // Load all gel files that were specified on all cores.
        try
		{
            for (var core = 0; core < testEnv.coresToRun; ++core)
            {
				for (var arrayIndex = 0; arrayIndex < testEnv.gelFilesToLoad.length; ++arrayIndex)
				{
					printTrace(" GEL File Core " + core + ": " + testEnv.gelFilesToLoad[arrayIndex]);
					debugSession[core].expression.evaluate('GEL_LoadGel("' + testEnv.gelFilesToLoad[arrayIndex] + '")');
				}
			}
        }
		catch (ex)
		{
			errCode = getErrorCode(ex);
            dssScriptEnv.traceWrite("Error code #" + errCode + ", could not load gel file: " + testEnv.gelFilesToLoad[arrayIndex] + "!\nAborting!");
            quit(errCode != 0 ? errCode : 1);
        }
    }

    printTrace("Connecting to target...");
    // Connect to target. If target is simulator or already connected, a warning will be reported.
	for (var core = 0; core < testEnv.coresToRun; ++core)
	{
		printTrace(" Connecting core " + core + "...");
		try
		{
			debugSession[core].target.connect();
			wait(1000);
		}
		catch (ex)
		{
			errCode = getErrorCode(ex);
			dssScriptEnv.traceWrite("Error code #" + errCode + ", could not connect to target!\nAborting!");
			quit(errCode != 0 ? errCode : 1);
		}
	}

	//wait(5000);
	
    if (testEnv.resetTarget)
    {
        printTrace("Resetting target...");

        // Reset target.
        try
		{
            for (var core = 0; core < testEnv.coresToRun; ++core)
            {
				printTrace(" Resetting core " + core + "...");
                debugSession[core].target.reset();
				wait(1000);
            }
        }
		catch (ex)
		{
			errCode = getErrorCode(ex);
            dssScriptEnv.traceWrite("Error code #" + errCode + ", could reset target!\nAborting!");
            quit(errCode != 0 ? errCode : 1);
        }
    }

    if (testEnv.gelFunctionsToRun.length != 0)
    {
		var arrayIndex = 0;
        printTrace("Running GEL Functions...");

        // Load all gel files that were specified.
        try
		{
        for (var arrayIndex = 0; arrayIndex < testEnv.gelFunctionsToRun.length; ++arrayIndex)
        {
          printTrace(" Executing GEL Function: " + testEnv.gelFunctionsToRun[arrayIndex]);
          debugSession[0].expression.evaluate(testEnv.gelFunctionsToRun[arrayIndex]);
          // wait for 5 seconds after each GEL function call
          var exitTime = (new Date()).getTime() + 5000;
          while((new Date()).getTime() < exitTime){};
        }
    }
		catch (ex)
		{
			errCode = getErrorCode(ex);
            dssScriptEnv.traceWrite("Error code #" + errCode + ", could run gel function: " + testEnv.gelFunctionsToRun[arrayIndex] + "!\nAborting!");
            quit(errCode != 0 ? errCode : 1);
        }
    }

	// Load and run each program provided.
	java.lang.System.out.println("testEnv.outFiles: " + testEnv.outFiles);
	printTrace("");
	var st = null;
	if (testEnv.separateFilePerCore)
	{
		var st2 = new java.util.StringTokenizer(testEnv.outFiles, "+");
		var index = 0;
		while (st2.hasMoreTokens())
		{
			perCoreOutFiles[index] = st2.nextToken()
			printTrace("Outfile[" + index + "] = " + perCoreOutFiles[index]);
			index += 1;
		}
		st = new java.util.StringTokenizer(perCoreOutFiles[0], "+");
	}
	else
	{
		st = new java.util.StringTokenizer(testEnv.outFiles, "+");
	}
	while (st.hasMoreTokens())
	{
		var outFile = st.nextToken();
	
		var filePath = new java.io.File(outFile);
		var outFileName = filePath.getName();
		testEnv.argvArgs[0] = outFileName;
	
		printTrace("Loading " + outFile);
		printTrace("");

	    // Load program and pass arguments to main (if applicable).
	    try
		{
			if (testEnv.initBss)
			{
                for (var core = 0; core < testEnv.coresToRun; ++core)
                {
                    debugSession[core].memory.setBssInitValue(testEnv.initBssValue);
                    printTrace(" initedBssValue session: " + core);
                }
			}
			
			if (testEnv.argvArgs.length < 2)
			{
                for (var core = 0; core < testEnv.coresToRun; ++core)
                {
					printTrace(" Loading out file core " + core + "...");
					if (testEnv.separateFilePerCore)
					{
						outFile = perCoreOutFiles[core];
					}
                    debugSession[core].memory.loadProgram(outFile);
					wait(1000);
               }
			}
			else
			{
                for (var core = 0; core < testEnv.coresToRun; ++core)
                {
					printTrace(" Loading out file core " + core + "...");
					if (testEnv.separateFilePerCore)
					{
						outFile = perCoreOutFiles[core];
					}
                    debugSession[core].memory.loadProgram(outFile, testEnv.argvArgs);
					wait(1000);
                }
			}
	    }
		catch (ex)
		{
			errCode = getErrorCode(ex);
	        printTrace("Error code #" + errCode + ", " + outFile + " load failed!\nAborting!");
	        quit(errCode != 0 ? errCode : 1);
	    }

		wait(5000);
	    printTrace("Done");

	    load(java.lang.System.getenv("LOADTI_PATH") + "/memXfer.js");

	    // Load data from the host to target memory (if applicable).
	    if ((testEnv.loadRaw.length > 0) || (testEnv.loadDat.length > 0))
	    {
	        printTrace("Loading data to target memory...");

            errCode = memLoad(dssScriptEnv, debugSession[0], testEnv.loadRaw, testEnv.loadDat);

	        if (errCode != 0)
	        {
	            printTrace("Memory load failed with errCode: " + errCode);
	        }
			else
			{
	            printTrace("Done");
	        }
	    }

	    if (!testEnv.onlyLoad)
	    {
	        printTrace("Target running...");

	        // Set script timeout value for run API.
	        dssScriptEnv.setScriptTimeout(testEnv.timeoutValue);

	        if (testEnv.cioFile != null)
	        {
                for (var core = 0; core < testEnv.coresToRun; ++core)
                {
                    // Begin CIO logging.
                    debugSession[core].beginCIOLogging(testEnv.cioFile);
                }
	        }

	        // Run to end of program (or timeout) and return total cycles unless asynch run.
	        try
			{
				// Is the target already at the end of the program? If so, do not try to run again.
				// Note: we need to check the existance of the symbol first, since the evaluate function does not, and will return errors if the symbol does not exist, causing the script to exit
				// Note: This check is to fix the following use case: if the debugger is configured to Auto Run to a label after program load but that label is not hit then the loadti script may cause the program to enter an infinite loop.
				if ( ( debugSession[0].symbol.exists("C$$EXIT") && debugSession[0].expression.evaluate( "PC == C$$EXIT" ) ) ||
					 ( debugSession[0].symbol.exists("C$$EXITE") && debugSession[0].expression.evaluate( "PC == C$$EXITE") ) ||
					 ( debugSession[0].symbol.exists("abort") && debugSession[0].expression.evaluate( "PC == abort") ) ) 
				{
					printTrace( "Target failed to run to desired user label after program load, and is at end of program.  Script execution aborted." );
				}
                else
                {		
					if (!testEnv.asyncRun)
					{
						printTrace("Interrupt to abort . . .");
						if (!testEnv.noProfile)
						{
	                        if (testEnv.coresToRun == 1)
	                        {
	                            // Run and benchmark a single core
	                            var cycles = debugSession[0].clock.runBenchmark();
	                        }
	    					else
	                        {
	                            // Run all cores
	                            var cycles = debugServer.simultaneous.run();
	                        }
	                    }
	                    else
	                    {
	                        for (var core = 0; core < testEnv.coresToRun; ++core)
	                        {
	                            if (testEnv.coresToRun > 1)
	                            {
	                                if (core == testEnv.coresToRun - 1)
	                                {
	                                    debugServer.simultaneous.run();
	                                }
	                            }
	                            else
	                            {
	                                debugSession[core].target.run();
	                            }
	                        }
						}
					}
					else
					{
						for (var core = 0; core < testEnv.coresToRun; ++core)
						{
							debugSession[core].target.runAsynch();
						}
					}
                }
		    }
            catch (ex)
            {
                errCode = getErrorCode(ex);
                if (errCode == 1001)
                {
                    for (var core = 0; core < testEnv.coresToRun; ++core)
                    {
                        printTrace(">> OVERALL TIMED OUT");
                        debugSession[core].target.halt();
                    }
                }
                else
                {
                    dssScriptEnv.traceWrite("Error code #" + errCode +
                            ", error encountered during program execution!\nAborting!");
                    quit(errCode != 0 ? errCode : 1);
                }
            }
		    //}

	        if (testEnv.cioFile != null && !testEnv.asyncRun)
	        {
                for (var core = 0; core < testEnv.coresToRun; ++core)
                {
                    // Stop CIO logging.
                    debugSession[core].endCIOLogging();
                }
	        }

	        // Set script timeout value to default.
	        dssScriptEnv.setScriptTimeout(defaultTimeout);

	        if (!testEnv.asyncRun && !testEnv.noProfile)
	        {
	            // Print cycle counts unless script timout occured on program execution.
	            if (errCode != 1001)
				{
                    if (testEnv.coresToRun == 1)
                    {
                        printTrace("NORMAL COMPLETION: " + cycles + " cycles");
                    }
                    else
                    {
                        printTrace("NORMAL COMPLETION: cycles-not-calculated");
                    }
	            }
	        }
	    }

	    // Save data from target memory to a file on the host (if applicable).
	    if ((testEnv.saveRaw.length > 0) || (testEnv.saveDat.length > 0))
	    {
	        // Only dump data if it is not a asynchronous run.
	        if (!testEnv.asyncRun)
	        {
	            printTrace("Saving data to file...");

                errCode = memSave(dssScriptEnv, debugSession[0], testEnv.saveRaw, testEnv.saveDat);

	            if (errCode != 0)
	            {
	                printTrace("Memory save failed with errCode: " + errCode);
					retVal = errCode;
	            }
				else
				{
	                printTrace("Done");
	            }
	        }
			else
			{
	            printTrace("Memory save options are not supported with an asynchronous run!");
	        }
	    }
	}
	
    wait(5000);
    // End automation.
    quit(retVal);
}
