import SwiftUI

// ----------------- 正字图标绘制 -----------------
struct ZhengView: View {
    var count: Int
    
    var body: some View {
        HStack(spacing: 2) {
            let full = count / 5
            let rem = count % 5
            
            if count == 0 {
                Text("待记")
                    .font(.system(size: 12))
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            } else {
                if full > 0 {
                    // 🌟 保持不变：前面的数字和完整的“正”字，维持原有的蓝色
                    Text("\(full)正")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.blue)
                }
                if rem > 0 {
                    // 🌟 核心修改：将单独的笔画颜色改为 Color.primary
                    // 这样它就会像对应径级的数据总数一样，浅色模式是黑色，深色模式自动变成白色
                    ZhengStrokesShape(rem: rem)
                        .stroke(Color.primary, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                        .frame(width: 36, height: 36)
                }
            }
        }
    }
}

struct ZhengStrokesShape: Shape {
    var rem: Int
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        if rem >= 1 { path.move(to: CGPoint(x: w*0.2, y: h*0.24)); path.addLine(to: CGPoint(x: w*0.8, y: h*0.24)) }
        if rem >= 2 { path.move(to: CGPoint(x: w*0.5, y: h*0.24)); path.addLine(to: CGPoint(x: w*0.5, y: h*0.76)) }
        if rem >= 3 { path.move(to: CGPoint(x: w*0.5, y: h*0.50)); path.addLine(to: CGPoint(x: w*0.8, y: h*0.50)) }
        if rem >= 4 { path.move(to: CGPoint(x: w*0.2, y: h*0.50)); path.addLine(to: CGPoint(x: w*0.2, y: h*0.84)) }
        if rem >= 5 { path.move(to: CGPoint(x: w*0.1, y: h*0.84)); path.addLine(to: CGPoint(x: w*0.9, y: h*0.84)) }
        return path
    }
}
