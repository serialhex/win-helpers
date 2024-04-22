net stop wuauserv
net stop cryptSvc
net stop bits
net stop msiserver

rd /s /q %systemroot%\SoftwareDistribution
rd /s /q %systemroot%\System32\catroot2

net start wuauserv
net start cryptSvc
net start bits
net start msiserver


set /p DUMMY=Finished!  Hit ENTER to continue...
