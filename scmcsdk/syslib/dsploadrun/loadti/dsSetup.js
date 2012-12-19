/** 
 * @dsSetup.js - DSS Generic TI Loader include file that contains functions used
 * by main.js to configure the Debug Server.
 */

var debugServer = null;
var isDebugServer = false;

/**
 * Checks host OS and then configures the Debug Server accordingly for the
 * configuration specified.
 
 * @param {config} configuration file used to configure Debug Server.
 * @param {dssScriptEnv} DSS Scripting Environment object.
 */
function configureDebugServer(config, dssScriptEnv)
{
    errCode = 0;

    if (java.lang.System.getProperty("os.name").contains("Windows") || java.lang.System.getProperty("os.name").contains("Linux"))
    {
		debugServer = dssScriptEnv.getServer("DebugServer.1");
        isDebugServer = true;

 	    // Do DSS Linux XPCOM specific setup.
        try
		{
            debugServer.setConfig(config);
        }
		catch (ex)
		{
			errCode = getErrorCode(ex);
            dssScriptEnv.traceWrite("Error code #" + errCode + ", could not import configuration " + config +
					"\nAborting!");
        }
    }
	else
	{
        dssScriptEnv.traceWrite("Unknown OS: " + System.getProperty("os.name"));
        errCode = 1;
    }

    return errCode;
}
