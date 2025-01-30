#!/bin/bash

if [[ -z "$1" ]]; then
    echo "Usage: $0 <URL>"
    echo "Example: $0 https://example.com/software.tar.gz"
    exit 1
fi

infpi_dir=~/.infpi
temp_dir=${infpi_dir}/temp
log_dir=${infpi_dir}/logs
local_dir=~/.local
log_file=${log_dir}/$(basename $1).log

# Ensure necessary directories exist
mkdir -p "${temp_dir}" "${local_dir}" "${log_dir}"

# Generate unique temp names
temp_name="${temp_dir}/$(head -c 16 /dev/urandom | xxd -p | tr -d '\n')"
temp_tar_name="${temp_name}.archive"

log() {
    local level="$1"
    local message="$2"
    echo "infpi $(date +"%Y-%m-%d %H:%M:%S") ${level}: ${message}" | tee -a "${log_file}"
}

cleanup() {
    log "INFO" "Deleting temporary directories..."
    rm -rf "${temp_name}" "${temp_tar_name}"
}

fail() {
    log "ERROR" "$1"
    cleanup
    exit 1
}

# Download the file with progress
log "INFO" "Downloading $1..."
curl -L -# -o "${temp_tar_name}" "$1" || fail "curl failed to download"

# Extract into temp dir
mkdir -p "${temp_name}"
tar -xf "${temp_tar_name}" -C "${temp_name}" || fail "tar failed to extract"

# Find the shallowest bin dir
nearest_bin_dir=$(find "${temp_name}" -type d -name bin -print | awk -F'/bin$' 'NR==1 {print $1; exit}')

# Handle error if no bin dir is found
if [[ -z "$nearest_bin_dir" ]]; then
    log "ERROR" "No bin directory was found in archive: $1"
    cleanup
    exit 1
fi

# Copy the files verbosely
log "INFO" "Copying files to ${local_dir}..."
rsync -ah --progress "${temp_name}/" "${local_dir}/" | tee -a "${log_file}" || fail "rsync failed to copy files"

cleanup
log "SUCCESS" "Installation complete from $1"
