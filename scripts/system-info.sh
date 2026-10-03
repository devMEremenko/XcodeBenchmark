#!/bin/sh

echo "macOS: $(sw_vers -productVersion)" # Print the macOS version.
xcodebuild -version | grep '^Xcode ' # Print the selected Xcode version.
HARDWARE=$(system_profiler SPHardwareDataType 2>/dev/null) # Read the hardware overview once.
printf '%s\n' "$HARDWARE" | grep -E 'Model Name:|Model Identifier:|Chip:|Processor Name:|Processor Speed:|Total Number of Cores:|Number of Processors:' # Print device and CPU details.

RAM_BYTES=$(sysctl -n hw.memsize 2>/dev/null) # Read installed RAM in bytes.
if printf '%s\n' "$RAM_BYTES" | grep -Eq '^[0-9]+$'; then # Check that RAM is a number.
    LC_ALL=C awk -v bytes="$RAM_BYTES" 'BEGIN { printf "Memory: %.0f GB\n", bytes / 1073741824 }' # Round RAM to whole GB.
else # Handle missing RAM information.
    echo "Memory: unavailable" # Report that RAM needs verification.
fi # Finish RAM collection.

DISK_DIRECTORY=$(mktemp -d "${TMPDIR:-/tmp}/xcodebenchmark-system.XXXXXX") || exit 1 # Create temporary storage for disk details.
trap 'rm -rf "$DISK_DIRECTORY"' EXIT # Remove temporary files when the script exits.
trap 'exit 130' INT # Stop when interrupted.
trap 'exit 143' TERM HUP # Stop when terminated or disconnected.

read_field() { # Read a value from a disk plist.
    plutil -extract "$2" raw -o - "$1" 2>/dev/null # Print the requested value.
} # Finish the plist reader.

storage_unavailable() { # Report ambiguous or missing storage information.
    echo "Storage Capacity: unavailable ($1)" # Explain what needs verification.
    exit 0 # Keep available system details usable.
} # Finish the storage warning.

DEVICE=$(df -P . | awk 'NR == 2 { print $1 }') # Identify the filesystem containing the checkout.
if ! diskutil info -plist "$DEVICE" > "$DISK_DIRECTORY/volume.plist" 2>/dev/null; then # Read the checkout volume.
    storage_unavailable "cannot identify the benchmark disk" # Report an unreadable volume.
fi # Finish the volume check.
CONTAINER=$(read_field "$DISK_DIRECTORY/volume.plist" APFSContainerReference) # Find the APFS container, if present.
if [ -n "$CONTAINER" ]; then # Resolve APFS storage to its physical disk.
    if ! diskutil apfs list -plist "$CONTAINER" > "$DISK_DIRECTORY/apfs.plist" 2>/dev/null; then # Read the container's physical stores.
        storage_unavailable "cannot identify APFS physical storage" # Report an unreadable container.
    fi # Finish the container check.
    if read_field "$DISK_DIRECTORY/apfs.plist" Containers.0.PhysicalStores.1.DeviceIdentifier >/dev/null; then # Check for multiple physical stores.
        storage_unavailable "multiple physical stores; verify the storage configuration" # Ask for verification through the output.
    fi # Finish the multiple-store check.
    DEVICE=$(read_field "$DISK_DIRECTORY/apfs.plist" Containers.0.PhysicalStores.0.DeviceIdentifier) # Select the physical store.
    [ -n "$DEVICE" ] || storage_unavailable "APFS physical store is missing" # Require an identified physical store.
    if ! diskutil info -plist "$DEVICE" > "$DISK_DIRECTORY/volume.plist" 2>/dev/null; then # Read the store's parent disk.
        storage_unavailable "cannot read the physical store" # Report an unreadable store.
    fi # Finish the physical-store check.
fi # Finish APFS resolution.

WHOLE_DISK=$(read_field "$DISK_DIRECTORY/volume.plist" ParentWholeDisk) # Find the whole disk containing the partition.
if [ -z "$WHOLE_DISK" ]; then # Handle a volume that is already a whole disk.
    WHOLE_DISK=$(read_field "$DISK_DIRECTORY/volume.plist" DeviceIdentifier) # Use its own disk identifier.
fi # Finish whole-disk selection.
[ -n "$WHOLE_DISK" ] || storage_unavailable "physical disk is missing" # Require an identified physical disk.
if ! diskutil info -plist "$WHOLE_DISK" > "$DISK_DIRECTORY/disk.plist" 2>/dev/null; then # Read the whole disk's capacity and type.
    storage_unavailable "cannot read physical disk capacity" # Report an unreadable disk.
fi # Finish the whole-disk check.

DISK_BYTES=$(read_field "$DISK_DIRECTORY/disk.plist" TotalSize) # Read physical capacity in bytes.
printf '%s\n' "$DISK_BYTES" | grep -Eq '^[0-9]+$' || storage_unavailable "physical disk capacity is missing" # Require a numeric capacity.
[ "$DISK_BYTES" -gt 0 ] || storage_unavailable "physical disk capacity is invalid" # Require a positive capacity.
MEDIA_NAME=$(read_field "$DISK_DIRECTORY/disk.plist" MediaName) # Read the disk manufacturer and model.
SOLID_STATE=$(read_field "$DISK_DIRECTORY/disk.plist" SolidState) # Read whether the disk is an SSD.
INTERNAL=$(read_field "$DISK_DIRECTORY/disk.plist" Internal) # Read whether the disk is internal.
echo "Storage Device: $WHOLE_DISK" # Identify which disk was measured.
case "$SOLID_STATE" in # Select the storage type label.
    true) echo "Storage Type: SSD" ;; # Label solid-state storage.
    false) echo "Storage Type: HDD" ;; # Label rotating storage.
    *) echo "Storage Type: unknown" ;; # Report an unverified storage type.
esac # Finish storage type reporting.
case "$INTERNAL" in # Select the storage location label.
    true) echo "Storage Location: internal" ;; # Identify internal storage.
    false) echo "Storage Location: external" ;; # Identify external storage.
    *) echo "Storage Location: unknown" ;; # Report an unverified location.
esac # Finish storage location reporting.

LC_ALL=C awk -v bytes="$DISK_BYTES" -v media="$MEDIA_NAME" ' # Format physical capacity using decimal storage units.
BEGIN { # Start capacity calculation.
    gb = bytes / 1000000000 # Convert bytes to decimal GB.
    capacity = int(gb + 0.5) # Round third-party capacity to whole GB.
    nominal = 0 # Start with the measured physical capacity.
    if (media ~ /^APPLE /) { # Map only Apple disks to nominal configurations.
        split("128 256 512 1000 2000 4000 8000 16000", choices, " ") # List standard Apple capacities in GB.
        best = 1 # Start with no nearby configuration.
        for (i = 1; i <= 8; i++) { # Compare each standard capacity.
            distance = (gb - choices[i]) / choices[i] # Calculate the relative difference.
            if (distance < 0) distance = -distance # Make the difference positive.
            if (distance < best) { # Keep the closest configuration.
                best = distance # Save its relative difference.
                candidate = choices[i] # Save its nominal capacity.
            } # Finish the closest-capacity check.
        } # Finish capacity comparisons.
        if (best <= 0.10) { # Accept a nominal capacity within ten percent.
            capacity = candidate # Use the nominal Apple capacity.
            nominal = 1 # Record that nominal mapping was used.
        } # Finish nominal capacity selection.
    } # Finish Apple capacity mapping.
    if (capacity >= 1000 && capacity % 1000 == 0) { # Use TB for whole terabyte capacities.
        printf "Storage Capacity: %d TB\n", capacity / 1000 # Print integer TB.
    } else { # Keep other capacities in GB.
        printf "Storage Capacity: %d GB\n", capacity # Print integer GB.
    } # Finish capacity reporting.
    source = "rounded physical disk capacity" # Describe the physical measurement.
    if (nominal) source = "nominal Apple configuration" # Describe nominal Apple mapping.
    printf "Storage Capacity Source: %s\n", source # Print how capacity was selected.
    printf "Physical Disk Size: %.0f bytes\n", bytes # Preserve the original measurement.
} # Finish capacity calculation.
' # Run the capacity formatter.
