#!/bin/bash
#######################################################################################################################
# Build and virtualize custom OpenWRT images for x86
# DO NOT RESIZE ROUTER NAND FLASH PARTITIONS, RESIZE IS FOR x86 BUILDS ONLY!!
# David Harrop
# February 2025
########################################################################################################################
# CUSTOM PACKAGES [ADD YOUR CUSTOM PACKAGE RECIPE HERE]
#######################################################################################################################

# Basic example recipe, change to suit.
CUSTOM_PACKAGES="blockd block-mount kmod-fs-ext4 kmod-fs-ntfs3 kmod-usb2 kmod-usb3 kmod-usb-storage kmod-usb-core \
    luci luci-app-ddns luci-app-samba4 luci-app-sqm sqm-scripts curl nano"

#######################################################################################################################

clear

# Prepare text output colours
CYAN='\033[0;36m'
LRED='\033[0;91m'
LYELLOW='\033[0;93m'
NC='\033[0m' # No Colour

# Make sure the user is NOT running this script as root
if [[ $EUID -eq 0 ]]; then
    echo
    echo -e "${LRED}This script must NOT be run as root, it will prompt for sudo when needed." 1>&2
    echo -e ${NC}
    exit 1
fi

# Check if sudo is installed. (Debian does not always include sudo by default.)
if ! command -v sudo &> /dev/null; then
    echo "${LRED}Sudo is not installed. Please install sudo."
    echo -e ${NC}
    exit 1
fi

# Make sure the user running setup is a member of the sudo group
if ! id -nG "$USER" | grep -qw "sudo"; then
    echo
    echo -e "${LRED}The current user (${USER}) must be a member of the 'sudo' group. Run: sudo usermod -aG sudo ${USER}${NC}" 1>&2
    exit 1
fi

# Cache a prompt for sudo so it can be used used where needed
echo
echo -e "${CYAN}Script requires sudo permissions and will prompt if necessary...${NC}"
echo
sudo sudo -v
echo
echo -e "${CYAN}Checking for curl...${NC}"
sudo apt-get update -qq && sudo apt-get install curl -qq -y
clear

#######################################################################################################################
# Mandatory static script parameters - do not edit unless expert
#######################################################################################################################

    TARGET="x86"             # x86, mvebu etc
    ARCH="64"                # 64, cortexa9 etc
    IMAGE_PROFILE="generic"  # x86 = generic, linksys_wrt1900acs etc. For profile options run $SOURCE_DIR/make info

#######################################################################################################################
# Initialise script prompt variables - do not edit unless expert
#######################################################################################################################

    VERSION=""               # "" = snapshot or enter specific version
    MOD_PARTSIZE=""          # true/false
    KERNEL_PARTSIZE=""       # variable set in MB
    ROOT_PARTSIZE=""         # variable set in MB (values over 8192 may give memory exhaustion errors)
    KERNEL_RESIZE_DEF="32"   # OWRT default is 32 MB - don't change this without a specific reason.
    ROOT_RESIZE_DEF="104"    # OWRT default is 104 MB. Don't go above 8192.
    IMAGE_TAG=""             # ID tag is added to the completed image filename to uniquely identify the built image(s)
    CREATE_VM=""             # Create VMware images of the final build true/false
    RELEASE_URL="https://downloads.openwrt.org/releases/" # Where to obtain latest stable version number

# Lookup the latest release version, and prompt for desired OWRT build version 
if [[ -z ${VERSION} ]]; then
    LATEST_RELEASE=$(curl -s "$RELEASE_URL" | grep -oP "([0-9]+\.[0-9]+\.[0-9]+)" | sort -V | tail -n1)
    echo
    echo -e "${CYAN}Enter OpenWRT version to build:${NC}"
    while true; do
        read -p "    Enter a release version number (latest stable release = $LATEST_RELEASE), or hit enter for latest snapshot: " VERSION
        [[ "${VERSION}" = "" ]] || [[ "${VERSION}" != "" ]] && break
    done
    echo
fi

# Prompt to resize image partitions only if x86
if [[ -z ${MOD_PARTSIZE} ]] && [[ ${IMAGE_PROFILE} = "generic" ]]; then
    echo -e "${CYAN}Modify OpenWRT Partitions (x86 ONLY!):${NC}"
    echo -e -n "    Modify partition sizes? [ y = resize | n = no changes (default) ] [y/N]: "
    read PROMPT
    if [[ ${PROMPT} =~ ^[Yy]$ ]]; then
        MOD_PARTSIZE=true
    else
        MOD_PARTSIZE=false
    fi
fi

# Set custom partition sizes only if x86
if [[ ${MOD_PARTSIZE} = true ]] && [[ ${IMAGE_PROFILE} = "generic" ]]; then
    [[ -z ${KERNEL_PARTSIZE} ]] &&
        read -p "    x86 ONLY!: Enter KERNEL partition MB [OWRT default is 32 - hit enter for ${KERNEL_RESIZE_DEF}, or enter custom size]: " KERNEL_PARTSIZE
    [[ -z ${ROOT_PARTSIZE} ]] &&
        read -p "    x86 ONLY!: Enter ROOT partition MB between 104 & 8192 [OWRT default is 104 - hit enter for ${ROOT_RESIZE_DEF}, or enter custom size]: " ROOT_PARTSIZE
fi

# If no kernel partition size value given, create a default value
if [[ ${MOD_PARTSIZE} = true ]] && [[ -z ${KERNEL_PARTSIZE} ]] && [[ ${IMAGE_PROFILE} = "generic" ]]; then
    KERNEL_PARTSIZE=$KERNEL_RESIZE_DEF
   fi
# If no root partition size value given, create a default value
if [[ ${MOD_PARTSIZE} = true ]] && [[ -z ${ROOT_PARTSIZE} ]] && [[ ${IMAGE_PROFILE} = "generic" ]]; then
    ROOT_PARTSIZE=$ROOT_RESIZE_DEF
fi

# Create a custom image name tag
if [[ -z ${IMAGE_TAG} ]]; then
    echo
    echo -e "${CYAN}Custom image filename identifier:${NC}"
    while true; do
        read -p "    Enter text to include in the image filename [Enter for \"custom\"]: " IMAGE_TAG
        [[ "${IMAGE_TAG}" = "" ]] || [[ "${IMAGE_TAG}" != "" ]] && break
    done
fi
# If no image name tag is given, create a default value
if [[ -z ${IMAGE_TAG} ]]; then
    IMAGE_TAG="custom"
fi

# Convert images for use in virtual environment?"
if [[ -z ${CREATE_VM} ]] && [[ ${IMAGE_PROFILE} = "generic" ]]; then
    echo
    echo -e "${CYAN}Virtual machine image conversion:${NC}"
    echo -e -n "    x86 ONLY!: Convert new OpenWRT images to a virtual machine format? [default = n] [y/N]: "
    read PROMPT
    if [[ ${PROMPT} =~ ^[Yy]$ ]]; then
        CREATE_VM=true
    else
        CREATE_VM=false
    fi
fi

# Display the VM conversion menu
echo
show_menu() {
    echo "    Select VM conversion format:"
    echo "    1) QEMU...............: qcow2"
    echo "    2) QEMU Enhanced......: eqd"
    echo "    3) Oracle Virutalbox..: vdi"
    echo "    4) MS HyperV..........: vhdx"
    echo "    5) VMware.............: vmdk"
}
read_choice() {
    local choice
    read -p "    Enter your choice (1-5): " choice
    echo $choice
}
conversion_cmd() {
    local choice=$1

    case $choice in
        1)
            CONVERT="qemu-img convert -f raw -O qcow2"
            ;;
        2)
            CONVERT="qemu-img convert -f raw -O qed"
            ;;
        3)
            CONVERT="qemu-img convert -f raw -O vdi"
            ;;
        4)
            CONVERT="qemu-img convert -f raw -O vhdx"
            ;;
        5)
            CONVERT="qemu-img convert -f raw -O vmdk" # ESXi also requires 'vmkfstools -i source.vmdk destintation.vmdk' to boot

            ;;
        *)
            echo "Invalid choice. Please select a number between 1 and 5."
            exit 1
            ;;
    esac
}
# Menu logic
if [[ ${CREATE_VM} = true ]]; then
    show_menu
    choice=$(read_choice)
    conversion_cmd $choice
fi

#######################################################################################################################
# Setup the image builder working environment
#######################################################################################################################

# Dynamically create the OpenWRT download link whilst also supporting legacy version imagebuilder download compression formats
if [[ -n ${VERSION} ]]; then
    BASE_URL="https://downloads.openwrt.org/releases/${VERSION}/targets/${TARGET}/${ARCH}"
    BUILDER_PREFIX="openwrt-imagebuilder-${VERSION}-${TARGET}-${ARCH}.Linux-x86_64.tar"
else
    BASE_URL="https://downloads.openwrt.org/snapshots/targets/${TARGET}/${ARCH}"
    BUILDER_PREFIX="openwrt-imagebuilder-${TARGET}-${ARCH}.Linux-x86_64.tar"
fi

BUILDER_XZ="${BASE_URL}/${BUILDER_PREFIX}.xz"
BUILDER_ZST="${BASE_URL}/${BUILDER_PREFIX}.zst"

# Try downloading .zst first, fallback to .xz if .zst is unavailable
if curl --head --silent --fail "${BUILDER_ZST}" >/dev/null; then
    BUILDER="${BUILDER_ZST}"
elif curl --head --silent --fail "${BUILDER_XZ}" >/dev/null; then
    BUILDER="${BUILDER_XZ}"
else
    echo
    echo "    Error: Could not find a valid image builder file for OpenWRT version ${VERSION:-snapshot}."
    echo
    exit 1
fi

echo
echo "    Using image builder: ${BUILDER}"


# Configure the build paths
SOURCE_FILE="${BUILDER##*/}" # Separate the tar.xz file name from the source download link
BUILD_ROOT="$(pwd)/openwrt_build_output"
OUTPUT="${BUILD_ROOT}/firmware_images"
VMDIR="${BUILD_ROOT}/vm"
INJECT_FILES="$(pwd)/openwrt_inject_files"
BUILD_LOG="${BUILD_ROOT}/owrt-build.log" # Creates a build log in the local working directory

# Set SOURCE_DIR based on download file extension (annoyingly snapshots changed to tar.zst. vs releases are tar.xz)
SOURCE_EXT="${SOURCE_FILE##*.}"
if [[ "${SOURCE_EXT}" == "xz" ]]; then
    SOURCE_DIR="${SOURCE_FILE%.tar.xz}"
	EXTRACT="tar -xJvf"
elif [[ "${SOURCE_EXT}" == "zst" ]]; then
    SOURCE_DIR="${SOURCE_FILE%.tar.zst}"
	EXTRACT="tar -I zstd -xf"
else
    echo "Unsupported file extension: ${SOURCE_EXT}"
fi

#######################################################################################################################
# Begin script build actions
#######################################################################################################################

# Clear out any previous builds
rm -rf "${BUILD_ROOT}"
rm -rf "${SOURCE_DIR}"

# Create the destination directories
mkdir -p "${BUILD_ROOT}"
mkdir -p "${OUTPUT}"
mkdir -p "${INJECT_FILES}"
if [[ ${CREATE_VM} = true ]] && [[ ${IMAGE_PROFILE} = "generic" ]]; then mkdir -p "${VMDIR}" ; fi

# Option to pre-configure images with injected config files
echo -e "${LYELLOW}"
echo -e "    OPTIONAL: TO BAKE A CUSTOM CONFIG INTO YOUR OWRT IMAGE:"
echo -e "    Before proceeding, copy your OWRT config files NOW to ${CYAN}${INJECT_FILES}${LYELLOW}"
echo
read -p "    Press ENTER to begin the OWRT build..."
echo -e "${NC}"

# Install OWRT build system dependencies for recent Ubuntu/Debian.
# See here for other distro dependencies: https://openwrt.org/docs/guide-developer/toolchain/install-buildsystem
    sudo apt-get install -y build-essential clang flex bison g++ gawk gcc-multilib g++-multilib \
    gettext git libncurses5-dev libssl-dev python3-distutils python3-setuptools rsync unzip zlib1g-dev file wget qemu-utils zstd  2>&1 | tee -a ${BUILD_LOG}

# Download the image builder source if we haven't already
if [ ! -f "${SOURCE_FILE}" ]; then
    wget -q --show-progress "$BUILDER"
    ${EXTRACT} "${SOURCE_FILE}" | tee -a ${BUILD_LOG}
fi

# Uncompress if the source tarball exists but there is no uncompressed source directory (saves re-download when build directories are cleared for a fresh build).
if [ -f "${SOURCE_FILE}" ]; then
     ${EXTRACT} "${SOURCE_FILE}" | tee -a ${BUILD_LOG}
fi

# Reconfigure the partition sizing source files (for x86 build only)
if [[ ${MOD_PARTSIZE} = true ]] && [[ ${IMAGE_PROFILE} = "generic" ]]; then
    # Patch the source partition size config settings
    sed -i "s/CONFIG_TARGET_KERNEL_PARTSIZE=.*/CONFIG_TARGET_KERNEL_PARTSIZE=$KERNEL_PARTSIZE/g" "$PWD/$SOURCE_DIR/.config"
    sed -i "s/CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=$ROOT_PARTSIZE/g" "$PWD/$SOURCE_DIR/.config"
    # Patch for source partition size config settings giving errors. See https://forum.openwrt.org/t/22-03-3-image-builder-issues/154168
    sed -i '/\$(CONFIG_TARGET_ROOTFS_PARTSIZE) \$(IMAGE_ROOTFS)/,/256/ s/256/'"$ROOT_PARTSIZE"'/' "$PWD/$SOURCE_DIR/target/linux/x86/image/Makefile"
fi

# Start a clean image build with the selected packages
    cd $(pwd)/"${SOURCE_DIR}"/
    make clean 2>&1 | tee -a ${BUILD_LOG}
    make image PROFILE="${IMAGE_PROFILE}" PACKAGES="${CUSTOM_PACKAGES}" EXTRA_IMAGE_NAME="${IMAGE_TAG}" FILES="${INJECT_FILES}" BIN_DIR="${OUTPUT}" 2>&1 | tee -a ${BUILD_LOG}

# Convert to virtual machine images
if [[ ${CREATE_VM} = true ]]; then
    # Extract all just before the image conversion type in the coversion command (in case of extra options/commands after '-O imagetype' )
    EXT="${CONVERT##* -O }"
    # Extracy only the image conversion output file extention (e.g., 'vmdk')
    EXT="${EXT%% *}"
    # Copy the new images to a separate directory for conversion to vm image
    cp $OUTPUT/*.gz $VMDIR
    # Create a list of new images to unzip
    for LIST in $VMDIR/*img.gz
    do
    echo $LIST
    gunzip $LIST
    done

    # Convert the unzipped images
    for LIST in $VMDIR/*.img
    do
    echo $LIST
    eval $CONVERT $LIST ${LIST%.*}.${EXT} 2>&1 | tee -a ${BUILD_LOG}
	done

    # Optionally remove all extracted raw source images from $VMDIR
    rm -f $VMDIR/*.img
fi

