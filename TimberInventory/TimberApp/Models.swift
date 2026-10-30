import Foundation

// 价格规则模型
struct PriceRule: Identifiable, Codable {
    var id: String = UUID().uuidString
    var length: String
    var minDia: String
    var maxDia: String
    var price: String
}

// 项目模型
struct Project: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var dates: [String] = []
    var priceRules: [PriceRule] = []
}

// 实测明细模型
struct Record: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var projectId: String
    var date: String
    var type: String
    var length: String
    var dia: String
    var count: Int
    var manualPrice: String
}
