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

    # Add GNU tools to PATH - Order matters! These directories are prepended to PATH
    # so tools in these directories will be found before system BSD tools
    cat >> "$config_file" << 'EOF'

# Use GNU tools instead of BSD tools
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
export PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"
export PATH="/opt/homebrew/opt/grep/libexec/gnubin:$PATH"
export PATH="/opt/homebrew/opt/findutils/libexec/gnubin:$PATH"
export PATH="/opt/homebrew/opt/gawk/libexec/gnubin:$PATH"
export PATH="/opt/homebrew/opt/gnu-tar/libexec/gnubin:$PATH"
export PATH="/opt/homebrew/opt/make/libexec/gnubin:$PATH"
export PATH="/opt/homebrew/opt/diffutils/libexec/gnubin:$PATH"
export PATH="/opt/homebrew/bin:$PATH"
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
    
    # Only update .zshrc if it exists (user uses zsh)
    if [[ -f "$HOME/.zshrc" ]]; then
        # For zsh, use a slightly different comment
        if grep -q "opt/coreutils/libexec/gnubin" "$HOME/.zshrc" 2>/dev/null; then
            print_warning ".zshrc already configured (skipping)"
        else
            cat >> "$HOME/.zshrc" << 'EOF'

# Use GNU tools instead of BSD tools
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
export PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"
export PATH="/opt/homebrew/opt/grep/libexec/gnubin:$PATH"
export PATH="/opt/homebrew/opt/findutils/libexec/gnubin:$PATH"
export PATH="/opt/homebrew/opt/gawk/libexec/gnubin:$PATH"
export PATH="/opt/homebrew/opt/gnu-tar/libexec/gnubin:$PATH"
export PATH="/opt/homebrew/opt/make/libexec/gnubin:$PATH"
export PATH="/opt/homebrew/opt/diffutils/libexec/gnubin:$PATH"
export PATH="/opt/homebrew/bin:$PATH"
EOF
            print_success ".zshrc configured"
        fi
    fi
    
    echo ""
    print_success "All shell configurations updated"
}

# Test in a new shell to verify PATH changes work
test_in_new_shell() {
    print_header "Testing in Fresh Shell"
    
    print_info "Testing commands in a new bash session..."
    
    # Test sed
    local sed_test=$(bash -l -c 'sed --version 2>&1 | head -1')
    if echo "$sed_test" | grep -q "GNU sed"; then
        print_success "sed works in new shell: $sed_test"
    else
        print_error "sed not working in new shell"
        print_info "You may need to manually restart your terminal"
    fi
    
    # Test grep
    local grep_test=$(bash -l -c 'grep --version 2>&1 | head -1')
    if echo "$grep_test" | grep -q "GNU grep"; then
        print_success "grep works in new shell: $grep_test"
    else
        print_error "grep not working in new shell"
    fi
    
    # Test find
    local find_test=$(bash -l -c 'find --version 2>&1 | head -1')
    if echo "$find_test" | grep -q "GNU findutils"; then
        print_success "find works in new shell: $find_test"
    else
        print_error "find not working in new shell"
    fi
    
    # Test ls (coreutils)
    local ls_test=$(bash -l -c 'ls --version 2>&1 | head -1')
    if echo "$ls_test" | grep -q "GNU coreutils"; then
        print_success "ls works in new shell: $ls_test"
    else
        print_warning "ls not working in new shell - PATH may need manual adjustment"
    fi
    
    echo ""
}

# Verify installation
verify_installation() {
    print_header "Verifying Installation"

    # Source the paths for verification
    export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
    export PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"
    export PATH="/opt/homebrew/opt/grep/libexec/gnubin:$PATH"
    export PATH="/opt/homebrew/opt/findutils/libexec/gnubin:$PATH"
    export PATH="/opt/homebrew/opt/gawk/libexec/gnubin:$PATH"
    export PATH="/opt/homebrew/opt/gnu-tar/libexec/gnubin:$PATH"
    export PATH="/opt/homebrew/opt/make/libexec/gnubin:$PATH"
    export PATH="/opt/homebrew/opt/diffutils/libexec/gnubin:$PATH"
    export PATH="/opt/homebrew/bin:$PATH"

    local all_ok=true

    # Check key GNU tools
    if sed --version 2>&1 | grep -q "GNU sed"; then
        print_success "sed: GNU version"
    else
        print_error "sed: GNU version not found"
        all_ok=false
    fi

    if grep --version 2>&1 | grep -q "GNU grep"; then
        print_success "grep: GNU version"
    else
        print_error "grep: GNU version not found"
        all_ok=false
    fi

    if tar --version 2>&1 | grep -q "GNU tar"; then
        print_success "tar: GNU version"
    else
        print_error "tar: GNU version not found"
        all_ok=false
    fi

    if make --version 2>&1 | grep -q "GNU Make"; then
        print_success "make: GNU version"
    else
        print_error "make: GNU version not found"
        all_ok=false
    fi

    if ls --version 2>&1 | grep -q "GNU coreutils"; then
        print_success "ls: GNU version"
    else
        print_error "ls: GNU version not found"
        all_ok=false
    fi

    if command -v bash &> /dev/null && bash --version | grep -q "version 5"; then
        print_success "bash: version 5.x"
    else
        print_warning "bash: not version 5.x"
    fi

    if command -v wget &> /dev/null; then
        print_success "wget: installed"
    else
        print_warning "wget: not found"
    fi

    if command -v git &> /dev/null; then
        print_success "git: installed"
    else
        print_warning "git: not found"
    fi

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
    test_in_new_shell
    print_summary
    print_tool_list
}

# Run main function
main
