#!/bin/bash

set -e

# Determine the user's home directory accurately
USER_HOME=$(getent passwd $USER | cut -d: -f6)

# Load environment variables from .env file
ENV_FILE="$USER_HOME/.env"
if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs)
else
    echo "Error: .env file not found at $ENV_FILE."
    echo "Please ensure the .env file exists and try again."
    exit 1
fi

# Validate required environment variables
if [ -z "$GITHUB_USERNAME" ] || [ -z "$GITHUB_EMAIL" ] || [ -z "$GITHUB_TOKEN" ] || [ -z "$POSTGRES_PASSWORD" ]; then
    echo "Error: Missing required environment variables."
    echo "Make sure to provide GITHUB_USERNAME, GITHUB_EMAIL, and GITHUB_TOKEN in the .env file."
    exit 1
fi

# Install dependencies for pyenv and Python build
sudo apt update && sudo apt upgrade -y

sudo apt install -y git gcc make build-essential zsh libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev \
    htop software-properties-common libpq-dev \

# install chromium
sudo snap install chromium
sudo snap install gitkraken --classic

# Set up Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
ZSH_CUSTOM="$USER_HOME/.oh-my-zsh/custom"
git clone https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k

# Install Zsh plugins
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions

# Replace the default theme with Powerlevel10k
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' $USER_HOME/.zshrc

# Configure plugins
sed -i 's/plugins=(git)/plugins=(git zsh-syntax-highlighting zsh-autosuggestions nvm gh poetry)/' $USER_HOME/.zshrc

# Enable auto correction
sed -i 's/# ENABLE_CORRECTION="true"/ENABLE_CORRECTION="true"/' $USER_HOME/.zshrc

# Enable completion waiting dots and make them pink
sed -i 's/# COMPLETION_WAITING_DOTS="true"/COMPLETION_WAITING_DOTS="%F{magenta}…%f"/' $USER_HOME/.zshrc

# Powerlevel10k configuration
# cat <<EOL >> $USER_HOME/.p10k.zsh
# # Powerlevel10k configuration with dark purple/pink theme
# POWERLEVEL9K_PROMPT_ON_NEWLINE=true
# POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=">"
# POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="❯ "
# POWERLEVEL9K_BACKGROUND="235"
# POWERLEVEL9K_FOREGROUND="white"
# POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context dir vcs)
# POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time)
# POWERLEVEL9K_COLOR_SCHEME='dark-pink-purple'
# EOL


# Configure Git
git config --global user.name "$GITHUB_USERNAME"
git config --global user.email "$GITHUB_EMAIL"
git config --global credential.helper store

# Set up GitHub credentials
cat <<EOL >> $USER_HOME/.git-credentials
https://$GITHUB_USERNAME:$GITHUB_TOKEN@github.com
EOL

# Persist environment variables in ~/.zshrc
cat <<EOL >> $USER_HOME/.zshrc

# Load environment variables from .env file
if [ -f "~/.env" ]; then
    export \$(grep -v '^#' "~/.env" | xargs)
fi
EOL

# Persist environment variables in ~/.bashrc
cat <<EOL >> $USER_HOME/.bashrc

# Load environment variables from .env file
if [ -f "~/.env" ]; then
    export \$(grep -v '^#' "~/.env" | xargs)
fi
EOL

# Install Homebrew
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> $USER_HOME/.profile
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> $USER_HOME/.bash_profile
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> $USER_HOME/.bashrc
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> $USER_HOME/.zprofile
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> $USER_HOME/.zshrc

source $USER_HOME/.bashrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

brew update
brew install gcc

# Install PostGreSQL and pgvector extension
brew install postgresql@14
brew install pgvector

# Insert manual database start into shell
PG_BIN_PATH=$(brew --prefix)/opt/postgresql@14/bin
PG_LOG_FILE=/home/linuxbrew/.linuxbrew/var/postgresql@14/server-stdout.log
PG_DATA_DIR=/home/linuxbrew/.linuxbrew/var/postgresql@14
if [ ! -x "$PG_BIN_PATH/createdb" ] || [ ! -x "$PG_BIN_PATH/psql" ] || [ ! -x "$PG_BIN_PATH/pg_ctl" ]; then
  echo "PostgreSQL binaries not found. Installation may have failed."
  exit 1
fi

start_postgres_lines=$(cat <<EOF

# Check if PostgreSQL is running; if not, start it
if ! $PG_BIN_PATH/pg_ctl -D $PG_DATA_DIR status > /dev/null 2>&1; then
  echo "Starting PostgreSQL..."
  $PG_BIN_PATH/pg_ctl -D $PG_DATA_DIR start -l $PG_LOG_FILE
fi

EOF
)
echo "$start_postgres_lines" >> ~/.bashrc
echo "$start_postgres_lines" >> ~/.zshrc
echo "$start_postgres_lines" >> ~/.bash_profile
echo "$start_postgres_lines" >> ~/.zprofile
echo "$start_postgres_lines" >> ~/.profile

# Reload profile
source $USER_HOME/.bashrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Force start the database
$PG_BIN_PATH/pg_ctl -D $PG_DATA_DIR start -l $PG_LOG_FILE

# sleep to allow the database to start
sleep 2

# Note: The default of the server is to use the current username
$PG_BIN_PATH/psql -d postgres -c "CREATE USER postgres WITH SUPERUSER CREATEDB CREATEROLE REPLICATION BYPASSRLS PASSWORD '$POSTGRES_PASSWORD';"
export PGPASSWORD=$POSTGRES_PASSWORD
$PG_BIN_PATH/createdb -U postgres opengpts
# Create the pg vector extension if needed
$PG_BIN_PATH/psql -U postgres -d opengpts -c "CREATE EXTENSION IF NOT EXISTS vector;"

# Install pyenv
brew install openssl readline sqlite3 xz zlib tcl-tk
brew install pyenv

# Add pyenv to the shell startup files for bash
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> $USER_HOME/.bashrc
echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> $USER_HOME/.bashrc
echo 'eval "$(pyenv init -)"' >> $USER_HOME/.bashrc

echo 'export PYENV_ROOT="$HOME/.pyenv"' >> $USER_HOME/.profile
echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> $USER_HOME/.profile
echo 'eval "$(pyenv init -)"' >> $USER_HOME/.profile

echo 'export PYENV_ROOT="$HOME/.pyenv"' >> $USER_HOME/.bash_profile
echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> $USER_HOME/.bash_profile
echo 'eval "$(pyenv init -)"' >> $USER_HOME/.bash_profile

# Add pyenv to the shell startup files for zsh
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> $USER_HOME/.zshrc
echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> $USER_HOME/.zshrc
echo 'eval "$(pyenv init -)"' >> $USER_HOME/.zshrc

echo 'export PYENV_ROOT="$HOME/.pyenv"' >> $USER_HOME/.zprofile
echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> $USER_HOME/.zprofile
echo 'eval "$(pyenv init -)"' >> $USER_HOME/.zprofile

# Reload the shell
source $USER_HOME/.bashrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Install Python 3.11 using pyenv
pyenv install 3.11
pyenv global 3.11

# Install pyenv-virtualenv
brew install pyenv-virtualenv
echo 'eval "$(pyenv virtualenv-init -)"' >> $USER_HOME/.bashrc
echo 'eval "$(pyenv virtualenv-init -)"' >> $USER_HOME/.zshrc

# Install Poetry
pyenv exec pip install poetry

# Install Node.js via NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | /bin/bash
# Note: zsh uses plugins for completions
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
nvm install 20

# Install other tools
brew install unzip
brew install dos2unix

# Install rcc
curl -o rcc https://downloads.robocorp.com/rcc/releases/latest/linux64/rcc
chmod a+x rcc
sudo mv rcc /usr/local/bin
# Set zsh completions for rcc
echo "autoload -U compinit; compinit" >> ~/.zshrc
rcc completion zsh > "${fpath[1]}/_rcc"

# Configure other settings in .zshrc
cat <<EOL >> $USER_HOME/.zshrc
HISTSIZE=10000
SAVEHIST=10000
EOL

# Set the default shell to Zsh, which will end the script
chsh -s $(which zsh)
