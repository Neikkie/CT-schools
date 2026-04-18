import Foundation
import Observation
import CoreLocation

// ViewModel to manage school data and UI state
@MainActor
@Observable
class SchoolViewModel {
    var schools: [School] = []
    var filteredSchools: [School] = []
    var isLoading = false
    var errorMessage: String?
    var searchText = ""
    var selectedTown: String?
    var selectedOrganizationType: String?
    var proximityFilter: ProximityFilter?
    var customLocation: CLLocationCoordinate2D?
    
    private let service = SchoolService.shared
    
    struct ProximityFilter {
        let location: CLLocationCoordinate2D
        let radiusMiles: Double
    }
    
    // Get unique towns from schools
    var towns: [String] {
        let townSet = Set(schools.compactMap { $0.town })
        return townSet.sorted()
    }
    
    // Get unique organization types
    var organizationTypes: [String] {
        let typeSet = Set(schools.compactMap { $0.organizationType })
        return typeSet.sorted()
    }
    
    // Fetch schools from API
    func fetchSchools() async {
        isLoading = true
        errorMessage = nil
        
        do {
            schools = try await service.fetchSchools()
            applyFilters()
            isLoading = false
        } catch {
            errorMessage = "Failed to load schools: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // Apply filters to schools list
    func applyFilters() {
        var results = schools
        
        // Filter by proximity
        if let proximityFilter = proximityFilter {
            results = results.filter { school in
                guard let lat = school.geocodedColumn?.latitude,
                      let lon = school.geocodedColumn?.longitude,
                      let latitude = Double(lat),
                      let longitude = Double(lon) else {
                    return false
                }
                
                let schoolLocation = CLLocation(latitude: latitude, longitude: longitude)
                let filterLocation = CLLocation(
                    latitude: proximityFilter.location.latitude,
                    longitude: proximityFilter.location.longitude
                )
                let distanceMeters = schoolLocation.distance(from: filterLocation)
                let distanceMiles = distanceMeters / 1609.34
                return distanceMiles <= proximityFilter.radiusMiles
            }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            results = results.filter { school in
                (school.name?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (school.districtName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (school.town?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Filter by town
        if let town = selectedTown {
            results = results.filter { $0.town == town }
        }
        
        // Filter by organization type
        if let orgType = selectedOrganizationType {
            results = results.filter { $0.organizationType == orgType }
        }
        
        filteredSchools = results
    }
    
    // Reset all filters
    func resetFilters() {
        searchText = ""
        selectedTown = nil
        selectedOrganizationType = nil
        proximityFilter = nil
        customLocation = nil
        applyFilters()
    }
    
    // Get schools sorted by distance from a location
    func schoolsSortedByDistance(from location: CLLocationCoordinate2D) -> [SchoolWithDistance] {
        let referenceLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        return filteredSchools.compactMap { school in
            guard let lat = school.geocodedColumn?.latitude,
                  let lon = school.geocodedColumn?.longitude,
                  let latitude = Double(lat),
                  let longitude = Double(lon) else {
                return nil
            }
            
            let schoolLocation = CLLocation(latitude: latitude, longitude: longitude)
            let distance = referenceLocation.distance(from: schoolLocation)
            return SchoolWithDistance(school: school, distance: distance)
        }.sorted { $0.distance < $1.distance }
    }
}

struct SchoolWithDistance {
    let school: School
    let distance: CLLocationDistance
}
