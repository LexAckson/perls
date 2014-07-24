#ePSC Validator
#Alex Jackson July 2014
#Checks an eProStudyConfig.xml for the following:
#		1	Output ePSC version
#		2	Output ISP login and password
#		3	Verify ISP password is login backwards
#		4	For each study list the name and display if applicable
#		--	For each language:
#		5	Output display name
#		6	Verify format and spelling for display name (country - lang)
#		7	Verify order of display name (alpha)
#		8	Verify language ID matches the display name
#		9	Verify no language ID is repeated per study
#		10	Output script name
#		11	Output version of the script
#		12	Output bitmap if applicable
#		13	Output image map if applicable


Install:

Open up the 'context menu shortcut.reg' and type in the path to the exe using 
double backslashes, replacing the &&&install dir with double \\&&&.

Ex.

@="\"&&&install dir with double \\&&&\" \"%1\""
@="\"C:\\Users\\alex.jackson\\Documents\\perls\\ePSCValidator.exe\" \"%1\""

Then double click on 'context menu shortcut.reg' to install the shortcut.

All done!
