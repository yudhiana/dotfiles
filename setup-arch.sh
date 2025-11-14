#!/bin/bash

echo "===================================================================="
echo "                 SETUP SCRIPT FOR MANJARO ARCH "
echo "     NON-INTERACTIVE • READ FROM .env • FEED SUDO PASSWORD"
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

# Sudo password (required)
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

[ -z "$GITHUB_PAT" ] && { echo "ERROR: GITHUB_PAT missing"; exit 1; }
[ -z "$SSH_KEY_NAME" ] && { echo "ERROR: SSH_KEY_NAME missing"; exit 1; }
[ -z "$SUDO_PASSWORD" ] && { echo "ERROR: SUDO_PASSWORD missing"; exit 1; }

SUDO="echo \"$SUDO_PASSWORD\" | sudo -S"
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
$SUDO sed -i 's/#EnableAUR/EnableAUR/' /etc/pamac.conf

# ----------------------------------------------------------
# 3. Install GitHub CLI
# ----------------------------------------------------------
echo "[2/23] Checking GitHub CLI..."
if ! command -v gh &>/dev/null; then
    $SUDO pacman -Syu --noconfirm
    $SUDO pacman -S --noconfirm github-cli
else
    echo "→ GitHub CLI already installed."
fi

# ----------------------------------------------------------
# 4. GitHub login
# ----------------------------------------------------------
echo "[3/23] GitHub login..."
echo "$GITHUB_PAT" | gh auth login --with-token
echo "→ GitHub login OK."

# ----------------------------------------------------------
# 5. Generate SSH Key
# ----------------------------------------------------------
echo "[4/23] Generating SSH key..."
rm -f "$SSH_KEY" "$SSH_KEY.pub" || true
ssh-keygen -t ed25519 -C "$SSH_KEY_NAME" -f "$SSH_KEY" -N ""
echo "→ SSH key created."

# ----------------------------------------------------------
# 6. SSH Agent
# ----------------------------------------------------------
echo "[5/23] Starting ssh-agent..."
if ! pgrep -u "$USER" ssh-agent >/dev/null; then
    eval "$(ssh-agent -s)"
fi
ssh-add "$SSH_KEY"

# ----------------------------------------------------------
# 7. Upload SSH key to GitHub
# ----------------------------------------------------------
echo "[6/23] Uploading SSH key..."
gh ssh-key add "$SSH_KEY.pub" --title "$SSH_KEY_NAME" --type authentication

# ----------------------------------------------------------
# 8. Install Docker
# ----------------------------------------------------------
echo "[7/23] Installing Docker..."
$SUDO pacman -S --noconfirm docker

# ----------------------------------------------------------
# 9. Install Docker Compose plugin
# ----------------------------------------------------------
echo "[8/23] Installing Docker Compose..."
$SUDO pacman -S --noconfirm docker-compose || \
$SUDO pacman -S --noconfirm docker-compose-plugin

# ----------------------------------------------------------
# 10. Enable Docker service
# ----------------------------------------------------------
echo "[9/23] Enabling Docker..."
$SUDO systemctl enable docker
$SUDO systemctl start docker
$SUDO usermod -aG docker "$USER"

# ----------------------------------------------------------
# 11. Install GitAhead (AUR)
# ----------------------------------------------------------
echo "[10/23] Installing GitAhead..."
if ! command -v gitahead &>/dev/null; then
    $SUDO pamac install --no-confirm gitahead-bin
else
    echo "→ GitAhead already installed."
fi

# ----------------------------------------------------------
# 12. Install Beekeeper Studio (AUR)
# ----------------------------------------------------------
echo "[11/23] Installing Beekeeper Studio..."
if ! command -v beekeeper-studio &>/dev/null; then
    $SUDO pamac install --no-confirm beekeeper-studio-bin
else
    echo "→ Beekeeper Studio already installed."
fi

# ----------------------------------------------------------
# 13. Install DBeaver CE
# ----------------------------------------------------------
echo "[12/23] Installing DBeaver CE..."
if ! command -v dbeaver &>/dev/null; then
    $SUDO pacman -S --noconfirm dbeaver
else
    echo "→ DBeaver already installed."
fi

# ----------------------------------------------------------
# 14. Install Visual Studio Code (AUR)
# ----------------------------------------------------------
echo "[13/23] Installing VSCode..."
if ! command -v code &>/dev/null; then
    $SUDO pamac install --no-confirm visual-studio-code-bin
else
    echo "→ VSCode already installed."
fi

# ----------------------------------------------------------
# 15. Install Google Chrome (AUR)
# ----------------------------------------------------------
echo "[14/23] Installing Google Chrome..."
if ! command -v google-chrome &>/dev/null; then
    $SUDO pamac install --no-confirm google-chrome
else
    echo "→ Chrome already installed."
fi

# ----------------------------------------------------------
# 16. Install MongoDB Compass (AUR)
# ----------------------------------------------------------
echo "[15/23] Installing MongoDB Compass..."
if ! command -v mongodb-compass &>/dev/null; then
    $SUDO pamac install --no-confirm mongodb-compass
else
    echo "→ Compass already installed."
fi

# ----------------------------------------------------------
# 17. Install Postman (AUR)
# ----------------------------------------------------------
echo "[16/23] Installing Postman..."
if ! command -v postman &>/dev/null; then
    $SUDO pamac install --no-confirm postman-bin
else
    echo "→ Postman already installed."
fi

# ----------------------------------------------------------
# 18. Install Golang
# ----------------------------------------------------------
echo "[17/23] Installing Golang..."
if ! command -v go &>/dev/null; then
    $SUDO pacman -S --noconfirm go
else
    echo "→ Go already installed."
fi

# ----------------------------------------------------------
# 19. Install PostgreSQL Client (client-only)
# ----------------------------------------------------------
echo "[18/23] Installing PostgreSQL client..."
if ! command -v psql &>/dev/null; then
    $SUDO pacman -S --noconfirm postgresql-libs
else
    echo "→ PostgreSQL client already installed."
fi

# ----------------------------------------------------------
# 20. Install MariaDB/MySQL Client
# ----------------------------------------------------------
echo "[19/23] Installing MariaDB/MySQL client..."
if ! command -v mysql &>/dev/null; then
    $SUDO pacman -S --noconfirm mariadb-clients
else
    echo "→ MariaDB/MySQL client already installed."
fi

# ----------------------------------------------------------
# 21. Install Redis CLI
# ----------------------------------------------------------
echo "[20/23] Installing Redis client..."
if ! command -v redis-cli &>/dev/null; then
    $SUDO pacman -S --noconfirm redis
else
    echo "→ Redis client already installed."
fi

# ----------------------------------------------------------
# 22. Install MongoDB Shell (mongosh)
# ----------------------------------------------------------
echo "[21/23] Installing MongoDB Shell..."
if ! command -v mongosh &>/dev/null; then
    $SUDO pamac install --no-confirm mongosh-bin
else
    echo "→ mongosh already installed."
fi

# ----------------------------------------------------------
# 23. Install SQLite CLI
# ----------------------------------------------------------
echo "[22/23] Installing SQLite..."
if ! command -v sqlite3 &>/dev/null; then
    $SUDO pacman -S --noconfirm sqlite
else
    echo "→ SQLite already installed."
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
