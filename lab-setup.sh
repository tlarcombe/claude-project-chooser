#!/bin/bash
# Lab machine setup for claude+
# Run with: sudo bash /path/to/lab-setup.sh
# After NAS is accessible at /mnt/raid0

set -euo pipefail

NAS=/mnt/raid0
USER=tlarcombe
HOME_DIR=/home/$USER

echo "=== claude+ lab setup on $(hostname) ==="

# ── 1. Install missing packages ───────────────────────────────────────────────
install_pkg() {
    local pkg=$1
    if command -v "$pkg" &>/dev/null; then
        echo "  $pkg: already installed"
    else
        echo "  Installing $pkg..."
        if command -v pacman &>/dev/null; then
            pacman -S --noconfirm "$pkg"
        elif command -v apt-get &>/dev/null; then
            apt-get install -y "$pkg"
        else
            echo "  WARNING: unknown package manager, install $pkg manually"
        fi
    fi
}

install_pkg fzf
install_pkg tmux

# ── 2. Mount NAS if not already ───────────────────────────────────────────────
if ! mountpoint -q $NAS 2>/dev/null; then
    echo "  Mounting NAS..."
    mkdir -p $NAS
    # Try fstab first
    mount $NAS 2>/dev/null || \
    mount -t nfs 192.168.1.8:/mnt/raid0/shares $NAS
fi
echo "  NAS: $(mountpoint -q $NAS && echo mounted || echo FAILED)"

# ── 3. Bind-mount ~/projects → NAS/projects ──────────────────────────────────
if ! mountpoint -q "$HOME_DIR/projects" 2>/dev/null; then
    echo "  Setting up ~/projects bind mount..."
    # Back up if it has local content
    if [ -d "$HOME_DIR/projects" ] && [ "$(ls -A $HOME_DIR/projects 2>/dev/null)" ]; then
        mv "$HOME_DIR/projects" "$HOME_DIR/projects.bak.$(date +%s)"
    fi
    mkdir -p "$HOME_DIR/projects"
    mount --bind "$NAS/projects" "$HOME_DIR/projects"
fi
echo "  ~/projects: $(mountpoint -q $HOME_DIR/projects && echo mounted || echo FAILED)"

# ── 4. Bind-mount ~/.claude/projects → NAS/claude-sessions ───────────────────
mkdir -p "$HOME_DIR/.claude"
if ! mountpoint -q "$HOME_DIR/.claude/projects" 2>/dev/null; then
    echo "  Setting up ~/.claude/projects bind mount..."
    mkdir -p "$HOME_DIR/.claude/projects"
    mount --bind "$NAS/claude-sessions" "$HOME_DIR/.claude/projects"
fi
echo "  ~/.claude/projects: $(mountpoint -q $HOME_DIR/.claude/projects && echo mounted || echo FAILED)"

# ── 5. Persist mounts in fstab ───────────────────────────────────────────────
add_fstab() {
    local line=$1
    if ! grep -qF "$line" /etc/fstab; then
        echo "$line" >> /etc/fstab
        echo "  Added to fstab: $line"
    else
        echo "  fstab already has: $line"
    fi
}

# NAS fstab (if not already there)
add_fstab "192.168.1.8:/mnt/raid0/shares $NAS nfs defaults,_netdev 0 0"
add_fstab "$NAS/projects $HOME_DIR/projects none bind 0 0"
add_fstab "$NAS/claude-sessions $HOME_DIR/.claude/projects none bind 0 0"

systemctl daemon-reload

# ── 6. claude binary (from NAS) ───────────────────────────────────────────────
if ! command -v claude &>/dev/null; then
    echo "  Setting up claude from NAS..."
    mkdir -p "$HOME_DIR/.local/bin"
    ln -sf "$NAS/home/tlarcombe/.local/share/claude/versions/2.1.45" \
           "$HOME_DIR/.local/bin/claude"
    chown "$USER:$USER" "$HOME_DIR/.local/bin/claude"
fi
echo "  claude: $(command -v claude || echo 'needs PATH reload')"

echo ""
echo "=== Done! Now run as $USER (not sudo): ==="
echo "  setup-user"
echo ""
echo "Or manually:"
echo "  mkdir -p ~/.local/bin"
echo "  ln -sf $NAS/home/tlarcombe/.local/bin/claude+ ~/.local/bin/claude+"
echo "  cp $NAS/projects/claude-project_chooser/.tmux.conf ~/.tmux.conf"
echo "  grep -q '.local/bin' ~/.zshrc || echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.zshrc"
echo "  grep -q '.local/bin' ~/.bashrc || echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc"
