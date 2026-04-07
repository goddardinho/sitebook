# GitHub Issue Templates

This directory contains issue templates for SiteBook Flutter project to streamline bug reporting, feature requests, and UAT feedback.

## Available Templates

### 🐛 Bug Report (`bug_report.yml`)
**Use for:** Issues that prevent expected functionality
- Structured priority and severity classification
- Platform-specific reporting
- Detailed reproduction steps
- UAT context tracking

### 🚀 Feature Request (`feature_request.yml`)  
**Use for:** New functionality requests
- User story format
- Business justification required
- Acceptance criteria definition
- Technical considerations

### 🔧 Enhancement (`enhancement.yml`)
**Use for:** Improvements to existing features
- Current vs. proposed behavior
- User benefit analysis
- Implementation suggestions
- Feature area classification

### 🔒 Security Issue (`security_issue.yml`)
**Use for:** Security vulnerabilities or concerns
- Security severity levels
- Impact assessment
- Private processing support
- Multiple security categories

### 🧪 UAT Feedback (`uat_feedback.yml`)
**Use for:** User Acceptance Testing feedback
- UAT-specific priority levels
- Test area classification
- User context capture
- Completion impact assessment

## Template Usage

1. **Navigate to Issues tab** in GitHub repository
2. **Click "New Issue"**
3. **Select appropriate template** from the list
4. **Fill out all required fields**
5. **Submit issue** for automatic triage

## Labels and Automation

### Auto-Applied Labels
- `bug` + `needs-triage` → Bug reports
- `feature` + `needs-triage` → Feature requests  
- `enhancement` + `needs-triage` → Enhancements
- `security` + `urgent` + `needs-triage` → Security issues
- `uat` + `feedback` + `needs-triage` → UAT feedback

### Manual Labels (Applied during triage)
- **Priority:** `P0-critical`, `P1-high`, `P2-medium`, `P3-low`
- **Platform:** `android`, `ios`, `web`, `cross-platform`
- **Status:** `in-progress`, `in-review`, `testing`, `blocked`
- **Area:** `ui-ux`, `api`, `database`, `notifications`, `maps`, `reservations`

## Workflow Integration

Issues created with these templates automatically:
1. **Get assigned** to project maintainer
2. **Receive appropriate labels** for filtering
3. **Enter triage queue** for priority assessment
4. **Link to UAT process** if applicable

## Customization

To modify templates:
1. **Edit YAML files** in this directory
2. **Test changes** by creating sample issues
3. **Update this README** if new templates added
4. **Commit changes** to activate updates

## Best Practices

- **Use specific titles** that clearly describe the issue
- **Fill all required fields** for faster processing  
- **Include screenshots/videos** when helpful
- **Provide device/browser details** for platform issues
- **Link related issues** when applicable
- **Follow up** on requested clarifications