# Issue Tracking Workflow Examples

This document provides practical examples of how to use the bug and feature tracking system in your daily workflow.

## 🔄 Complete Issue Lifecycle Example

### 1. Issue Creation
**UAT tester reports:** Form validation not working on iOS

```
Title: [UAT-P1] Reservations - Form validation not working on iOS
Type: Bug Report  
Priority: P1 - High
Platform: iOS
Description: Email validation allows invalid formats during reservation
```

### 2. Issue Triage  
**Developer reviews and assigns:**
- Confirms reproduction on iPhone 14 Pro, iOS 17.2
- Assigns to iOS specialist
- Links to related form validation issues
- Moves from `needs-triage` to `in-progress`

### 3. Development Work
**Developer creates branch and commits:**

```bash
# Create feature branch
git checkout -b bugfix/issue-42-ios-email-validation

# Make changes
git add lib/features/reservations/forms/reservation_form.dart
git commit -m "fix(reservations): resolve email validation on iOS devices

- Update email regex to handle iOS-specific input behavior  
- Add proper input type handling for iOS Safari
- Improve validation error messaging

Fixes #42"
```

### 4. Pull Request
**Developer creates PR with template:**

```markdown
## Description
Fixed email validation that was failing on iOS devices due to input handling differences.

## Issue Reference  
Fixes #42

## Type of Change
- [x] Bug fix (non-breaking change that fixes an issue)

## Testing Performed
- [x] Manual testing completed on iPhone 14 Pro
- [x] UAT validation completed

## Platform Testing
- [ ] Android tested  
- [x] iOS tested
- [ ] Web tested
```

### 5. Review and Testing
- Code review completed
- UAT tester verifies fix on iOS device
- Issue status updated to `testing` → `closed`

## 🏷️ Label Management Examples

### Automatic Labeling (Via Templates)
```yaml
# Bug Report Results In:
labels: ["bug", "needs-triage"]

# UAT Feedback Results In:  
labels: ["uat", "feedback", "needs-triage"]
```

### Manual Triage Labeling
```bash
# High priority Android bug
Labels: P1-high, android, bug, ui-ux

# Cross-platform feature request
Labels: P2-medium, feature, cross-platform, enhancement

# UAT blocking issue
Labels: P0-critical, uat-blocker, needs-immediate-attention
```

## 🎯 UAT-Specific Workflow

### UAT Issue Naming Convention
```
[UAT-{Priority}] {Feature Area} - {Brief Description}

Examples:
[UAT-P0] Core - App crashes on startup (Android)
[UAT-P1] Reservations - Cannot submit form with special characters  
[UAT-P2] Maps - Location permission handling unclear
[UAT-P3] Settings - Minor alignment issue in preferences
```

### UAT Daily Workflow
```bash
# Morning: Review overnight issues
git checkout feature/user-acceptance-testing
git pull origin feature/user-acceptance-testing

# Filter for UAT issues needing attention
# GitHub: is:issue is:open label:uat label:needs-triage

# Address P0 issues immediately
git checkout -b hotfix/issue-45-uat-crash-fix

# Work on fix, commit, PR
git commit -m "fix(core): resolve startup crash on Android API 26

Critical fix for UAT blocker preventing testing on older Android devices.

Fixes #45"
```

## 🚀 Feature Request Workflow

### From Idea to Implementation
```markdown
1. User submits feature request via GitHub template
2. Product owner reviews and prioritizes  
3. Developer estimates effort and assigns to sprint
4. Feature branch created: feature/issue-67-notification-preferences
5. Implementation with regular commits:
   - feat(notifications): add preference storage service  
   - feat(notifications): implement preferences UI
   - feat(notifications): integrate with monitoring system
6. PR created with full testing verification
7. UAT team validates feature meets acceptance criteria
8. Feature merged to main branch
```

## 🔧 Enhancement Workflow

### Continuous Improvement Process
```bash
# Enhancement identified during UAT
Title: [ENHANCEMENT] Maps - Add distance sorting for campgrounds
Priority: P2 - Medium
Impact: Would improve user experience significantly

# Implementation
git checkout -b enhance/issue-89-distance-sorting
# Develop enhancement
git commit -m "enhance(maps): add distance-based sorting option

- Add distance calculation service
- Implement sort dropdown in campgrounds list  
- Persist user sort preference
- Update UI to show distance from current location

Closes #89"
```

## 📊 Tracking and Reporting Examples

### Weekly Issue Summary Query
```bash
# GitHub CLI examples
gh issue list --label "P0-critical,P1-high" --state open
gh issue list --label "uat" --state closed --limit 20
gh issue list --assignee "@me" --state open
```

### Sprint Planning Queries
```bash
# Issues ready for development
gh issue list --label "triaged" --label "P1-high,P2-medium" 

# UAT feedback for next iteration  
gh issue list --label "uat" --label "enhancement" --state open

# Security issues requiring attention
gh issue list --label "security" --state open
```

## 🔍 Search and Filter Examples

### Finding Related Issues
```
# Similar validation issues
is:issue validation email form

# iOS-specific problems  
is:issue label:ios is:open

# UAT blockers
is:issue label:uat-blocker is:open

# Performance concerns
is:issue performance slow label:enhancement
```

### Custom Saved Searches
```bash
# My active work
is:issue assignee:@me is:open

# UAT critical path  
is:issue label:uat (label:P0-critical OR label:P1-high) is:open

# Ready for testing
is:issue label:in-review -label:testing

# Recently resolved
is:issue is:closed updated:>2026-04-01
```

## 🎭 Role-Based Examples

### UAT Tester Daily Routine
```bash
1. Check for new builds/fixes to retest
2. Submit feedback using UAT template
3. Verify previously reported issues are resolved  
4. Report completion status for test areas
```

### Developer Daily Routine  
```bash
1. Triage new issues assigned to me
2. Update status on in-progress work
3. Create PRs linking to resolved issues
4. Review and respond to clarification requests
```

### Project Manager Weekly Routine
```bash
1. Review UAT progress and blocking issues
2. Prioritize new features based on feedback
3. Generate weekly report on issue resolution
4. Plan next sprint based on feedback trends
```

## 🚨 Escalation Examples

### Critical Issue Process
```
1. P0 issue reported → Immediate notification
2. Assign to available developer → Start work immediately  
3. Create hotfix branch → Deploy fix within hours
4. Update UAT team → Resume testing with fix
5. Document lessons learned → Prevent recurrence
```

### UAT Blocker Process
```
1. UAT team identifies blocker → Escalate immediately
2. Assess impact on UAT timeline → Adjust schedule if needed
3. All hands to resolve → Multiple developers if needed
4. Alternative testing approach → Continue UAT where possible
5. Resolution verification → UAT team confirms fix
```

This workflow documentation ensures everyone understands not just the tracking system, but how to use it effectively in their daily work.