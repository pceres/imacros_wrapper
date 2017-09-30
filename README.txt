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
- Install the free version of iMacros (if not done yet).
- Load the files inside the iMacros Macro folder. They should appear in the iMacros toolbar in your browser (tested in Firefox).
- Run imacros_wrapper.js : an endless loop should start in the browser. 
  This means that the imacros_wrapper is ready to receive automation commands from the Matlab part of the tool.
- Open Matlab, and add to the path the imacros Macro subfolder (where the iw.m file is located).
  This way you are ready to run iw commands from Matlab prompt or from any program.
- See iw.m help ("help iw" from Matlab prompt), and then start playing, beginning from the examples shown (such as the Google test).
