-- Installer app: starts the bundled install.sh in the background and quits.
-- install.sh shows its own windows and writes its log to the data folder.
set installer to POSIX path of (path to resource "install.sh")
do shell script "/bin/bash " & quoted form of installer & " >/dev/null 2>&1 < /dev/null &"
