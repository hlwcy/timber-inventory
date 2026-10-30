import Foundation

struct TimberCalculator {
    // 国标单材积计算算法 (GB/T 144)
    static func calcSingleVolume(length LStr: String, dia DStr: String) -> Double {
        guard let L = Double(LStr), let D = Double(DStr), L > 0, D > 0 else { return 0.0 }
        var V: Double = 0.0
        
        if L < 2.0 || L >= 10.2 {
            V = 0.8 * L * pow((D + 0.5 * L), 2) / 10000.0
        } else if L >= 2.0 && D >= 4 && D <= 13 {
            V = 0.7854 * L * pow((D + 0.45 * L + 0.2), 2) / 10000.0
        } else if L >= 2.0 && D >= 14 {
            V = 0.7854 * L * pow((D + 0.5 * L + 0.005 * L * L + 0.000125 * L * pow(14.0 - L, 2) * (D - 10.0)), 2) / 10000.0
        }
        
        if D >= 4 && D <= 7 {
            return (V * 10000.0).rounded() / 10000.0
        } else {
            return (V * 1000.0).rounded() / 1000.0
        }
    }
    
    // 金额计算
    static func calcMoney(vol: Double, price: Double) -> Double {
        return (vol * price * 100.0).rounded() / 100.0
    }
    
    // 格式化材积
    static func formatVol(_ v: Double, dia dStr: String) -> String {
        let d = Double(dStr) ?? 0.0
        if d >= 4 && d <= 7 {
            return String(format: "%.4f", v)
        } else {
            return String(format: "%.3f", v)
        }
    }
    
    // 格式化汇总材积
    static func formatSum(_ v: Double) -> String {
        return String(format: "%.3f", v)
    }
}
