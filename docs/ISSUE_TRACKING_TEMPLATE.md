# Issue Tracking Spreadsheet Template

This CSV template can be imported into Excel, Google Sheets, or any spreadsheet application for local issue tracking.

## Column Definitions

| Column | Description | Valid Values |
|--------|-------------|--------------|
| Issue_ID | Unique identifier | Auto-increment: ISSUE-001, ISSUE-002, etc. |
| Title | Brief, descriptive title | Free text |
| Type | Issue category | Bug, Feature, Enhancement, Security, UAT |
| Priority | Priority level | P0, P1, P2, P3 |
| Severity | Impact level | Blocker, Major, Minor, Trivial |
| Status | Current state | New, Triaged, In Progress, In Review, Testing, Closed |
| Platform | Affected platforms | Android, iOS, Web, All |
| Reporter | Who reported it | Name or role |
| Assignee | Who's working on it | Name |
| Date_Reported | When reported | YYYY-MM-DD |
| Date_Resolved | When resolved | YYYY-MM-DD |
| Description | Detailed description | Free text |
| Steps_to_Reproduce | How to reproduce | Free text |
| Expected_Behavior | What should happen | Free text |
| Actual_Behavior | What actually happens | Free text |
| Resolution_Notes | How it was fixed | Free text |
| UAT_Related | UAT context | Yes, No |
| Git_Branch | Related branch | branch-name |
| Commit_Hash | Resolution commit | git hash |
| Test_Status | Testing verification | Not Started, In Progress, Passed, Failed |

## CSV Template

```csv
Issue_ID,Title,Type,Priority,Severity,Status,Platform,Reporter,Assignee,Date_Reported,Date_Resolved,Description,Steps_to_Reproduce,Expected_Behavior,Actual_Behavior,Resolution_Notes,UAT_Related,Git_Branch,Commit_Hash,Test_Status
ISSUE-001,Sample Bug Report,Bug,P2,Minor,New,Android,UAT Tester 1,,2026-04-06,,Sample description,1. Step one\n2. Step two,Expected result,Actual result,,Yes,,,Not Started
ISSUE-002,Sample Feature Request,Feature,P3,N/A,Triaged,All,Product Owner,Developer A,2026-04-06,,Sample feature description,,,,,No,,,Not Started
ISSUE-003,Sample Enhancement,Enhancement,P2,Minor,Closed,iOS,UAT Tester 2,Developer B,2026-04-05,2026-04-06,Sample enhancement,1. Navigate to settings,Setting should save,Setting doesn't persist,Fixed SharedPreferences implementation,Yes,feature/user-acceptance-testing,abc123f,Passed
```

## Usage Instructions

1. **Copy the CSV content above** into a new file named `issue_tracking.csv`
2. **Import into your preferred spreadsheet application**
3. **Customize columns** as needed for your workflow
4. **Add filtering and sorting** to view issues by status, priority, etc.
5. **Use conditional formatting** to highlight high-priority items
6. **Export regularly** for backup and sharing

## Spreadsheet Setup Tips

### Excel/Google Sheets Formatting
- **Freeze top row** for column headers
- **Auto-filter on all columns** for easy sorting
- **Conditional formatting** for priority and status
- **Data validation** for dropdown columns (Priority, Status, etc.)
- **Text wrapping** for description columns

### Recommended Views
- **Active Issues:** Status != Closed
- **High Priority:** Priority = P0 or P1
- **UAT Issues:** UAT_Related = Yes
- **My Issues:** Assignee = [Your Name]
- **This Week:** Date_Reported >= [Week Start]

### Color Coding Suggestions
- **P0 Issues:** Red background
- **P1 Issues:** Orange background  
- **Closed Issues:** Green text
- **UAT Issues:** Blue border
- **Overdue:** Yellow background (if due date added)

## Maintenance

1. **Daily:** Update status for active issues
2. **Weekly:** Review and triage new issues
3. **Monthly:** Archive resolved issues, update process as needed
4. **Export backup** regularly to prevent data loss

This template provides the same tracking capability as GitHub Issues while keeping everything local and customizable to your specific needs.