# dotfiles
# 📘 Developer Machine Setup Scripts  
### Fully Automated • Ubuntu + Manjaro • Docker • GitHub • Dev Tools

This repository contains **production-ready, automated setup scripts** for preparing a complete developer environment on **Ubuntu** and **Manjaro/Arch Linux**.

Both scripts support:

| Feature | Supported | Details |
|--------|-----------|---------|
| Non-interactive installation | ✔ | Fully automated, no user prompts |
| `.env` configuration | ✔ | Stores GitHub PAT, SSH key name, sudo password |
| GitHub PAT login | ✔ | Authenticated login using `gh auth login --with-token` |
| SSH key generation | ✔ | Generates ED25519 key + auto uploads to GitHub |
| Core development tools | ✔ | VSCode, GitAhead, Beekeeper Studio, DBeaver, Postman |
| Docker environment | ✔ | Docker Engine, CLI, Buildx, Compose plugin |
| Database client tools | ✔ | PostgreSQL, MariaDB/MySQL, Redis, SQLite, mongosh |
| Productivity apps | ✔ | Chrome, Compass, Postman |
| Verified OS-specific packages | ✔ | Uses correct apt/pacman/pamac repositories |


---

# 📂 Repository Structure
```
    /
    ├── setup-ubuntu.sh        # Ubuntu automated setup script
    ├── setup-manjaro.sh       # Manjaro/Arch automated setup script
    └── README.md              # This documentation
```
---

# 🔐 Environment Variables (.env)
- GITHUB_PAT=your_github_personal_access_token
- SSH_KEY_NAME=your_ssh_key_name
- SUDO_PASSWORD=your_sudo_password


🚀 Features Installed on Both OS Versions
# 🔵 Developer Tools
- GitHub CLI (gh)
- SSH keys + GitHub upload
- Visual Studio Code
- GitAhead
- Beekeeper Studio
- DBeaver CE
- Postman
- Golang (Go)

# 🐳 Docker Environment
- Docker Engine
- Docker CLI
- Buildx plugin
- Docker Compose plugin
- User added to docker group

# 🧩 Database Tools
- PostgreSQL client
- MariaDB/MySQL client
- Redis CLI
- SQLite
- MongoDB Compass
- MongoDB Shell (mongosh)

# 🌐 Browsers
- Google Chrome (latest)