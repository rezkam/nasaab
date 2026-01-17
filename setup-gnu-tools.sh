#!/usr/bin/env bash

################################################################################
# GNU Tools Setup for macOS
#
# Installs GNU tools and configures shell via PATH.
#
# Usage: ./setup-gnu-tools.sh
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "  $1"
}

# Check if running on macOS
check_macos() {
    print_header "Checking Operating System"
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This script is for macOS only!"
        print_info "Detected OS: $OSTYPE"
        exit 1
    fi
    print_success "Running on macOS"
}

# Check and install Homebrew
check_homebrew() {
    print_header "Checking Homebrew"
    if command -v brew &> /dev/null; then
        print_success "Homebrew is already installed"
        BREW_VERSION=$(brew --version | head -1)
        print_info "$BREW_VERSION"
    else
        print_warning "Homebrew not found. Installing..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for Apple Silicon Macs
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        
        if command -v brew &> /dev/null; then
            print_success "Homebrew installed successfully"
        else
            print_error "Failed to install Homebrew"
            exit 1
        fi
    fi
}

# Install a Homebrew package if not already installed
install_package() {
    local package=$1
    local display_name=${2:-$package}
    
    if brew list "$package" &> /dev/null; then
        print_success "$display_name is already installed"
        return 0
    else
        print_info "Installing $display_name..."
        if brew install "$package"; then
            print_success "$display_name installed successfully"
            return 0
        else
            print_error "Failed to install $display_name"
            return 1
        fi
    fi
}

# Install GNU tools
install_gnu_tools() {
    print_header "Installing GNU Tools"

    install_package "coreutils" "GNU Coreutils"
    install_package "gnu-sed" "GNU sed"
    install_package "grep" "GNU grep"
    install_package "findutils" "GNU findutils (find, xargs, etc.)"
    install_package "gawk" "GNU awk"
    install_package "gnu-tar" "GNU tar"
    install_package "make" "GNU make"
    install_package "diffutils" "GNU diffutils"
    install_package "bash" "GNU Bash"
    install_package "wget" "wget"
    install_package "watch" "watch"
    install_package "git" "git"
    install_package "less" "less"
    install_package "tmux" "tmux"
    install_package "ripgrep" "ripgrep (rg)"

    echo ""
    print_success "All GNU tools installed"
}


# Update shell configuration file
update_shell_config() {
    local config_file=$1
    local shell_name=$2

    # Check if file exists, if not create it
    if [[ ! -f "$config_file" ]]; then
        touch "$config_file"
        print_info "Created $config_file"
    fi

    # Check if already configured
    if grep -q "opt/coreutils/libexec/gnubin" "$config_file" 2>/dev/null; then
        print_warning "$shell_name already configured (skipping)"
        return 0
    fi

    cat >> "$config_file" << 'EOF'

# Use GNU tools instead of BSD tools
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:/opt/homebrew/opt/gnu-sed/libexec/gnubin:/opt/homebrew/opt/grep/libexec/gnubin:/opt/homebrew/opt/findutils/libexec/gnubin:/opt/homebrew/opt/gawk/libexec/gnubin:/opt/homebrew/opt/gnu-tar/libexec/gnubin:/opt/homebrew/opt/make/libexec/gnubin:/opt/homebrew/opt/diffutils/libexec/gnubin:/opt/homebrew/bin:$PATH"
EOF

    print_success "$shell_name configured"
}

# Update .bash_profile to source .bashrc
update_bash_profile() {
    local bash_profile="$HOME/.bash_profile"
    
    if [[ -f "$bash_profile" ]] && grep -q "source.*bashrc" "$bash_profile" 2>/dev/null; then
        print_warning ".bash_profile already sources .bashrc (skipping)"
        return 0
    fi
    
    cat >> "$bash_profile" << 'EOF'

# Source .bashrc if it exists
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi
EOF
    
    print_success ".bash_profile configured to source .bashrc"
}

# Update shell configurations
update_shell_configs() {
    print_header "Updating Shell Configurations"

    update_shell_config "$HOME/.bashrc" ".bashrc (bash)"
    update_bash_profile
    update_shell_config "$HOME/.profile" ".profile (universal)"
    update_shell_config "$HOME/.zshrc" ".zshrc (zsh)"

    echo ""
    print_success "All shell configurations updated"
}

# Check if a tool matches expected version pattern
check_tool() {
    local cmd=$1
    local pattern=$2
    local name=$3
    local required=${4:-true}

    if $cmd --version 2>&1 | grep -q "$pattern"; then
        print_success "$name: verified"
        return 0
    else
        if $required; then
            print_error "$name: not found"
            return 1
        else
            print_warning "$name: not found"
            return 0
        fi
    fi
}

# Verify installation
verify_installation() {
    print_header "Verifying Installation"

    export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:/opt/homebrew/opt/gnu-sed/libexec/gnubin:/opt/homebrew/opt/grep/libexec/gnubin:/opt/homebrew/opt/findutils/libexec/gnubin:/opt/homebrew/opt/gawk/libexec/gnubin:/opt/homebrew/opt/gnu-tar/libexec/gnubin:/opt/homebrew/opt/make/libexec/gnubin:/opt/homebrew/opt/diffutils/libexec/gnubin:/opt/homebrew/bin:$PATH"

    local all_ok=true

    check_tool sed "GNU sed" "sed" || all_ok=false
    check_tool grep "GNU grep" "grep" || all_ok=false
    check_tool tar "GNU tar" "tar" || all_ok=false
    check_tool make "GNU Make" "make" || all_ok=false
    check_tool ls "GNU coreutils" "ls" || all_ok=false
    check_tool bash "version 5" "bash" false
    command -v wget &> /dev/null && print_success "wget: verified" || print_warning "wget: not found"
    command -v git &> /dev/null && print_success "git: verified" || print_warning "git: not found"

    echo ""

    if $all_ok; then
        print_success "All tools verified successfully!"
    else
        print_error "Some tools failed verification"
        return 1
    fi
}

# Print summary
print_summary() {
    print_header "Installation Complete!"

    echo ""
    echo -e "${GREEN}✓ All GNU tools installed and configured${NC}"
    echo ""
    echo -e "${YELLOW}⚠  RESTART YOUR SHELL: ${BLUE}exec \$SHELL${NC}"
    echo ""
    echo -e "Verify with: ${BLUE}sed --version${NC} or ${BLUE}ls --version${NC}"
    echo ""
}

# Print tool list
print_tool_list() {
    cat << 'EOF'

Installed tools:
  coreutils (ls, cp, mv, rm, cat, date, etc. - 100+ utilities)
  sed, grep, find, awk, tar, make, diff
  bash 5.x, wget, watch, git, less, tmux, ripgrep

EOF
}

# Main execution
main() {
    clear
    print_header "GNU Tools Setup for macOS"
    echo ""
    echo "Press ENTER to continue or Ctrl+C to cancel..."
    read -r

    check_macos
    check_homebrew
    install_gnu_tools
    update_shell_configs
    verify_installation
    print_summary
    print_tool_list
}

# Run main function
main
