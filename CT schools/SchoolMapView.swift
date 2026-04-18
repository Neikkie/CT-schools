import SwiftUI
import MapKit

// Apple Maps-style map view for schools
struct SchoolMapView: View {
    @Bindable var viewModel: SchoolViewModel
    @Bindable var favoritesManager: FavoritesManager
    @Bindable var themeManager: ThemeManager
    @State private var locationManager = LocationManager()
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedSchool: School?
    @State private var showingFilters = false
    @State private var showingSettings = false
    @State private var mapStyle: MapStyleOption = .standard
    @State private var hasSetInitialPosition = false
    @State private var searchText = ""
    @State private var showingSearch = false
    
    private var defaultRegion: MKCoordinateRegion {
        // Hartford, CT with street-level zoom
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 41.7658, longitude: -72.6734),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
    }
    
    var body: some View {
        ZStack {
            // Map layer
            mapView
                .ignoresSafeArea()
            
            // Apple Maps-style overlay UI
            VStack(spacing: 0) {
                // Top search and controls
                appleMapTopBar
                    .padding(.top, 8)
                
                Spacer()
                
                // Bottom controls (Apple Maps style)
                VStack(spacing: 12) {
                    // Map style and controls on the right
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 10) {
                            // Map style picker
                            AppleMapButton(icon: mapStyle.appleIcon) {
                                cycleMapStyle()
                            }
                            
                            // Location button
                            AppleMapButton(icon: "location.fill") {
                                centerOnUserLocation()
                            }
                            
                            // 3D toggle
                            AppleMapButton(icon: "view.3d") {
                                // Toggle 3D view
                            }
                        }
                        .padding(.trailing, 16)
                    }
                    
                    // School info card
                    if let school = selectedSchool {
                        AppleMapSchoolCard(
                            school: school,
                            distance: getDistance(to: school),
                            onClose: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedSchool = nil
                                }
                            },
                            onCall: {
                                callSchool(school)
                            },
                            favoritesManager: favoritesManager
                        )
                        .padding(.horizontal, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.bottom, selectedSchool != nil ? 16 : 90)
            }
        }
        .sheet(isPresented: $showingFilters) {
            ModernFilterView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(themeManager: themeManager)
        }
        .task {
            if viewModel.schools.isEmpty {
                await viewModel.fetchSchools()
            }
        }
        .onAppear {
            locationManager.startUpdatingLocation()
            if position == .automatic && !hasSetInitialPosition {
                position = .region(defaultRegion)
                hasSetInitialPosition = true
            }
        }
        .onChange(of: locationManager.userLocation) { oldValue, newValue in
            guard let location = newValue else { return }
            
            // Always zoom to user location with street-level detail
            withAnimation(.easeInOut(duration: 1.5)) {
                position = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                ))
                hasSetInitialPosition = true
            }
        }
    }
    
    private var appleMapTopBar: some View {
        VStack(spacing: 12) {
            // Search bar (Apple Maps style)
            HStack(spacing: 12) {
                // Search field
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    TextField("Search schools", text: $searchText)
                        .font(.system(size: 17, design: .default))
                        .submitLabel(.search)
                        .onChange(of: searchText) {
                            viewModel.searchText = searchText
                            viewModel.applyFilters()
                        }
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            viewModel.searchText = ""
                            viewModel.applyFilters()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                .glow(color: Color(red: 0.2, green: 0.6, blue: 0.9), radius: 6)
                
                // Filter button
                Button {
                    showingFilters.toggle()
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.primary)
                        .frame(width: 44, height: 44)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                }
                
                // Settings button
                Button {
                    showingSettings.toggle()
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.primary)
                        .frame(width: 44, height: 44)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.horizontal, 16)
            
            // School count chip (Apple Maps style)
            if viewModel.filteredSchools.count > 0 {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Text("\(viewModel.filteredSchools.count) schools")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.regularMaterial, in: Capsule())
                    .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                    .shimmer(duration: 3.0, bounce: false)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    private func cycleMapStyle() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch mapStyle {
            case .standard:
                mapStyle = .hybrid
            case .hybrid:
                mapStyle = .imagery
            case .imagery:
                mapStyle = .standard
            }
        }
    }
    
    private func centerOnUserLocation() {
        guard let location = locationManager.userLocation else { return }
        withAnimation(.easeInOut(duration: 0.5)) {
            position = .region(MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ))
        }
    }
    
    @ViewBuilder
    private var mapContent: some View {
        ZStack {
            if viewModel.isLoading {
                loadingView
            } else if let errorMessage = viewModel.errorMessage {
                errorView(message: errorMessage)
            } else {
                mapView
            }
        }
    }
    
    private var loadingView: some View {
        ProgressView("Loading schools...")
            .scaleEffect(1.2)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
            Text("Error")
                .font(.title)
                .fontWeight(.bold)
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Retry") {
                Task {
                    await viewModel.fetchSchools()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    @MapContentBuilder
    private var mapAnnotations: some MapContent {
        ForEach(viewModel.filteredSchools, id: \.id) { school in
            if let coordinate = schoolCoordinate(for: school) {
                Annotation("", coordinate: coordinate) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedSchool = school
                        }
                    } label: {
                        SchoolPinView(
                            school: school,
                            isSelected: selectedSchool?.id == school.id,
                            distance: getDistance(to: school)
                        )
                    }
                }
                .tag(school)
            }
        }
        
        UserAnnotation()
        
        if let customLoc = viewModel.customLocation {
            Annotation("", coordinate: customLoc) {
                CustomLocationPin()
            }
        }
    }
    

    
    private var mapView: some View {
        Map(position: $position, interactionModes: .all, selection: $selectedSchool) {
            mapAnnotations
        }
        .mapStyle(currentMapStyle)
        .mapControls {
            MapCompass()
            MapScaleView()
        }
    }
    
    private var currentMapStyle: MapStyle {
        switch mapStyle {
        case .standard:
            return .standard(elevation: .realistic)
        case .hybrid:
            return .hybrid(elevation: .realistic)
        case .imagery:
            return .imagery(elevation: .realistic)
        }
    }
    

    private func schoolCoordinate(for school: School) -> CLLocationCoordinate2D? {
        guard let lat = school.geocodedColumn?.latitude,
              let lon = school.geocodedColumn?.longitude,
              let latitude = Double(lat),
              let longitude = Double(lon) else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    private func zoomToSchool(_ school: School) {
        guard let coordinate = schoolCoordinate(for: school) else { return }
        position = .region(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    private func centerMapOnSchools() {
        let schoolsWithCoordinates = viewModel.filteredSchools.compactMap { school -> CLLocationCoordinate2D? in
            schoolCoordinate(for: school)
        }
        
        guard !schoolsWithCoordinates.isEmpty else { return }
        
        let minLat = schoolsWithCoordinates.map { $0.latitude }.min() ?? 0
        let maxLat = schoolsWithCoordinates.map { $0.latitude }.max() ?? 0
        let minLon = schoolsWithCoordinates.map { $0.longitude }.min() ?? 0
        let maxLon = schoolsWithCoordinates.map { $0.longitude }.max() ?? 0
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.3,
            longitudeDelta: (maxLon - minLon) * 1.3
        )
        
        position = .region(MKCoordinateRegion(center: center, span: span))
    }
    
    private func updateMapRegion() {
        if !viewModel.filteredSchools.isEmpty {
            centerMapOnSchools()
        }
    }
    
    private func getDistance(to school: School) -> CLLocationDistance? {
        guard let coordinate = schoolCoordinate(for: school) else { return nil }
        
        let referenceLocation: CLLocation?
        if let customLoc = viewModel.customLocation {
            referenceLocation = CLLocation(latitude: customLoc.latitude, longitude: customLoc.longitude)
        } else if let userLoc = locationManager.userLocation {
            referenceLocation = userLoc
        } else {
            return nil
        }
        
        guard let refLoc = referenceLocation else { return nil }
        let schoolLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return refLoc.distance(from: schoolLocation)
    }
    
    private func callSchool(_ school: School) {
        guard let phone = school.phone,
              let url = URL(string: "tel:\(phone.filter { $0.isNumber })") else {
            return
        }
        UIApplication.shared.open(url)
    }
    
    private func schoolsNearUser(location: CLLocation, radiusMiles: Double) -> Int {
        return viewModel.filteredSchools.filter { school in
            guard let coordinate = schoolCoordinate(for: school) else { return false }
            let schoolLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let distanceMeters = location.distance(from: schoolLocation)
            let distanceMiles = distanceMeters / 1609.34
            return distanceMiles <= radiusMiles
        }.count
    }
    
    private func markerColor(for school: School) -> Color {
        guard let dist = getDistance(to: school) else {
            return Color(red: 0.2, green: 0.6, blue: 0.9) // Modern blue
        }
        
        let miles = dist / 1609.34
        if miles < 1 {
            return Color(red: 0.2, green: 0.8, blue: 0.4) // Modern green
        } else if miles < 5 {
            return Color(red: 0.3, green: 0.7, blue: 0.85) // Teal
        } else {
            return Color(red: 0.2, green: 0.6, blue: 0.9) // Modern blue
        }
    }
}

// Map style options
enum MapStyleOption: String, CaseIterable {
    case standard = "Standard"
    case hybrid = "Hybrid"
    case imagery = "Satellite"
    
    var icon: String {
        switch self {
        case .standard: return "map"
        case .hybrid: return "map.fill"
        case .imagery: return "globe.americas.fill"
        }
    }
    
    var appleIcon: String {
        switch self {
        case .standard: return "map"
        case .hybrid: return "square.stack.3d.up.fill"
        case .imagery: return "globe"
        }
    }
}

// Apple Maps-style button
struct AppleMapButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: 40, height: 40)
                .background(.regularMaterial, in: Circle())
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
        }
        .floating(distance: 3)
    }
}

// Apple Maps-style school card
struct AppleMapSchoolCard: View {
    let school: School
    let distance: CLLocationDistance?
    let onClose: () -> Void
    let onCall: () -> Void
    @Bindable var favoritesManager: FavoritesManager
    
    private var schoolTypeColor: Color {
        guard let orgType = school.organizationType?.lowercased() else {
            return Color(red: 0.2, green: 0.6, blue: 0.9)
        }
        
        if orgType.contains("magnet") {
            return Color(red: 0.9, green: 0.3, blue: 0.5)
        } else if orgType.contains("charter") {
            return Color(red: 0.6, green: 0.4, blue: 0.9)
        } else if orgType.contains("technical") || orgType.contains("vocational") {
            return Color(red: 0.2, green: 0.7, blue: 0.5)
        } else {
            return Color(red: 0.2, green: 0.6, blue: 0.9)
        }
    }
    
    private func openInMapsStreetView() {
        guard let lat = school.geocodedColumn?.latitude,
              let lon = school.geocodedColumn?.longitude,
              let latitude = Double(lat),
              let longitude = Double(lon) else {
            return
        }
        
        let urlString = "http://maps.apple.com/?ll=\(latitude),\(longitude)&q=\(school.name?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "School")&t=m"
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .top, spacing: 12) {
                // School icon
                ZStack {
                    Circle()
                        .fill(schoolTypeColor.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(schoolTypeColor)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(school.name ?? "Unknown School")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    
                    if let district = school.districtName {
                        Text(district)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    HStack(spacing: 8) {
                        if let town = school.town {
                            HStack(spacing: 4) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 11))
                                Text(town)
                                    .font(.system(size: 13))
                            }
                            .foregroundStyle(.secondary)
                        }
                        
                        if let dist = distance {
                            Text("• \(LocationManager.formatDistance(dist))")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Close button
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(16)
            
            Divider()
            
            // Action buttons (Apple Maps style)
            HStack(spacing: 0) {
                // Directions
                Button {
                    openInMapsStreetView()
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.blue)
                        Text("Directions")
                            .font(.system(size: 12))
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                
                if school.phone != nil {
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Call
                    Button(action: onCall) {
                        VStack(spacing: 6) {
                            Image(systemName: "phone.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(Color.green)
                            Text("Call")
                                .font(.system(size: 12))
                                .foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                // Details
                NavigationLink(destination: SchoolDetailView(school: school, favoritesManager: favoritesManager)) {
                    VStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.gray)
                        Text("Details")
                            .font(.system(size: 12))
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
            .padding(.horizontal, 8)
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
        .glow(color: schoolTypeColor, radius: 10)
    }
}

// Custom school pin view with 3D building icon
struct SchoolPinView: View {
    let school: School
    let isSelected: Bool
    let distance: CLLocationDistance?
    
    private var pinColor: Color {
        guard let dist = distance else {
            return Color(red: 0.2, green: 0.6, blue: 0.9) // Modern blue
        }
        
        let miles = dist / 1609.34
        if miles < 1 {
            return Color(red: 0.2, green: 0.8, blue: 0.4) // Modern green
        } else if miles < 5 {
            return Color(red: 0.3, green: 0.7, blue: 0.85) // Teal
        } else {
            return Color(red: 0.2, green: 0.6, blue: 0.9) // Modern blue
        }
    }
    
    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                // Outer glow for selected
                if isSelected {
                    Circle()
                        .fill(pinColor.opacity(0.3))
                        .frame(width: 70, height: 70)
                        .blur(radius: 10)
                }
                
                // 3D Building Pin
                ZStack {
                    // Background circle with depth
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    pinColor.opacity(0.6),
                                    pinColor.opacity(0.9),
                                    pinColor
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: isSelected ? 56 : 40, height: isSelected ? 56 : 40)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.8), Color.white.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: isSelected ? 4 : 3
                                )
                        )
                        .shadow(color: .black.opacity(0.35), radius: isSelected ? 12 : 8, x: 0, y: isSelected ? 6 : 4)
                        .shadow(color: pinColor.opacity(0.5), radius: isSelected ? 8 : 5, x: 0, y: 0)
                    
                    // 3D Building layers
                    ZStack {
                        // Back building layer (darker for depth)
                        Image(systemName: "building.2.fill")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.5), Color.white.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .font(.system(size: isSelected ? 26 : 18, weight: .bold))
                            .offset(x: isSelected ? -1 : -0.5, y: isSelected ? 1 : 0.5)
                            .blur(radius: 0.5)
                        
                        // Front building layer (bright white)
                        Image(systemName: "building.2.fill")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.white, Color.white.opacity(0.9)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .font(.system(size: isSelected ? 26 : 18, weight: .bold))
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                        
                        // Highlight on windows
                        Image(systemName: "building.2.fill")
                            .foregroundStyle(Color.white.opacity(0.4))
                            .font(.system(size: isSelected ? 26 : 18, weight: .bold))
                            .blur(radius: 2)
                            .blendMode(.overlay)
                    }
                }
                .rotation3DEffect(
                    .degrees(isSelected ? 5 : 0),
                    axis: (x: 1, y: 1, z: 0),
                    perspective: 0.8
                )
            }
            
            // 3D Pointer for selected
            if isSelected {
                ZStack {
                    // Shadow layer
                    Image(systemName: "arrowtriangle.down.fill")
                        .foregroundStyle(Color.black.opacity(0.3))
                        .font(.system(size: 18))
                        .offset(x: 1, y: -7)
                        .blur(radius: 1)
                    
                    // Main pointer with gradient
                    Image(systemName: "arrowtriangle.down.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [pinColor.opacity(0.8), pinColor],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .font(.system(size: 18))
                        .offset(y: -8)
                        .shadow(color: .black.opacity(0.2), radius: 3)
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// Custom 3D location pin for manually added locations
struct CustomLocationPin: View {
    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(Color.purple.opacity(0.25))
                .frame(width: 60, height: 60)
                .blur(radius: 8)
            
            // 3D Pin with depth
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.purple.opacity(0.6),
                                Color.purple.opacity(0.9),
                                Color.purple
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.8), Color.white.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3.5
                            )
                    )
                    .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 5)
                    .shadow(color: Color.purple.opacity(0.5), radius: 6, x: 0, y: 0)
                
                // 3D Map pin icon with layers
                ZStack {
                    // Back layer
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(Color.white.opacity(0.4))
                        .font(.system(size: 22, weight: .bold))
                        .offset(x: -0.5, y: 0.5)
                        .blur(radius: 0.5)
                    
                    // Front layer
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.white, Color.white.opacity(0.85)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .font(.system(size: 22, weight: .bold))
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                }
            }
            .rotation3DEffect(
                .degrees(5),
                axis: (x: 1, y: 1, z: 0),
                perspective: 0.8
            )
        }
    }
}

// Enhanced school marker with distance display
struct EnhancedSchoolMarker: View {
    let school: School
    let isSelected: Bool
    let distance: CLLocationDistance?
    let showDistance: Bool
    
    private var markerColor: Color {
        if isSelected {
            return .blue
        } else if let dist = distance {
            let miles = dist / 1609.34
            if miles < 1 { return .green }
            else if miles < 5 { return .orange }
            else { return .red }
        } else {
            return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                // Outer glow for selected
                if isSelected {
                    Circle()
                        .fill(markerColor.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .blur(radius: 8)
                }
                
                // Main marker
                ZStack {
                    Circle()
                        .fill(markerColor.gradient)
                        .frame(width: isSelected ? 44 : 32, height: isSelected ? 44 : 32)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: isSelected ? 3 : 2.5)
                        )
                        .shadow(color: .black.opacity(0.3), radius: isSelected ? 8 : 4)
                    
                    Image(systemName: "building.2.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: isSelected ? 20 : 14, weight: .semibold))
                }
            }
            
            // Distance label
            if showDistance, let dist = distance {
                Text(LocationManager.formatDistance(dist))
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(markerColor.gradient)
                            .shadow(radius: 2)
                    )
            }
            
            // Pointer for selected
            if isSelected {
                Image(systemName: "arrowtriangle.down.fill")
                    .foregroundStyle(markerColor)
                    .font(.system(size: 14))
                    .offset(y: -6)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .animation(.easeInOut(duration: 0.2), value: showDistance)
    }
}

// Custom annotation view for schools on the map (legacy support)
struct SchoolAnnotationView: View {
    let school: School
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.blue : Color.red)
                    .frame(width: isSelected ? 40 : 30, height: isSelected ? 40 : 30)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: isSelected ? 3 : 2)
                    )
                    .shadow(radius: isSelected ? 6 : 3)
                
                Image(systemName: "building.2.fill")
                    .foregroundStyle(.white)
                    .font(.system(size: isSelected ? 18 : 14))
            }
            
            if isSelected {
                Image(systemName: "arrowtriangle.down.fill")
                    .foregroundStyle(Color.blue)
                    .font(.system(size: 12))
                    .offset(y: -5)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}



// Map style picker view
struct MapStylePickerView: View {
    @Binding var selectedStyle: MapStyleOption
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(MapStyleOption.allCases, id: \.self) { style in
                Button {
                    selectedStyle = style
                } label: {
                    HStack {
                        Image(systemName: style.icon)
                            .frame(width: 30)
                        Text(style.rawValue)
                        Spacer()
                        if selectedStyle == style {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding()
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                if style != MapStyleOption.allCases.last {
                    Divider()
                }
            }
        }
        .frame(width: 200)
    }
}

// Custom callout view that appears when tapping a school marker
struct CustomCalloutView: View {
    let school: School
    let distance: CLLocationDistance?
    let onNavigate: () -> Void
    let onCall: () -> Void
    @Bindable var favoritesManager: FavoritesManager
    
    private func openInMapsStreetView() {
        guard let lat = school.geocodedColumn?.latitude,
              let lon = school.geocodedColumn?.longitude,
              let latitude = Double(lat),
              let longitude = Double(lon) else {
            return
        }
        
        // Open Apple Maps with street view at the school location
        let urlString = "http://maps.apple.com/?ll=\(latitude),\(longitude)&q=\(school.name?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "School")&t=m"
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with school name and type
            VStack(alignment: .leading, spacing: 6) {
                Text(school.name ?? "Unknown School")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                if let orgType = school.organizationType {
                    Text(orgType)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.blue.gradient)
                        .cornerRadius(6)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
            
            // School details
            VStack(alignment: .leading, spacing: 10) {
                if let district = school.districtName {
                    InfoCalloutRow(
                        icon: "building.2",
                        title: "District",
                        value: district
                    )
                }
                
                if let town = school.town {
                    InfoCalloutRow(
                        icon: "mappin.circle.fill",
                        title: "Location",
                        value: town
                    )
                }
                
                if let gradeRange = school.gradeRange {
                    InfoCalloutRow(
                        icon: "graduationcap.fill",
                        title: "Grades",
                        value: gradeRange
                    )
                }
                
                if let dist = distance {
                    InfoCalloutRow(
                        icon: "location.fill",
                        title: "Distance",
                        value: LocationManager.formatDistance(dist)
                    )
                }
                
                if school.interdistrictMagnet == "Y" {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text("Interdistrict Magnet School")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            
            Divider()
            
            // Action buttons
            HStack(spacing: 0) {
                Button {
                    openInMapsStreetView()
                } label: {
                    HStack {
                        Image(systemName: "map.fill")
                        Text("Street View")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.blue.gradient)
                }
                
                Divider()
                    .frame(height: 44)
                
                if school.phone != nil {
                    CalloutActionButton(
                        icon: "phone.fill",
                        label: "Call",
                        color: .green,
                        action: onCall
                    )
                    
                    Divider()
                        .frame(height: 44)
                }
                
                NavigationLink(destination: SchoolDetailView(school: school, favoritesManager: favoritesManager)) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                        Text("Details")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.purple.gradient)
                }
            }
        }
        .frame(width: 280)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

// Info row for callout
struct InfoCalloutRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 20)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
    }
}

// Action button for callout
struct CalloutActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(label)
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(color.gradient)
        }
    }
}

// Modern marker label for clustering
struct ModernSchoolMarkerLabel: View {
    let school: School
    let distance: CLLocationDistance?
    let showDistance: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(school.name ?? "School")
                .font(.caption2)
                .fontWeight(.semibold)
                .lineLimit(1)
            
            if showDistance, let dist = distance {
                Text(LocationManager.formatDistance(dist))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// Glassmorphic button component
struct GlassmorphicButton: View {
    let icon: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(
                    isActive ?
                    LinearGradient(
                        colors: [Color(red: 0.2, green: 0.6, blue: 0.9), Color(red: 0.1, green: 0.5, blue: 0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(
                        colors: [.primary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 48, height: 48)
                .background(
                    .ultraThinMaterial,
                    in: Circle()
                )
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                .shadow(color: .black.opacity(0.04), radius: 1, x: 0, y: 1)
        }
    }
}

// Modern map style picker
struct ModernMapStylePicker: View {
    @Binding var selectedStyle: MapStyleOption
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(MapStyleOption.allCases, id: \.self) { style in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedStyle = style
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        dismiss()
                    }
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(selectedStyle == style ? Color.blue.opacity(0.15) : Color.clear)
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: style.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(
                                    selectedStyle == style ?
                                    Color(red: 0.2, green: 0.6, blue: 0.9) :
                                    Color.primary
                                )
                        }
                        
                        Text(style.rawValue)
                            .font(.system(size: 15, weight: selectedStyle == style ? .semibold : .medium, design: .rounded))
                        
                        Spacer()
                        
                        if selectedStyle == style {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(red: 0.2, green: 0.6, blue: 0.9), Color(red: 0.1, green: 0.5, blue: 0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                if style != MapStyleOption.allCases.last {
                    Divider()
                        .padding(.leading, 64)
                }
            }
        }
        .frame(width: 240)
        .background(
            .regularMaterial,
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 8)
        .presentationCompactAdaptation(.popover)
    }
}

#Preview {
    SchoolMapView(viewModel: SchoolViewModel(), favoritesManager: FavoritesManager(), themeManager: ThemeManager())
}
