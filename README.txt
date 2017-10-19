# imacros_wrapper
Control iMacros using Matlab, merging the web automation of the first with the computational power of the latter.
The iMacros tool is a powerful web automation tool, but it has poor computational capabilities,
because they are demanded to Javascript language (imacros_wrapper.js is an example!).
Those that are more familiar with Matlab language, imacros_wrapper offers the opportunity to interact with iMacros:
the idea is to create small iMacros script that do the dirty work on the browser, and then to recover the info from, 
or pass parameters to, these scripts, from the Matlab environment.
In one of the samples in the iw.m help Google website is asked for several keywords, and the number of pages with those words
are taken back and shown in a powerful Matlab bar plot.


Instructions for set up: 
- Install the free version of iMacros 8.9.7 (newer versions don't work. See here for downgrading from the latest version: http://wiki.imacros.net/iMacros_for_Firefox#How_to_Downgrade).
- the tool was tested with the following Firefox-iMacros combinations:
	+ Windows 7: Firefox (version 56.0.1) & iMacros 8.9.7
	+ Linux Slackware 14.2: Firefox (version 45.2.0) & iMacros 8.9.7
- Load the files inside the iMacros Macro folder. They should appear in the iMacros toolbar in your browser (tested in Firefox).
- Run imacros_wrapper.js : an endless loop should start in the browser. 
  This means that the imacros_wrapper is ready to receive automation commands from the Matlab part of the tool.
- Open Matlab, and add to the path the imacros Macro subfolder (where the iw.m file is located).
  This way you are ready to run iw commands from Matlab prompt or from any program.
- See iw.m help ("help iw" from Matlab prompt), and then start playing, beginning from the examples shown (such as the Google test).


To improve performance, allowing very long runs (many days):
- disable sleep mode, to let iMacros wrapper work continuously.
  On a Linux laptop, you can achieve this with the following command: xset -dpms s off
- disable JavaScript commands in iMacros window. Otherwise, the script becomes slower and slower.
  On the iMacros side tab: Manage --> Settings --> Javascript scripting settings --> uncheck "Show Javascript during replay"
- disable download history saving, if many downloads have to be done (such as san example). Otherwise history could become
  so long that clearing becomes impossible.

To open multiple Firefox instances with different profiles, run following prompt commands:
"C:\Program Files (x86)\Mozilla Firefox\firefox.exe" "imacros://run/?m=iw\imacros_wrapper.js"
"C:\Program Files (x86)\Mozilla Firefox\firefox.exe" -P <profile_2> --no-remote "imacros://run/?m=iw\imacros_wrapper.js"
...
"C:\Program Files (x86)\Mozilla Firefox\firefox.exe" -P <profile_N> --no-remote "imacros://run/?m=iw\imacros_wrapper.js"
