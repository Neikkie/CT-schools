//
//  ContentView.swift
//  CT schools
//
//  Created by Shanique Beckford on 4/16/26.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = SchoolViewModel()
    @State private var favoritesManager = FavoritesManager()
    @State private var themeManager = ThemeManager()
    
    var body: some View {
        TabView {
            SchoolListView(viewModel: viewModel, favoritesManager: favoritesManager, themeManager: themeManager)
                .tabItem {
                    Label("List", systemImage: "list.bullet")
                }
            
            SchoolMapView(viewModel: viewModel, favoritesManager: favoritesManager, themeManager: themeManager)
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
            
            FavoritesView(viewModel: viewModel, favoritesManager: favoritesManager, themeManager: themeManager)
                .tabItem {
                    Label("Favorites", systemImage: "heart.fill")
                }
        }
        .preferredColorScheme(themeManager.selectedTheme.colorScheme)
    }
}

// Modern list view for schools with card-based layout
struct SchoolListView: View {
    @Bindable var viewModel: SchoolViewModel
    @Bindable var favoritesManager: FavoritesManager
    @Bindable var themeManager: ThemeManager
    @State private var showingFilters = false
    @State private var showingSettings = false
    @State private var scrollOffset: CGFloat = 0
    @State private var isRefreshing = false
    
    private var headerOpacity: Double {
        min(max(scrollOffset / 50, 0), 1)
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Animated liquid glass background
                AnimatedGradientBackground()
                
                if viewModel.isLoading {
                    VStack(spacing: 24) {
                        LoadingDots(color: Color(red: 0.2, green: 0.6, blue: 0.9))
                        Text("Loading schools...")
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = viewModel.errorMessage {
                    errorStateView(message: errorMessage)
                } else {
                    VStack(spacing: 0) {
                        // Sticky header with school count
                        stickyHeader
                            .opacity(headerOpacity)
                        
                        // Scrollable content
                        ScrollView {
                            VStack(spacing: 0) {
                                // Floating search bar
                                floatingSearchBar
                                    .padding(.horizontal, 20)
                                    .padding(.top, 16)
                                    .padding(.bottom, 8)
                                
                                // Filter chips
                                if viewModel.selectedTown != nil || viewModel.selectedOrganizationType != nil {
                                    activeFiltersView
                                        .padding(.horizontal, 20)
                                        .padding(.bottom, 12)
                                }
                                
                                // School cards
                                LazyVStack(spacing: 16) {
                                    ForEach(viewModel.filteredSchools) { school in
                                        NavigationLink(destination: SchoolDetailView(school: school, favoritesManager: favoritesManager)) {
                                            ModernSchoolCard(school: school, favoritesManager: favoritesManager)
                                        }
                                        .buttonStyle(CardButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 24)
                                
                                if viewModel.filteredSchools.isEmpty {
                                    emptyStateView
                                }
                            }
                            .background(GeometryReader { geometry in
                                Color.clear
                                    .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).minY)
                            })
                        }
                        .refreshable {
                            await refreshSchools()
                        }
                        .coordinateSpace(name: "scroll")
                        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                            scrollOffset = value
                        }
                    }
                }
                
                // Floating action buttons
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            FloatingActionButton(icon: "line.3.horizontal.decrease.circle.fill", color: Color(red: 0.2, green: 0.6, blue: 0.9)) {
                                showingFilters.toggle()
                            }
                            
                            FloatingActionButton(icon: "gearshape.fill", color: Color(red: 0.5, green: 0.5, blue: 0.5)) {
                                showingSettings.toggle()
                            }
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 0.2, green: 0.6, blue: 0.9), Color(red: 0.1, green: 0.5, blue: 0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text("CT Schools")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                ModernFilterView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(themeManager: themeManager)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(themeManager: themeManager)
            }
            .task {
                if viewModel.schools.isEmpty {
                    await viewModel.fetchSchools()
                }
            }
        }
    }
    
    private func refreshSchools() async {
        isRefreshing = true
        await viewModel.fetchSchools()
        isRefreshing = false
    }
    
    private var stickyHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(viewModel.filteredSchools.count) Schools")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                
                if viewModel.selectedTown != nil || viewModel.selectedOrganizationType != nil {
                    Text("Filtered")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.leading, 20)
            
            Spacer()
        }
        .frame(height: 50)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .fill(Color.primary.opacity(0.1))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
    
    private var floatingSearchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.secondary)
            
            TextField("Search schools, districts, or towns", text: $viewModel.searchText)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .autocorrectionDisabled()
            
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                    viewModel.applyFilters()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .liquidGlass(intensity: 0.8, tint: Color(red: 0.2, green: 0.6, blue: 0.9))
        .onChange(of: viewModel.searchText) {
            viewModel.applyFilters()
        }
    }
    
    private var activeFiltersView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let town = viewModel.selectedTown {
                    FilterChip(text: town, icon: "mappin.circle.fill") {
                        viewModel.selectedTown = nil
                        viewModel.applyFilters()
                    }
                }
                
                if let orgType = viewModel.selectedOrganizationType {
                    FilterChip(text: orgType, icon: "building.2.fill") {
                        viewModel.selectedOrganizationType = nil
                        viewModel.applyFilters()
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundStyle(.secondary.opacity(0.5))
            
            Text("No schools found")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
            
            Text("Try adjusting your search or filters")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            
            Button {
                viewModel.resetFilters()
            } label: {
                Text("Reset Filters")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.2, green: 0.6, blue: 0.9), Color(red: 0.1, green: 0.5, blue: 0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Capsule()
                    )
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 60)
        .frame(maxWidth: .infinity)
    }
    
    private func errorStateView(message: String) -> some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.orange)
            }
            
            VStack(spacing: 8) {
                Text("Oops!")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                
                Text(message)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button {
                Task {
                    await viewModel.fetchSchools()
                }
            } label: {
                Text("Try Again")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.2, green: 0.6, blue: 0.9), Color(red: 0.1, green: 0.5, blue: 0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Capsule()
                    )
                    .shadow(color: Color(red: 0.2, green: 0.6, blue: 0.9).opacity(0.3), radius: 12, x: 0, y: 6)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Scroll offset preference key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// Modern school card with glassmorphism and color coding
struct ModernSchoolCard: View {
    let school: School
    @Bindable var favoritesManager: FavoritesManager
    
    private var schoolTypeColor: (primary: Color, secondary: Color) {
        guard let orgType = school.organizationType?.lowercased() else {
            return (Color(red: 0.2, green: 0.6, blue: 0.9), Color(red: 0.1, green: 0.5, blue: 0.8))
        }
        
        if orgType.contains("magnet") {
            return (Color(red: 0.9, green: 0.3, blue: 0.5), Color(red: 0.8, green: 0.2, blue: 0.4)) // Pink/Red
        } else if orgType.contains("charter") {
            return (Color(red: 0.6, green: 0.4, blue: 0.9), Color(red: 0.5, green: 0.3, blue: 0.8)) // Purple
        } else if orgType.contains("technical") || orgType.contains("vocational") {
            return (Color(red: 0.2, green: 0.7, blue: 0.5), Color(red: 0.1, green: 0.6, blue: 0.4)) // Teal/Green
        } else {
            return (Color(red: 0.2, green: 0.6, blue: 0.9), Color(red: 0.1, green: 0.5, blue: 0.8)) // Blue (Public)
        }
    }
    
    private var schoolIcon: String {
        guard let orgType = school.organizationType?.lowercased() else {
            return "building.2.fill"
        }
        
        if orgType.contains("magnet") {
            return "star.fill"
        } else if orgType.contains("charter") {
            return "graduationcap.fill"
        } else if orgType.contains("technical") || orgType.contains("vocational") {
            return "wrench.and.screwdriver.fill"
        } else {
            return "building.2.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // 3D Icon avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                schoolTypeColor.primary.opacity(0.15),
                                schoolTypeColor.secondary.opacity(0.25)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: schoolIcon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [schoolTypeColor.primary, schoolTypeColor.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: schoolTypeColor.primary.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .breathing(minScale: 0.98, maxScale: 1.02)
            
            // School info
            VStack(alignment: .leading, spacing: 6) {
                Text(school.name ?? "Unknown School")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if let district = school.districtName {
                    Text(district)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 8) {
                    if let town = school.town {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 11))
                            Text(town)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                        }
                        .foregroundStyle(.secondary)
                    }
                    
                    // Grade badge (only show if grades are available)
                    if let gradeRange = school.gradeRange {
                        Text(gradeRange)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(schoolTypeColor.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(schoolTypeColor.primary.opacity(0.12))
                            )
                    }
                }
                
                // Organization type badge
                if let orgType = school.organizationType {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(schoolTypeColor.primary)
                            .frame(width: 6, height: 6)
                        
                        Text(orgType)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(schoolTypeColor.primary)
                    }
                }
            }
            
            Spacer(minLength: 0)
            
            // Favorite button
            Button {
                favoritesManager.toggleFavorite(school.id)
            } label: {
                Image(systemName: favoritesManager.isFavorite(school.id) ? "heart.fill" : "heart")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(favoritesManager.isFavorite(school.id) ? Color.red : Color.gray.opacity(0.5))
            }
            .buttonStyle(.plain)
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                .shadow(color: .black.opacity(0.04), radius: 1, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.primary.opacity(0.08),
                            Color.primary.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shimmer(duration: 2.5, bounce: false)
    }
}

// Custom button style for cards
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// Filter chip component
struct FilterChip: View {
    let text: String
    let icon: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            
            Text(text)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .lineLimit(1)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                colors: [Color(red: 0.2, green: 0.6, blue: 0.9), Color(red: 0.1, green: 0.5, blue: 0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: Capsule()
        )
        .shadow(color: Color(red: 0.2, green: 0.6, blue: 0.9).opacity(0.3), radius: 6, x: 0, y: 3)
    }
}

// Floating action button
struct FloatingActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(color.gradient)
                        .shadow(color: color.opacity(0.4), radius: 12, x: 0, y: 6)
                        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                )
        }
        .glow(color: color, radius: 8)
        .floating(distance: 5)
    }
}

// Modern filter view with glassmorphic design
struct ModernFilterView: View {
    @Bindable var viewModel: SchoolViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Animated gradient background
                AnimatedGradientBackground()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Town filter
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color(red: 0.2, green: 0.6, blue: 0.9), Color(red: 0.1, green: 0.5, blue: 0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                Text("Town")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(.primary)
                            }
                            
                            Picker("Select Town", selection: $viewModel.selectedTown) {
                                Text("All Towns").tag(nil as String?)
                                ForEach(viewModel.towns, id: \.self) { town in
                                    Text(town).tag(town as String?)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Organization type filter
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "building.2.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color(red: 0.9, green: 0.3, blue: 0.5), Color(red: 0.8, green: 0.2, blue: 0.4)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                Text("School Type")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(.primary)
                            }
                            
                            Picker("Select Type", selection: $viewModel.selectedOrganizationType) {
                                Text("All Types").tag(nil as String?)
                                ForEach(viewModel.organizationTypes, id: \.self) { type in
                                    Text(type).tag(type as String?)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Active filters summary
                        if viewModel.selectedTown != nil || viewModel.selectedOrganizationType != nil {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Active Filters")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 20)
                                
                                VStack(spacing: 8) {
                                    if let town = viewModel.selectedTown {
                                        HStack {
                                            Image(systemName: "mappin.circle.fill")
                                                .font(.system(size: 12))
                                                .foregroundStyle(Color(red: 0.2, green: 0.6, blue: 0.9))
                                            Text(town)
                                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                            Spacer()
                                            Button {
                                                viewModel.selectedTown = nil
                                                viewModel.applyFilters()
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 16))
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(Color(red: 0.2, green: 0.6, blue: 0.9).opacity(0.15))
                                        )
                                    }
                                    
                                    if let orgType = viewModel.selectedOrganizationType {
                                        HStack {
                                            Image(systemName: "building.2.fill")
                                                .font(.system(size: 12))
                                                .foregroundStyle(Color(red: 0.9, green: 0.3, blue: 0.5))
                                            Text(orgType)
                                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                            Spacer()
                                            Button {
                                                viewModel.selectedOrganizationType = nil
                                                viewModel.applyFilters()
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 16))
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(Color(red: 0.9, green: 0.3, blue: 0.5).opacity(0.15))
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // Reset button
                        if viewModel.selectedTown != nil || viewModel.selectedOrganizationType != nil {
                            Button {
                                viewModel.resetFilters()
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Reset All Filters")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [Color.red.opacity(0.8), Color.red.opacity(0.9)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                                )
                                .shadow(color: Color.red.opacity(0.3), radius: 12, x: 0, y: 6)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        viewModel.applyFilters()
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                }
            }
            .onChange(of: viewModel.selectedTown) {
                viewModel.applyFilters()
            }
            .onChange(of: viewModel.selectedOrganizationType) {
                viewModel.applyFilters()
            }
        }
    }
}

// Favorites view showing bookmarked schools
struct FavoritesView: View {
    @Bindable var viewModel: SchoolViewModel
    @Bindable var favoritesManager: FavoritesManager
    @Bindable var themeManager: ThemeManager
    @State private var showingSettings = false
    
    private var favoriteSchools: [School] {
        favoritesManager.getFavoriteSchools(from: viewModel.schools)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Animated liquid glass background
                AnimatedGradientBackground()
                
                if viewModel.isLoading {
                    VStack(spacing: 24) {
                        LoadingDots(color: Color.red)
                        Text("Loading schools...")
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                } else if favoriteSchools.isEmpty {
                    emptyFavoritesView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(favoriteSchools) { school in
                                NavigationLink(destination: SchoolDetailView(school: school, favoritesManager: favoritesManager)) {
                                    ModernSchoolCard(school: school, favoritesManager: favoritesManager)
                                }
                                .buttonStyle(CardButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                    }
                    .refreshable {
                        await viewModel.fetchSchools()
                    }
                }
                
                // Settings button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingActionButton(icon: "gearshape.fill", color: Color(red: 0.5, green: 0.5, blue: 0.5)) {
                            showingSettings.toggle()
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.red, Color.pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text("Favorites")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                    }
                }
            }
            .task {
                if viewModel.schools.isEmpty {
                    await viewModel.fetchSchools()
                }
            }
        }
    }
    
    private var emptyFavoritesView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "heart.slash")
                    .font(.system(size: 40))
                    .foregroundStyle(.red)
            }
            .breathing(minScale: 0.95, maxScale: 1.05)
            
            VStack(spacing: 8) {
                Text("No Favorites Yet")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                
                Text("Tap the heart icon on any school to add it to your favorites")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
}
