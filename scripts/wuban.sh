#!/bin/bash

# Wuban: The Emergence Agent Skill Installer
# Usage: wuban install <github-url-or-slug>

VERSION="0.1.0"
SKILLS_DIR="$HOME/.openclaw/workspace/skills"
GITHUB_PREFIX="https://github.com/"
GITEE_PREFIX="https://gitee.com/"

show_help() {
    echo "Wuban v$VERSION - Emergence Agent Skill Installer"
    echo "Usage: wuban [command] [args]"
    echo ""
    echo "Commands:"
    echo "  install <slug>    Install a skill (e.g. emergence-science/skill-image-generation)"
    echo "                    Prefix with gitee: for Gitee (e.g. gitee:org/repo)"
    echo "  list              List installed skills"
    echo "  remove <name>     Uninstall a skill"
    echo "  update            Self-update the wuban script"
    echo "  version           Show version"
}

detect_sandbox() {
    OS=$(uname -s)
    echo "Detecting environment ($OS)..."
    
    if [[ "$OS" == "Darwin" ]] || [[ "$OS" == *"NT"* ]]; then
        # Check for venv or docker on Mac/Windows
        if [ -z "$VIRTUAL_ENV" ]; then
            if ! command -v docker >/dev/null 2>&1; then
                echo "Warning: No Python Virtual Environment or Docker detected on $OS."
                echo "Installing on the host OS is not recommended. Create a venv first!"
                read -p "Proceed anyway? (y/N) " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    exit 1
                fi
            else
                echo "Docker detected. Proceeding..."
            fi
        else
            echo "Python Virtual Environment detected. Proceeding..."
        fi
    elif [[ "$OS" == "Linux" ]]; then
        echo "Linux detected (Standard environment). Proceeding..."
    fi
}

install_skill() {
    local SLUG=$1
    if [ -z "$SLUG" ]; then
        echo "Error: Skill slug required."
        exit 1
    fi

    detect_sandbox

    # Handle Gitee vs GitHub vs Local
    if [[ "$SLUG" == gitee:* ]]; then
        URL_SLUG=${SLUG#gitee:}
        REPO_URL="${GITEE_PREFIX}${URL_SLUG}.git"
        REPO_NAME=$(basename "$URL_SLUG")
    elif [[ "$SLUG" == http* ]]; then
        REPO_URL="$SLUG"
        REPO_NAME=$(basename "$SLUG" .git)
    elif [[ "$SLUG" == /* ]] || [[ "$SLUG" == file://* ]]; then
        REPO_URL="${SLUG#file://}"
        REPO_NAME=$(basename "$REPO_URL")
    else
        REPO_URL="${GITHUB_PREFIX}${SLUG}.git"
        REPO_NAME=$(basename "$SLUG")
    fi

    TARGET_PATH="$SKILLS_DIR/$REPO_NAME"

    echo "Installing $REPO_NAME from $REPO_URL..."
    
    mkdir -p "$SKILLS_DIR"

    if [ -d "$TARGET_PATH" ]; then
        echo "Updating existing skill at $TARGET_PATH..."
        cd "$TARGET_PATH" && git pull
    else
        git clone "$REPO_URL" "$TARGET_PATH"
    fi

    if [ $? -ne 0 ]; then
        echo "Error: Failed to clone repository."
        exit 1
    fi

    # Check for metadata
    if [ ! -f "$TARGET_PATH/metadata.json" ]; then
        echo "Warning: No metadata.json found in skill repository."
    fi

    # Run install script if available
    if [ -f "$TARGET_PATH/install.sh" ]; then
        echo "Running installation script for $REPO_NAME..."
        chmod +x "$TARGET_PATH/install.sh"
        (cd "$TARGET_PATH" && ./install.sh)
    fi

    # Python dependencies
    if [ -f "$TARGET_PATH/requirements.txt" ]; then
        echo "Installing Python dependencies..."
        pip install -r "$TARGET_PATH/requirements.txt" --quiet
    fi

    # Node dependencies
    if [ -f "$TARGET_PATH/package.json" ]; then
        echo "Installing Node.js dependencies..."
        (cd "$TARGET_PATH" && npm install --silent)
    fi

    echo "Successfully installed $REPO_NAME to $TARGET_PATH"
}

list_skills() {
    if [ ! -d "$SKILLS_DIR" ]; then
        echo "No skills installed."
        exit 0
    fi
    echo "Installed Emergence Skills:"
    ls -1 "$SKILLS_DIR"
}

case "$1" in
    install)
        install_skill "$2"
        ;;
    list)
        list_skills
        ;;
    update)
        echo "Updating wuban..."
        curl -sL https://emergence.science/scripts/wuban.sh -o wuban
        chmod +x wuban
        echo "Update complete."
        ;;
    version)
        echo "Wuban v$VERSION"
        ;;
    *)
        show_help
        ;;
esac
