# Publishing to GitHub

This guide explains how to publish this repository to GitHub.

## Prerequisites

- A GitHub account
- Git installed on your system
- GitHub CLI (`gh`) installed (optional but recommended)

## Method 1: Using GitHub CLI (Recommended)

### Install GitHub CLI

```bash
# macOS
brew install gh

# Ubuntu/Debian
sudo apt install gh
```

### Authenticate with GitHub

```bash
gh auth login
```

### Create and Push Repository

```bash
# Create a new public repository on GitHub
gh repo create cmod7-led-blinky --public --source=. --remote=origin --push

# Or create a private repository
gh repo create cmod7-led-blinky --private --source=. --remote=origin --push
```

The repository will be created and your code will be pushed automatically.

## Method 2: Using GitHub Web Interface

### Step 1: Create Repository on GitHub

1. Go to https://github.com/new
2. Repository name: `cmod7-led-blinky` (or your preferred name)
3. Description: `LED Blinky example for Digilent CMOD A7-35T using OpenXC7 open-source toolchain`
4. Choose Public or Private
5. **Do NOT** initialize with README, .gitignore, or license (we already have these)
6. Click "Create repository"

### Step 2: Add Remote and Push

GitHub will show you commands similar to these:

```bash
# Add the remote repository
git remote add origin https://github.com/YOUR_USERNAME/cmod7-led-blinky.git

# Push your code
git branch -M main
git push -u origin main
```

Replace `YOUR_USERNAME` with your GitHub username.

## Verify Upload

After pushing, visit your repository URL:
```
https://github.com/YOUR_USERNAME/cmod7-led-blinky
```

## Repository Topics (Recommended)

Add these topics to your GitHub repository to help others discover it:

- `fpga`
- `verilog`
- `xilinx`
- `artix-7`
- `openxc7`
- `open-source-fpga`
- `cmod-a7`
- `nextpnr`
- `yosys`
- `docker`

To add topics:
1. Go to your repository on GitHub
2. Click the gear icon next to "About"
3. Add topics in the "Topics" field

## Update README Badge (Optional)

Consider adding a license badge to your README.md:

```markdown
[![License](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
```

## Clone Your Repository

Others can clone your repository with:

```bash
git clone https://github.com/YOUR_USERNAME/cmod7-led-blinky.git
cd cmod7-led-blinky
```

## Recommended Repository Settings

### Branch Protection (Optional)

For collaborative projects, consider enabling branch protection:

1. Go to Settings → Branches
2. Add rule for `main` branch
3. Enable "Require pull request reviews before merging"

### Issues and Discussions

Enable these features to allow community contributions:

1. Go to Settings → General
2. Enable "Issues" for bug reports and feature requests
3. Enable "Discussions" for Q&A and community support

## License

This project uses the BSD 3-Clause License. See [LICENSE](LICENSE) for details.
