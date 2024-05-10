#!/bin/bash

# Function to ask for user input and set environment variables
read_var() {
    local prompt=$1
    local varname=$2
    local default_value=$3

    read -p "$prompt [$default_value]: " input_value
    export $varname="${input_value:-$default_value}"
}

# Prompt for user credentials and environment settings
read_var "Enter root password" "ROOT_PASSWORD" "default_root_password"
read_var "Enter your GitHub username" "GITHUB_USERNAME" "your_github_username"
read_var "Enter your GitHub email" "GITHUB_EMAIL" "your_email@example.com"
read_var "Enter your GitHub Personal Access Token" "GITHUB_TOKEN" "your_github_token"

# Create a new password for the root user
echo "root:$ROOT_PASSWORD" | sudo chpasswd

# Update and upgrade the system
sudo apt update && sudo apt upgrade -y

# Install essential tools
sudo apt install -y \
    build-essential \
    curl \
    wget \
    git \
    zsh \
    htop \
    python-is-python3 \
    python3.11 \
    python3.11-venv \
    python3.11-dev \
    software-properties-common \
    libpq-dev \
    postgresql \
    postgresql-contrib \
    postgresql-server-dev-all

# Set up Zsh as the default shell
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k
chsh -s $(which zsh)

# Install Zsh plugins
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions

# Configure .zshrc with Powerlevel10k and plugins
cat <<EOL >> ~/.zshrc
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-syntax-highlighting zsh-autosuggestions)
source $ZSH/oh-my-zsh.sh
EOL

# Powerlevel10k configuration
cat <<'EOL' >> ~/.p10k.zsh
# Powerlevel10k configuration with dark purple/pink theme
POWERLEVEL9K_PROMPT_ON_NEWLINE=true
POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=">"
POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="❯ "
POWERLEVEL9K_BACKGROUND="235"
POWERLEVEL9K_FOREGROUND="white"
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context dir vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time)
POWERLEVEL9K_COLOR_SCHEME='dark-pink-purple'
EOL

# Apply changes
source ~/.zshrc

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.profile
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Install Python environment management tools
brew install pyenv
brew install poetry

# Set up Python 3.11 environment
pyenv install 3.11.0
pyenv global 3.11.0

# Install golang-migrate via Homebrew
brew install golang-migrate

# Install NVM and Node.js
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
nvm install node

# Install and configure PostgreSQL
sudo service postgresql start
sudo -u postgres psql -c "CREATE USER $USER WITH SUPERUSER PASSWORD '$ROOT_PASSWORD';"
sudo -u postgres createdb opengpts
sudo -u postgres psql -c "CREATE EXTENSION IF NOT EXISTS vector;"

# Configure Git
git config --global user.name "$GITHUB_USERNAME"
git config --global user.email "$GITHUB_EMAIL"
git config --global credential.helper store

# Set up GitHub credentials
cat <<EOL >> ~/.git-credentials
https://$GITHUB_USERNAME:$GITHUB_TOKEN@github.com
EOL

# Final message
echo "Bootstrap script complete! You may need to restart your terminal for all changes to take effect."

