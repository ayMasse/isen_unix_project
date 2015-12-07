#! /bin/bash

# Parse arguments and stores their values
function parseArgs () {
    # Loop to retrieve arguments
    while [ $# -gt 0 ]
    do
        case $1 in
            -o) mOutputDir=$2; shift 1;;
            -a) mArchivePath=$2; shift 1;;
        esac
        shift 1
    done

    # Debug check of fields values
    if [ $DEBUG -eq 1 ]
    then
        echo "mArchivePath = $mArchivePath"
        echo "mOutputDir = $mOutputDir"
    fi

    # Check if arguments are not missing
    if [ -z $mArchivePath ]
    then
        echo "Please enter a valid archive path."
        exit 0
    elif [ -z $mOutputDir ]
    then
        echo "Please enter a directory to backup (or leave the field empty - using current directory as the output)."
        exit 0
    elif [ ! -f $mArchivePath ]
    then
        echo "Please enter a valid archive path."
        exit 0
    elif [ ! -d $mOutputDir ]
    then
        echo "Backup directory must be a directory."
        exit 0
    fi
}

# Checks if temporary directory exists. Creates it otherwise.
function checkTempDir () {
    if [ ! -e $1 ]
    then
        mkdir "$1"

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

# Handle archive extraction
function restoreArchive () {
    # Check if the target archive is the initial one.
    if [[ $( basename $mArchivePath ) == $mInitialArchiveName ]]; then
        tar -xf $mArchivePath -C $mOutputDir
    else
        restoreFragmentedArchive
    fi
}

# Handle fragmented archive extraction
function restoreFragmentedArchive () {
    checkTempDir $mTmpDir
    mArchiveDir=$( dirname $mArchivePath )

    restoreInitialArchive
    restoreSelectedArchive

    cp $mTmpDir/* $mOutputDir
    rm -r $mTmpDir
}

# Checks if initial backup archive exists. Extracts it if yes, warns the user if not.
function restoreInitialArchive () {
    mInitialArchivePath="$mArchiveDir/$mInitialArchiveName"

    if [[ -f $mInitialArchivePath ]]; then
        tar -xf $mInitialArchivePath -C $mTmpDir
    else
        echo "Inital backup not found. May cause issues in some texts recovery."
    fi
}

# Restore the target archive in the temporary directory. Applies patch if needed, then copy results to output directory.
function restoreSelectedArchive () {
    tar -xf $mArchivePath -C $mTmpDir

    applyPatches
}

# Applies patches for text files.
function applyPatches () {
    mFiles=$( find $mTmpDir ! -name *".patch" ) # Get all files without .patch

    # Set separator to "New Line"
    SAVEIFS=$IFS
    IFS=$(echo -en "\n\b")

    for mFile in $mFiles
    do
        mFileType=$( file -bi $mFile )

        # Check if current file is a text file
        if [[ $mFileType == *"text"* ]]; then
            patchFile $mFile
        fi
    done

    # Set the IFS with its former value
    IFS=$SAVEIFS
}

# Checks if patch exists for given file and patchs it if it is.
function patchFile () {
    mPatch="$1.patch"
    if [[ -f $mPatch ]]; then
        patch $1 -i $mPatch
        rm $mPatch
    fi
}

# MAIN Function
DEBUG=1
mInitialArchiveName='backup_init.tar.gz'
mOutputDir="."
mTmpDir=".tmp"

parseArgs $*
restoreArchive
