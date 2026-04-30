#!/usr/bin/env python3
"""
GitHub Issue Creation Script for Enhanced Search and Filtering System
Requires: requests library (pip install requests)
Usage: python scripts/create_github_issues.py
"""

import json
import requests
import os
import sys
from typing import Dict, List

# Configuration
GITHUB_API_URL = "https://api.github.com"
REPO_OWNER = ""  # Set your GitHub username/organization
REPO_NAME = ""   # Set your repository name

def get_github_token():
    """Get GitHub token from environment variable."""
    token = os.environ.get('GITHUB_TOKEN')
    if not token:
        print("❌ GitHub token not found!")
        print("📝 Set environment variable: export GITHUB_TOKEN='your_token_here'")
        print("🔑 Create token at: https://github.com/settings/tokens")
        sys.exit(1)
    return token

def create_github_issue(token: str, issue_data: Dict) -> requests.Response:
    """Create a single GitHub issue."""
    url = f"{GITHUB_API_URL}/repos/{REPO_OWNER}/{REPO_NAME}/issues"
    headers = {
        'Authorization': f'token {token}',
        'Accept': 'application/vnd.github.v3+json',
        'Content-Type': 'application/json'
    }

    response = requests.post(url, headers=headers, json=issue_data)
    return response

def load_issues_data() -> List[Dict]:
    """Load issue data from JSON file."""
    try:
        with open('scripts/github_issues_data.json', 'r') as f:
            data = json.load(f)
            return data['issues']
    except FileNotFoundError:
        print("❌ github_issues_data.json not found!")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"❌ Invalid JSON: {e}")
        sys.exit(1)

def main():
    """Main execution function."""
    # Check configuration
    if not REPO_OWNER or not REPO_NAME:
        print("❌ Repository configuration missing!")
        print("📝 Edit REPO_OWNER and REPO_NAME in this script")
        sys.exit(1)

    # Get GitHub token
    token = get_github_token()

    # Load issue data
    issues = load_issues_data()

    print(f"🚀 Creating {len(issues)} GitHub issues for Enhanced Search and Filtering...")
    print(f"📍 Repository: {REPO_OWNER}/{REPO_NAME}")
    print()

    created_issues = []

    for i, issue_data in enumerate(issues, 1):
        title = issue_data['title']
        print(f"📝 Creating Issue {i}: {title}")

        try:
            response = create_github_issue(token, issue_data)

            if response.status_code == 201:
                issue_info = response.json()
                created_issues.append({
                    'title': title,
                    'number': issue_info['number'],
                    'url': issue_info['html_url']
                })
                print(f"   ✅ Created: #{issue_info['number']}")
            else:
                print(f"   ❌ Failed: {response.status_code} - {response.text}")

        except requests.RequestException as e:
            print(f"   ❌ Error: {e}")

        print()

    # Summary
    print("=" * 60)
    print(f"✅ Successfully created {len(created_issues)} issues:")
    print()

    for issue in created_issues:
        print(f"#{issue['number']}: {issue['title']}")
        print(f"   🔗 {issue['url']}")
        print()

    if len(created_issues) < len(issues):
        failed_count = len(issues) - len(created_issues)
        print(f"⚠️  {failed_count} issues failed to create")

    print("📋 Next Steps:")
    print("1. Review created issues in GitHub")
    print("2. Prioritize based on user feedback")
    print("3. Assign to team members")
    print("4. Set up project board for tracking")

if __name__ == "__main__":
    main()
