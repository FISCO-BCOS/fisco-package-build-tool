#!/bin/bash

#set -e

module_name="install.sh"

# uname -v > /dev/null 2>&1 || { echo >&2 "ERROR - ${myname} use 'uname' to identify the platform."; exit 1; }
# case $(uname -s) in 
#   Darwin)
#       ;;
#   Linux)
#            if [ ! -f "/etc/os-release" ];then
#                   { echo >&2 "ERROR - Unsupported or unidentified Linux distro."; exit 1; }
#            fi
#            DISTRO_NAME=$(. /etc/os-release; echo $NAME)
#            case $DISTRO_NAME in
#                    Ubuntu*)
#                        ;;
#                    CentOS*)
#                        ;;
#                    Oracle*) 
#                        ;;
#                     *)
#                        ;;.
#             esac
#       ;;
#   *)
#       ;;
#   esac

function dependencies_install() 
{
    local myname=$1
    if [ -z $myname ];then
        myname=$module_name
    fi

    # Check for 'uname' and abort if it is not available.
    uname -v > /dev/null 2>&1 || { echo >&2 "ERROR - ${myname} use 'uname' to identify the platform."; exit 1; }

    case $(uname -s) in 

    #------------------------------------------------------------------------------
    # macOS
    #------------------------------------------------------------------------------
    Darwin)
        case $(sw_vers -productVersion | awk -F . '{print $1"."$2}') in
            10.9)
                echo "Running $myname on OS X 10.9 Mavericks."
                ;;
            *)
                echo "Unsupported macOS version."
                exit 1
                ;;
        esac #case $(sw_vers

        ;; #Darwin)
        
    #------------------------------------------------------------------------------
    # Linux
    #------------------------------------------------------------------------------
    Linux)

        if [ ! -f "/etc/os-release" ];then
            { echo >&2 "ERROR - Unsupported or unidentified Linux distro."; exit 1; }
        fi

        DISTRO_NAME=$(. /etc/os-release; echo $NAME)
        # echo "Linux distribution: $DISTRO_NAME."

        case $DISTRO_NAME in
    #------------------------------------------------------------------------------
    # Ubuntu  # At least 16.04
    #------------------------------------------------------------------------------
            Ubuntu*)

                    sudo apt-get -y install lsof
                    sudo apt-get -y install crudini
                    sudo apt-get -y install gettext
                    sudo apt-get -y install bc
                    sudo apt-get -y install cmake
                    sudo apt-get -y install git
                    sudo apt-get -y install openssl
                    sudo apt-get -y install build-essential
                    sudo apt-get -y install libcurl4-openssl-dev libgmp-dev
                    sudo apt-get -y install libleveldb-dev  libmicrohttpd-dev
                    sudo apt-get -y install libminiupnpc-dev
                    sudo apt-get -y install libssl-dev libkrb5-dev
                    sudo apt-get -y install uuid-dev

                ;;
    #------------------------------------------------------------------------------
    # CentOS  # At least 7.2
    #------------------------------------------------------------------------------
            CentOS*)

                    sudo yum -y install bc
                    sudo yum -y install gettext
                    sudo yum -y install cmake3
                    sudo yum -y install git gcc-c++
                    sudo yum -y install openssl openssl-devel
                    sudo yum -y install leveldb-devel curl-devel 
                    sudo yum -y install libmicrohttpd-devel gmp-devel 
                    sudo yum -y install lsof
                    sudo yum -y install crudini
                    sudo yum -y install libuuid-devel

                ;;
    #------------------------------------------------------------------------------
    # Oracle Linux Server # At least 7.4
    #------------------------------------------------------------------------------
            Oracle*) 
                   
                    sudo yum -y install lsof
                    sudo yum -y install bc
                    sudo yum -y install gettext
                    sudo yum -y install cmake3
                    sudo yum -y install git gcc-c++
                    sudo yum -y install openssl openssl-devel
                    sudo yum -y install leveldb-devel curl-devel 
                    sudo yum -y install libmicrohttpd-devel gmp-devel 
                    sudo yum -y install crudini
                    sudo yum -y install libuuid-devel

                ;;
    #------------------------------------------------------------------------------
    # Other Linux
    #------------------------------------------------------------------------------
            *)
                { echo >&2 "ERROR - Unsupported Linux distribution: $DISTRO_NAME."; exit 1; }
                ;;
        esac # case $DISTRO_NAME

        ;; #Linux)

    #------------------------------------------------------------------------------
    # Other platform (not Linux, FreeBSD or macOS).
    #------------------------------------------------------------------------------
    *)
        #other
        { echo >&2 "ERROR - Unsupported or unidentified operating system."; exit 1; }
        ;;
    esac
}

