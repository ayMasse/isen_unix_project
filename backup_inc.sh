#! /bin/bash

#parsing arguments and storing their values in $outputDirectory and &patchArchive
function parseArgs () {

    # Loop to retrieve arguments
    while [ $# -gt 0 ]
    do
        case $1 in
            -o) outputDirectory=$2; shift 1;;
            -a) patchArchive=$2; shift 1;;
	    -i) backIgnore=$2; shift 1;;
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
    elif [ -z $outputDirectory ]
    then
        echo "Please enter a directory to backup (or leave the field empty - using current directory as the output)."
        exit 0
    elif [ -z $backIgnore ]
    then
    	echo "Please enter a backignore file."
    	exit 0
    elif [ ! -f $backIgnore ]
    then
    	echo "Backignore must be a file"
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

function createIgnoreFilter() {
    for pattern in $( cat $backIgnore )
    do
        filter="$filter ! -name $pattern"
    done
}

function handleArchiveExtracting() {
		local backupDirectory="$outputDirectory/.backup"

		checkTempDir "$backupDirectory/tmp"
		checkTempDir "$backupDirectory/tmp2"
		
		chooseLatestArchive $backupDirectory
		
		tar -xf "$patchArchive" -C "$backupDirectory/tmp2"

		createIgnoreFilter

		local patchFiles=$( find "$backupDirectory/tmp2" -type f -name "*.patch" $filter)
		local binaryFiles=$( find "$backupDirectory/tmp2" -type f ! -name "*.patch" $filter)
		
		for patch in $patchFiles
		do
			local cleanedName=$( basename $patch .patch )
		        if [ $DEBUG -eq 1 ]
		        then
				echo "cleanedName = $cleanedName"
				echo "patch file = $patch"
			fi
			patch "$backupDirectory/tmp/${cleanedName}" "$patch"
		done 
		
		for binary in $binaryFiles
		do
			local cleanedName=$( basename $binary )
		        if [ $DEBUG -eq 1 ]
		        then
				echo "cleanedName = $cleanedName"
				echo "binary file = $binary"
			fi
			mv -f "$binary" "$backupDirectory/tmp/${cleanedName}"
		done 	
		
		## TODO : save the archive
		local oldTime=$(echo "$patchArchive" | cut -d _ -f 2)
		local newTime=$(date +%s)
		
		filesToBackup=$( ls "$backupDirectory/tmp/" )
		
		SAVEIFS=$IFS
		IFS=$(echo -en "\n\b")
		
		for file in $filesToBackup
		do
			tar -uf "$backupDirectory/inc_backup_${newTime}_${oldTime}.tgz" -C "$backupDirectory/tmp/" "$file"
		done
		
		# Set the IFS with its former value
		IFS=$SAVEIFS

		rm -rf $backupDirectory/tmp
		rm -rf $backupDirectory/tmp2
		exit 0
}

function chooseLatestArchive() {
	local notInitialBackups=$( ls -Xr | grep -x "inc_backup_[0-9]*_[a-zA-Z]*.tar.gz" )
	if [ ! -z $notInitialBackups ]			## THERE IS A MORE RECENT ONE (<=> INCREMENTAL BACKUP) AVAILABLE
	then
		local arr=($notInitialBackups)
		local baseArchive=${arr[0]}
		tar -xf "${*}/${baseArchive}" -C "$backupDirectory/tmp" ### RESTORE NOT BACKUP_INIT
	elif [ -f "${*}"/backup_init.tar.gz ]
	then
		tar -xf "${*}/backup_init.tar.gz" -C "$backupDirectory/tmp" ### RESTORE BACKUP_INIT
	else
		echo "Trying to extract a patch archive without any existing base archive. Aborting."
		exit 0
	fi
}

################# MAIN
DEBUG=1
parseArgs $*
handleArchiveExtracting
