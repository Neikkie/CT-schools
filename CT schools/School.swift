import Foundation

// Model representing a Connecticut school from the API
struct School: Identifiable, Codable, Hashable {
    var id: String { organizationCode ?? UUID().uuidString }
    
    let name: String?
    let districtName: String?
    let organizationType: String?
    let organizationCode: String?
    let address: String?
    let town: String?
    let zipcode: String?
    let phone: String?
    let studentOpenDate: String?
    let interdistrictMagnet: String?
    
    // Grade level fields
    let prekindergarten: String?
    let kindergarten: String?
    let grade1: String?
    let grade2: String?
    let grade3: String?
    let grade4: String?
    let grade5: String?
    let grade6: String?
    let grade7: String?
    let grade8: String?
    let grade9: String?
    let grade10: String?
    let grade11: String?
    let grade12: String?
    
    // Location data
    let geocodedColumn: GeocodedColumn?
    
    enum CodingKeys: String, CodingKey {
        case name
        case districtName = "district_name"
        case organizationType = "organization_type"
        case organizationCode = "organization_code"
        case address
        case town
        case zipcode
        case phone
        case studentOpenDate = "student_open_date"
        case interdistrictMagnet = "interdistrict_magnet"
        case prekindergarten
        case kindergarten
        case grade1 = "grade_1"
        case grade2 = "grade_2"
        case grade3 = "grade_3"
        case grade4 = "grade_4"
        case grade5 = "grade_5"
        case grade6 = "grade_6"
        case grade7 = "grade_7"
        case grade8 = "grade_8"
        case grade9 = "grade_9"
        case grade10 = "grade_10"
        case grade11 = "grade_11"
        case grade12 = "grade_12"
        case geocodedColumn = "geocoded_column"
    }
    
    // Computed property to get grade range (returns nil if no grades available)
    var gradeRange: String? {
        var grades: [String] = []
        
        if prekindergarten == "Y" { grades.append("PreK") }
        if kindergarten == "Y" { grades.append("K") }
        if grade1 == "Y" { grades.append("1") }
        if grade2 == "Y" { grades.append("2") }
        if grade3 == "Y" { grades.append("3") }
        if grade4 == "Y" { grades.append("4") }
        if grade5 == "Y" { grades.append("5") }
        if grade6 == "Y" { grades.append("6") }
        if grade7 == "Y" { grades.append("7") }
        if grade8 == "Y" { grades.append("8") }
        if grade9 == "Y" { grades.append("9") }
        if grade10 == "Y" { grades.append("10") }
        if grade11 == "Y" { grades.append("11") }
        if grade12 == "Y" { grades.append("12") }
        
        guard !grades.isEmpty else {
            return nil
        }
        
        if grades.count == 1 {
            return grades[0]
        } else {
            return "\(grades.first ?? "") - \(grades.last ?? "")"
        }
    }
    
    // Computed property to get all grades offered as a comma-separated list
    var gradesOffered: String? {
        var grades: [String] = []
        
        if prekindergarten == "Y" { grades.append("PreK") }
        if kindergarten == "Y" { grades.append("K") }
        if grade1 == "Y" { grades.append("1") }
        if grade2 == "Y" { grades.append("2") }
        if grade3 == "Y" { grades.append("3") }
        if grade4 == "Y" { grades.append("4") }
        if grade5 == "Y" { grades.append("5") }
        if grade6 == "Y" { grades.append("6") }
        if grade7 == "Y" { grades.append("7") }
        if grade8 == "Y" { grades.append("8") }
        if grade9 == "Y" { grades.append("9") }
        if grade10 == "Y" { grades.append("10") }
        if grade11 == "Y" { grades.append("11") }
        if grade12 == "Y" { grades.append("12") }
        
        guard !grades.isEmpty else {
            return nil
        }
        
        return grades.joined(separator: ", ")
    }
}

struct GeocodedColumn: Codable, Hashable {
    let latitude: String?
    let longitude: String?
    let humanAddress: String?
    
    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case humanAddress = "human_address"
    }
}
