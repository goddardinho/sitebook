# Enhanced Search and Filtering System

**Issue Type:** Feature Enhancement  
**Priority:** Medium  
**Status:** Open  
**Assignee:** TBD  
**Labels:** `enhancement`, `ui`, `search`, `filters`

## Summary

Implement comprehensive search and filtering capabilities for campground discovery, including radius selection, state-based filtering, and enhanced amenity filtering.

## Background

The current search system has basic text search functionality, but users need more granular control over their search parameters to find relevant campgrounds efficiently.

## Current State

### ✅ Working Features
- Basic text search functionality
- Location-based campground discovery
- Recreation.gov API integration
- National Parks inclusion via enhanced filtering
- Amenity filtering system (18 common amenities)
- Reactive state management with Riverpod

### ❌ Missing Features
- **Search radius selector UI** - Implementation exists but not visible to users
- State-based filtering (search within specific states)
- Advanced amenity categories
- Distance display in search results
- Search history/saved searches

## Detailed Requirements

### 1. Search Radius Selection
**Problem:** Users cannot control search radius despite backend implementation being complete.

**Requirements:**
- [ ] Fix UI visibility issue for radius selector dropdown
- [ ] Display options: 10, 25, 50, 100, 200, 500 miles
- [ ] Default to 50 miles for reasonable search scope
- [ ] Persist radius selection during session
- [ ] Reset radius when clearing all filters

**Technical Notes:**
- Backend logic implemented in `searchRadiusProvider` 
- UI component `_buildRadiusSelector()` exists but not displaying
- May be layout/formatting issue in `campgrounds_screen.dart`

### 2. State-Based Filtering
**Problem:** Users searching for campgrounds in specific states get results from neighboring states.

**Requirements:**
- [ ] Add state dropdown filter in search UI
- [ ] Support multiple state selection
- [ ] Integrate with Recreation.gov state-based API queries
- [ ] Show state information in campground results
- [ ] Clear state filter option

**Implementation Notes:**
- Add `stateFiltersProvider` similar to existing `amenityFiltersProvider`
- Modify `location_based_campground_service.dart` to include state parameter
- Update search results UI to display state information

### 3. Enhanced Amenity Filtering
**Problem:** Current amenity filtering covers basic needs but lacks advanced categories.

**Current Amenities (18):**
- Basic: Restrooms, Showers, Potable Water, Picnic Tables
- Activities: Hiking Trails, Swimming, Fishing, Boating
- Utilities: Electricity, RV Hookups, Internet, Cell Service
- Facilities: Store, Restaurant, Amphitheater, Visitor Center
- Accessibility: ADA Accessible, Pet Friendly

**Additional Categories Needed:**
- [ ] **Camping Types:** Tent Sites, RV Sites, Group Sites, Cabin Rentals
- [ ] **Recreation:** Mountain Biking, Horseback Riding, Rock Climbing, Wildlife Viewing
- [ ] **Seasonal:** Winter Activities, Beach Access, Fall Foliage
- [ ] **Utilities:** Full Hookups (30/50 amp), Dump Station, Laundry, WiFi Quality
- [ ] **Services:** Firewood Sales, Ice, Propane, Equipment Rentals

### 4. Search Results Enhancements
**Problem:** Search results lack contextual information for decision-making.

**Requirements:**
- [ ] Display distance from user location
- [ ] Show state/region information
- [ ] Highlight matching amenities in results
- [ ] Sort options (distance, popularity, amenities, price)
- [ ] "More like this" suggestions based on selected campgrounds

### 5. Search Experience Improvements
**Problem:** Users lose search context and have to re-enter parameters.

**Requirements:**
- [ ] Search history (last 5 searches)
- [ ] Save favorite search parameters
- [ ] Quick filter presets ("Family Friendly", "RV Ready", "Primitive Camping")
- [ ] Search parameter chips showing active filters
- [ ] One-tap clear all vs. individual filter clearing

## Implementation Plan

### Phase 1: Fix Existing Issues (1-2 days)
1. Debug and fix search radius selector UI visibility
2. Verify all current filtering works properly
3. Add distance display to search results

### Phase 2: State Filtering (2-3 days)
1. Add state selection UI component
2. Implement state-based API filtering
3. Update search results with state information
4. Test cross-state search scenarios

### Phase 3: Enhanced Amenities (3-4 days)
1. Research Recreation.gov facility activity data for additional amenities
2. Implement expanded amenity categories
3. Update filtering logic and UI
4. Test amenity-based search accuracy

### Phase 4: Search Experience (2-3 days)
1. Add search history functionality
2. Implement search parameter persistence
3. Create quick filter presets
4. Add search result sorting options

## Technical Implementation Notes

### Files to Modify
- `lib/features/campgrounds/campgrounds_screen.dart` - Search UI and radius selector fix
- `lib/shared/providers/campground_providers_live.dart` - State filtering provider
- `lib/shared/services/location_based_campground_service.dart` - Enhanced filtering logic
- `lib/shared/services/recreation_gov_api_service.dart` - State-based API queries
- New file: `lib/shared/models/search_preferences.dart` - Search history/preferences

### API Considerations
- Verify Recreation.gov API supports state-based filtering
- Check rate limits for multiple filter combinations
- Optimize API calls to avoid redundant requests
- Consider caching frequently accessed filter combinations

## Testing Requirements

### Unit Tests
- [ ] Search radius selection logic
- [ ] State filtering combinations
- [ ] Amenity filter interactions
- [ ] Search parameter persistence

### Integration Tests
- [ ] API response handling with multiple filters
- [ ] UI state management across filter changes
- [ ] Search result sorting and display
- [ ] Cross-platform (Android/iOS) filter behavior

### User Acceptance Testing
- [ ] Search radius affects results appropriately
- [ ] State filtering returns accurate results
- [ ] Amenity combinations work as expected
- [ ] Search experience is intuitive and fast

## Definition of Done

### Functionality
- [ ] All filter types work individually and in combination
- [ ] Search results accurately reflect selected parameters
- [ ] Filter state persists during user session
- [ ] Performance acceptable with multiple filters applied

### User Experience
- [ ] Search interface is intuitive and responsive
- [ ] Clear visual feedback for active filters
- [ ] Easy to clear individual or all filters
- [ ] Search results load quickly (<2 seconds)

### Code Quality
- [ ] Unit tests cover new filtering logic
- [ ] Integration tests verify API interactions
- [ ] Code follows project architecture patterns
- [ ] Documentation updated for new features

## Related Issues/Dependencies
- Recreation.gov API documentation review
- Location services accuracy requirements
- Performance optimization for complex queries
- Offline search capability (future consideration)

---

**Created:** April 30, 2026  
**Last Updated:** April 30, 2026  
**Estimated Effort:** 8-12 days development + 2-3 days testing