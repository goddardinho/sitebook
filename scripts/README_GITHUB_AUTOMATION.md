# GitHub Issue Creation Automation

This directory contains scripts to automatically create GitHub issues from the Enhanced Search and Filtering System requirements.

## Available Scripts

### 1. GitHub CLI Script (Recommended)
**File:** `create_github_issues.sh`
**Requirements:** [GitHub CLI](https://cli.github.com/)

```bash
# Install GitHub CLI (macOS)
brew install gh

# Authenticate with GitHub
gh auth login

# Make script executable and run
chmod +x scripts/create_github_issues.sh
./scripts/create_github_issues.sh
```

**Creates 5 focused issues:**
1. 🔴 **Fix Search Radius Selector UI Visibility** (High Priority)
2. 🗺️ **Add State-Based Campground Filtering** (Medium Priority)
3. 🏕️ **Expand Amenity Filtering Categories** (Medium Priority) 
4. 📊 **Enhance Search Results with Distance and Sorting** (Medium Priority)
5. ⭐ **Add Search History and Quick Filters** (Low Priority)

### 2. Python API Script
**File:** `create_github_issues.py`
**Requirements:** `pip install requests`

```bash
# Set up environment
export GITHUB_TOKEN="your_personal_access_token"

# Edit script configuration
# Set REPO_OWNER and REPO_NAME in the script

# Run script
python scripts/create_github_issues.py
```

### 3. JSON Data File
**File:** `github_issues_data.json`
Contains structured issue data that can be used with other tools or imported into project management systems.

## Setup Instructions

### Option 1: GitHub CLI (Easiest)
1. Install GitHub CLI: `brew install gh`
2. Authenticate: `gh auth login`
3. Run: `./scripts/create_github_issues.sh`

### Option 2: Python Script
1. Install Python requests: `pip install requests`
2. Create GitHub Personal Access Token:
   - Go to GitHub Settings → Developer settings → Personal access tokens
   - Create token with 'repo' scope
3. Set environment variable: `export GITHUB_TOKEN="your_token"`
4. Edit script: Set `REPO_OWNER` and `REPO_NAME`
5. Run: `python scripts/create_github_issues.py`

### Option 3: Manual Creation
Use the original comprehensive document: `docs/GITHUB_ISSUE_ENHANCED_SEARCH_FILTERS.md`

## Issue Structure

Each created issue includes:
- **Clear problem statement**
- **Specific requirements checklist**
- **Implementation notes**
- **Files to modify**
- **Acceptance criteria**
- **Priority and time estimates**
- **Proper labels for organization**

## Labels Used

- `bug` - Issues that fix broken functionality
- `enhancement` - New features or improvements
- `ui` - User interface related
- `search` - Search functionality
- `filters` - Filtering system
- `ux` - User experience improvements
- `high-priority` - Critical issues that block core functionality
- `productivity` - Features that improve user efficiency

## Next Steps After Issue Creation

1. **Review Issues**: Check all created issues for accuracy
2. **Set Priorities**: Adjust priority based on user feedback and business needs
3. **Assign Team Members**: Distribute work based on expertise
4. **Create Project Board**: Set up GitHub Projects for tracking
5. **Define Milestones**: Group issues into release milestones
6. **Start with High Priority**: Begin with Search Radius Selector fix

## Customization

To modify the issues before creation:
1. Edit `github_issues_data.json` for content changes
2. Modify scripts for different labels, assignees, or milestones
3. Update the comprehensive document and regenerate

## Troubleshooting

**"GitHub CLI not found"**
- Install: `brew install gh` (macOS) or visit [cli.github.com](https://cli.github.com/)

**"Not authenticated"**
- Run: `gh auth login`

**"Permission denied"**
- Ensure your GitHub account has write access to the repository
- For personal access tokens, ensure 'repo' scope is enabled

**"API rate limit exceeded"**
- Wait for rate limit reset or use authenticated requests
- GitHub CLI handles this automatically