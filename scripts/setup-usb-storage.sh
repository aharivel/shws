#!/bin/bash
# =============================================================================
# USB Storage Setup Script for Weather Station
# =============================================================================
# This script configures USB storage for persistent data and updates fstab
# for automatic mounting on system reboot.

set -euo pipefail  # Exit on any error

# Configuration
USB_MOUNT_POINT="/mnt/usb"
PROMETHEUS_DATA_DIR="$USB_MOUNT_POINT/prometheus"
BACKUP_DIR="$USB_MOUNT_POINT/backups"
FSTAB_BACKUP="/etc/fstab.backup.$(date +%Y%m%d-%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Detect USB devices
detect_usb_devices() {
    log_info "Detecting USB storage devices..."
    
    # List block devices that are USB and not mounted at /
    USB_DEVICES=$(lsblk -ndo NAME,SIZE,TYPE,MOUNTPOINT,TRAN | grep -E "usb.*disk" | grep -v "/" || true)
    
    if [[ -z "$USB_DEVICES" ]]; then
        log_warn "No USB storage devices detected. Please ensure USB drive is connected."
        
        # Show all block devices for reference
        log_info "Available block devices:"
        lsblk
        
        read -p "Enter the device name manually (e.g., sdb, sdc): " MANUAL_DEVICE
        if [[ -n "$MANUAL_DEVICE" ]]; then
            SELECTED_DEVICE="/dev/${MANUAL_DEVICE}"
            log_info "Using manually specified device: $SELECTED_DEVICE"
        else
            log_error "No device specified. Exiting."
            exit 1
        fi
    else
        log_info "Found USB devices:"
        echo "$USB_DEVICES"
        echo
        
        # Auto-select first USB device or prompt user
        FIRST_USB=$(echo "$USB_DEVICES" | head -n1 | awk '{print $1}')
        SELECTED_DEVICE="/dev/${FIRST_USB}"
        
        log_warn "Auto-selecting: $SELECTED_DEVICE"
        read -p "Continue with this device? [Y/n]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            read -p "Enter the correct device name (e.g., sdb, sdc): " MANUAL_DEVICE
            SELECTED_DEVICE="/dev/${MANUAL_DEVICE}"
        fi
    fi
    
    log_info "Selected device: $SELECTED_DEVICE"
}

# Check and create filesystem if needed
prepare_filesystem() {
    log_info "Checking filesystem on $SELECTED_DEVICE..."
    
    # Check if device has a filesystem
    if ! blkid "$SELECTED_DEVICE" &>/dev/null; then
        log_warn "No filesystem detected on $SELECTED_DEVICE"
        read -p "Create ext4 filesystem? [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "Creating ext4 filesystem..."
            mkfs.ext4 -F "$SELECTED_DEVICE"
            log_success "Filesystem created successfully"
        else
            log_error "Cannot proceed without filesystem. Exiting."
            exit 1
        fi
    else
        log_success "Filesystem detected on $SELECTED_DEVICE"
        blkid "$SELECTED_DEVICE"
    fi
    
    # Get UUID for fstab entry
    USB_UUID=$(blkid -s UUID -o value "$SELECTED_DEVICE")
    log_info "Device UUID: $USB_UUID"
}

# Create mount point and mount device
mount_device() {
    log_info "Setting up mount point..."
    
    # Create mount point if it doesn't exist
    if [[ ! -d "$USB_MOUNT_POINT" ]]; then
        mkdir -p "$USB_MOUNT_POINT"
        log_success "Created mount point: $USB_MOUNT_POINT"
    fi
    
    # Check if already mounted
    if mountpoint -q "$USB_MOUNT_POINT"; then
        log_warn "$USB_MOUNT_POINT is already mounted"
        umount "$USB_MOUNT_POINT" || {
            log_error "Failed to unmount $USB_MOUNT_POINT"
            exit 1
        }
    fi
    
    # Mount the device
    log_info "Mounting $SELECTED_DEVICE to $USB_MOUNT_POINT..."
    mount "$SELECTED_DEVICE" "$USB_MOUNT_POINT"
    
    if mountpoint -q "$USB_MOUNT_POINT"; then
        log_success "Device mounted successfully"
        df -h "$USB_MOUNT_POINT"
    else
        log_error "Failed to mount device"
        exit 1
    fi
}

# Create directory structure
create_directory_structure() {
    log_info "Creating directory structure..."
    
    # Create directories with proper permissions
    mkdir -p "$PROMETHEUS_DATA_DIR/prometheus"
    mkdir -p "$BACKUP_DIR"
    
    # Set ownership for Prometheus (UID:GID 1000:1000 as per docker-compose)
    chown -R 1000:1000 "$PROMETHEUS_DATA_DIR"
    chmod -R 755 "$PROMETHEUS_DATA_DIR"
    
    # Set general permissions
    chmod 755 "$BACKUP_DIR"
    
    log_success "Directory structure created:"
    ls -la "$USB_MOUNT_POINT"
}

# Update fstab for persistent mounting
update_fstab() {
    log_info "Updating /etc/fstab for persistent mounting..."
    
    # Backup existing fstab
    cp /etc/fstab "$FSTAB_BACKUP"
    log_info "Backed up fstab to: $FSTAB_BACKUP"
    
    # Check if entry already exists
    if grep -q "$USB_UUID" /etc/fstab; then
        log_warn "USB device already in fstab. Removing old entry..."
        sed -i "/$USB_UUID/d" /etc/fstab
    fi
    
    # Add new fstab entry
    # Different mount options based on filesystem type
    FS_TYPE=$(blkid -o value -s TYPE "$SELECTED_DEVICE")
    if [[ "$FS_TYPE" == "vfat" || "$FS_TYPE" == "fat32" ]]; then
        FSTAB_ENTRY="UUID=$USB_UUID $USB_MOUNT_POINT $FS_TYPE defaults,nofail,uid=1000,gid=1000,umask=022 0 2"
    else
        FSTAB_ENTRY="UUID=$USB_UUID $USB_MOUNT_POINT $FS_TYPE defaults,nofail 0 2"
    fi
    echo "$FSTAB_ENTRY" >> /etc/fstab
    
    log_success "Added fstab entry:"
    echo "$FSTAB_ENTRY"
    
    # Test the fstab entry
    log_info "Testing fstab entry..."
    umount "$USB_MOUNT_POINT"
    mount "$USB_MOUNT_POINT"
    
    if mountpoint -q "$USB_MOUNT_POINT"; then
        log_success "Fstab entry verified successfully"
    else
        log_error "Fstab entry test failed"
        # Restore backup
        cp "$FSTAB_BACKUP" /etc/fstab
        log_error "Restored fstab from backup"
        exit 1
    fi
}

# Create a test file to verify write permissions
test_permissions() {
    log_info "Testing write permissions..."
    
    TEST_FILE="$USB_MOUNT_POINT/weather-station-test"
    echo "Weather Station USB Setup - $(date)" > "$TEST_FILE"
    
    if [[ -f "$TEST_FILE" ]]; then
        log_success "Write test successful"
        rm "$TEST_FILE"
    else
        log_error "Write test failed"
        exit 1
    fi
}

# Display summary
show_summary() {
    echo
    log_success "=== USB Storage Setup Complete ==="
    echo "Device: $SELECTED_DEVICE"
    echo "UUID: $USB_UUID"
    echo "Mount Point: $USB_MOUNT_POINT"
    echo "Prometheus Data: $PROMETHEUS_DATA_DIR"
    echo "Backup Dir: $BACKUP_DIR"
    echo "Fstab Backup: $FSTAB_BACKUP"
    echo
    log_info "The USB storage will now automatically mount on system reboot."
    log_info "You can now run: make core"
    echo
}

# Main execution
main() {
    log_info "Starting USB storage setup for Weather Station..."
    echo
    
    check_root
    detect_usb_devices
    prepare_filesystem
    mount_device
    create_directory_structure
    update_fstab
    test_permissions
    show_summary
}

# Run main function
main "$@"