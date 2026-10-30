import SwiftUI

class DataManager: ObservableObject {
    @Published var projects: [Project] = []
    @Published var records: [Record] = []
    
    init() {
        loadData()
    }
    
    func saveData() {
        if let projData = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(projData, forKey: "proLogProjects_v26")
        }
        if let recData = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(recData, forKey: "proLogRecords_v26")
        }
    }
    
    func loadData() {
        if let projData = UserDefaults.standard.data(forKey: "proLogProjects_v26"),
           let savedProjects = try? JSONDecoder().decode([Project].self, from: projData) {
            self.projects = savedProjects
        }
        if let recData = UserDefaults.standard.data(forKey: "proLogRecords_v26"),
           let savedRecords = try? JSONDecoder().decode([Record].self, from: recData) {
            self.records = savedRecords
        }
    }
    
    // 匹配匹配项目统一规则价格/手动改价
    func getEffectivePrice(projId: String, length: String, dia: String, manualPrice: String) -> Double {
        if let mp = Double(manualPrice), mp >= 0 {
            return mp
        }
        guard let p = projects.first(where: { $0.id == projId }) else { return 0.0 }
        let l = Double(length) ?? 0.0
        let d = Double(dia) ?? 0.0
        
        let rule = p.priceRules.first { r in
            guard let rL = Double(r.length), rL == l else { return false }
            guard let minD = Double(r.minDia), d >= minD else { return false }
            if !r.maxDia.isEmpty, let maxD = Double(r.maxDia), d > maxD {
                return false
            }
            return true
        }
        
        if let rule = rule, let price = Double(rule.price) {
            return price
        }
        return 0.0
    }
    
    // 首次进入空日期，预填 1m-4m 及 4-22cm 径级
    func ensureDefaultData(projId: String, dateStr: String) {
        let dRecords = records.filter { $0.projectId == projId && $0.date == dateStr }
        if dRecords.isEmpty {
            let defaultLengths = ["1", "2", "3", "4"]
            let defaultDias = [4, 6, 8, 10, 12, 14, 16, 18, 20, 22]
            for len in defaultLengths {
                for dia in defaultDias {
                    records.append(Record(
                        projectId: projId,
                        date: dateStr,
                        type: "杉木",
                        length: len,
                        dia: String(dia),
                        count: 0,
                        manualPrice: ""
                    ))
                }
            }
            saveData()
        }
    }
    
    // 统计计算
    func getStats(for recs: [Record]) -> (count: Int, vol: Double, amount: Double) {
        var count = 0
        var vol = 0.0
        var amount = 0.0
        for r in recs {
            let singleV = TimberCalculator.calcSingleVolume(length: r.length, dia: r.dia)
            let totalV = singleV * Double(r.count)
            let price = getEffectivePrice(projId: r.projectId, length: r.length, dia: r.dia, manualPrice: r.manualPrice)
            count += r.count
            vol += totalV
            amount += TimberCalculator.calcMoney(vol: totalV, price: price)
        }
        return (count, vol, amount)
    }
}
