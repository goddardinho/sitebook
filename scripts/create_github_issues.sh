#!/bin/bash
# GitHub Issue Creation Script for Enhanced Search and Filtering System
# Requires: gh CLI tool (https://cli.github.com/)
# Usage: ./scripts/create_github_issues.sh

set -e

# Check if GitHub CLI is installed and authenticated
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed"
    echo "📥 Install from: https://cli.github.com/"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub"
    echo "🔐 Run: gh auth login"
    exit 1
fi

echo "🚀 Creating GitHub issues for Enhanced Search and Filtering System..."

# Create necessary labels if they don't exist
echo "🏷️ Setting up GitHub labels..."
gh label create "bug" --color "d73a4a" --description "Something isn't working" --force 2>/dev/null || true
gh label create "enhancement" --color "a2eeef" --description "New feature or request" --force 2>/dev/null || true
gh label create "ui" --color "1d76db" --description "User interface related" --force 2>/dev/null || true
gh label create "search" --color "0e8a16" --description "Search functionality" --force 2>/dev/null || true
gh label create "filters" --color "fbca04" --description "Filtering system" --force 2>/dev/null || true
gh label create "high-priority" --color "e99695" --description "Critical issues that block core functionality" --force 2>/dev/null || true
gh label create "ux" --color "c5def5" --description "User experience improvements" --force 2>/dev/null || true
gh label create "productivity" --color "bfdadc" --description "Features that improve user efficiency" --force 2>/dev/null || true

echo "✅ Labels created/updated"
echo ""

# Issue 1: Search Radius Selector Fix (High Priority)
echo "📍 Creating Issue 1: Search Radius Selector Fix"
gh issue create \
    --title "Fix Search Radius Selector UI Visibility" \
    --label "bug,ui,high-priority" \
    --assignee "@me" \
    --body "## Problem
Users cannot control search radius despite backend implementation being complete.

## Current State
- ✅ Backend logic implemented in \`searchRadiusProvider\`
- ✅ UI component \`_buildRadiusSelector()\` exists
- ❌ Dropdown not visible to users

## Requirements
- [ ] Debug UI visibility issue for radius selector dropdown
- [ ] Display options: 10, 25, 50, 100, 200, 500 miles
- [ ] Default to 50 miles for reasonable search scope
- [ ] Persist radius selection during session
- [ ] Reset radius when clearing all filters

## Technical Notes
- Layout/formatting issue in \`campgrounds_screen.dart\`
- May be related to \`_isSearching\` state management
- Expand header height may need adjustment

## Files to Check
- \`lib/features/campgrounds/campgrounds_screen.dart\`
- \`lib/shared/providers/campground_providers_live.dart\`

## Definition of Done
- [ ] Radius selector dropdown appears when search icon is tapped
- [ ] All radius options (10-500 miles) are selectable
- [ ] Search results update when radius changes
- [ ] Radius resets properly when search is cleared

**Priority:** High - Core search functionality not working
**Estimate:** 1-2 days"

# Issue 2: State-Based Filtering
echo "🗺️ Creating Issue 2: State-Based Filtering"
gh issue create \
    --title "Add State-Based Campground Filtering" \
    --label "enhancement,search,filters" \
    --body "## Problem
Users searching for campgrounds in specific states get results from neighboring states, making trip planning difficult.

## Requirements
- [ ] Add state dropdown filter in search UI
- [ ] Support multiple state selection
- [ ] Integrate with Recreation.gov state-based API queries
- [ ] Show state information in campground results
- [ ] Clear state filter option

## Implementation Plan
1. **Add State Provider**
   - Create \`stateFiltersProvider\` similar to \`amenityFiltersProvider\`
   - Support Set<String> for multiple states

2. **Update API Service**
   - Modify \`location_based_campground_service.dart\` to include state parameter
   - Research Recreation.gov API state filtering capabilities

3. **Enhance UI**
   - Add state selector to search interface
   - Show state information in search results
   - Add state chips for active filters

## Files to Modify
- \`lib/shared/providers/campground_providers_live.dart\`
- \`lib/shared/services/location_based_campground_service.dart\`
- \`lib/features/campgrounds/campgrounds_screen.dart\`
- \`lib/shared/services/recreation_gov_api_service.dart\`

## Acceptance Criteria
- [ ] State dropdown appears in search interface
- [ ] Multiple states can be selected simultaneously
- [ ] Search results respect state filtering
- [ ] State information displayed in results
- [ ] State filters can be cleared individually or together

**Priority:** Medium
**Estimate:** 2-3 days"

# Issue 3: Enhanced Amenity Filtering
echo "🏕️ Creating Issue 3: Enhanced Amenity Filtering"
gh issue create \
    --title "Expand Amenity Filtering Categories" \
    --label "enhancement,filters,ux" \
    --body "## Problem
Current amenity filtering covers basic needs but lacks advanced categories that campers frequently search for.

## Current Amenities (18)
- **Basic:** Restrooms, Showers, Potable Water, Picnic Tables
- **Activities:** Hiking Trails, Swimming, Fishing, Boating
- **Utilities:** Electricity, RV Hookups, Internet, Cell Service
- **Facilities:** Store, Restaurant, Amphitheater, Visitor Center
- **Accessibility:** ADA Accessible, Pet Friendly

## Additional Categories Needed
- [ ] **Camping Types:** Tent Sites, RV Sites, Group Sites, Cabin Rentals
- [ ] **Recreation:** Mountain Biking, Horseback Riding, Rock Climbing, Wildlife Viewing
- [ ] **Seasonal:** Winter Activities, Beach Access, Fall Foliage
- [ ] **Utilities:** Full Hookups (30/50 amp), Dump Station, Laundry, WiFi Quality
- [ ] **Services:** Firewood Sales, Ice, Propane, Equipment Rentals

## Implementation Plan
1. **Research Recreation.gov Data**
   - Analyze facility activity data for available amenities
   - Map API responses to new categories

2. **Update Amenity System**
   - Expand amenity list in providers
   - Organize amenities by categories
   - Update filtering logic

3. **Enhance UI**
   - Group amenities in expandable categories
   - Add category-based quick filters
   - Improve amenity selection interface

## Files to Modify
- \`lib/shared/providers/campground_providers_live.dart\`
- \`lib/shared/services/location_based_campground_service.dart\`
- Amenity filtering UI components

## Acceptance Criteria
- [ ] All new amenity categories are available for filtering
- [ ] Amenities are organized in logical categories
- [ ] Search results accurately reflect amenity selections
- [ ] UI remains performant with expanded options

**Priority:** Medium
**Estimate:** 3-4 days"

# Issue 4: Search Results Enhancement
echo "📊 Creating Issue 4: Search Results Enhancement"
gh issue create \
    --title "Enhance Search Results with Distance and Sorting" \
    --label "enhancement,ux,search" \
    --body "## Problem
Search results lack contextual information needed for decision-making, such as distance, location context, and sorting options.

## Requirements
- [ ] Display distance from user location
- [ ] Show state/region information
- [ ] Highlight matching amenities in results
- [ ] Sort options (distance, popularity, amenities, price)
- [ ] \"More like this\" suggestions based on selected campgrounds

## Implementation Details
1. **Distance Calculation**
   - Use existing location services
   - Display distance in miles/kilometers
   - Sort by distance as default option

2. **Result Enhancement**
   - Show state/region prominently
   - Highlight amenities that match filters
   - Add visual indicators for special features

3. **Sorting System**
   - Distance (default)
   - Popularity (based on Recreation.gov data)
   - Number of matching amenities
   - Price (if available)

## Files to Modify
- Search results display components
- \`lib/shared/services/location_based_campground_service.dart\`
- Result card UI components

## Acceptance Criteria
- [ ] Distance displayed for each campground
- [ ] State/region clearly visible
- [ ] Matching amenities highlighted
- [ ] Sort options work correctly
- [ ] Results load quickly (<2 seconds)

**Priority:** Medium
**Estimate:** 2-3 days"

# Issue 5: Search Experience Improvements
echo "⭐ Creating Issue 5: Search Experience Improvements"
gh issue create \
    --title "Add Search History and Quick Filters" \
    --label "enhancement,ux,productivity" \
    --body "## Problem
Users lose search context and have to re-enter parameters, making the search experience inefficient for repeated use.

## Requirements
- [ ] Search history (last 5 searches)
- [ ] Save favorite search parameters
- [ ] Quick filter presets (\"Family Friendly\", \"RV Ready\", \"Primitive Camping\")
- [ ] Search parameter chips showing active filters
- [ ] One-tap clear all vs. individual filter clearing

## Implementation Plan
1. **Search History**
   - Store recent searches in local storage
   - Display in dropdown/sheet
   - Allow quick reapplication

2. **Quick Presets**
   - Define common filter combinations
   - \"Family Friendly\": Restrooms, Showers, Playgrounds, Store
   - \"RV Ready\": Full Hookups, Dump Station, Pull-through Sites
   - \"Primitive Camping\": Minimal amenities, nature focus

3. **Active Filter Display**
   - Show chips for active filters
   - Individual clear buttons
   - Clear all option

## Files to Create/Modify
- \`lib/shared/models/search_preferences.dart\`
- \`lib/shared/providers/search_history_provider.dart\`
- Search UI components
- Local storage service

## Acceptance Criteria
- [ ] Search history persists between app sessions
- [ ] Quick presets apply correct filter combinations
- [ ] Active filters clearly visible with clear options
- [ ] Search experience is fast and intuitive

**Priority:** Low
**Estimate:** 2-3 days"

echo "✅ All issues created successfully!"
echo ""
echo "📋 Next Steps:"
echo "1. Review created issues in GitHub"
echo "2. Prioritize based on user feedback"
echo "3. Assign to team members"
echo "4. Set up project board for tracking"
echo ""
echo "🔗 View issues: gh issue list"
