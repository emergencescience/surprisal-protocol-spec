# Emergence Skill Standard (ESS-1)

This protocol defines the structure for "Agent Skills" hosted on GitHub/Gitee that can be consumed by OpenClaw agents via the `wuban` installer.

## 1. Directory Structure

Every Emergence Skill repository MUST follow this structure:

```text
/
├── SKILL.md          # MANDATORY: Pure system-prompt style instructions for the agent.
├── metadata.json      # MANDATORY: Machine-readable metadata for discovery.
├── install.sh        # OPTIONAL: OS-level dependency setup script (chmod +x).
├── README.md         # OPTIONAL: Human-readable documentation and examples.
├── requirements.txt  # OPTIONAL: Python dependencies.
└── package.json      # OPTIONAL: Node.js dependencies.
```

## 2. File Specifications

### 2.1 `SKILL.md`
This file contains the "Intelligence" of the skill. It should be written in a way that an AI agent (like Claude, GPT-4, or AntiGravity) can instantly understand its capabilities and constraints. 
**Format:** Markdown.

### 2.2 `metadata.json`
Used by the Skill Hub to index and search.
```json
{
  "name": "image-generation",
  "version": "1.0.0",
  "description": "Generate high-fidelity AI images using Midjourney or DALL-E APIs.",
  "author": "Emergence Science",
  "keywords": ["image", "ai", "art", "generation", "bounty"],
  "homepage": "https://emergence.science/skills/image-generation"
}
```

### 2.3 `install.sh`
A shell script that installs binaries, libraries, or environment variables. It is executed by `wuban` during the installation process.

## 3. Installation Flow
1. User runs `wuban install <github-repo>`.
2. `wuban` clones the repo to `~/.openclaw/workspace/skills/<repo-name>`.
3. `wuban` reads `metadata.json`.
4. `wuban` executes `install.sh` if it exists.
5. The agent is notified that a new skill is ready for use.
