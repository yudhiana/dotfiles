#!/bin/bash

echo "===================================================================="
echo "                      UBUNTU DEV MACHINE SETUP"
echo "  NON-INTERACTIVE • .env SUPPORT • AUTOMATED • VERIFIED 2025"
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
SSH_KEY_NAME=my-ubuntu-ssh-key

# Sudo password (required)
SUDO_PASSWORD=
EOF

    echo ""
    echo "Default .env created. Fill variables then rerun."
    exit 1
fi

# ----------------------------------------------------------
# 1. Load environment variables
# ----------------------------------------------------------
echo "Loading .env variables..."
source "$ENV_FILE"

[ -z "$GITHUB_PAT" ] && { echo "ERROR: GITHUB_PAT missing"; exit 1; }
[ -z "$SSH_KEY_NAME" ] && { echo "ERROR: SSH_KEY_NAME missing"; exit 1; }
[ -z "$SUDO_PASSWORD" ] && { echo "ERROR: SUDO_PASSWORD missing"; exit 1; }

SUDO="echo \"$SUDO_PASSWORD\" | sudo -S"
SSH_KEY="$HOME/.ssh/${SSH_KEY_NAME}_id_ed25519"

# ----------------------------------------------------------
# 2. Update system
# ----------------------------------------------------------
echo "[1/28] Updating system..."
$SUDO apt update -y
$SUDO apt upgrade -y

# ----------------------------------------------------------
# 3. Install prerequisites
# ----------------------------------------------------------
echo "[2/28] Installing prerequisites..."
$SUDO apt install -y curl wget gnupg lsb-release ca-certificates apt-transport-https software-properties-common

# ----------------------------------------------------------
# 4. Install GitHub CLI
# ----------------------------------------------------------
echo "[3/28] Installing GitHub CLI..."
if ! command -v gh >/dev/null 2>&1; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | $SUDO tee /usr/share/keyrings/githubcli-archive-keyring.gpg >/dev/null

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
    https://cli.github.com/packages stable main" \
        | $SUDO tee /etc/apt/sources.list.d/github-cli.list >/dev/null

    $SUDO apt update -y
    $SUDO apt install -y gh
else
    echo "→ GitHub CLI already installed."
fi

# ----------------------------------------------------------
# 5. GitHub login
# ----------------------------------------------------------
echo "[4/28] Logging in to GitHub..."
echo "$GITHUB_PAT" | gh auth login --with-token

# ----------------------------------------------------------
# 6. Generate SSH key
# ----------------------------------------------------------
echo "[5/28] Generating SSH key..."
rm -f "$SSH_KEY" "$SSH_KEY.pub" || true
ssh-keygen -t ed25519 -C "$SSH_KEY_NAME" -f "$SSH_KEY" -N ""

eval "$(ssh-agent -s)"
ssh-add "$SSH_KEY"

echo "[6/28] Uploading SSH key to GitHub..."
gh ssh-key add "$SSH_KEY.pub" --title "$SSH_KEY_NAME"

# ----------------------------------------------------------
# 7. Install Docker
# ----------------------------------------------------------
echo "[7/28] Installing Docker..."
$SUDO apt remove -y docker docker-engine docker.io containerd runc || true

$SUDO mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    | $SUDO tee /etc/apt/sources.list.d/docker.list >/dev/null

$SUDO apt update -y
$SUDO apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

$SUDO usermod -aG docker "$USER"
echo "→ Docker installed."

# ----------------------------------------------------------
# 8. Install GitAhead
# ----------------------------------------------------------
echo "[8/28] Installing GitAhead..."
if ! command -v gitahead >/dev/null 2>&1; then
    wget -O /tmp/gitahead.deb https://github.com/gitahead/gitahead/releases/latest/download/GitAhead.deb
    $SUDO apt install -y /tmp/gitahead.deb
fi

# ----------------------------------------------------------
# 9. Install Beekeeper Studio
# ----------------------------------------------------------
echo "[9/28] Installing Beekeeper Studio..."
if ! command -v beekeeper-studio >/dev/null 2>&1; then
    wget -O /tmp/beekeeper.deb https://github.com/beekeeper-studio/beekeeper-studio/releases/latest/download/Beekeeper-Studio.deb
    $SUDO apt install -y /tmp/beekeeper.deb
fi

# ----------------------------------------------------------
# 10. Install DBeaver CE
# ----------------------------------------------------------
echo "[10/28] Installing DBeaver CE..."
$SUDO apt install -y dbeaver-ce

# ----------------------------------------------------------
# 11. Install Visual Studio Code
# ----------------------------------------------------------
echo "[11/28] Installing VSCode..."
if ! command -v code >/dev/null 2>&1; then
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
        | gpg --dearmor | $SUDO tee /usr/share/keyrings/ms-vscode.gpg >/dev/null

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ms-vscode.gpg] \
    https://packages.microsoft.com/repos/code stable main" \
        | $SUDO tee /etc/apt/sources.list.d/vscode.list >/dev/null

    $SUDO apt update -y
    $SUDO apt install -y code
fi

# ----------------------------------------------------------
# 12. Install Google Chrome
# ----------------------------------------------------------
echo "[12/28] Installing Google Chrome..."
if ! command -v google-chrome >/dev/null 2>&1; then
    wget -O /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    $SUDO apt install -y /tmp/chrome.deb
fi

# ----------------------------------------------------------
# 13. Install MongoDB Compass
# ----------------------------------------------------------
echo "[13/28] Installing MongoDB Compass..."
if ! command -v mongodb-compass >/dev/null 2>&1; then
    wget -O /tmp/compass.deb https://downloads.mongodb.com/compass/mongodb-compass_latest_amd64.deb
    $SUDO apt install -y /tmp/compass.deb
fi

# ----------------------------------------------------------
# 14. Install Postman
# ----------------------------------------------------------
echo "[14/28] Installing Postman..."
if ! command -v postman >/dev/null 2>&1; then
    wget -O /tmp/postman.tar.gz https://dl.pstmn.io/download/latest/linux64
    $SUDO tar -xzf /tmp/postman.tar.gz -C /opt
    $SUDO ln -sf /opt/Postman/Postman /usr/bin/postman
fi

# ----------------------------------------------------------
# 15. Install Golang
# ----------------------------------------------------------
echo "[15/28] Installing Golang..."
$SUDO apt install -y golang-go

# ----------------------------------------------------------
# 16. Install PostgreSQL Client
# ----------------------------------------------------------
echo "[16/28] Installing PostgreSQL Client..."
$SUDO apt install -y postgresql-client

# ----------------------------------------------------------
# 17. Install MariaDB/MySQL Client
# ----------------------------------------------------------
echo "[17/28] Installing MariaDB/MySQL Client..."
$SUDO apt install -y mariadb-client

# ----------------------------------------------------------
# 18. Install Redis CLI
# ----------------------------------------------------------
echo "[18/28] Installing Redis CLI..."
$SUDO apt install -y redis-tools

# ----------------------------------------------------------
# 19. Install SQLite
# ----------------------------------------------------------
echo "[19/28] Installing SQLite..."
$SUDO apt install -y sqlite3

# ----------------------------------------------------------
# 20. Install MongoDB Shell (mongosh)
# ----------------------------------------------------------
echo "[20/28] Installing MongoDB Shell..."
if ! command -v mongosh >/dev/null 2>&1; then
    wget -qO - https://pgp.mongodb.com/server-6.0.asc \
        | $SUDO tee /etc/apt/keyrings/mongodb-server-6.0.gpg >/dev/null

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/mongodb-server-6.0.gpg] \
    https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/6.0 multiverse" \
        | $SUDO tee /etc/apt/sources.list.d/mongodb-org-6.0.list >/dev/null

    $SUDO apt update -y
    $SUDO apt install -y mongodb-mongosh
fi

echo ""
echo "===================================================================="
echo " 🎉 UBUNTU SETUP COMPLETE!"
echo " Tools Installed:"
echo "   - Docker + Docker Compose + Buildx"
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
echo "   - Redis CLI"
echo "   - SQLite"
echo "   - MongoDB Shell (mongosh)"
echo "===================================================================="
echo " 🔁 Logout/login required for Docker group"
echo "===================================================================="
