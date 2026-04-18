import SwiftUI
import MapKit

// User-friendly view for controlling proximity-based filtering
struct ProximityControlView: View {
    @Bindable var viewModel: SchoolViewModel
    @Bindable var locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedRadius: Double = 10.0
    @State private var useCustomLocation = false
    @State private var customLocationText = ""
    @State private var customLocationName: String?
    @State private var isSearchingLocation = false
    @State private var searchError: String?
    
    let radiusOptions: [Double] = [1, 5, 10, 25, 50, 100]
    
    var body: some View {
        NavigationStack {
            Form {
                // Current Location Section
                Section {
                    if !locationManager.isAuthorized {
                        locationPermissionView
                    } else if let address = locationManager.userAddress {
                        currentLocationView(address: address)
                    } else {
                        loadingLocationView
                    }
                } header: {
                    Text("Your Location")
                }
                
                // Custom Location Section
                Section {
                    Toggle("Search Different Location", isOn: $useCustomLocation)
                        .tint(.blue)
                    
                    if useCustomLocation {
                        customLocationInputView
                    }
                } header: {
                    Text("Find Schools Near")
                } footer: {
                    if !useCustomLocation {
                        Text("Turn on to search schools near a different city or address")
                    }
                }
                
                // Distance Range Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Within \(selectedRadius == 1 ? "1 mile" : "\(Int(selectedRadius)) miles")")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                        
                        Picker("Distance Range", selection: $selectedRadius) {
                            ForEach(radiusOptions, id: \.self) { radius in
                                Text(radius == 1 ? "1 mi" : "\(Int(radius)) mi")
                                    .tag(radius)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Distance Range")
                }
                
                // Action Section
                Section {
                    if viewModel.proximityFilter != nil {
                        activeFilterView
                    } else {
                        Button {
                            applyProximityFilter()
                        } label: {
                            HStack {
                                Spacer()
                                Image(systemName: "location.circle.fill")
                                Text("Find Nearby Schools")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                        .disabled(!canApplyFilter)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
            }
            .navigationTitle("Nearby Schools")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if !locationManager.isAuthorized {
                    locationManager.requestLocationPermission()
                }
                locationManager.startUpdatingLocation()
            }
        }
    }
    
    // MARK: - View Components
    
    private var locationPermissionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "location.slash.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                Text("Location Access Needed")
                    .font(.headline)
            }
            
            Text("To find schools near you, please allow location access.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Button {
                locationManager.requestLocationPermission()
            } label: {
                HStack {
                    Image(systemName: "location.fill")
                    Text("Enable Location")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(.vertical, 8)
    }
    
    private func currentLocationView(address: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.gradient)
                    .frame(width: 50, height: 50)
                
                Image(systemName: "location.fill")
                    .foregroundStyle(.white)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(address)
                    .font(.headline)
                
                Text("Current location")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.title2)
        }
        .padding(.vertical, 4)
    }
    
    private var loadingLocationView: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text("Finding your location...")
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    private var customLocationInputView: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Enter a city or address")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    
                    TextField("e.g., Hartford, CT", text: $customLocationText)
                        .textFieldStyle(.plain)
                        .autocapitalization(.words)
                        .submitLabel(.search)
                        .onSubmit {
                            Task {
                                await searchLocation()
                            }
                        }
                    
                    if !customLocationText.isEmpty {
                        Button {
                            customLocationText = ""
                            viewModel.customLocation = nil
                            customLocationName = nil
                            searchError = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            
            if isSearchingLocation {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Searching...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            if let error = searchError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.subheadline)
                }
                .foregroundStyle(.orange)
            }
            
            if let locationName = customLocationName {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.purple.gradient)
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(locationName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Custom location set")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            Button {
                Task {
                    await searchLocation()
                }
            } label: {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Search Location")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(customLocationText.isEmpty || isSearchingLocation)
        }
    }
    
    private var activeFilterView: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Filter Active")
                        .font(.headline)
                    
                    let locationDesc = useCustomLocation && customLocationName != nil ? customLocationName! : (locationManager.userAddress ?? "your location")
                    Text("Showing schools within \(Int(selectedRadius)) mile\(selectedRadius == 1 ? "" : "s") of \(locationDesc)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            
            Button(role: .destructive) {
                clearFilters()
            } label: {
                HStack {
                    Image(systemName: "xmark.circle")
                    Text("Clear Location Filter")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }
    
    // MARK: - Helper Properties & Functions
    
    private var canApplyFilter: Bool {
        if useCustomLocation {
            return viewModel.customLocation != nil
        } else {
            return locationManager.userLocation != nil
        }
    }
    
    private func applyProximityFilter() {
        let location: CLLocationCoordinate2D?
        
        if useCustomLocation {
            location = viewModel.customLocation
        } else if let userLoc = locationManager.userLocation {
            location = userLoc.coordinate
        } else {
            location = nil
        }
        
        guard let loc = location else { return }
        
        viewModel.proximityFilter = SchoolViewModel.ProximityFilter(
            location: loc,
            radiusMiles: selectedRadius
        )
        viewModel.applyFilters()
        dismiss()
    }
    
    private func clearFilters() {
        viewModel.proximityFilter = nil
        viewModel.customLocation = nil
        useCustomLocation = false
        customLocationText = ""
        customLocationName = nil
        searchError = nil
        viewModel.applyFilters()
    }
    
    private func searchLocation() async {
        guard !customLocationText.isEmpty else { return }
        
        isSearchingLocation = true
        searchError = nil
        
        let geocoder = CLGeocoder()
        
        do {
            let placemarks = try await geocoder.geocodeAddressString(customLocationText)
            
            if let placemark = placemarks.first,
               let location = placemark.location {
                viewModel.customLocation = location.coordinate
                customLocationName = formatPlacemark(placemark)
                searchError = nil
            } else {
                searchError = "Location not found. Try a different search."
                viewModel.customLocation = nil
                customLocationName = nil
            }
        } catch {
            searchError = "Unable to find this location. Please try again."
            viewModel.customLocation = nil
            customLocationName = nil
        }
        
        isSearchingLocation = false
    }
    
    private func formatPlacemark(_ placemark: CLPlacemark) -> String {
        var parts: [String] = []
        
        if let locality = placemark.locality {
            parts.append(locality)
        }
        if let state = placemark.administrativeArea {
            parts.append(state)
        }
        
        return parts.isEmpty ? customLocationText : parts.joined(separator: ", ")
    }
}

#Preview {
    ProximityControlView(
        viewModel: SchoolViewModel(),
        locationManager: LocationManager()
    )
}
