import Foundation

// Manager for handling favorite schools with persistence
@MainActor
@Observable
class FavoritesManager {
    var favoriteSchoolIds: Set<String> = []

    private let favoritesKey = "favoriteSchools"

    init() {
        loadFavorites()
    }

    func isFavorite(_ schoolId: String) -> Bool {
        favoriteSchoolIds.contains(schoolId)
    }

    func toggleFavorite(_ schoolId: String) {
        if favoriteSchoolIds.contains(schoolId) {
            favoriteSchoolIds.remove(schoolId)
        } else {
            favoriteSchoolIds.insert(schoolId)
        }
        saveFavorites()
    }

    func getFavoriteSchools(from allSchools: [School]) -> [School] {
        allSchools.filter { school in
            favoriteSchoolIds.contains(school.id)
        }
    }

    private func saveFavorites() {
        let array = Array(favoriteSchoolIds)
        UserDefaults.standard.set(array, forKey: favoritesKey)
    }

    private func loadFavorites() {
        if let array = UserDefaults.standard.array(forKey: favoritesKey) as? [String] {
            favoriteSchoolIds = Set(array)
        }
    }
}
