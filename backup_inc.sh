#! /bin/bash

#parsing arguments and storing their values in $outputDirectory and &patchArchive
function parseArgs () {

    # Loop to retrieve arguments
    while [ $# -gt 0 ]
    do
        case $1 in
            -o) directory=$2; shift 1;;
            -a) patchArchive=$2; shift 1;;
	    -i) backignore=$2; shift 1;;
        esac
        shift 1
    done
    
    # Debug check of fields values
    if [ $DEBUG -eq 1 ]
    then
        echo "patchArchive = $patchArchive"
        echo "directory = $outputDirectory"
    fi
    
local isArchiveValid=$( echo "$archiveName" | grep -x "backup_[0-9]*_[a-zA-Z]*.tar.gz" )

    # Check if arguments are not missing
    if [ -z $patchArchive ]
    then
        echo "Please enter a reference patch file."
        exit 0
    elif [ -z $directory ]
    then
        echo "Please enter a directory to backup (or leave the field empty - using current directory as the output)."
        exit 0
    elif [ ! -f $isArchiveValid ]
    then
        echo "Please enter a valid patchArchive file."
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
        echo "A file named $* is preventing this program to create a needed directory with this name. Abort."
        exit 0
    fi
}

function handleArchiveExtracting() {

		local baseArchiveToExtract=$( chooseLatestArchive $backupDirectory )
		checkTempDir "$outputDirectory/tmp"

		tar -xf "$baseArchiveToExtract" -C "$backupDirectory/tmp" 

		local patchFiles=$( find "$outputDirectory/tmp" -type f -name "*.patch" )
		local binaryFiles=$( find "$outputDirectory/tmp" -type f ! -name "*.patch" )
		
		for patch in $patchFiles
		do
			local cleanedName=$( basename $patch .patch )
		        if [ $DEBUG -eq 1 ]
		        then
				echo "cleanedName = $cleanedName"
				echo "patch file = $patch"
			fi
			patch "$outputDirectory/tmp"/"${cleanedName}" "$patch"
		done 
		
		for binary in $binaryFiles
		do
			local cleanedName=$( basename $binary )
		        if [ $DEBUG -eq 1 ]
		        then
				echo "cleanedName = $cleanedName"
				echo "binary file = $binary"
			fi
			mv "$binary" "${outputDirectory}/tmp"/"${cleanedName}"
		done 	
		
		## TODO : save the archive

		rm -rf $backupDirectory/tmp
		exit 0
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
