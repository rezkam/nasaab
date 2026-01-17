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

        # Add Homebrew to PATH
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -f "/usr/local/bin/brew" ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi

        if command -v brew &> /dev/null; then
            print_success "Homebrew installed successfully"
        else
            print_error "Failed to install Homebrew"
            exit 1
        fi
    fi

    # Cache brew prefix
    BREW_PREFIX=$(brew --prefix)
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
    install_package "parallel" "GNU parallel"
    install_package "jq" "jq"
    install_package "glow" "glow"

    echo ""
    print_success "All GNU tools installed"
}

# Register Homebrew bash as a valid login shell
register_homebrew_bash() {
    print_header "Registering Homebrew Bash"

    local homebrew_bash="${BREW_PREFIX}/bin/bash"

    if [[ ! -x "$homebrew_bash" ]]; then
        print_warning "Homebrew bash not found at $homebrew_bash"
        return 0
    fi

    # Ensure symlink path is in /etc/shells (not Cellar path which breaks on upgrades)
    if grep -qF "$homebrew_bash" /etc/shells 2>/dev/null; then
        print_success "Homebrew bash already in /etc/shells"
    else
        print_info "Adding $homebrew_bash to /etc/shells (requires sudo)"
        if sudo sh -c "echo '$homebrew_bash' >> /etc/shells"; then
            print_success "Homebrew bash registered as valid shell"
        else
            print_warning "Failed to add bash to /etc/shells (may need manual setup)"
            return 0
        fi
    fi

    # If user is on old bash or Cellar path, switch to symlink path
    local current_shell=$(dscl . -read ~/ UserShell | awk '{print $2}')
    if [[ "$current_shell" == "/bin/bash" || "$current_shell" == *"/Cellar/"* ]]; then
        print_info "Switching to Homebrew bash..."
        if chsh -s "$homebrew_bash"; then
            print_success "Default shell changed to $homebrew_bash"
        else
            print_warning "Failed to change shell (run: chsh -s $homebrew_bash)"
        fi
    elif [[ "$current_shell" == "$homebrew_bash" ]]; then
        print_success "Already using Homebrew bash"
    else
        print_info "Current shell: $current_shell (keeping as-is)"
    fi
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
    if grep -q "coreutils/libexec/gnubin" "$config_file" 2>/dev/null; then
        print_warning "$shell_name already configured (skipping)"
        return 0
    fi

    cat >> "$config_file" <<EOF

# Use GNU tools instead of BSD tools
export PATH="${BREW_PREFIX}/opt/coreutils/libexec/gnubin:${BREW_PREFIX}/opt/gnu-sed/libexec/gnubin:${BREW_PREFIX}/opt/grep/libexec/gnubin:${BREW_PREFIX}/opt/findutils/libexec/gnubin:${BREW_PREFIX}/opt/gawk/libexec/gnubin:${BREW_PREFIX}/opt/gnu-tar/libexec/gnubin:${BREW_PREFIX}/opt/make/libexec/gnubin:${BREW_PREFIX}/opt/diffutils/libexec/gnubin:${BREW_PREFIX}/bin:\$PATH"
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

# Check tool version is greater than or equal to minimum
check_version() {
    local cmd=$1
    local min_version=$2
    local name=$3
    local required=${4:-true}

    if ! command -v $cmd &> /dev/null; then
        if $required; then
            print_error "$name: not found"
            return 1
        else
            print_warning "$name: not found"
            return 0
        fi
    fi

    local version=$($cmd --version 2>&1 | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
    if [[ -z "$version" ]]; then
        print_warning "$name: version check failed"
        return 0
    fi

    if awk -v ver="$version" -v min="$min_version" 'BEGIN {exit !(ver >= min)}'; then
        print_success "$name: $version (>= $min_version)"
        return 0
    else
        if $required; then
            print_error "$name: $version (need >= $min_version)"
            return 1
        else
            print_warning "$name: $version (need >= $min_version)"
            return 0
        fi
    fi
}

# Verify installation
verify_installation() {
    print_header "Verifying Installation"

    export PATH="${BREW_PREFIX}/opt/coreutils/libexec/gnubin:${BREW_PREFIX}/opt/gnu-sed/libexec/gnubin:${BREW_PREFIX}/opt/grep/libexec/gnubin:${BREW_PREFIX}/opt/findutils/libexec/gnubin:${BREW_PREFIX}/opt/gawk/libexec/gnubin:${BREW_PREFIX}/opt/gnu-tar/libexec/gnubin:${BREW_PREFIX}/opt/make/libexec/gnubin:${BREW_PREFIX}/opt/diffutils/libexec/gnubin:${BREW_PREFIX}/bin:$PATH"

    local all_ok=true

    # Verify GNU tools (must be GNU versions, not BSD)
    check_tool sed "GNU sed" "sed" || all_ok=false
    check_tool grep "GNU grep" "grep" || all_ok=false
    check_tool find "GNU findutils" "find" || all_ok=false
    check_tool tar "GNU tar" "tar" || all_ok=false
    check_tool make "GNU Make" "make" || all_ok=false
    check_tool awk "GNU Awk" "awk" || all_ok=false
    check_tool diff "diffutils" "diff" || all_ok=false
    check_tool ls "GNU coreutils" "ls" || all_ok=false

    # Verify other tools with version requirements
    check_version bash 5.0 "bash" false
    check_version git 2.0 "git" false
    command -v wget &> /dev/null && print_success "wget: verified" || print_warning "wget: not found"
    command -v watch &> /dev/null && print_success "watch: verified" || print_warning "watch: not found"
    command -v tmux &> /dev/null && print_success "tmux: verified" || print_warning "tmux: not found"
    command -v less &> /dev/null && print_success "less: verified" || print_warning "less: not found"
    command -v rg &> /dev/null && print_success "rg: verified" || print_warning "rg: not found"
    command -v parallel &> /dev/null && print_success "parallel: verified" || print_warning "parallel: not found"
    command -v jq &> /dev/null && print_success "jq: verified" || print_warning "jq: not found"
    command -v glow &> /dev/null && print_success "glow: verified" || print_warning "glow: not found"

    echo ""

    if $all_ok; then
        print_success "All tools verified successfully!"
    else
        print_error "Some tools failed verification"
        print_warning "You may need to restart your shell"
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
  bash 5.x, wget, watch, git, less, tmux, ripgrep, parallel, jq, glow

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
    register_homebrew_bash
    update_shell_configs
    verify_installation
    print_summary
    print_tool_list
}

# Run main function
main
