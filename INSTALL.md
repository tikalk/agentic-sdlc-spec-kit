# Agentic SDLC: Installation & Setup Guide for AI Assistants

This guide is designed for AI agents to help new team members successfully install and configure the Agentic SDLC Spec Kit with Team AI Directives.

## Your Role as an AI Assistant

You are helping a new team member get up and running with our Spec-Driven Development workflow. Your job is to:
1. Guide them through prerequisites installation
2. Help initialize their project with team-ai-directives
3. Verify the setup is working correctly
4. Answer questions and troubleshoot issues

**Approach:** Be proactive, check for errors, and provide clear next steps. Always verify each step succeeds before moving to the next.

---

## Pre-Flight Checklist (Ask the User)

Before starting, gather this information:

```
□ What operating system are you using? (macOS/Linux/Windows)
□ Which AI coding agent will you use? (GitHub Copilot/Cursor/Claude Code/Windsurf/Codex/other)
□ Is this a new project or existing codebase?
□ Do you have the team-ai-directives URL from your team lead?
□ Is the team-ai-directives repository private? (needs GH_TOKEN)
```

---

## Phase 1: Prerequisites Installation

### Step 1.1: Check for uv (Python Package Manager)

**Ask the user:**
> "First, let's check if you have `uv` installed. Please run this command in your terminal:"

```bash
uv --version
```

**If uv is installed:**
- ✅ Great! uv is already installed. Moving to next step.

**If uv is NOT installed:**

**For macOS/Linux:**
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

**For Windows:**
```powershell
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

**Verify installation:**
```bash
uv --version
```

**Expected output:** Something like `uv 0.5.x` (any recent version is fine)

---

### Step 1.2: Install Agentic SDLC Specify CLI

**Tell the user:**
> "Now let's install the Specify CLI tool. This is the core tool for our Spec-Driven Development workflow."

```bash
uv tool install agentic-sdlc-specify-cli --from git+https://github.com/tikalk/agentic-sdlc-spec-kit.git
```

**What this does:**
- Downloads and installs the `specify` command-line tool
- Makes it available globally via uv's tool management

**Expected output:** Installation progress followed by `Installed package agentic-sdlc-specify-cli`

---

### Step 1.3: Verify Installation

**Tell the user:**
> "Let's verify the installation was successful:"

```bash
specify check
```

**What to look for:**
- ✅ Version number displayed
- ✅ Git status check
- ✅ AI agent detection (may show warnings if agents aren't installed yet - that's OK)

**If errors occur:**
- Check internet connection (needs to access GitHub)
- Try re-running the install command
- Check if `uv` is in PATH: `which uv` (macOS/Linux) or `where uv` (Windows)

---

## Phase 2: Project Initialization

### Step 2.1: Navigate to Project Directory

**Ask the user:**
> "Are you:
> 1. Starting a new project, or
> 2. Setting up an existing codebase?"

**Option 1: New Project**
```bash
mkdir my-project
cd my-project
```

**Option 2: Existing Project**
```bash
cd /path/to/your/existing-project
```

---

### Step 2.2: Get Team AI Directives URL

**Ask the user:**
> "Please provide the team-ai-directives URL from your team lead. It should look like one of these:"

Examples:
```
https://github.com/YOUR_ORG/team-ai-directives/archive/refs/tags/v1.0.0.zip
https://github.com/YOUR_ORG/team-ai-directives.git
```

**Store this URL** - you'll need it for the next step.

---

### Step 2.3: Handle Private Repository Access (If Needed)

**Ask the user:**
> "Is the team-ai-directives repository private?"

**If YES:**

1. **Check for GitHub CLI:**
```bash
gh --version
```

2. **If gh is not installed, install it:**
   - macOS: `brew install gh`
   - Linux: See https://github.com/cli/cli#installation
   - Windows: `winget install --id GitHub.cli`

3. **Authenticate with GitHub:**
```bash
gh auth login
```

4. **Set GH_TOKEN environment variable:**
```bash
export GH_TOKEN=$(gh auth token)
```

**Verify token works:**
```bash
echo $GH_TOKEN
```

Should display a long string of characters (the token).

**For Windows (PowerShell):**
```powershell
$env:GH_TOKEN = (gh auth token)
```

---

### Step 2.4: Initialize Project with Specify

**Tell the user:**
> "Now let's initialize your project with the team AI directives. This will set up the Spec Kit structure and integrate your team's directives."

**For new projects:**
```bash
specify init . --team-ai-directives <DIRECTIVES_URL>
```

**For existing projects (force mode):**
```bash
specify init . --force --team-ai-directives <DIRECTIVES_URL>
```

**Replace `<DIRECTIVES_URL>` with the actual URL from Step 2.2**

**What happens during initialization:**
1. Creates `.specify/` directory structure
2. Installs team-ai-directives to `.specify/extensions/team-ai-directives/`
3. Sets up AI agent configuration files based on your chosen agent
4. Creates initial project files

---

### Step 2.5: Select AI Coding Agent

**During initialization, the user may be prompted to select their AI agent.**

**Ask the user:**
> "Which AI coding agent are you using?"

Options:
- `claude` - Claude Code CLI
- `copilot` - GitHub Copilot (VS Code)
- `cursor-agent` - Cursor IDE
- `gemini` - Gemini CLI
- `codex` - Codex CLI (add `--ai-skills` flag)
- `windsurf` - Windsurf IDE
- `opencode` - opencode CLI
- `qwen` - Qwen Code CLI
- Other options available: `junie`, `auggie`, `codebuddy`, `qoder`, `kiro-cli`, `amp`, `shai`, `tabnine`, `kimi`, `pi`, `iflow`, `forge`, `bob`, `trae`, `agy`, `vibe`

**If they need to specify manually:**
```bash
specify init . --ai <AGENT_NAME> --team-ai-directives <DIRECTIVES_URL>
```

**For Codex with skills:**
```bash
specify init . --ai codex --ai-skills --team-ai-directives <DIRECTIVES_URL>
```

---

### Step 2.6: Verify Project Structure

**Tell the user:**
> "Let's verify the project was set up correctly:"

```bash
ls -la .specify/
```

**Expected directory structure:**
```
.specify/
├── commands/           # AI agent commands
├── memory/            # Project memory (constitution goes here)
├── specs/             # Feature specifications
├── templates/         # Spec Kit templates
└── extensions/
    └── team-ai-directives/    # Team AI directives
        ├── context_modules/
        │   ├── constitution.md
        │   ├── personas/
        │   └── rules/
        └── skills/
```

**Verify team-ai-directives installation:**
```bash
ls -la .specify/extensions/team-ai-directives/
```

Should show: `context_modules/`, `skills/`, `AGENTS.md`, `.skills.json`, etc.

---

## Phase 3: Verify Team AI Directives Integration

### Step 3.1: Run Verification Command

**Tell the user:**
> "Let's verify the team-ai-directives extension is properly integrated:"

```bash
specify run adlc.team-ai-directives.verify
```

**What to check:**
- ✅ Extension installation verified
- ✅ Skills registry accessible
- ✅ CDR tracking available
- ✅ Constitution alignment check passed

**If errors occur:**
- Check that team-ai-directives URL was correct
- Verify GH_TOKEN is set (for private repos)
- Try re-initializing the project

---

### Step 3.2: Explore Team AI Directives (Optional but Recommended)

**Tell the user:**
> "Let's explore what team AI directives are available to you:"

**View available personas:**
```bash
ls .specify/extensions/team-ai-directives/context_modules/personas/
```

**View available skills:**
```bash
cat .specify/extensions/team-ai-directives/.skills.json | head -50
```

**Read the team constitution:**
```bash
cat .specify/extensions/team-ai-directives/context_modules/constitution.md
```

---

## Phase 4: Initial Project Setup

### Step 4.1: Create Project Constitution

**Tell the user:**
> "Now let's create your project's constitution. This defines the core principles and standards for your project. You only need to do this once per project."

**Instructions for the user:**
1. Open your AI coding agent in the IDE (e.g., GitHub Copilot chat, Cursor chat, Claude Code)
2. Run the constitution command:

```
/spec.constitution
```

**Or with specific focus areas:**
```
/spec.constitution Create principles focused on code quality, testing standards, API design consistency, and security requirements
```

**What happens:**
- AI creates a constitution based on team principles
- File is saved to `.specify/memory/constitution.md`

**Verify creation:**
```bash
cat .specify/memory/constitution.md
```

---

### Step 4.2: Test Quick Workflow

**Tell the user:**
> "Let's test the setup with a simple task using the quick workflow:"

**In your AI agent chat:**
```
/quick.implement "Create a README.md file with project title and basic description"
```

**What to expect:**
- AI generates a Mission Brief
- Reviews implementation approach
- Creates the file

**Verify output:**
```bash
cat README.md
```

---

## Phase 5: Full Feature Workflow Test (Optional)

### Step 5.1: Create a Test Feature

**Tell the user:**
> "Let's walk through a complete feature development workflow to ensure everything works:"

**Step 1: Create Specification**
```
/spec.specify "Create a simple utility module for string manipulation with functions for slug generation and title case conversion"
```

**What should happen:**
- New feature branch created
- `specs/[branch]/spec.md` generated

**Step 2: Create Plan**
```
/spec.plan "Implement in Python with comprehensive unit tests using pytest"
```

**What should happen:**
- `specs/[branch]/plan.md` generated
- Supporting documents created

**Step 3: Generate Tasks**
```
/spec.tasks
```

**What should happen:**
- `specs/[branch]/tasks.md` generated with checklist

**Step 4: Implement**
```
/spec.implement
```

**What should happen:**
- Code files created
- Tests implemented
- Tasks checked off

---

## Troubleshooting Common Issues

### Issue: "specify: command not found"

**Solution:**
```bash
# Ensure uv tools are in PATH
export PATH="$HOME/.local/bin:$PATH"

# Or re-install specify
uv tool install agentic-sdlc-specify-cli --force --from git+https://github.com/tikalk/agentic-sdlc-spec-kit.git
```

### Issue: "Failed to download team-ai-directives"

**Solutions:**
1. Check internet connection
2. Verify the URL is correct
3. For private repos, ensure GH_TOKEN is set:
   ```bash
   export GH_TOKEN=$(gh auth token)
   ```
4. Check GitHub token has access to the repository

### Issue: "No AI agent detected"

**Solutions:**
1. Manually specify the agent: `--ai <agent-name>`
2. Check your AI agent is installed (e.g., `claude --version`)
3. Use `--ignore-agent-tools` to skip detection

### Issue: "Permission denied" on Windows

**Solution:**
Run terminal as Administrator or use PowerShell with appropriate execution policy:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Issue: Commands not appearing in AI agent

**Solutions:**
1. Restart your IDE
2. Check agent-specific directory exists (e.g., `.claude/commands/`, `.cursor/commands/`)
3. For Copilot: Check `.github/agents/` directory
4. Reload window in VS Code: `Cmd/Ctrl + Shift + P` → "Developer: Reload Window"

---

## Post-Installation Checklist

**Verify with the user:**

```
□ uv installed and working
□ specify CLI installed (specify check passes)
□ Project initialized with team-ai-directives
□ .specify/ directory exists with proper structure
□ Team-ai-directives installed in .specify/extensions/
□ Project constitution created
□ Quick workflow tested successfully
□ Full feature workflow tested (optional)
□ AI agent commands available in IDE
```

---

## Next Steps for the Team Member

**Tell the user:**
> "Great! Your environment is set up. Here's what to do next:"

1. **Read the Quick Start Guide**
   ```bash
   cat quickstart.md
   ```

2. **Review Team Standards**
   - Check `.specify/extensions/team-ai-directives/context_modules/constitution.md`
   - Find your role's persona in `context_modules/personas/`

3. **Start Your First Real Feature**
   - Use `/spec.specify` to create a specification
   - Follow the full SDD workflow

4. **Join the Team**
   - Ask your team lead about current projects
   - Review existing specs in the `specs/` directory

---

## Quick Command Reference for You (The AI Assistant)

**When helping the user, remember these key commands:**

| User Need | Your Response |
|-----------|---------------|
| "How do I install?" | Guide through Phase 1 (uv + specify CLI) |
| "How do I set up a project?" | Guide through Phase 2 (init with team-ai-directives) |
| "How do I create my first spec?" | Guide through Step 4.1 (constitution) then Step 5.1 (test feature) |
| "Commands not showing" | Check Step 2.5 (AI agent selection) and troubleshooting |
| "Private repo access issues" | Guide through Step 2.3 (GH_TOKEN setup) |
| "What's next?" | Point to Next Steps section |

---

## Resources

**Point the user to these resources:**

- **This repo's README.md** - Project-specific information
- **AGENTS.md** - Instructions for AI agents working on this project
- **Team AI Directives:** `.specify/extensions/team-ai-directives/`
  - `README.md` - Full team directives documentation
  - `GETTING_STARTED.md` - Team-specific quick start
  - `AGENTS.md` - How agents use team directives
- **Spec Kit Documentation:** https://github.com/tikalk/agentic-sdlc-spec-kit
- **Spec-Driven Development Guide:** `./spec-driven.md`

---

**You're now ready to help team members get started with Agentic SDLC! 🚀**
