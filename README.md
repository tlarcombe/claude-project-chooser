# claude+

An fzf-based project chooser for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Pick from all your projects with Claude sessions, or create a new one.

## What it does

- Scans `~/.claude/projects/` for all Claude Code session data
- Scans `~/projects/` for directories without sessions
- Displays an interactive fzf picker sorted by most recent activity
- Shows session counts, last activity dates, and session summaries
- Launches Claude Code with `--continue` for projects with existing sessions

## Requirements

- [fzf](https://github.com/junegunn/fzf)
- python3 (for JSON parsing)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)

## Install

```bash
cp claude+ ~/.local/bin/claude+
chmod +x ~/.local/bin/claude+
```

## Usage

```bash
claude+
```

### Selection behavior

- **Project with sessions** → resumes the most recent session (`--continue`)
- **Project without sessions** → starts a new session
- **+ NEW PROJECT** → prompts for a name, creates `~/projects/<name>`, runs `git init`, creates empty `CLAUDE.md`, and launches Claude Code
- **Esc / Ctrl-C** → clean exit
