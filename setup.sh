#!/bin/bash

# =================================================================
# YemenJPT - Automated Setup Script
# =================================================================
# This script prepares the environment and launches the platform.
# =================================================================

# --- Color Codes ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_CYAN='\033[0;36m'

# --- Helper Functions ---
function print_info() {
    echo -e "${C_BLUE}INFO: $1${C_RESET}"
}

function print_success() {
    echo -e "${C_GREEN}SUCCESS: $1${C_RESET}"
}

function print_warning() {
    echo -e "${C_YELLOW}WARNING: $1${C_RESET}"
}

function print_error() {
    echo -e "${C_RED}ERROR: $1${C_RESET}"
}

function command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# --- Main Script ---
print_info "Starting YemenJPT Platform Setup..."

# 1. Check for dependencies (Docker and Docker Compose)
print_info "Checking for dependencies..."
if ! command_exists docker; then
    print_error "Docker is not installed. Please install Docker before running this script."
    exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
    print_error "Docker Compose V2 is not available. Please ensure you can run 'docker compose'."
    exit 1
fi
print_success "All dependencies are satisfied."

# 2. Check for .env file
print_info "Checking for .env configuration file..."
if [ ! -f .env ]; then
    print_warning "'.env' file not found."
    if [ -f .env.example ]; then
        cp .env.example .env
        print_error "A new '.env' file has been created from the example. Please fill in all the required values and run the script again."
    else
        print_error "'.env.example' is also missing. Cannot proceed without configuration."
    fi
    exit 1
fi
print_success "Configuration file '.env' found."

# 3. Create necessary data directories
print_info "Creating persistent data directories..."
mkdir -p ./data/traefik/letsencrypt
mkdir -p ./data/postgres
mkdir -p ./data/portainer
mkdir -p ./data/uptime-kuma
mkdir -p ./data/gitea
mkdir -p ./data/n8n
mkdir -p ./data/ollama
print_success "Data directories created successfully."

# 4. Launch Docker Compose
print_info "Starting all platform services via Docker Compose..."
print_info "This may take several minutes on the first run as images are downloaded."

docker compose up -d

if [ $? -eq 0 ]; then
    print_success "YemenJPT Platform has been started successfully!"
    echo -e "${C_CYAN}=====================================================${C_RESET}"
    echo -e "${C_CYAN}          🎉 Your platform is now live! 🎉          ${C_RESET}"
    echo -e "${C_CYAN}=====================================================${C_RESET}"
    
    # Read domain from .env to show helpful links
    DOMAIN=$(grep -E '^DOMAIN=' .env | cut -d '=' -f2 | tr -d '"')
    if [ -n "$DOMAIN" ]; then
        echo -e "You can access your services at the following URLs:"
        echo -e "  - ${C_GREEN}Main App:${C_RESET} https://$DOMAIN"
        echo -e "  - ${C_YELLOW}Access Portal:${C_RESET} https://portal.$DOMAIN"
        echo -e "  - ${C_YELLOW}System Admin:${C_RESET} https://sys.$DOMAIN"
        echo -e "  - ${C_YELLOW}Status Page:${C_RESET} https://status.$DOMAIN"
    fi
    
    echo -e "\nTo view logs, use: ${C_GREEN}docker compose logs -f <service_name>${C_RESET}"
    echo -e "To stop the platform, use: ${C_GREEN}docker compose down${C_RESET}"
else
    print_error "Failed to start the platform. Please check the Docker Compose logs for more details."
    print_error "Run 'docker compose logs' to see the error messages."
    exit 1
fi
