#! /bin/bash

# Parsing arguments and storing their values in $backIgnore and $backupDirectory
function parseArgs () {
    # Loop to retrieve arguments
    while [ $# -gt 0 ]
    do
        case $1 in
            "-i") backIgnore=$2; shift 1;;
            "-d") backupDirectory=$2; shift 1;;
        esac
        shift 1
    done

    # Debug check of fields values
    if [ $DEBUG -eq 1 ]
    then
        echo "backIgnore = $backIgnore"
        echo "backupDirectory = $backupDirectory"
    fi

    # Check if arguments are not missing
    if [ -z $backIgnore ]
    then
        echo "Please enter a backignore file."
        exit 0
    elif [ -z $backupDirectory ]
    then
        echo "Please enter a directory to backup."
        exit 0
    elif [ ! -f $backIgnore ]
    then
        echo "Please enter a valid backignore file."
        exit 0
    elif [ ! -d $backupDirectory ]
    then
        echo "Backup directory must be a directory."
        exit 0
    fi
}

# Create the filter for files to ignore
function createIgnoreFilter() {
    for pattern in $( cat $backIgnore )
    do
        filter="$filter ! -name $pattern"
    done
}

# Explore from the main directory
function explorer() {
    echo $filter
    local mExplorer=$( find $backupDirectory $filter -type f )

    # Set separator to "New Line"
    SAVEIFS=$IFS
    IFS=$(echo -en "\n\b")

    # Begin treatment for each file
    for mFile in $mExplorer
    do
        if [ $DEBUG -eq 1 ]
        then
            echo "Initialize backup for $mFile"
        fi

        backupFile $mFile
    done

    # Set the IFS with its former value
    IFS=$SAVEIFS
}

# Set all variables in order to archive the file properly
function backupFile () {
    mDir=$( dirname $1)
    mSimpleDirName=$( basename $mDir )
    mBackupPath="$mDir/.backup"
    mArchivePath="$mBackupPath/$mArchiveName"
    mSimpleFileName=$( basename $1 )

    if [ ! -L "$1" ] && [ -O "$1" ] && [ $mSimpleDirName != ".backup" ]
    then
        checkBackupDir $mBackupPath
        checkArchive
        checkFileType $1
    fi
}

# Check type of file and call apropriate function to archive it.
function checkFileType () {
    mFileType=$( file -bi $1)

    if [[ $mFileType == *"text"* ]]
    then
        backupText $1
    else
        backupBinary $1
    fi
}

# Backup a binary file
function backupBinary () {
    tar -uf $mArchivePath -C $mDir $mSimpleFileName
}

# Backup a text file
function backupText () {
    # Extract the file from the archive
    if [ -f "$mBackupPath/$mInitialArchiveName" ] && [[ $( tar -tvf "$mBackupPath/$mInitialArchiveName" | grep "$mSimpleFileName" ) == *"$mSimpleFileName"* ]]
    then
        tar -f "$mBackupPath/$mInitialArchiveName" -x $mSimpleFileName
        diff $mSimpleFileName $1 > "$mSimpleFileName.patch"
        tar -uf $mArchivePath "$mSimpleFileName.patch"
        rm "$mSimpleFileName"
        rm "$mSimpleFileName.patch"
    else
        tar -uf "$mBackupPath/$mInitialArchiveName" -C $mDir $mSimpleFileName

        if [[ $mInitialArchiveName != $mArchiveName ]]
        then
            touch "$mSimpleFileName.patch"
            tar -uf $mArchivePath "$mSimpleFileName.patch"
            rm "$mSimpleFileName.patch"
        fi
    fi
}


# Check if the .backup directory exists. If not create it.
function checkBackupDir () {
    if [ ! -e $1 ]
    then
        mkdir $1

        if [ $DEBUG -eq 1 ]
        then
            echo "Created directory $1"
        fi

    elif [ ! -d $1 ]
    then
        echo "A file named .backup is preventing this program to create a needed directory with this name. Abort."
        exit 0
    fi
}

# Check if initial archive exists. If yes, create a new archive.
function checkArchive () {
    mTime=$( date +%s )
    mHostname=$( hostname )

    if [ -f $mArchivePath ]
    then
        mLastTimeModified=$( date +%s -r $mArchivePath)

        if [ ! $mTime == $mLastTimeModified ]
        then
            mArchiveName="backup_$mTime _$mHostname.tar.gz"
            mArchivePath="$mBackupPath/$mArchiveName"
        fi
    fi
}

# MAIN Function

DEBUG=1
mInitialArchiveName='backup_init.tar.gz'
mArchiveName=$mInitialArchiveName

parseArgs $*
createIgnoreFilter
explorer
