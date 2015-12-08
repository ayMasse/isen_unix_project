# UNIX project (ISEN Lille - 2015/2016)

Our team was made of the students:

* Olive NDAYIZIGIYE
* Aymeric MASSE
* Paul LESUR

# Development system

Our scripts have been tested on 2 Linux distributions:

1. Arch Linux
2. Debian GNU/Linux 8 (jessie)

# Tools used

Here is the list of the different tools (ie bash commands) in those scripts:

1. basename (GNU coreutils) 8.23
2. cat (GNU coreutils) 8.23
3. date (GNU coreutils) 8.23
4. diff (GNU diffutils) 3.3
5. dirname (GNU coreutils) 8.23
6. echo (built-in bash)
7. expr (GNU coreutils) 8.23
8. file 5.22
9. find (GNU findutils) 4.4.2
10. grep (GNU grep) 2.20
11. hostname 3.15
12. mkdir (GNU coreutils) 8.23
13. rm (GNU coreutils) 8.23
14. shift
15. tar (GNU tar) 1.27.1
16. test (GNU coreutils) 8.23
17. touch (GNU coreutils) 8.23

# Behavior

## Just to be sure, here's an explanation of the desired behavior for each script:

### backup.sh

#### Parameters

1. -d DIRECTORY

DIRECTORY is the folder you want to backup. It is recursive (each sub directory will have its own backup).
It creates, in each directory a subdirectory named **.backup** which will contain the different backups.

2. -i BACKIGNORE

The file BACKIGNORE contains a list of patterns you want to ignore during the backup.
It is matched **ONLY** against the file name, **NOT** against the path of the files.

#### Result

* A subdirectory named **.backup** is created inside *each* directory inside DIRECTORY (the script is recursive)

* If it's the first time you launch the script, it wil create inside **.backup** a file named backup_init.tar.gz which is the *full* backup of the folder

* Each following use of the backup.sh will create a *patch archive* which will use backup_init.tar.gz as a reference. 
*Patch archives* contain all binaries, but patch files for the text files (see man diff).

* The *patch archives* are named like this: backup_*time_since_epoch*_*hostname*.tar.gz

#### Usage example

./backup.sh -d folder/ -i backignore

### restore_backup.sh

#### Parameters

1. -o OUTPUT_DIR

OUTPUT_DIR is the folder where you want to restore the ARCHIVE given

2. -a ARCHIVE

The archive (either *patch* or *full*) to backup inside OUTPUT_DIR

#### Result

* This script first delete **ALL** files inside the OUTPUT_DIR
* It then restores the backup
* If it's a *patch archive*, it restores backup_init.tar.gz then patch the result thanks to ARCHIVE

#### Usage example

./restore_backup.sh -o folder/ -a folder/.backup/backup_init.tar.gz

./restore_backup.sh -o folder/ -a folder/.backup/backup_1111111_hostname.tar.gz

### backup_inc.sh

#### Parameters

1. -d DIRECTORY

DIRECTORY is the folder where the backups are stored

2. -i BACKIGNORE

The file BACKIGNORE contains a list of patterns you want to ignore during the backup.
It is matched **ONLY** against the file name, **NOT** against the path of the files.

3. -a ARCHIVE

Is the name of the *patch archive* you want to use as the reference

#### Result

This script creates a *patch archive* except its reference is **another patch archive**.
The behavior is the same as backup.sh otherwise.

#### Usage example

./backup_inc -d folder/ -a folder/.backup/backup_1111_hostname.tar.gz -i inc_backignore 
