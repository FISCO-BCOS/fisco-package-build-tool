#!/bin/bash

#set -e

module_name="fisco-package-build-tool"

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

function os_version_check() 
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
            *)
                echo "Darwin operation."
                ;;
        esac #case $(sw_vers

        ;; #Darwin)
        
    #------------------------------------------------------------------------------
    # Linux
    #------------------------------------------------------------------------------
    Linux)

        if [ ! -f "/etc/os-release" ];then
             error_message "ERROR - Unsupported or unidentified Linux distro."
        fi

        DISTRO_NAME=$(. /etc/os-release; echo $NAME)
        echo "Linux distribution: $DISTRO_NAME."

        case $DISTRO_NAME in
    #------------------------------------------------------------------------------
    # Ubuntu  # At least 16.04
    #------------------------------------------------------------------------------
            Ubuntu*)

                echo "Running $myname on Ubuntu."

                UBUNTU_VERSION=""
                type lsb_release >/dev/null 2>&1
                if [ $? -eq 0 ];then
                    UBUNTU_VERSION=$(lsb_release -r | awk '{print $2}')
                else
                    UBUNTU_VERSION=$(. /etc/os-release; echo $VERSION | awk '{print $1}')
                fi

                echo "Ubuntu Version => $UBUNTU_VERSION"

                ver=$(echo "$UBUNTU_VERSION" | awk -F . '{print $1$2}')
                #Ubuntu 16.04 or Ubuntu 16.04+
                if [ $ver -ne 1604 ];then
                    error_message "ERROR - Unsupported Ubuntu Version. At least 16.04 is required."
                fi

                ;;
    #------------------------------------------------------------------------------
    # CentOS  # At least 7.2
    #------------------------------------------------------------------------------
            CentOS*)
                echo "Running $myname on CentOS."
                CENTOS_VERSION=""
                if [ -f /etc/centos-release ];then
                    CENTOS_VERSION=$(cat /etc/centos-release)
                elif [ -f /etc/redhat-release ];then
                    CENTOS_VERSION=$(cat /etc/redhat-release)
                elif [ -f /etc/system-release ];then
                    CENTOS_VERSION=$(cat /etc/system-release)
                fi

                if [ -z "$CENTOS_VERSION" ];then
                    error_message "unable to determine CentOS Version."
                fi

                echo "CentOS Version => $CENTOS_VERSION"
                ver=$(echo "$CENTOS_VERSION" | awk '{print $4}' | awk -F . '{print $1$2}')

                #CentOS 7.2 or CentOS 7.2+
                if [ $ver -lt 72 ];then
                    error_message "ERROR - Unsupported CentOS Version. At least 7.2 is required."
                fi
                ;;
    #------------------------------------------------------------------------------
    # Oracle Linux Server # At least 7.4
    #------------------------------------------------------------------------------
            Oracle*) 
                echo "Running $myname on Oracle Linux."
                ORACLE_LINUX_VERSION=""
                if [ -f /etc/oracle-release ];then
                    ORACLE_LINUX_VERSION=$(cat /etc/oracle-release)
                elif [ -f /etc/system-release ];then
                    ORACLE_LINUX_VERSION=$(cat /etc/system-release)
                fi

                if [ -z "$ORACLE_LINUX_VERSION" ];then
                    error_message "unable to determine Oracle Linux version."
                fi

                echo "Oracle Linux Version => $ORACLE_LINUX_VERSION"
                ver=$(echo "$ORACLE_LINUX_VERSION" | awk '{print $5}' | awk -F . '{print $1$2}')

                #Oracle Linux 7.4 or Oracle Linux 7.4+
                if [ $ver -lt 74 ];then
                    error_message "ERROR - Unsupported Oracle Linux, At least 7.4 Oracle Linux is required."
                fi

                ;;
    #------------------------------------------------------------------------------
    # Other Linux
    #------------------------------------------------------------------------------
            *)
                error_message "ERROR - Unsupported Linux distribution: $DISTRO_NAME."
                ;;
        esac # case $DISTRO_NAME

        ;; #Linux)

    #------------------------------------------------------------------------------
    # Other platform (not Linux, FreeBSD or macOS).
    #------------------------------------------------------------------------------
    *)
        #other
        error_message "ERROR - Unsupported or unidentified operating system."
        ;;
    esac
}
