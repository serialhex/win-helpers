net stop wuauserv
rd /s /q %systemroot%\SoftwareDistribution
net start wuauserv
set /p DUMMY=Finished!  Hit ENTER to continue...
