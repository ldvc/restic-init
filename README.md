# restic-init
> Set up restic backup task.

Basic idea is to speed up the initialization process for creating a backup job. Run once, and forget about it!

## Installation

Linux:

```sh
git clone git@github.com:ldvc/restic-init.git
```

## Usage example

In order to start, run the script (as root) in order to retrieve [restic](https://github.com/restic/restic/releases) binary, [restic-tools](https://github.com/binarybucks/restic-tools) wrapper and help configuring config files for starting a backup task.

```
[22:35][root@chronos][/home/ludo/github/restic-init] bash bin/set-restic.sh myrepo sftp
-------------------------------------------------------------------------------------------------
This script will:
  * clone restic-tools project as a wrapper for restic
  * give steps for getting restic binary
  * create SSH config file for root
  * create cron task
-------------------------------------------------------------------------------------------------
Would you like to continue?
```

## Release History

* 0.0.1
    * Init

## Meta

Ludovic TERRIER – [@ludovicterrier](https://twitter.com/ludovicterrier) – ludovic+github@terrier.im

Distributed under the MIT license. See ``LICENSE`` for more information.

[https://github.com/ldvc/](https://github.com/ldvc/)
