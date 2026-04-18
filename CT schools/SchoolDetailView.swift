import SwiftUI
import MapKit

// Detailed view for a single school
struct SchoolDetailView: View {
    let school: School
    @Bindable var favoritesManager: FavoritesManager
    @State private var region: MKCoordinateRegion?
    @State private var showingShareSheet = false
    
    var body: some View {
        ZStack {
            // Animated gradient background
            AnimatedGradientBackground()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text(school.name ?? "Unknown School")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        if let district = school.districtName {
                            Text(district)
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                        
                        if let orgType = school.organizationType {
                            Text(orgType)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial)
                
                // Map Section
                if let lat = school.geocodedColumn?.latitude,
                   let lon = school.geocodedColumn?.longitude,
                   let latitude = Double(lat),
                   let longitude = Double(lon) {
                    Map(position: .constant(.region(MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )))) {
                        Marker(school.name ?? "School", coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                    }
                    .frame(height: 250)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Contact Information
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Contact Information", icon: "envelope.fill")
                        
                        if let address = school.address {
                            InfoRow(icon: "location.fill", title: "Address", value: address)
                        }
                        
                        if let town = school.town {
                            InfoRow(icon: "building.2.fill", title: "Town", value: town)
                        }
                        
                        if let zipcode = school.zipcode {
                            InfoRow(icon: "mappin.circle.fill", title: "Zip Code", value: zipcode)
                        }
                        
                        if let phone = school.phone {
                            HStack {
                                Label("Phone", systemImage: "phone.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Link(phone, destination: URL(string: "tel:\(phone.filter { $0.isNumber })")!)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                .liquidGlass(intensity: 0.6, tint: Color(red: 0.2, green: 0.6, blue: 0.9))
                .padding(.horizontal)
                
                // School Information
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "School Information", icon: "building.columns.fill")
                        
                        if let gradeRange = school.gradeRange {
                            InfoRow(icon: "graduationcap.fill", title: "Grades", value: gradeRange)
                        }
                        
                        if let orgCode = school.organizationCode {
                            InfoRow(icon: "number", title: "Organization Code", value: orgCode)
                        }
                        
                        if let openDate = school.studentOpenDate {
                            InfoRow(icon: "calendar", title: "Opening Date", value: openDate)
                        }
                        
                        if let magnet = school.interdistrictMagnet {
                            InfoRow(icon: "star.fill", title: "Interdistrict Magnet", value: magnet == "Y" ? "Yes" : "No")
                        }
                    }
                }
                .liquidGlass(intensity: 0.6, tint: Color(red: 0.6, green: 0.4, blue: 0.9))
                .padding(.horizontal)
                
                // Grade Levels Detail
                if let gradesOffered = school.gradesOffered {
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Grade Levels Offered", icon: "list.bullet.clipboard.fill")
                            
                            Text(gradesOffered)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundStyle(.primary)
                                .padding(.top, 4)
                        }
                    }
                    .liquidGlass(intensity: 0.6, tint: Color(red: 0.2, green: 0.7, blue: 0.5))
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 20)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    // Share button
                    Button {
                        showingShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    
                    // Favorite button
                    Button {
                        favoritesManager.toggleFavorite(school.id)
                    } label: {
                        Image(systemName: favoritesManager.isFavorite(school.id) ? "heart.fill" : "heart")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(favoritesManager.isFavorite(school.id) ? Color.red : Color.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [generateShareText()])
        }
    }
    
    private func generateShareText() -> String {
        var text = ""
        
        if let name = school.name {
            text += "\(name)\n"
        }
        
        if let district = school.districtName {
            text += "District: \(district)\n"
        }
        
        if let orgType = school.organizationType {
            text += "Type: \(orgType)\n"
        }
        
        if let gradesOffered = school.gradesOffered {
            text += "Grades: \(gradesOffered)\n"
        }
        
        if let address = school.address, let town = school.town, let zip = school.zipcode {
            text += "Address: \(address), \(town), CT \(zip)\n"
        }
        
        if let phone = school.phone {
            text += "Phone: \(phone)\n"
        }
        
        text += "\nShared from CT Schools App"
        
        return text
    }
}

// Share sheet wrapper for UIActivityViewController
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Section header component
struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        Label(title, systemImage: icon)
            .font(.headline)
            .foregroundStyle(.primary)
    }
}

// Info row component
struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
        }
    }
}

// Grade chip component
struct GradeChip: View {
    let label: String
    let offered: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Text(label)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(offered ? .white : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(offered ? Color.blue : (colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2)))
            .cornerRadius(8)
            .opacity(offered ? 1.0 : 0.5)
    }
}

#Preview {
    NavigationStack {
        SchoolDetailView(school: School(
            name: "Sample Elementary School",
            districtName: "Hartford School District",
            organizationType: "Public Schools",
            organizationCode: "12345",
            address: "123 Main St",
            town: "Hartford",
            zipcode: "06103",
            phone: "(860) 555-0123",
            studentOpenDate: "1995-09-01",
            interdistrictMagnet: "Y",
            prekindergarten: "Y",
            kindergarten: "Y",
            grade1: "Y",
            grade2: "Y",
            grade3: "Y",
            grade4: "Y",
            grade5: "Y",
            grade6: "N",
            grade7: "N",
            grade8: "N",
            grade9: "N",
            grade10: "N",
            grade11: "N",
            grade12: "N",
            geocodedColumn: GeocodedColumn(
                latitude: "41.7658",
                longitude: "-72.6734",
                humanAddress: nil
            )
        ), favoritesManager: FavoritesManager())
    }
}
