#!/usr/bin/env sh

set -e

myname="fisco-package-build-tool"

# Check for 'uname' and abort if it is not available.
uname -v > /dev/null 2>&1 || { echo >&2 "ERROR - ${myname} use 'uname' to identify the platform."; exit 1; }

case $(uname -s) in

#------------------------------------------------------------------------------
# macOS
#------------------------------------------------------------------------------
Darwin)
    case $(sw_vers -productVersion | awk -F . '{print $1"."$2}') in
        10.9)
            echo "Installing $myname dependencies on OS X 10.9 Mavericks."
            ;;
        10.10)
            echo "Installing $myname dependencies on OS X 10.10 Yosemite."
            ;;
        10.11)
            echo "Installing $myname dependencies on OS X 10.11 El Capitan."
            ;;
        10.12)
            echo "Installing $myname dependencies on macOS 10.12 Sierra."
            echo ""
            echo "NOTE - You are in unknown territory with this preview OS."
            echo "Even Homebrew doesn't have official support yet, and there are"
            echo "known issues (see https://github.com/ethereum/webthree-umbrella/issues/614)."
            echo "If you would like to partner with us to work through these issues, that"
            echo "would be fantastic.  Please just comment on that issue.  Thanks!"
            ;;
        *)
            echo "Unsupported macOS version."
            echo "We only support Mavericks, Yosemite and El Capitan, with work-in-progress on Sierra."
            exit 1
            ;;
    esac

    # Check for Homebrew install and abort if it is not installed.
    brew -v > /dev/null 2>&1 || { echo >&2 "ERROR - cpp-ethereum requires a Homebrew install.  See http://brew.sh."; exit 1; }

    # And finally install all the external dependencies.
    brew install \
        leveldb \
        libmicrohttpd \
        miniupnpc

    ;;

#------------------------------------------------------------------------------
# FreeBSD
#------------------------------------------------------------------------------
FreeBSD)
    echo "Installing $myname dependencies on FreeBSD."
    echo "ERROR - $myname doesn't have FreeBSD support yet."
    exit 1
    ;;

#------------------------------------------------------------------------------
# Linux
#------------------------------------------------------------------------------
Linux)

    # Detect if sudo is needed.
    if [ $(id -u) != 0 ]; then
        SUDO="sudo"
    fi

#------------------------------------------------------------------------------
# Arch Linux
#------------------------------------------------------------------------------

    if [ -f "/etc/arch-release" ]; then

        echo "Installing $myname dependencies on Arch Linux."

    elif [ -f "/etc/os-release" ]; then

        DISTRO_NAME=$(. /etc/os-release; echo $NAME)
	echo "Linux distribution: $DISTRO_NAME."
        case $DISTRO_NAME in

        Debian*)
            echo "Installing cpp-ethereum dependencies on Debian Linux."

            $SUDO apt-get -q update
            $SUDO apt-get -qy install \
                build-essential \
                libboost-all-dev \
                libcurl4-openssl-dev \
                libgmp-dev \
                libleveldb-dev \
                libmicrohttpd-dev \
                libminiupnpc-dev
            ;;

        Fedora)
            echo "Installing cpp-ethereum dependencies on Fedora Linux."
            $SUDO dnf -qy install \
                gcc-c++ \
                boost-devel \
                leveldb-devel \
                curl-devel \
                libmicrohttpd-devel \
                gmp-devel
            ;;

#------------------------------------------------------------------------------
# Ubuntu
#
# TODO - I wonder whether all of the Ubuntu-variants need some special
# treatment?
#
# TODO - We should also test this code on Ubuntu Server, Ubuntu Snappy Core
# and Ubuntu Phone.
#
# TODO - Our Ubuntu build is only working for amd64 and i386 processors.
# It would be good to add armel, armhf and arm64.
# See https://github.com/ethereum/webthree-umbrella/issues/228.
#------------------------------------------------------------------------------
        Ubuntu|LinuxMint)
            echo "Installing cpp-ethereum dependencies on Ubuntu."
            if [ "$TRAVIS" ]; then
                # Setup prebuilt LLVM on Travis CI:
                $SUDO apt-get -qy remove llvm  # Remove confilicting package.
                echo "deb http://apt.llvm.org/trusty/ llvm-toolchain-trusty-3.9 main" | \
                    $SUDO tee -a /etc/apt/sources.list > /dev/null
                LLVM_PACKAGES="llvm-3.9-dev libz-dev"
            fi
            $SUDO apt-get -q update
            $SUDO apt-get install -qy --no-install-recommends --allow-unauthenticated \
                build-essential \
                libboost-all-dev \
                libcurl4-openssl-dev \
                libgmp-dev \
                libleveldb-dev \
                libmicrohttpd-dev \
                libminiupnpc-dev \
                $LLVM_PACKAGES
            ;;

        CentOS*)
            echo "Installing cpp-ethereum dependencies on CentOS."
            # Enable EPEL repo that contains leveldb-devel
            $SUDO yum -y -q install epel-release
            $SUDO yum -y -q install \
                make \
                gcc-c++ \
                boost-devel \
                leveldb-devel \
                curl-devel \
                libmicrohttpd-devel \
                gmp-devel \
                openssl openssl-devel
            ;;
		#add Oracle Linux Server dependencies
		Oracle*)
            echo "Installing cpp-ethereum dependencies on Oracle Linux Server."
            # Enable EPEL repo that contains leveldb-devel
            $SUDO yum -y -q install epel-release
            $SUDO yum -y -q install \
                make \
                gcc-c++ \
                boost-devel \
                leveldb-devel \
                curl-devel \
                libmicrohttpd-devel \
                gmp-devel \
                openssl openssl-devel
            ;;

        *)
            echo "Unsupported Linux distribution: $DISTRO_NAME."
            exit 1
            ;;

        esac

    elif [ -f "/etc/alpine-release" ]; then

        # Alpine Linux
        echo "Installing cpp-ethereum dependencies on Alpine Linux."
        $SUDO apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/ \
            g++ \
            make \
            boost-dev \
            curl-dev \
            libmicrohttpd-dev \
            leveldb-dev

    else

        case $(lsb_release -is) in

#------------------------------------------------------------------------------
# OpenSUSE
#------------------------------------------------------------------------------
        openSUSE*)
            #openSUSE
            echo "Installing cpp-ethereum dependencies on openSUSE."
            echo "ERROR - 'install_deps.sh' doesn't have openSUSE support yet."
            echo "See http://cpp-ethereum.org/building-from-source/linux.html for manual instructions."
            echo "If you would like to get 'install_deps.sh' working for openSUSE, that would be fantastic."
            echo "See https://github.com/ethereum/webthree-umbrella/issues/552."
            exit 1
            ;;

#------------------------------------------------------------------------------
# Other (unknown) Linux
# Major and medium distros which we are missing would include Mint, CentOS,
# RHEL, Raspbian, Cygwin, OpenWrt, gNewSense, Trisquel and SteamOS.
#------------------------------------------------------------------------------
        *)
            #other Linux
            echo "ERROR - Unsupported or unidentified Linux distro."
            echo "See http://cpp-ethereum.org/building-from-source/linux.html for manual instructions."
            echo "If you would like to get your distro working, that would be fantastic."
            echo "Drop us a message at https://gitter.im/ethereum/cpp-ethereum-development."
            exit 1
            ;;
        esac
    fi
    ;;

#------------------------------------------------------------------------------
# Other platform (not Linux, FreeBSD or macOS).
# Not sure what might end up here?
# Maybe OpenBSD, NetBSD, AIX, Solaris, HP-UX?
#------------------------------------------------------------------------------
*)
    #other
    echo "ERROR - Unsupported or unidentified operating system."
    echo "See http://cpp-ethereum.org/building-from-source/ for manual instructions."
    echo "If you would like to get your operating system working, that would be fantastic."
    echo "Drop us a message at https://gitter.im/ethereum/cpp-ethereum-development."
    ;;
esac
