import Foundation

// Service class to handle API requests for CT schools data
class SchoolService {
    static let shared = SchoolService()
    
    private let baseURL = "https://data.ct.gov/resource/9k2y-kqxn.json"
    
    private init() {}
    
    // Fetch all schools from the API
    func fetchSchools() async throws -> [School] {
        guard let url = URL(string: baseURL) else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let schools = try decoder.decode([School].self, from: data)
        return schools
    }
    
    // Fetch schools with optional filtering
    func fetchSchools(town: String? = nil, organizationType: String? = nil, limit: Int = 1000) async throws -> [School] {
        var urlString = baseURL + "?$limit=\(limit)"
        
        if let town = town {
            urlString += "&town=\(town.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? town)"
        }
        
        if let orgType = organizationType {
            urlString += "&organization_type=\(orgType.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? orgType)"
        }
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let schools = try decoder.decode([School].self, from: data)
        return schools
    }
}
