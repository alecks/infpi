#!/bin/bash

if [[ -z "$1" ]]; then
    echo "Simple script to install programs packaged in tarballs into the ~/.local folder. Made for the UoE School of Informatics' DICE computers."
    echo "-- Usage: infpi <URL>"
    echo "-- Example: infpi https://example.com/software.tar.gz"
    exit 1
fi

tar_basename=$(basename "$1")

infpi_dir=~/.infpi
infpi_temp_dir=${infpi_dir}/temp
log_dir=${infpi_dir}/logs
local_dir=~/.local
log_file=${log_dir}/${tar_basename}.log

# Ensure necessary directories exist
mkdir -p "${infpi_temp_dir}" "${local_dir}/bin" "${log_dir}"

# Generate unique temp names
temp_tar_name="${infpi_temp_dir}/$(head -c 2 /dev/urandom | xxd -p | tr -d '\n')${tar_basename}"
temp_name="${temp_tar_name}EX"

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

confirm_continue() {
    read -rp "Continue with installation? (Y/n): " confirm
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        echo "Exiting..."
        cleanup
        exit 0
    fi
}

dirtree() {
    echo ""
    tree --noreport -ad "$1"
    tree -aL 1 "$1"
    echo ""
}

rsync_interactive_overwrite() {
    local include_only_dirs="$2"
    local in_dir="$1"

    # Apply include/exclude only if we’re focusing on directories
    if [[ "$include_only_dirs" == "true" ]]; then
        rsync_opts=(
          "--include=*/"
          "--include=*"
          "--exclude=*/*"
        )
    else
        rsync_opts=()
    fi

    # Dry-run rsync to detect files that will be overwritten
    existing_files=$(rsync "${rsync_opts[@]}" -ain --existing "${in_dir}/" "${local_dir}/" | grep "^>f" | awk '{print $2}')

    if [[ -n "$existing_files" ]]; then
        echo "The following files already exist in ~/.local and the package being installed has different contents:"
        echo "$existing_files"
        echo ""

        read -rp "Overwrite All/Some/No files? (a/s/N): " ask_each
            case "$ask_each" in
                [Ss])
                    for file in $existing_files; do
                        read -rp "Overwrite $file? (y/N): " overwrite
                        if [[ "$overwrite" =~ ^[Yy]$ ]]; then
                            mv "${in_dir}/${file}" "${local_dir}/${file}" || return 1
                            log "INFO" "Overwrote ${file}"
                        else
                            log "INFO" "Skipped ${file}"
                        fi
                    done
                    ;;
                [Aa])
                    log "INFO" "Overwriting all files without confirmation..."
                    rsync -a --info=progress2 "${rsync_opts[@]}" "${in_dir}/" "${local_dir}/" || return 1
                    ;;
                *)
                    log "INFO" "Skipping all overwrites. Only new files will be copied."
                    rsync -a --info=progress2 --ignore-existing "${rsync_opts[@]}" "${in_dir}/" "${local_dir}/" || return 1
                    ;;
            esac
    else
        log "INFO" "No files to be overwritten, merging..."
        rsync -a --info=progress2 "${rsync_opts[@]}" "${in_dir}/" "${local_dir}/" || return 1
    fi
}

# Download the file with progress
log "INFO" "Downloading $1..."
echo ""
curl -L -# -o "${temp_tar_name}" "$1" || fail "curl failed to download"
echo "Downloaded. Extracting..."

# Extract into temp dir
mkdir -p "${temp_name}"
tar -xf "${temp_tar_name}" -C "${temp_name}" || fail "tar failed to extract"
rm -rf "${temp_tar_name}"

echo ""
dirtree "$temp_name" | tee -a "${log_file}"
echo ""

# Find the shallowest bin directory
# TODO: do this for lib dir
nearest_bin_dir=$(find "${temp_name}" -type d -name bin | head -n 1 | sed 's:/bin$::')

if [[ -n "$nearest_bin_dir" ]]; then
    echo "Assuming this is the directory to be moved to .local:"
    dirtree "$nearest_bin_dir"

    # TODO: Allow moving all files, not just directories.
    echo "-- A bin directory was found. The DIRECTORIES listed above will be moved to ~/.local."
    confirm_continue

    rsync_interactive_overwrite "$nearest_bin_dir" "true" || fail "Failed to merge files"
    log "INFO" "Directories moved to ~/.local. Top-level files have not been moved."
else
    log "INFO" "No bin directory found, checking for executables..."
    
    executables=$(find "${temp_name}" -type f -executable)

    if [[ -n "${executables}" ]]; then
        echo ""
        echo "${executables}" | xargs -I {} basename "{}" | tee -a "${log_file}"
        echo ""
        echo "-- The executables listed above will be moved to ~/.local."

        confirm_continue

        log "INFO" "Moving executables to ~/.local/bin..."
        mv "${executables[@]}" "${local_dir}/bin/" || fail "Failed to move executables to bin"
        log "INFO" "Executables moved to ~/.local/bin"

        # Check for anything left over after copying executables. Split into files and dirs.
        remaining_dirs=$(find "${temp_name}" -mindepth 1 -type d 2>/dev/null)
        remaining_files=$(find "${temp_name}" -maxdepth 1 -type f 2>/dev/null)
        if [[ -n "${remaining_files}" || -n "${remaining_dirs}" ]]; then
            echo ""
            dirtree "${temp_name}"
            echo ""
            echo "-- The files remaining in the archive are listed above."

            echo "Please choose what you would like to do:"
            echo "-- 1: Move only directories to ~/.local, excluding top-level files (recommended)"
            echo "-- 2: Move everything to ~/.local (may clutter your .local folder with READMEs, etc)"
            echo "-- 3: Delete the remaining files (if you know you don't need them)"
            echo "-- 4: Leave them in another location for manual handling"

            while true; do
                echo ""
                read -rp "Enter choice (1, 2, 3, 4): " choice
            case "${choice}" in
                1)
                    # Only move directories
                    log "INFO" "Moving remaining directories, excluding top-level files, to ~/.local"
                    rsync_interactive_overwrite "$temp_name" "true" || fail "Failed to merge files"
                    cleanup
                    log "SUCCESS" "Installation complete, copied executables and directories excluding top-level files"
                    exit 0
                    ;;
                2)
                    # Continue like normal, move all the rest
                    log "INFO" "Moving all files to ${local_dir}..."
                    rsync_interactive_overwrite "$temp_name" || fail "Failed to merge files"
                    ;;
                3)
                    # Exit so we don't continue copying
                    cleanup
                    log "SUCCESS" "Installation complete, remaining files have been deleted"
                    exit 0
                    ;;
                4)
                    # Exit so we don't continue copying
                    log "SUCCESS" "Installation partially complete, files remain in ${temp_name}"
                    exit 0
                    ;;
                *)
                    echo "Invalid option. Enter 1, 2, 3, or 4."
                    ;;
            esac
        done
        fi
    else
        fail "No bin directory or executables found in archive: $1"
    fi
fi

cleanup
log "SUCCESS" "Installation complete from $1"

