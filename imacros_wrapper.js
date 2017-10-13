//imacros-js:showsteps no

// default values for configurable parameters
var dump_type = "TXT";  // {TXT,HTM,CPL,BMP,JPEG,PNG} default web page dump type
var pause_time = 1;     // default pause in idle loop
var flg_clear = 0;      // default CLEAR behaviour [0,1] 1 --> issue CLEAR command at each loop, clearing all cookies. Speed up performances, but prevents login and session management 

var retcode;
var action, params;
var download_folder, fullname_cmd, os;

var filename_cmd     = "command.csv"; 	  // input file for command to be executed
var filename_retcode = "return_code.txt"; // output file for return code and msg
var filename_dump    = "output.htm";	  // output file for html dump

// valorize global variables
os = getOS(); // detect operating system
download_folder = detect_iMacros_downdload_folder(); // detect root folder for iMacros
fullname_cmd = download_folder+filename_cmd; 	// fullname for file used to pass command to iMacros wrapper

// run infinite loop
myLoop();



// *****
function myLoop() {

var ancora;

iimDisplay("Starting loop");

iimPlayCode("FILEDELETE NAME="+download_folder+filename_retcode); // remove retcode file
iimPlayCode("FILEDELETE NAME="+download_folder+filename_cmd);     // remove command file

iimSet("DUMP_TYPE",dump_type); // {TXT,HTM,CPL,BMP,JPEG,PNG}

ancora = 1;
while (ancora) {
	if (flg_clear) {
		iimPlayCode("CLEAR"); // clear all cookies, but this prevents login and session management
	}
	result = ticFunction();
	do_pause(pause_time);
	code = result[0];
	errmsg = result[1];
	if (code != 0 ) {
		// some action was performed
    		var now = new Date();
    		iimSet('TIMESTAMP',now.toLocaleString());
		iimSet('RETURN_CODE',-code); // code in iw.m have an inverted sign
		iimSet('RETURN_MSG',errmsg);
		iimSet('DEST_FILENAME',filename_retcode);
		iimSet('CMD_FILENAME',filename_cmd);
		iimPlay('iw/iw_write_return_code');
	}
	ancora = (code>=0);
}
} // end function



// *****
function ticFunction() {
//  0; // continue looping, no command found
// ??? // from run_cmd (not blocking errors):
// 	1; // command executed correctly
// 	2; // macro error
// 	3; // unknown internal param
// 	4; // error dumping web page
// -1; // end loop request
// -2; // unknown action requested
// -3; // error reading command

// 1) first execute command
if (check_file_esists(fullname_cmd)) {
	var fullname_cmd2 = fullname_cmd;
	if (os == "Windows") {
		fullname_cmd2 = fullname_cmd.replace(/\//g,"\\"); // replace / as \
	}
	var ret = iimSet("FILENAME",fullname_cmd2);
	retcode = iimPlay("iw/iw_read_cmd");
	if (retcode < 0)
	{ 
		alert(iimGetLastError());
		return [-3, 'Error reading command']; // error reading command
	} else {
		action = iimGetLastExtract(1);
		params = iimGetLastExtract(2);
		result = run_cmd(action,params);
		retcode = result[0];
		retmsg  = result[1] + ' [' + action + ',' + params +']';
	}
} else {
	//iimDisplay("Missing command file, waiting for it...");
	return [0, 'Continuing looping, no command found']; // continuing looping, no command found
}  

if ( (retcode  == 1) || (retcode == 2) ) {
	// 2) dump page if (retcode=1) there was no error, or (retcode=2) macro was run, 
	//    but exited with an error
	iimPlayCode("FILEDELETE NAME="+download_folder+filename_dump); // remove dumped page file to ensure future feedback is the intended one
	iimSet("OUT_FILENAME",filename_dump);
	iimSet("DUMP_TYPE",dump_type);
	retcode2 = iimPlay("iw/iw_dump_page");
	if (retcode2 < 0)
	{ 
		iimDisplay(iimGetLastError());
		return [4, 'Error dumping web page ('+retcode2+')']; // error dumping web page
	}
}

return [retcode, retmsg];
} // end function



// *****
function do_pause(pause_time) {
// make a pause using iMacros
iimSet('PAUSETIME',pause_time);
iimPlay('iw/iw_pause');
}



// *****
function run_cmd(action,params) {
//  1; // macro executed correctly (run action)
//  2; // macro error (run action)
//  3; // unknown internal param (set_param action)
// -1; // end loop request (stop action)
// -2; // unknown action
			
iimDisplay("found action \""+action+"\"  with params \""+params + "\"");
switch(action) {
    case "stop":
	    iimDisplay("Stopping loop");
        return [-1, 'End loop request']; // end loop request
        break;
		
    case "run":
		var res = params.split("|&");
		for (i = 1; i < res.length; i++) {
			res2 = res[i].split("|=");
			variab = res2[0];
			value  = res2[1];
			if (variab) {
				iimSet(variab,value);
			}
		}
		iimDisplay("Running macro " + params);
		retcode = iimPlay(res[0]);
		if (retcode < 0)
		{
			error_msg = retcode + ": " + iimGetLastError();
			iimDisplay(error_msg);
			return [2, error_msg]; // macro error
		} else {
			// retcode = 1 //default return code for correct execution is 1
		}
		break;
		
    case "set_param":
		var res = params.split("|&");
		for (i = 0; i < res.length; i++) {
			res2 = res[i].split("|=");
			variab = res2[0];
			value  = res2[1];
			
			switch (variab) {
			case "dump_type": // web page dump type (iw_dump_page)
				dump_type = value;
				break;
			case "pause_time":
				pause_time = value;
				break
			case "flg_clear":
				flg_clear = Number(value);
				break
			default:
				return [3, 'Unknown internal param']; // unknown internal param
				//break;
			}
		}
		iimDisplay("Setting params " + params);
		return [1, 'Params set correctly']
		
    default:
    	alert("Unknown action " + action + "!");
		
	throw new Error("Unknown action " + action + "!");
        return [-2, 'Unknown action requested']; // unknown action requested
}
return [retcode, 'Action performed correctly'];
} // end function



// *****
function check_file_esists(filename) {

var ret = iimPlayCode("SET !FOLDER_DATASOURCE "+filename);

if (ret >= 0) {
    // file exists
    return 1;
} else {
    // file doesn't exist
    return 0;
}
} // end function



// *****
function getOS() {
  var userAgent = window.navigator.userAgent,
      platform = window.navigator.platform,
      macosPlatforms = ['Macintosh', 'MacIntel', 'MacPPC', 'Mac68K'],
      windowsPlatforms = ['Win32', 'Win64', 'Windows', 'WinCE'],
      iosPlatforms = ['iPhone', 'iPad', 'iPod'],
      os = null;

  if (macosPlatforms.indexOf(platform) !== -1) {
    os = 'Mac OS';
  } else if (iosPlatforms.indexOf(platform) !== -1) {
    os = 'iOS';
  } else if (windowsPlatforms.indexOf(platform) !== -1) {
    os = 'Windows';
  } else if (/Android/.test(userAgent)) {
    os = 'Android';
  } else if (!os && /Linux/.test(platform)) {
    os = 'Linux';
  }

  return os;
}



// *****
function detect_iMacros_downdload_folder() {
//download_folder =  "D:\\Users\\ceres\\Documents\\iMacros\\Downloads\\";
//download_folder = "/home/ceres/iMacros/Downloads/";

iimPlayCode("SET !EXTRACT {{!FOLDER_DATASOURCE}}");
datasource_folder = iimGetLastExtract(1);
download_folder = datasource_folder.replace("Datasources","Downloads");
if (getOS()== "Windows") {
	download_folder =  download_folder + "\\";
} else {
	download_folder =  download_folder + "/";
}
return download_folder;

} // end function
