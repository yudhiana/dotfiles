#!/bin/bash

echo "===================================================================="
echo "                 SETUP SCRIPT FOR MANJARO ARCH "
echo "     NON-INTERACTIVE • READ FROM .env • FEED SUDO PASSWORD"
echo "===================================================================="
echo ""

# Ask for sudo once at start
sudo -v

set -e
set -o pipefail

ENV_FILE=".env"

# ----------------------------------------------------------
# 0. Create .env if missing
# ----------------------------------------------------------
if [ ! -f "$ENV_FILE" ]; then
    echo "Creating default .env file..."
    cat <<EOF > $ENV_FILE
# GitHub Personal Access Token (required)
GITHUB_PAT=

# SSH key name (required)
SSH_KEY_NAME=my-manjaro-ssh-key

EOF

    echo ""
    echo "Default .env created."
    echo "Fill GITHUB_PAT, SSH_KEY_NAME before re-running."
    exit 1
fi

# ----------------------------------------------------------
# 1. Load .env
# ----------------------------------------------------------
echo "Loading .env variables..."
source "$ENV_FILE"

[ -z "$GITHUB_PAT" ] && { echo "ERROR: GITHUB_PAT missing"; exit 1; }
[ -z "$SSH_KEY_NAME" ] && { echo "ERROR: SSH_KEY_NAME missing"; exit 1; }

SSH_KEY="$HOME/.ssh/${SSH_KEY_NAME}_id_ed25519"

# ----------------------------------------------------------
# 2. Validate pamac exists (AUR support)
# ----------------------------------------------------------
echo "[1/23] Checking pamac..."
if ! command -v pamac &>/dev/null; then
    echo "ERROR: pamac is not installed. Install using:"
    echo "sudo pacman -S --noconfirm pamac-cli pamac-gtk"
    exit 1
fi
echo "→ pamac OK."

# Ensure AUR enabled
sudo sed -i 's/#EnableAUR/EnableAUR/' /etc/pamac.conf

# ----------------------------------------------------------
# 3. Install GitHub CLI
# ----------------------------------------------------------
echo "[2/23] Checking GitHub CLI..."
if ! command -v gh &>/dev/null; then
    sudo pacman -Syu --noconfirm
    sudo pacman -S --noconfirm github-cli
else
    echo "→ GitHub CLI already installed."
fi

# ----------------------------------------------------------
# 4. GitHub login
# ----------------------------------------------------------
echo "[3/23] GitHub login..."
if gh auth status >/dev/null 2>&1; then
    echo "→ GH CLI already Logged in github"
else
    echo "starting to login"
    echo "$GITHUB_PAT" | gh auth login --with-token
    echo "→ GitHub login successfully."
    exit 1
fi

# ----------------------------------------------------------
# 5. Generate SSH Key
# ----------------------------------------------------------
echo "[4/23] Generating SSH key..."
# Check BEFORE generating or deleting
SKIP_SSH_SETUP=false
if [[ -f "$SSH_KEY" || -f "$SSH_KEY.pub" ]]; then
    echo "⚠  Existing SSH key found:"
    [[ -f "$SSH_KEY" ]] && echo "  - $SSH_KEY"
    [[ -f "$SSH_KEY.pub" ]] && echo "  - $SSH_KEY.pub"
    SKIP_SSH_SETUP=true
else
    ssh-keygen -t ed25519 -C "$SSH_KEY_NAME" -f "$SSH_KEY" -N ""
    echo "→ SSH key created."
fi

# ----------------------------------------------------------
# 6. SSH Agent
# ----------------------------------------------------------
echo "[5/23] Starting ssh-agent..."
if [ "$SKIP_SSH_SETUP" = false ]; then
    if ! pgrep -u "$USER" ssh-agent >/dev/null; then
        eval "$(ssh-agent -s)"
    fi
    
    ssh-add "$SSH_KEY"
else
    echo "→ ssh-agent skipped"
fi

# ----------------------------------------------------------
# 7. Upload SSH key to GitHub
# ----------------------------------------------------------
echo "[6/23] Uploading SSH key..."
if [ "$SKIP_SSH_SETUP" = false ]; then
    gh ssh-key add "$SSH_KEY.pub" --title "$SSH_KEY_NAME" --type authentication
else
    echo "→ uploading ssh-key skipped"
fi

# ----------------------------------------------------------
# 8. Install Docker
# ----------------------------------------------------------

echo "[7/23] Installing Docker..."
if docker --version >/dev/null 2>&1; then
    echo "→ docker install skipped"
else
    sudo pacman -S --noconfirm docker
    INSTALL_EXIT_CODE=$?

    # Chek instalation already successed
    if [ $INSTALL_EXIT_CODE -ne 0 ]; then
        echo "docker instalation failure."
        exit 1
    fi 
fi

# ----------------------------------------------------------
# 9. Install Docker Compose plugin
# ----------------------------------------------------------
echo "[8/23] Installing Docker Compose..."
if docker compose version >/dev/null 2>&1; then
    echo "→ docker compose install skipped"
else
   sudo pacman -S --noconfirm docker-compose || \
   sudo pacman -S --noconfirm docker-compose-plugin
   INSTALL_EXIT_CODE=$?

    # Chek instalation already successed
    if [ $INSTALL_EXIT_CODE -ne 0 ]; then
        echo "docker compose instalation failure."
        exit 1
    fi 
fi

# ----------------------------------------------------------
# 10. Enable Docker service
# ----------------------------------------------------------
echo "[9/23] Enabling Docker..."
if systemctl is-enabled --quiet docker; then
    echo "→ Docker service already enabled."
else
    
    # Enable Docker service
    sudo systemctl enable --now docker
    
    # Check enabled succesfully
    if systemctl is-enabled --quiet docker; then
        echo "→ Docker service successfully enabled."
    else
        echo "→ Docker service failed enable process"
        exit 1
    fi
fi

# ----------------------------------------------------------
# 11. Install Ferdium (Flatpak)
# ----------------------------------------------------------
echo "[10/23] Installing Ferdium..."
if ! flatpak list | grep -q 'org.ferdium.Ferdium'; then
    echo "→ Ferdium not installed. Installing..."
    sudo flatpak install --assumeyes flathub org.ferdium.Ferdium
    if flatpak list | grep -q 'org.ferdium.Ferdium'; then
        echo "→ Ferdium successfully installed."
    else
        echo "→ Failed to install Ferdium."
        exit 1
    fi
else
    echo "→ Ferdium already installed."
fi

# ----------------------------------------------------------
# 12. Install Beekeeper Studio (AUR)
# ----------------------------------------------------------
if ! pacman -Q beekeeper-studio-bin &>/dev/null; then
    echo "→ Beekeeper Studio not installed. Installing..."
    sudo pamac install --no-confirm beekeeper-studio-bin
    if pacman -Q beekeeper-studio-bin &>/dev/null; then
        echo "→ Beekeeper Studio successfully installed."
    else
        echo "→ Failed to install Beekeeper Studio."
        exit 1
    fi
else
    echo "→ Beekeeper Studio already installed."
fi


# ----------------------------------------------------------
# 13. Install DBeaver CE
# ----------------------------------------------------------
echo "[12/23] Installing DBeaver CE..."
if ! command -v dbeaver &>/dev/null; then
    sudo pacman -S --noconfirm dbeaver
    if command -v dbeaver &>/dev/null; then
        echo "→ DBeaver successfully installed."
    else
        echo "→ Failed to install DBeaver."
        exit 1
    fi
else
    echo "→ DBeaver already installed."
fi

# ----------------------------------------------------------
# 14. Install Visual Studio Code (AUR)
# ----------------------------------------------------------
echo "[13/23] Installing VSCode..."
if ! command -v code &>/dev/null; then
    sudo pamac install --no-confirm visual-studio-code-bin
    if command -v code &>/dev/null; then
        echo "→ Visual Studio Code successfully installed."
    else
        echo "→ Failed to install Visual Studio Code."
        exit 1
    fi
else
    echo "→ VSCode already installed."
fi

# ----------------------------------------------------------
# 15. Install Google Chrome (AUR)
# ----------------------------------------------------------
echo "[14/23] Installing Google Chrome..."
if ! command -v google-chrome-stable &>/dev/null; then
    sudo pamac install --no-confirm google-chrome
    if command -v google-chrome-stable &>/dev/null; then
        echo "→ Google Chrome successfully installed."
    else
        echo "→ Failed to install Google Chrome."
        exit 1
    fi
else
    echo "→ Google Chrome already installed."
fi

# ----------------------------------------------------------
# 16. Install MongoDB Compass (AUR)
# ----------------------------------------------------------
echo "[15/23] Installing MongoDB Compass..."
if ! command -v mongodb-compass &>/dev/null; then
    sudo pamac install --no-confirm mongodb-compass
    if command -v mongodb-compass &>/dev/null; then
        echo "→ MongoDB Compass successfully installed."
    else
        echo "→ Failed to install MongoDB Compass."
        exit 1
    fi
else
    echo "→ MongoDB Compass already installed."
fi

# ----------------------------------------------------------
# 17. Install Postman (AUR)
# ----------------------------------------------------------
echo "[16/23] Installing Postman..."
if ! command -v postman &>/dev/null; then
    sudo pamac install --no-confirm postman-bin
    if command -v postman &>/dev/null; then
        echo "→ Postman successfully installed."
    else
        echo "→ Failed to install Postman."
        exit 1
    fi
else
    echo "→ Postman already installed."
fi

# ----------------------------------------------------------
# 18. Install Golang
# ----------------------------------------------------------
echo "[17/23] Installing Golang..."
if ! command -v go &>/dev/null; then
    sudo pacman -S --noconfirm go
    if command -v go &>/dev/null; then
        echo "→ Go successfully installed."
    else
        echo "→ Failed to install Go."
        exit 1
    fi
else
    echo "→ Go already installed."
fi

# ----------------------------------------------------------
# 19. Install PostgreSQL Client (client-only)
# ----------------------------------------------------------
echo "[18/23] Installing PostgreSQL client..."
if ! command -v psql &>/dev/null; then
    sudo pacman -S --noconfirm postgresql-libs
    if command -v psql &>/dev/null; then
        echo "→ PostgreSQL client successfully installed."
    else
        echo "→ Failed to install PostgreSQL client."
        exit 1
    fi
else
    echo "→ PostgreSQL client already installed."
fi

# ----------------------------------------------------------
# 20. Install MariaDB/MySQL Client
# ----------------------------------------------------------
echo "[19/23] Installing MariaDB/MySQL client..."
if ! command -v mysql &>/dev/null; then
    sudo pacman -S --noconfirm mariadb-clients
    if command -v mysql &>/dev/null; then
        echo "→ MariaDB/MySQL client successfully installed."
    else
        echo "→ Failed to install MariaDB/MySQL client."
        exit 1
    fi
else
    echo "→ MariaDB/MySQL client already installed."
fi

# ----------------------------------------------------------
# 21. Install Redis CLI
# ----------------------------------------------------------
echo "[20/23] Installing Redis client..."
if ! command -v redis-cli &>/dev/null; then
    sudo pacman -S --noconfirm redis
    if command -v redis-cli &>/dev/null; then
        echo "→ Redis client successfully installed."
    else
        echo "→ Failed to install Redis client."
        exit 1
    fi
else
    echo "→ Redis client already installed."
fi

# ----------------------------------------------------------
# 22. Install MongoDB Shell (mongosh)
# ----------------------------------------------------------
echo "[21/23] Installing MongoDB Shell..."
if ! command -v mongosh &>/dev/null; then
    sudo pamac install --no-confirm mongosh-bin
    if command -v mongosh &>/dev/null; then
        echo "→ MongoDB Shell successfully installed."
    else
        echo "→ Failed to install MongoDB Shell."
        exit 1
    fi
else
    echo "→ MongoDB Shell already installed."
fi

# ----------------------------------------------------------
# 23. Install SQLite CLI
# ----------------------------------------------------------
echo "[22/23] Installing SQLite..."
if ! command -v sqlite3 &>/dev/null; then
    sudo pacman -S --noconfirm sqlite
    if command -v sqlite3 &>/dev/null; then
        echo "→ SQLite successfully installed."
    else
        echo "→ Failed to install SQLite."
        exit 1
    fi
else
    echo "→ SQLite already installed."
fi

# ----------------------------------------------------------
# 23. Install Flameshot
# ----------------------------------------------------------
echo "[23/23] Installing Flameshot..."
if ! flatpak list | grep -q 'org.flameshot.Flameshot'; then
    echo "→ Flameshot not installed. Installing..."
    sudo flatpak install --assumeyes flathub org.flameshot.Flameshot
    if flatpak list | grep -q 'org.flameshot.Flameshot'; then
        echo "→ Flameshot successfully installed."
    else
        echo "→ Failed to install Flameshot."
        exit 1
    fi
else
    echo "→ Flameshot already installed."
fi

echo ""
echo "===================================================================="
echo " 🎉 SETUP COMPLETE!"
echo " Tools Installed:"
echo "   - Docker + Compose"
echo "   - GitAhead"
echo "   - Beekeeper Studio"
echo "   - DBeaver CE"
echo "   - Visual Studio Code"
echo "   - Google Chrome"
echo "   - MongoDB Compass"
echo "   - Postman"
echo "   - Golang"
echo "   - PostgreSQL Client"
echo "   - MariaDB/MySQL Client"
echo "   - Redis"
echo "   - MongoDB Shell"
echo "   - SQLite CLI"
echo "===================================================================="
echo " 🔁 Logout/login required for Docker group"
echo "===================================================================="
