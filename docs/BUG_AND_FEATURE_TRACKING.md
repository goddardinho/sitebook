# Bug and Feature Tracking Process

**Version:** 1.1  
**Date:** April 10, 2026  
**Status:** Active - GitHub Issues Integration  
**Primary Tracking Tool:** [GitHub Issues](https://github.com/your-repo/issues)

## 📋 Overview

This document establishes the bug tracking and feature request workflow for SiteBook Flutter. **All issues are tracked using GitHub Issues** with this document serving as the process reference guide.

### 🎯 Quick Start
1. **Report Issues:** Use GitHub Issues with provided templates
2. **Reference Process:** Follow guidelines in this document  
3. **Track Progress:** Monitor issues via GitHub project boards
4. **Integration:** Link commits/PRs to issues for automatic closure

## 🛠️ GitHub Issues Setup

### Labels System
Our GitHub repository uses the following label structure:

#### Priority Labels
- 🔴 `P0-Critical` - Immediate response required
- 🟠 `P1-High` - 1-2 day response time  
- 🟡 `P2-Medium` - 1 week response time
- 🟢 `P3-Low` - Next release cycle

#### Type Labels  
- 🐛 `bug` - Something is broken
- 🚀 `feature` - New functionality request
- 🔧 `enhancement` - Improvement to existing feature
- 📚 `documentation` - Documentation updates needed
- 🧪 `testing` - Testing-related issues
- 🔒 `security` - Security-related concerns

#### Platform Labels
- 🤖 `android` - Android-specific issues
- 🍎 `ios` - iOS-specific issues  
- 🌐 `web` - Web-specific issues

#### Status Labels
- 🔍 `triaged` - Issue reviewed and classified
- 🚧 `in-progress` - Actively being worked on
- 👀 `in-review` - Code review in progress
- 🧪 `testing` - Solution being tested

### Issue Templates
Use the provided GitHub Issue templates (`.github/ISSUE_TEMPLATE/`):
- **Bug Report** - For reporting defects
- **Feature Request** - For new functionality  
- **Enhancement** - For improvements to existing features

## 🎯 Tracking Scope

### What We Track
- **🐛 Bugs:** Issues that prevent expected functionality
- **🚀 Feature Requests:** New functionality requests from users/stakeholders
- **🔧 Enhancements:** Improvements to existing features
- **📱 Platform Issues:** Platform-specific problems (iOS, Android, Web)
- **🔒 Security Issues:** Security vulnerabilities or concerns
- **⚡ Performance Issues:** Speed, memory, or efficiency problems

### What We Don't Track
- General questions or support requests
- Duplicate issues (link to original)
- Issues resolved in current development cycle

## 📊 Issue Classification System

### Priority Levels
| Priority | Description | Response Time | Examples |
|----------|-------------|---------------|-----------|
| **P0 - Critical** | App crashes, data loss, security vulnerabilities | Immediate | App won't start, payment failures, data corruption |
| **P1 - High** | Core functionality broken, major UX issues | 1-2 days | Reservation form broken, maps not loading, login fails |
| **P2 - Medium** | Feature partially working, minor UX issues | 1 week | Filters not working properly, slow loading screens |
| **P3 - Low** | Cosmetic issues, nice-to-have improvements | Next release | UI alignment issues, text formatting |

### Severity Levels
| Severity | Impact | User Effect |
|----------|--------|-------------|
| **Blocker** | Complete feature failure | Users cannot complete critical tasks |
| **Major** | Significant functionality loss | Users can work around but with difficulty |
| **Minor** | Partial functionality loss | Users experience inconvenience |
| **Trivial** | Cosmetic or very minor issue | Minimal impact on user experience |

### Issue Types
- 🐛 **Bug** - Something is broken
- 🚀 **Feature** - New functionality request  
- 🔧 **Enhancement** - Improvement to existing feature
- 📚 **Documentation** - Documentation updates needed
- 🧪 **Testing** - Testing-related issues
- 🔒 **Security** - Security-related concerns

## � GitHub Integration Workflow

### Issue Lifecycle in GitHub
1. **Create Issue** - Use templates to ensure complete information
2. **Auto-Label** - Templates apply initial labels (bug/feature/enhancement)
3. **Triage** - Add priority, platform, and status labels
4. **Assignment** - Assign to developer or team
5. **Development** - Link commits and PRs to issues
6. **Testing** - Move to testing label when ready for UAT
7. **Closure** - Auto-close with `Fixes #123` in commit messages

### Commit Message Integration
Link commits to issues using these formats:
- `Fixes #123` - Closes issue when merged
- `Addresses #123` - References without closing
- `Related to #123` - Links related work

### Branch Naming Convention
- `bug/issue-123-fix-login-crash`
- `feature/issue-124-recreation-images`  
- `enhancement/issue-125-improve-search`

### Milestones and Projects
- **Milestones** - Group issues by release (v1.1, v1.2)
- **Projects** - Track progress across features
- **Labels** - Filter and organize by type, priority, platform

### Issue Lifecycle States
```
[New] → [Triaged] → [In Progress] → [In Review] → [Testing] → [Closed]
                ↓
            [Duplicate/Invalid]
```

### State Definitions
- **New:** Issue reported but not yet reviewed
- **Triaged:** Issue reviewed, classified, and assigned priority
- **In Progress:** Someone is actively working on the issue
- **In Review:** Solution implemented, awaiting code review
- **Testing:** Solution being tested (UAT or developer testing)
- **Closed:** Issue resolved and verified
- **Duplicate/Invalid:** Issue closed due to duplication or invalidity

## 📝 Issue Reporting Template

### Bug Report Template
```markdown
**Bug Title:** [Brief, descriptive title]

**Priority:** [P0/P1/P2/P3]
**Severity:** [Blocker/Major/Minor/Trivial]
**Platform(s):** [Android/iOS/Web]
**Device/Browser:** [Specific device or browser version]

**Description:**
[Clear description of what happened]

**Steps to Reproduce:**
1. [Step one]
2. [Step two]
3. [Step three]

**Expected Behavior:**
[What should have happened]

**Actual Behavior:**
[What actually happened]

**Screenshots/Videos:**
[Attach if applicable]

## 🚀 Next Steps: Repository Setup

### 1. GitHub Repository Configuration
When you create/push to your GitHub repository:

1. **Push these templates** - The `.github/ISSUE_TEMPLATE/` files will be automatically available
2. **Set up labels** - Create the priority, type, platform, and status labels listed above  
3. **Create milestones** - Set up v1.1, v1.2, etc. for release planning
4. **Enable Projects** - Optional: Create project boards for kanban-style tracking

### 2. Create Initial Issues
Start with known items from your documentation:

**Example Issue Ready to Create:**
- See `docs/EXAMPLE_GITHUB_ISSUE_RECREATION_IMAGES.md` 
- Copy content into new GitHub issue
- Apply labels: `feature`, `P2-Medium`, `android`, `ios`, `web`
- Assign to milestone: `v1.1`

### 3. Team Training
- Share this process document with team members
- Demonstrate GitHub Issues workflow  
- Establish triage meeting schedule (weekly recommended)
- Define assignment and review processes

### 4. Integration with Development
- Update commit message practices to reference issues
- Establish branch naming conventions  
- Link Pull Requests to related issues
- Set up notifications for issue updates

---

## 📞 Support and Questions

For questions about this process:
- Create a GitHub Discussion (general questions)
- Update this document via Pull Request (process improvements)
- Contact project maintainers for urgent process issues

**Document Owner:** Development Team  
**Last Updated:** April 10, 2026  
**Next Review:** May 1, 2026

**Reporter:** [Name/Role]
**Date Reported:** [Date]
```

### Feature Request Template
```markdown
**Feature Title:** [Brief, descriptive title]

**Priority:** [P0/P1/P2/P3]
**Type:** [Feature/Enhancement]
**Platform(s):** [Android/iOS/Web/All]

**User Story:**
As a [type of user], I want [some goal] so that [some reason].

**Description:**
[Detailed description of the requested feature]

**Acceptance Criteria:**
- [ ] [Criteria 1]
- [ ] [Criteria 2]
- [ ] [Criteria 3]

**Business Justification:**
[Why this feature is important]

**Technical Considerations:**
[Any technical constraints or considerations]

**Mockups/Examples:**
[Attach if available]

**Reporter:** [Name/Role]
**Date Requested:** [Date]
```

## 🎯 UAT-Specific Tracking

### UAT Issue Categories
- **UAT-Critical:** Issues that block UAT completion
- **UAT-Major:** Issues that significantly impact user testing
- **UAT-Minor:** Issues noted during UAT but don't block testing
- **UAT-Enhancement:** Improvements suggested during UAT

### UAT Issue Naming Convention
```
[UAT-{Priority}] {Feature Area} - {Brief Description}

Examples:
[UAT-P1] Reservations - Form validation not working on iOS
[UAT-P2] Maps - Location services slow to initialize
[UAT-P3] Settings - Minor UI alignment issues
```

## 📍 Integration with Git Workflow

### Branch Naming for Issues
```
hotfix/issue-{number}-{brief-description}    # For P0/P1 bugs
bugfix/issue-{number}-{brief-description}    # For P2/P3 bugs  
feature/issue-{number}-{brief-description}   # For new features
enhance/issue-{number}-{brief-description}   # For enhancements
```

### Commit Message Convention
```
{type}({scope}): {description}

fix(reservations): resolve form validation on iOS devices
feat(notifications): add granular notification preferences  
enhance(maps): improve location service initialization speed
docs(uat): update testing procedures based on feedback

Fixes #123
Closes #456
```

### Pull Request Template
```markdown
## Description
[Brief description of changes]

## Issue Reference
Fixes #{issue-number}

## Type of Change
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality) 
- [ ] Breaking change (fix or feature that causes existing functionality to change)
- [ ] Documentation update

## Testing Performed
- [ ] Unit tests updated/added
- [ ] Integration tests updated/added  
- [ ] Manual testing completed
- [ ] UAT validation completed

## Platform Testing
- [ ] Android tested
- [ ] iOS tested  
- [ ] Web tested

## Screenshots
[Add screenshots if UI changes]

## Additional Notes
[Any additional context]
```

## 🔧 Issue Triage Process

### Daily Triage (During UAT)
1. **New Issue Review** (15 min)
   - Review all new issues reported in last 24 hours
   - Apply initial classification (priority/severity/type)
   - Assign to appropriate team member

2. **Priority Assessment**  
   - P0: Address immediately
   - P1: Plan for current sprint
   - P2: Add to backlog for next sprint
   - P3: Add to backlog for future consideration

3. **Duplicate Detection**
   - Check for existing similar issues
   - Link related issues
   - Close duplicates with reference to original

### Weekly Review (Post-UAT/Ongoing)
1. **Backlog Grooming**
   - Review P2/P3 backlog items
   - Re-prioritize based on user feedback
   - Close stale or irrelevant issues

2. **Progress Review**
   - Check status of in-progress issues
   - Identify blocked items
   - Update stakeholders on critical issues

## 📊 Tracking Tools and Templates

### Option 1: GitHub Issues (Recommended)
- **Pros:** Integrated with code, free, good automation
- **Cons:** Requires GitHub account for reporters
- **Setup:** Issue templates in `.github/ISSUE_TEMPLATE/`

### Option 2: Local Tracking Spreadsheet
- **Pros:** Simple, offline access, customizable
- **Cons:** No automation, harder to collaborate
- **Template:** Available in `docs/ISSUE_TRACKING_TEMPLATE.xlsx`

### Option 3: Dedicated Tool (Future)
- **Options:** Jira, Linear, Asana, Monday.com
- **When:** If issue volume grows significantly
- **Migration:** Export data from current system

## 📈 Metrics and Reporting

### Key Metrics to Track
- **Issues by Priority:** P0, P1, P2, P3 distribution
- **Issues by Type:** Bug vs Feature vs Enhancement
- **Resolution Time:** Average time to resolve by priority
- **Platform Distribution:** Issues by platform (Android/iOS/Web)
- **UAT Effectiveness:** Issues found during UAT vs post-release

### Weekly Report Template
```markdown
## Issue Tracking Report - Week of [Date]

### Summary
- **New Issues:** {count}
- **Resolved Issues:** {count}  
- **Active Issues:** {count}
- **Critical Issues:** {count}

### By Priority
- P0: {count} ({resolved} resolved)
- P1: {count} ({resolved} resolved)
- P2: {count} ({resolved} resolved)  
- P3: {count} ({resolved} resolved)

### By Platform
- Android: {count}
- iOS: {count}
- Web: {count}
- Cross-platform: {count}

### Notable Issues
[Brief description of critical or interesting issues]

### Blockers
[Any issues blocking development or release]

### Upcoming Focus
[Priorities for next week]
```

## 🎯 UAT Execution Integration

### Pre-UAT Setup
1. **Create UAT milestone** in tracking system
2. **Set up UAT-specific labels/categories**
3. **Brief testers** on reporting process
4. **Establish daily triage schedule**

### During UAT
1. **Daily issue triage meetings** (15-30 min)
2. **Real-time issue classification**  
3. **Immediate hotfixes** for P0 issues
4. **Regular communication** with UAT team

### Post-UAT Analysis
1. **UAT effectiveness review**
2. **Issue pattern analysis**  
3. **Process improvement recommendations**
4. **Release readiness assessment**

## 🚀 Getting Started

### Immediate Actions (Next 24 Hours)
1. **Set up GitHub Issue Templates**
   - Copy templates from this document
   - Configure labels and milestones
   - Test with sample issues

2. **Brief UAT Team**
   - Share this document
   - Walk through reporting process
   - Set expectations for issue quality

3. **Create Initial Labels/Categories**
   - Priority labels (P0-P3)
   - Type labels (bug, feature, enhancement)
   - Platform labels (android, ios, web)
   - UAT-specific labels

### Week 1 Goals
- [ ] All team members familiar with process
- [ ] Issue templates configured and tested
- [ ] Daily triage schedule established  
- [ ] First UAT issues reported and triaged
- [ ] Hotfix process tested with P1 issue

## 📞 Roles and Responsibilities

### Issue Reporter
- Use appropriate template
- Provide clear reproduction steps
- Include relevant screenshots/videos
- Respond to clarification requests

### Triage Lead
- Daily review of new issues
- Priority and severity assignment
- Assignment to appropriate team member
- Stakeholder communication for critical issues

### Developer  
- Accurate effort estimates
- Clear progress updates
- Thorough testing before marking complete
- Documentation of solution approach

### UAT Lead
- Verification of bug fixes
- Acceptance criteria validation
- Final sign-off on resolved issues
- Process improvement feedback

## 📝 Document Maintenance

- **Review Frequency:** Weekly during UAT, monthly thereafter
- **Update Triggers:** Process gaps identified, tool changes, team feedback
- **Owner:** Project Lead
- **Approvers:** Development Team, UAT Lead

---

**Next Steps:** 
1. Review and customize templates for your needs
2. Set up chosen tracking tool (recommend GitHub Issues)
3. Brief UAT team on process
4. Begin issue tracking with first UAT execution

**Document Status:** Ready for implementation  
**Last Updated:** April 6, 2026