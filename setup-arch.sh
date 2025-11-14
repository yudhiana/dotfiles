#!/bin/bash

echo "===================================================================="
echo "                 SETUP SCRIPT FOR MANJARO ARCH "
echo "  NON-INTERACTIVE • READ FROM .env • FEED SUDO PASSWORD"
echo "===================================================================="
echo ""

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

# Sudo password (required for non-interactive sudo)
SUDO_PASSWORD=
EOF

    echo ""
    echo "Default .env created."
    echo "Fill GITHUB_PAT, SSH_KEY_NAME, and SUDO_PASSWORD before re-running."
    exit 1
fi

# ----------------------------------------------------------
# 1. Load .env
# ----------------------------------------------------------
echo "Loading .env variables..."
source "$ENV_FILE"

[ -z "$GITHUB_PAT" ] && { echo "ERROR: GITHUB_PAT missing in .env"; exit 1; }
[ -z "$SSH_KEY_NAME" ] && { echo "ERROR: SSH_KEY_NAME missing in .env"; exit 1; }
[ -z "$SUDO_PASSWORD" ] && { echo "ERROR: SUDO_PASSWORD missing in .env"; exit 1; }

SUDO="echo \"$SUDO_PASSWORD\" | sudo -S"
SSH_KEY="$HOME/.ssh/${SSH_KEY_NAME}_id_ed25519"

# ----------------------------------------------------------
# 2. Install GitHub CLI
# ----------------------------------------------------------
echo "[1/22] Checking GitHub CLI..."
if ! command -v gh &> /dev/null; then
    $SUDO pacman -Syu --noconfirm
    $SUDO pacman -S --noconfirm github-cli
else
    echo "→ GitHub CLI already installed."
fi

# ----------------------------------------------------------
# 3. GitHub login
# ----------------------------------------------------------
echo "[2/22] Logging in to GitHub using PAT..."
echo "$GITHUB_PAT" | gh auth login --with-token
echo "→ GitHub login OK."

# ----------------------------------------------------------
# 4. Generate SSH key
# ----------------------------------------------------------
echo "[3/22] Generating SSH key: $SSH_KEY_NAME"
rm -f "$SSH_KEY" "$SSH_KEY.pub" 2>/dev/null || true
ssh-keygen -t ed25519 -C "$SSH_KEY_NAME" -f "$SSH_KEY" -N ""
echo "→ SSH key created."

# ----------------------------------------------------------
# 5. SSH agent
# ----------------------------------------------------------
echo "[4/22] Starting ssh-agent..."
if ! pgrep -u "$USER" ssh-agent >/dev/null; then
    eval "$(ssh-agent -s)"
fi
ssh-add "$SSH_KEY"
echo "→ SSH key loaded."

# ----------------------------------------------------------
# 6. Upload SSH key
# ----------------------------------------------------------
echo "[5/22] Uploading key to GitHub..."
gh ssh-key add "$SSH_KEY.pub" --title "$SSH_KEY_NAME" --type authentication
echo "→ Key uploaded."

# ----------------------------------------------------------
# 7. Install Docker
# ----------------------------------------------------------
echo "[6/22] Installing Docker..."
$SUDO pacman -S --noconfirm docker
echo "→ Docker installed."

# ----------------------------------------------------------
# 8. Install Docker Compose
# ----------------------------------------------------------
echo "[7/22] Installing Docker Compose..."
$SUDO pacman -S --noconfirm docker-compose || \
$SUDO pacman -S --noconfirm docker-compose-plugin
echo "→ Docker Compose installed."

# ----------------------------------------------------------
# 9. Enable Docker + add group
# ----------------------------------------------------------
echo "[8/22] Enabling Docker service..."
$SUDO systemctl enable docker
$SUDO systemctl start docker
$SUDO usermod -aG docker "$USER"
echo "→ Docker running."

# ----------------------------------------------------------
# 10. Install GitAhead (AUR)
# ----------------------------------------------------------
echo "[9/22] Installing GitAhead..."
if ! command -v gitahead &>/dev/null; then
    $SUDO pamac update --no-confirm || true
    $SUDO pamac install --no-confirm gitahead-bin
else
    echo "→ GitAhead installed."
fi

# ----------------------------------------------------------
# 11. Install Beekeeper Studio (AUR)
# ----------------------------------------------------------
echo "[10/22] Installing Beekeeper Studio..."
if ! command -v beekeeper-studio &>/dev/null; then
    $SUDO pamac install --no-confirm beekeeper-studio-bin
else
    echo "→ Beekeeper Studio installed."
fi

# ----------------------------------------------------------
# 12. Install DBeaver CE
# ----------------------------------------------------------
echo "[11/22] Installing DBeaver CE..."
if ! command -v dbeaver &>/dev/null; then
    $SUDO pacman -S --noconfirm dbeaver
else
    echo "→ DBeaver installed."
fi

# ----------------------------------------------------------
# 13. Install VSCode (AUR)
# ----------------------------------------------------------
echo "[12/22] Installing Visual Studio Code..."
if ! command -v code &>/dev/null; then
    $SUDO pamac install --no-confirm visual-studio-code-bin
else
    echo "→ VSCode installed."
fi

# ----------------------------------------------------------
# 14. Install Google Chrome (AUR)
# ----------------------------------------------------------
echo "[13/22] Installing Google Chrome..."
if ! command -v google-chrome &>/dev/null; then
    $SUDO pamac install --no-confirm google-chrome
else
    echo "→ Google Chrome installed."
fi

# ----------------------------------------------------------
# 15. Install MongoDB Compass (AUR)
# ----------------------------------------------------------
echo "[14/22] Installing MongoDB Compass..."
if ! command -v mongodb-compass &>/dev/null; then
    $SUDO pamac install --no-confirm mongodb-compass
else
    echo "→ MongoDB Compass installed."
fi

# ----------------------------------------------------------
# 16. Install Postman (AUR)
# ----------------------------------------------------------
echo "[15/22] Installing Postman..."
if ! command -v postman &>/dev/null; then
    $SUDO pamac install --no-confirm postman-bin
else
    echo "→ Postman installed."
fi


# ----------------------------------------------------------
# 17. Install Golang
# ----------------------------------------------------------
echo "[16/22] Installing Golang..."
if ! command -v go &>/dev/null; then
    $SUDO pacman -S --noconfirm go
else
    echo "→ Go already installed."
fi


# ----------------------------------------------------------
# 17. Install PostgreSQL Client
# ----------------------------------------------------------
echo "[17/22] Installing PostgreSQL client..."
if ! command -v psql &>/dev/null; then
    $SUDO pacman -S --noconfirm postgresql
else
    echo "→ PostgreSQL client already installed."
fi

# ----------------------------------------------------------
# 18. Install MariaDB/MySQL Client
# ----------------------------------------------------------
echo "[18/22] Installing MariaDB/MySQL client..."
if ! command -v mysql &>/dev/null; then
    $SUDO pacman -S --noconfirm mariadb-clients
else
    echo "→ MariaDB/MySQL client already installed."
fi

# ----------------------------------------------------------
# 19. Install Redis CLI
# ----------------------------------------------------------
echo "[19/22] Installing Redis client..."
if ! command -v redis-cli &>/dev/null; then
    $SUDO pacman -S --noconfirm redis
else
    echo "→ Redis client already installed."
fi

# ----------------------------------------------------------
# 20. Install MongoDB Shell (mongosh)
# ----------------------------------------------------------
echo "[20/22] Installing MongoDB Shell (mongosh)..."
if ! command -v mongosh &>/dev/null; then
    $SUDO pamac install --no-confirm mongosh-bin
else
    echo "→ mongosh already installed."
fi

# ----------------------------------------------------------
# 21. Install SQLite CLI
# ----------------------------------------------------------
echo "[21/22] Installing SQLite tools..."
if ! command -v sqlite3 &>/dev/null; then
    $SUDO pacman -S --noconfirm sqlite
else
    echo "→ SQLite already installed."
fi


echo ""
echo "===================================================================="
echo " 🎉 SETUP COMPLETE!"
echo " SSH Key Name:             $SSH_KEY_NAME"
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
echo "   - PostgreSQL"
echo "   - MariaDB/MySQL"
echo "   - Redis"
echo "   - MongoDB Shell (mongosh)"
echo "   - SQLite CLI"
echo "===================================================================="
echo " 🔁 Logout/login required for Docker group"
echo "===================================================================="
