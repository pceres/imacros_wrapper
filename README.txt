# imacros_wrapper
*** Description
Control iMacros using Matlab, merging the web automation of the first with the computational power of the latter.
The iMacros tool is a powerful web automation tool, but it has poor computational capabilities,
because they are demanded to Javascript language (imacros_wrapper.js is an example!).
Those that are more familiar with Matlab language, imacros_wrapper offers the opportunity to interact with iMacros:
the idea is to create small iMacros script that do the dirty work on the browser, and then to recover the info from, 
or pass parameters to, these scripts, from the Matlab environment.
In one of the samples in the iw.m help Google website is asked for several keywords, and the number of pages with those words
are taken back and shown in a powerful Matlab bar plot.


*** Instructions for set up: 
- Install Firefox browser, or, if already installed, check that you have the right version (read later) for iMacros to work. For a given version, say 56.0.1
- Install the FREE version of iMacros 8.9.7 (WARNING! Newer versions don't work. See here for downgrading from the latest version: https://addons.mozilla.org/it/firefox/addon/imacros-for-firefox/versions/).
- the tool was tested with the following Firefox-iMacros combinations:
	+ Windows 7: Firefox (version 56.0.1) & iMacros 8.9.7
	+ Linux Slackware 14.2: Firefox (version 45.2.0) & iMacros 8.9.7
- Check that iMacros is working: you should be able to view the sidebar by pressing F8, or using the Firefox menus (View --> Sidebar --> iOpus iMacros). Run some test script
- From iMacros sidebar, locate the iMacros Macros folder (Manage --> Settings --> Folders), that is the folder where new iMacros scripts are saved. In later examples, let's assume <path_to_iMacros_Macros>
- Copy the iMacros_wrapper files (extracted from zipped archive downloaded from github) inside the iMacros Macro folder. They should appear in the iMacros toolbar in your browser (in particular, iw subfolder and all its content; close/reopen to refresh the sidebar).
- Run imacros_wrapper.js : an endless loop should start in the browser.
  This means that the imacros_wrapper is ready to receive automation commands from the Matlab part of the tool (iw.m).
- Install Matlab (version 2009b is checked, but it should work on later versions, as well), or check version using the command 'version'
- Add to the path the imacros Macro subfolder (where the iw.m file is located): addpath '<path_to_iMacros_Macros>/iw'
  This way you are ready to run iw commands from Matlab prompt from any folder.
- See iw.m help ("help iw" from Matlab prompt), and then start playing, beginning from the examples shown (such as the Google test).


*** To improve performance, allowing very long runs (many days):
- disable sleep mode, to let iMacros wrapper work continuously.
  On a Linux laptop, you can achieve this with the following command: xset -dpms s off
- disable JavaScript commands in iMacros window. Otherwise, the script becomes slower and slower.
  On the iMacros side tab: Manage --> Settings --> Javascript scripting settings --> uncheck "Show Javascript during replay"
- disable download history saving, if many downloads have to be done (such as san example). Otherwise history could become
  so long that clearing becomes impossible.

*** To open multiple Firefox instances with different profiles, run following prompt commands:
"C:\Program Files (x86)\Mozilla Firefox\firefox.exe" "imacros://run/?m=iw\imacros_wrapper.js"
"C:\Program Files (x86)\Mozilla Firefox\firefox.exe" -P <profile_2> --no-remote "imacros://run/?m=iw\imacros_wrapper.js"
...
"C:\Program Files (x86)\Mozilla Firefox\firefox.exe" -P <profile_N> --no-remote "imacros://run/?m=iw\imacros_wrapper.js"

To create a different Firefox profile, from command prompt run firefox with -P argument (the profile manager gui will open):
"C:\Program Files (x86)\Mozilla Firefox\firefox.exe" -P
For each new Firefox instance, follow the instructions for set up indicated above


*** extension: san script
You can download a single batch, a typology (for example birth records for a given town and repository), or a whole town (for example all
civil state records types for Caposele in "Stato civile della Restaurazione") from one of the available online Italian archive states in san website.
Instructions for san.m (automatic image download from http://www.antenati.san.beniculturali.it):
- First of all follow the previous installation instructions: iw.m must be working for san.m to operate, and the iMacros_wrapper must be running in the Firefox sidebar
- Move Matlab work path into san folder: cd '<path_to_iMacros_Macros>/iw/san'
- Type the following Matlab command: help san
  to get an help message
- Once iMAcros_wrapper loop is running in Firefox sidebar, from Matlab you can launch the following commands:
	san_action  = 'dnld_town' % you want to download a whole town
	san_url     = 'http://www.antenati.san.beniculturali.it/v/Archivio+di+Stato+di+Salerno/Stato+civile+della+restaurazione/Caposeleprovincia+di+Avellino/' % url where the record types for the town are listed
	san_folder  = '/home/ceres/StatoCivileSAN/Caposele_Restaurazione/' % local folder on the pc where images have to be stored (on Windows it will look like this: 'C:\some\path')
	san_town    = 'Caposele' % name of town, letters only
	san_caption = 'Caposele(provincia di Avellino)' % name of town EXACTLY as it appears in the web page
    result = san(san_action,{san_url,san_folder,san_town,san_caption}) % pay attention to parenthesis!
- You should see Firefox browser to start downloading images for you, while the Matlab windows reports what is happening. If you go in the download folder that you indicated ('/home/ceres/StatoCivileSAN/Caposele_Restaurazione/' in our example), you should see new subfolders to be created, containing each a year of a certain record type.
- You can safely interrupt the Matlab script by clicking CTRL+c, then closing both Matlab and Firefox, if you need to switch your pc off.
  The san.m script will take note of what has been already downloaded, and, provided it finds the image files, it will skip download.
