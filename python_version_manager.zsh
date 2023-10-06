#!/usr/bin/env zsh

# Script Name: Localbrew
# Description: A script to install and manage Python versions in a user-friendly manner.
# Usage:       source localbrew.sh; pybrew <version> | setenv <version> | setpy <version>
# Author:      Emrul Hasan Zawad
# Date:        October 2023

# Define a log file for error messages
ERROR_LOG="$HOME/localbrew/error_log.txt"

# Error Handling
handle_error() {
    local msg=$1
    echo $msg
    echo $msg >> $ERROR_LOG
    return 1
}

# The Configuration Blueprint
configure_python() {
    local prefix=$1
    ./configure --prefix=$prefix \
                --libdir=$prefix/lib \
                --includedir=$prefix/include \
                --datarootdir=$prefix/share \
                --enable-optimizations || handle_error "Configuration failed. Check error_log.txt for details."
}

# Cast the Creation Ballet
make_python() {
    make || handle_error "Make command failed. Check error_log.txt for details."
}

# The Courteous Finale
install_python() {
    make altinstall || handle_error "Installation failed. Check error_log.txt for details."
}

# The Installation Ballet, now refactored
pybrew_install() {
    local prefix=$1
    local version=$2

    configure_python $prefix || return 1
    make_python || return 1
    install_python || return 1
}

# Function to manage the PATH variable
update_path() {
    local new_path=$1

    # Remove any existing path to a different Python version
    export PATH=$(echo $PATH | sed -E -e "s|/Users/[^:]+/Python-[0-9\.]+/bin:||g")

    # Add the new path to the beginning of the PATH variable
    export PATH="$new_path:$PATH"
}

# Update pybrew function with input validation and instructions
pybrew() {
    echo "Bestow upon thee a prefix directory for this Python installation (e.g., $HOME/localbrew/Python-3.9.6):"
    read raw_prefix
    local prefix=$(eval echo $raw_prefix)  # Resolve relative paths

    # Validate prefix directory input
    if [[ -z "$prefix" ]]; then
        handle_error "Ah, the prefix directory cannot be empty!"
        return 1
    fi

    # Version input validation and instruction
    local version=$1
    if [[ -z "$version" ]]; then
        handle_error "Ah, the version of Python is required! (e.g., 3.9.6)"
        return 1
    fi

    pybrew_install $prefix $version
}

# Update setenv function to use update_path
setenv() {
    local version=${1:-$(< $HOME/localbrew/.pybrew_default_version)}
    local prefix=$(< $HOME/localbrew/.pybrew_prefix_$version)

    if [[ ! -d $prefix/bin ]]; then
        handle_error "Ah, a stumble! The bin directory is not to be found in the bestowed prefix."
        return 1
    fi

    # Update the PATH
    update_path "$prefix/bin"

    export PYTHONHOME=$prefix

    echo "Thy shell now dances with Python $version."
}

# Function to set the default Python version at the profile level
setpy() {
    local version=$1
    local prefix=$(< $HOME/localbrew/.pybrew_prefix_$version)

    # Ensure the bin directory exists in the specified prefix
    if [[ ! -d $prefix/bin ]]; then
        handle_error "Ah, a stumble! The bin directory is not to be found in the bestowed prefix."
        return 1
    fi

    # Remove any existing setenv invocation from the profile file
    sed -i '' '/setenv/d' $HOME/.zshrc

    # Append a setenv invocation to the profile file
    echo "setenv $version" >> $HOME/.zshrc

    echo "Thou hast set Python $version as thy default. A new dance begins upon the next shell session."
}
