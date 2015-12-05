#! /bin/bash

#parsing arguments and storing their values in $outputDirectory and &archivePath
function parseArgs () {
    outputDirectory="./"
    # Loop to retrieve arguments
    while [ $# -gt 0 ]
    do
        case $1 in
            -o) outputDirectory=$2; shift 1;;
            -a) archivePath=$2; shift 1;;
        esac
        shift 1
    done
    
    # Debug check of fields values
    if [ $DEBUG -eq 1 ]
    then
        echo "archivePath = $archivePath"
        echo "outputDirectory = $outputDirectory"
    fi
    
    # Check if arguments are not missing
    if [ -z $archivePath ]
    then
        echo "Please enter a archivePath file."
        exit 0
    elif [ -z $outputDirectory ]
    then
        echo "Please enter a directory to backup (or leave the field empty - using current directory as the output)."
        exit 0
    elif [ ! -f $archivePath ]
    then
        echo "Please enter a valid archivePath file."
        exit 0
    elif [ ! -d $outputDirectory ]
    then
        echo "Backup directory must be a directory."
        exit 0
    fi
}

function deleteAllButBackupDir() {
	find $outputDirectory -maxdepth 1 -type f -delete
}

function checkTempDir () {
    if [ ! -e $* ]
    then
        mkdir "$*"
        
        if [ $DEBUG -eq 1 ]
        then
            echo "Created directory $*"
        fi
        
    elif [ ! -d $* ]
    then
        echo "A file named .backup is preventing this program to create a needed directory with this name. Abort."
        exit 0
    fi
}

function handleArchiveExtracting() {
	local backupDirectory=$( dirname $archivePath )		## FOLDER WHERE ALL THE BACKUP ARE ( <=> .backup FOLDER)
	local archiveName=$( basename $archivePath )		## NAME OF THE ARCHIVE ITSELF (USED FOR REGEXP)
	
	local baseArchive=$( echo "$archiveName" | grep -x "backup_init.tar.gz\|inc_backup_[0-9]*_[0-9]*.tgz" )
	local patchArchive=$( echo "$archiveName" | grep -x "backup_[0-9]*_[a-zA-Z]*.tar.gz" )
	echo "baseArchive = $baseArchive"
	echo "backupDirectory = $backupDirectory"

	if [ ! -z $baseArchive ]		## IS THE ARCHIVE A "BASIC" ONE (INITIAL BACKUP OR INCREMENTAL BACKUP ?)
	then
		deleteAllButBackupDir
		tar -xf "$archivePath" -C "$outputDirectory" 
	
	elif [ ! -z $patchArchive ]		## IS THE ARCHIVE A PATCH ARCHIVE ?
	then
		deleteAllButBackupDir
		
		baseArchiveToExtract=$( chooseLatestArchive $backupDirectory )
		checkTempDir "$backupDirectory/tmp"
		tar -xf $archivePath -C $backupDirectory/tmp		#### EXTRACT THE ARCHIVE INTO A TEMPORARY FOLDER

		local patchFiles=$( find "$backupDirectory/tmp" -type f -name "*.patch" )
		local binaryFiles=$( find "$backupDirectory/tmp" -type f ! -name "*.patch" )
		
		for patch in $patchFiles
		do
			local cleanedName=$( basename $patch .patch )
		        if [ $DEBUG -eq 1 ]
		        then
				echo "cleanedName = $cleanedName"
				echo "patch file = $patch"
			fi
			patch "${outputDirectory}"/"${cleanedName}" "$patch"
		done 
		
		for binary in $binaryFiles
		do
			local cleanedName=$( basename $binary )
		        if [ $DEBUG -eq 1 ]
		        then
				echo "cleanedName = $cleanedName"
				echo "binary file = $binary"
			fi
			mv "$binary" "${outputDirectory}"/"${cleanedName}"
		done 	
		
		rm -rf $backupDirectory/tmp
	
	else		## OTHERWISE WE WON'T PROCESS IT
		echo "Archive doesn't exist/ doesn't have a correct name. Aborting."
		exit 0
	fi
}

function chooseLatestArchive() {
	local notInitialBackups=$( ls -Xr | grep -x "backup_[0-9]*_[a-zA-Z]*.tar.gz" )
	if [ ! -z $notInitialBackups ]			## THERE IS A MORE RECENT ONE (<=> INCREMENTAL BACKUP) AVAILABLE
	then
		local arr=($notInitialBackups)
		local baseArchive=${arr[0]}
		tar -xf "${*}/${baseArchive}" -C "$outputDirectory" ### RESTORE BACKUP_INIT
	elif [ -f "${*}"/backup_init.tar.gz ]
	then
		tar -xf "${*}/backup_init.tar.gz" -C "$outputDirectory" ### RESTORE BACKUP_INIT
	else
		echo "Trying to extract a patch archive without any existing base archive. Aborting."
		exit 0
	fi
}

################# MAIN
DEBUG=1
parseArgs $*
handleArchiveExtracting
