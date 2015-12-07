#! /bin/bash

# Parsing arguments and storing their values in $mBackIgnore and $mBackupDir
function parseArgs () {
    # Loop to retrieve arguments
    while [ $# -gt 0 ]
    do
        case $1 in
            "-i") mBackIgnore=$2; shift 1;;
            "-d") mBackupDir=$2; shift 1;;
            "-a") mReferenceArchivePath=$2; shift 1;;
        esac
        shift 1
    done

    # Debug check of fields values
    if [ $DEBUG -eq 1 ]
    then
        echo "mBackIgnore = $mBackIgnore"
        echo "mBackupDir = $mBackupDir"
    fi

    # Check if arguments are not missing
    if [ -z $mBackIgnore ]
    then
        echo "Please enter a mBackIgnore file."
        exit 0
    elif [ -z $mBackupDir ]
    then
        echo "Please enter a directory to backup."
        exit 0
    elif [ ! -f $mBackIgnore ]
    then
        echo "Please enter a valid mBackIgnore file."
        exit 0
    elif [ ! -d $mBackupDir ]
    then
        echo "Backup directory must be a directory."
        exit 0
    fi
}

# Create the filter for files to ignore
function createIgnoreFilter() {
    for pattern in $( cat $mBackIgnore )
    do
        filter="$filter ! -name $pattern"
    done
}

# Explore from the main directory
function explorer() {
    if [[ $DEBUG -eq 1 ]]; then
        echo $filter
    fi

    mExplorer=$( find $mBackupDir -mindepth 1 -maxdepth 1 $filter -type f )

    # Get times used later
    oldTime=$(echo $mReferenceArchivePath | cut -d _ -f 2)
    newTime=$(date +%s)

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
    mLastModifiedDate=$( date +%s -r $1 )

    if [ ! -L "$1" ] && [ -O "$1" ] && [ $mSimpleDirName != ".backup" ] && [ $( expr $mLastModifiedDate - $oldTime ) -gt 0 ]
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
    if [ -f "$mBackupPath/$mInitialArchiveName" ] && [[ $( tar -f "$mBackupPath/$mInitialArchiveName" -x $mSimpleFileName ) != 0 ]]
    then
        mPatch="$mSimpleFileName.patch"
        tar -f "$mBackupPath/$mInitialArchiveName" -x $mSimpleFileName

        if [[ $( tar -f $mReferenceArchivePath -x $mPatch ) != 0 ]]; then
            patch $mSimpleFileName -i $mPatch
            rm $mPatch
        fi

        diff $mSimpleFileName $1 > $mPatch
        tar -uf $mArchivePath $mPatch
        rm $mSimpleFileName
        rm $mPatch
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
            mArchiveName="inc_backup_${newTime}_${oldTime}.tar.gz"
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
