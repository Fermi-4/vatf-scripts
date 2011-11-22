// factory_defaults dss script
// Import the DSS packages into our namespace to save on typing
importPackage(Packages.com.ti.debug.engine.scripting);
importPackage(Packages.com.ti.ccstudio.scripting.environment);
importPackage(Packages.java.lang);
importPackage(Packages.java.io);
importPackage(Packages.java.util);

// Create our scripting environment object - which is the main entry point into
// any script and the factory for creating other Scriptable ervers and Sessions
var script = ScriptingEnvironment.instance()

var debugScriptEnv = ScriptingEnvironment.instance();
// program_evm environment.
testEnv = {};

// Get the Debug Server and start a Debug Session
var debugServer = script.getServer("DebugServer.1");

//***************Functions define***************************


function isFile(path)
{
	try
	{   
		file = new java.io.FileReader(path);
	}
	catch (ex)
	{
		return false;
	}

	return true;

}


//****************Get New Time Stamp***********************
function localTime()
{
	// get time stamp
	var currentTime = new Date();
	var year = currentTime.getFullYear();
	var month = currentTime.getMonth() + 1;
	month = month + "";
	if (month.length == 1)
	{
		month = "0" + month;
	}
	var day = currentTime.getDate();
	var hour = currentTime.getHours();
	var minute = currentTime.getMinutes();
	minute = minute + "";
	if (minute.length == 1)
	{
		minute = "0" + minute;
	}
	var second = currentTime.getSeconds();
	second = second + "";
	if (second.length == 1)
	{
		second = "0" + second;
	}
    
	return (year+"_"+month+"_"+day+"_"+hour+minute+second);
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

function pausecomp(millis)
 {
  var date = new Date();
  var curDate = null;
  do { curDate = new Date(); }
  while(curDate-date < millis)
  { 
  //print("Waiting "+millis+"ms...\r\n") 
  }
}

function cleanup_and_exit()
{
if (testEnv.cioFile != null)
{
	// Stop CIO logging.
	debugSession.endCIOLogging();
}

debugSession.terminate();
debugServer.stop()

// Stop logging and exit.
script.traceEnd();
java.lang.System.exit(0);

}
//*******************************************
// Declarations and Inititalizations
var root_dir    = java.lang.System.getProperty("user.dir");
var host_os           = "";
var script_logs    = root_dir+"/logs/";
var script_configs = root_dir+"/configs/";
var script_binaries = root_dir+"/binaries/";
var targetConfig = "";
var writeAll = false;
var big_endian = false;
var targetFlag = "unknown";
var targetConfig = "unknown";
var emul560 = false;

testEnv.cioFile = null;

if (java.lang.System.getProperty("os.name").match(/Linux/i))
{
        host_os = "-linuxhost";
}

// Parse the arguments
if (arguments.length > 0 && arguments.length < 4)
{
    // parse the board spec
    var board_spec = arguments[0].toLowerCase();
    board_spec = board_spec.replace(/^tmd(x|s)/, "");
    board_spec = board_spec.replace(/^evmc/, "evm");
    
    // find endian, user wants
    if (board_spec.match(/-be$/))
    {
        big_endian = true;
        board_spec = board_spec.replace(/-be$/, "");
    }
    else
        board_spec = board_spec.replace(/-le$/, "");
        
    // find onboard emulation option for this board 
    if (board_spec.match(/lx?e$/))
    {
        emul560 = true;
        board_spec = board_spec.replace(/e$/, "");
    }
        
    // for now, use the same software for lx and l variants
    board_spec = board_spec.replace(/lx$/, "l");
    
    // for now, treat evm6618l as an alias for evm6670l
    board_spec = board_spec.replace(/evm6618/, "evm6670");
        
    targetFlag = board_spec;
    
    endian_spec = (big_endian ? "-be" : "");
    
    board_binaries = script_binaries + targetFlag + endian_spec + "/";
    targetConfig = java.lang.System.getenv("PROGRAM_EVM_TARGET_CONFIG_FILE");
    if (!targetConfig) {   
        targetConfig = script_configs + targetFlag + "/" + targetFlag + (emul560 ? "e" : "") + host_os + ".ccxml";
    }
  

    print("board: " + targetFlag);
    print("endian: " + (big_endian ? "Big" : "Little"));
    print("emulation: " + (emul560 ? "XDS560 mezzanine" : "onboard XDS100"));
    print("binaries: " + board_binaries);
    print("ccxml: " + targetConfig);

    var dir = new File(board_binaries);
    if (!dir.exists())
    {
        print("board binaries directory not found");
        java.lang.System.exit(2);
    }
 
}
else
{
  print("Syntax error in command line");
	print("Syntax: gel_test.js [tmdx|tmds]evm[c](<device>)l[x][e][-le|-be]")
  
	print("    tmdx: TMDX type EVM")
	print("    tmds: TMDS type EVM")
	print("    c: Not used, for backward compatibility")
	print("    <device> is the board name e.g 6472,6678 etc")
	print("    l: Low cost EVM")
	print("    x: EVM supports encryption")
	print("    e: EVM uses 560 Mezzanine Emulator daughter card")
	print("    le: Little Endian")
	print("    be: Big Endian")

	print("    example: TMDXEVM6678L-le")	
	java.lang.System.exit(0);
}

var ddr_test_program = board_binaries + "ddr_test_program" + ".out";


switch (targetFlag)
{
	case "evm6457l":
		cpu_id = "C64XP_1";
		break;
	case "evm6474l":
		cpu_id = "C64XP_0";
		break;
	case "evm6455":
		cpu_id = "C64XP_0";
		break;
	case "evm6474":
		cpu_id = "C64XP_1A";
		break;
	case "evm6472l":
		cpu_id = "C64XP_A";
		break;
	case "evm6670l":
		cpu_id = "C66xx_0";
		break;
	case "evm6678l":
		cpu_id = "C66xx_0";
		break;
	default:
		script.traceWrite("Could not file cpu id for target " + targetFlag + "\n");


}

start = localTime();
testEnv.cioFile = script_logs+targetFlag+"_"+start+"-cio"+".txt";
// Create a log file in the current directory to log script execution
script.traceBegin(script_logs+targetFlag+"_"+start+"-trace"+".txt")

// Configure target
debugServer.setConfig(targetConfig);
pausecomp(1000);
debugSession = debugServer.openSession("*",cpu_id);
if (testEnv.cioFile != null)
	debugSession.beginCIOLogging(testEnv.cioFile);
pausecomp(1000);
debugSession.target.connect();
pausecomp(1000);
// debugSession.target.reset();
// pausecomp(1000);


	start = localTime();
	script.traceWrite("Start writing DDR test");
	script.traceWrite("DDR test program:" + ddr_test_program + "\r\n");
	if (isFile(ddr_test_program)) 
	{
  
		debugSession.memory.loadProgram(ddr_test_program);
		try
		{
      debugSession.target.run()
		}
		catch (ex)
		{
		   errCode = getErrorCode(ex);
		   script.traceWrite("Error code #" + errCode + ", could not load file " + sFilename +
					" to target memory!");
		}
		debugSession.target.run()
		end = localTime();
	}
	else
	{
		script.traceWrite("Required ddrtest files do not exist in " + board_binaries + "\n");
	 
	}
cleanup_and_exit();
