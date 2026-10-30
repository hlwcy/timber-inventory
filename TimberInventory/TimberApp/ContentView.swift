import SwiftUI

struct ContentView: View {
    @StateObject var manager = DataManager()
    @State private var selectedTab = 0
    @State private var showingAddProject = false
    @State private var newProjName = ""
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 1. 项目导航树
            NavigationStack {
                List {
                    ForEach(manager.projects.sorted(by: { $0.name < $1.name })) { proj in
                        NavigationLink(destination: DateListView(projId: proj.id).environmentObject(manager)) {
                            let pRecs = manager.records.filter { $0.projectId == proj.id }
                            let st = manager.getStats(for: pRecs)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: "folder.fill").foregroundColor(.blue)
                                    Text(proj.name)
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(.primary)
                                }
                                
                                HStack(spacing: 12) {
                                    Label("\(st.count)根", systemImage: "number.circle.fill").foregroundColor(.orange)
                                    Label("\(TimberCalculator.formatSum(st.vol))m³", systemImage: "cube.box.fill").foregroundColor(.green)
                                    Label("¥\(String(format: "%.2f", st.amount))", systemImage: "yensign.circle.fill").foregroundColor(.red)
                                }
                                .font(.system(size: 12, weight: .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .onDelete { offsets in
                        let sorted = manager.projects.sorted(by: { $0.name < $1.name })
                        for index in offsets {
                            let p = sorted[index]
                            manager.projects.removeAll { $0.id == p.id }
                            manager.records.removeAll { $0.projectId == p.id }
                        }
                        manager.saveData()
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle("项目管理")
                .toolbar {
                    Button(action: { showingAddProject = true }) {
                        Label("新建项目", systemImage: "plus.circle.fill").font(.system(size: 16, weight: .bold))
                    }
                }
                .alert("新建项目", isPresented: $showingAddProject) {
                    TextField("输入项目名称", text: $newProjName)
                    Button("取消", role: .cancel) { newProjName = "" }
                    Button("保存") {
                        if !newProjName.trimmingCharacters(in: .whitespaces).isEmpty {
                            manager.projects.append(Project(name: newProjName.trimmingCharacters(in: .whitespaces)))
                            manager.saveData()
                            newProjName = ""
                        }
                    }
                }
            }
            .tabItem { Label("盘点登记", systemImage: "square.and.pencil") }
            .tag(0)
            
            // 2. 报表
            NavigationStack {
                GlobalStatsView().environmentObject(manager)
                    .navigationTitle("数据汇总")
            }
            .tabItem { Label("统计报表", systemImage: "chart.bar.fill") }
            .tag(1)
        }
    }
}

// ----------------- 日期列表 -----------------
struct DateListView: View {
    var projId: String
    @EnvironmentObject var manager: DataManager
    @State private var showingAddDate = false
    @State private var newDate = Date()
    @State private var showingRuleModal = false
    
    var body: some View {
        let proj = manager.projects.first(where: { $0.id == projId })
        let dates = (proj?.dates ?? []).sorted(by: >)
        
        List {
            ForEach(dates, id: \.self) { dateStr in
                NavigationLink(destination: LengthListView(projId: projId, dateStr: dateStr).environmentObject(manager)) {
                    let dRecs = manager.records.filter { $0.projectId == projId && $0.date == dateStr }
                    let st = manager.getStats(for: dRecs)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "calendar").foregroundColor(.blue)
                            Text("\(dateStr)")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.primary)
                        }
                        
                        HStack(spacing: 12) {
                            Label("\(st.count)根", systemImage: "number.circle.fill").foregroundColor(.orange)
                            Label("\(TimberCalculator.formatSum(st.vol))m³", systemImage: "cube.box.fill").foregroundColor(.green)
                            Label("¥\(String(format: "%.2f", st.amount))", systemImage: "yensign.circle.fill").foregroundColor(.red)
                        }
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    }
                    .padding(.vertical, 6)
                }
            }
            .onDelete { offsets in
                for index in offsets {
                    let dStr = dates[index]
                    if let pIdx = manager.projects.firstIndex(where: { $0.id == projId }) {
                        manager.projects[pIdx].dates.removeAll { $0 == dStr }
                    }
                    manager.records.removeAll { $0.projectId == projId && $0.date == dStr }
                }
                manager.saveData()
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(proj?.name ?? "日期列表")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: { showingRuleModal = true }) {
                    Image(systemName: "yensign.circle")
                    Text("定价")
                }
                .foregroundColor(.orange)
                
                Button(action: { showingAddDate = true }) {
                    Image(systemName: "plus")
                    Text("日期")
                }
            }
        }
        .sheet(isPresented: $showingRuleModal) { RuleModalView(projId: projId).environmentObject(manager) }
        .sheet(isPresented: $showingAddDate) {
            NavigationStack {
                Form { DatePicker("选择实测日期", selection: $newDate, displayedComponents: .date).datePickerStyle(.graphical) }
                .navigationTitle("新建日期")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("取消") { showingAddDate = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("保存") {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy-MM-dd"
                            let dateStr = formatter.string(from: newDate)
                            if let pIdx = manager.projects.firstIndex(where: { $0.id == projId }) {
                                if !manager.projects[pIdx].dates.contains(dateStr) {
                                    manager.projects[pIdx].dates.append(dateStr)
                                    manager.saveData()
                                }
                            }
                            showingAddDate = false
                        }
                    }
                }
            }
        }
    }
}

// ----------------- 长度规格列表 -----------------
struct LengthListView: View {
    var projId: String
    var dateStr: String
    @EnvironmentObject var manager: DataManager
    @State private var showingAddLen = false
    @State private var newType = "杉木"
    @State private var newLen = ""
    
    var body: some View {
        let dRecs = manager.records.filter { $0.projectId == projId && $0.date == dateStr }
        let lengths = Array(Set(dRecs.compactMap { Double($0.length) })).sorted()
        
        List {
            ForEach(lengths, id: \.self) { lenVal in
                let lenStr = lenVal.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", lenVal) : String(lenVal)
                NavigationLink(destination: RecordDetailListView(projId: projId, dateStr: dateStr, lenStr: lenStr).environmentObject(manager)) {
                    let lRecs = dRecs.filter { Double($0.length) == lenVal }
                    let st = manager.getStats(for: lRecs)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(lenStr).font(.system(size: 22, weight: .heavy)).foregroundColor(.blue)
                            Text("m 规格组").font(.system(size: 15, weight: .bold)).foregroundColor(.primary)
                        }
                        
                        HStack(spacing: 12) {
                            Label("\(st.count)根", systemImage: "number.circle.fill").foregroundColor(.orange)
                            Label("\(TimberCalculator.formatSum(st.vol))m³", systemImage: "cube.box.fill").foregroundColor(.green)
                            Label("¥\(String(format: "%.2f", st.amount))", systemImage: "yensign.circle.fill").foregroundColor(.red)
                        }
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    }
                    .padding(.vertical, 6)
                }
            }
            .onDelete { offsets in
                for index in offsets {
                    let lenVal = lengths[index]
                    manager.records.removeAll { $0.projectId == projId && $0.date == dateStr && Double($0.length) == lenVal }
                }
                manager.saveData()
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(dateStr)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { manager.ensureDefaultData(projId: projId, dateStr: dateStr) }
        .toolbar {
            Button(action: { showingAddLen = true }) {
                Image(systemName: "plus")
                Text("长度")
            }
        }
        .sheet(isPresented: $showingAddLen) {
            NavigationStack {
                Form {
                    TextField("树种", text: $newType)
                    TextField("输入长度(m)", text: $newLen).keyboardType(.decimalPad)
                }
                .navigationTitle("新增长度规格")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("取消") { showingAddLen = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("确定创建") {
                            if let lVal = Double(newLen), lVal > 0 {
                                let lStr = lVal.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", lVal) : String(lVal)
                                let defaultDias = [4, 6, 8, 10, 12, 14, 16, 18, 20, 22]
                                for dia in defaultDias {
                                    manager.records.append(Record(
                                        projectId: projId, date: dateStr, type: newType.isEmpty ? "杉木" : newType,
                                        length: lStr, dia: String(dia), count: 0, manualPrice: ""
                                    ))
                                }
                                manager.saveData()
                                newLen = ""
                                showingAddLen = false
                            }
                        }
                    }
                }
            }
        }
    }
}

// ----------------- 自定义特效与工具 -----------------
struct DashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height / 2))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height / 2))
        return path
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

func formatPriceOmitZero(_ price: Double) -> String {
    let formatter = NumberFormatter()
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 2
    return formatter.string(from: NSNumber(value: price)) ?? "0"
}


// ----------------- 径级明细行页面 (悬浮卡片式，修复顶部过大空白) -----------------
struct RecordDetailListView: View {
    var projId: String
    var dateStr: String
    var lenStr: String
    @EnvironmentObject var manager: DataManager
    
    @State private var showingAddSpec = false
    @State private var addType = "杉木"
    @State private var addDia = ""
    @State private var addPrice = ""
    
    @State private var isRecordingGlobal = false
    
    var body: some View {
        let lRecs = manager.records.filter { $0.projectId == projId && $0.date == dateStr && Double($0.length) == Double(lenStr) }
        
        let uniqueTypes = lRecs.reduce(into: [String]()) { if !$0.contains($1.type) { $0.append($1.type) } }
        let st = manager.getStats(for: lRecs)
        
        List {
            ForEach(Array(uniqueTypes.enumerated()), id: \.element) { index, type in
                let typeRecs = lRecs.filter { $0.type == type }.sorted { (Double($0.dia) ?? 0) < (Double($1.dia) ?? 0) }
                
                ForEach(typeRecs, id: \.id) { item in
                    RecordRow(item: item, projId: projId, isRecording: isRecordingGlobal)
                        .environmentObject(manager)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        // 微调：缩小上下 insets，防止每个卡片之间的缝隙过大
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
                .onDelete { offsets in
                    for offset in offsets {
                        let target = typeRecs[offset]
                        manager.records.removeAll { $0.id == target.id }
                    }
                    manager.saveData()
                }
                
                // 树种之间的虚线分割
                if index < uniqueTypes.count - 1 {
                    DashedLine()
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundColor(Color.gray.opacity(0.4))
                        .frame(height: 1)
                        .padding(.vertical, 4)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                }
            }
        }
        .listStyle(.plain)
        .background(Color(UIColor.systemGroupedBackground))
        // 强行吃掉 List 顶部的默认安全留白区
        .padding(.top, -6)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text("\(lenStr)m").font(.system(size: 18, weight: .bold)).foregroundColor(.orange)
                    Text("(\(st.count)根 | \(TimberCalculator.formatSum(st.vol))方 | ¥\(formatPriceOmitZero(st.amount)))")
                        .font(.system(size: 11, weight: .medium)).foregroundColor(.secondary)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button(action: {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isRecordingGlobal.toggle()
                        }
                    }) {
                        Text(isRecordingGlobal ? "完成记录" : "记录")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(isRecordingGlobal ? .green : .blue)
                    }
                    
                    Button(action: { showingAddSpec = true }) {
                        Text("➕规格")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddSpec) {
            NavigationStack {
                Form {
                    TextField("树种", text: $addType)
                    TextField("径级(cm)", text: $addDia).keyboardType(.numberPad)
                    TextField("手动单价(可留空)", text: $addPrice).keyboardType(.decimalPad)
                }
                .navigationTitle("新增特殊规格")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("取消") { showingAddSpec = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("确定落账") {
                            if !addDia.isEmpty {
                                manager.records.append(Record(
                                    projectId: projId, date: dateStr, type: addType.isEmpty ? "杂木" : addType,
                                    length: lenStr, dia: addDia, count: 0, manualPrice: addPrice
                                ))
                                manager.saveData()
                                addDia = ""; addPrice = ""
                                showingAddSpec = false
                            }
                        }
                    }
                }
            }
        }
    }
}


// ----------------- 单行记录卡片 (独立悬浮框、极致靠边、信息对调) -----------------
struct RecordRow: View {
    var item: Record
    var projId: String
    var isRecording: Bool
    @EnvironmentObject var manager: DataManager
    
    @State private var countInputStr: String = ""
    @State private var priceInputStr: String = ""
    
    var body: some View {
        let singleV = TimberCalculator.calcSingleVolume(length: item.length, dia: item.dia)
        let totalV = singleV * Double(item.count)
        
        let baseEffPrice = manager.getEffectivePrice(projId: item.projectId, length: item.length, dia: item.dia, manualPrice: "")
        let finalDisplayAmount = TimberCalculator.calcMoney(vol: totalV, price: manager.getEffectivePrice(projId: item.projectId, length: item.length, dia: item.dia, manualPrice: item.manualPrice))
        
        HStack(alignment: .center, spacing: 0) {
            
            // 左侧区：向左吸附
            VStack(alignment: .leading, spacing: 4) {
                // 第一行：树种 + 径级 + 单材立方
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(item.type).font(.system(size: 15, weight: .bold)).foregroundColor(.blue)
                    
                    Text("\(item.dia)cm")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(.red)
                        .fixedSize(horizontal: true, vertical: false)
                        .layoutPriority(1)
                    
                    Text("\(TimberCalculator.formatVol(singleV, dia: item.dia))m³")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                
                // 第二行：单价输入框
                HStack(spacing: 0) {
                    Text("单价:¥").font(.system(size: 11)).foregroundColor(.gray)
                    TextField(formatPriceOmitZero(baseEffPrice), text: $priceInputStr)
                        .keyboardType(.decimalPad).font(.system(size: 12, weight: .bold))
                        .foregroundColor(item.manualPrice.isEmpty ? .gray : .primary)
                        .frame(width: 44)
                        .padding(.vertical, 2).padding(.horizontal, 4)
                        .background(Color(UIColor.tertiarySystemFill)).cornerRadius(4)
                        .onChange(of: priceInputStr) { newValue in
                            if let idx = manager.records.firstIndex(where: { $0.id == item.id }) {
                                manager.records[idx].manualPrice = newValue
                                manager.saveData()
                            }
                        }
                }
                
                // 第三行：共计
                Text("共:\(TimberCalculator.formatVol(totalV, dia: item.dia))m³ | ¥\(formatPriceOmitZero(finalDisplayAmount))")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.gray)
                    .lineLimit(1).minimumScaleFactor(0.6)
            }
            
            Spacer(minLength: 4)
            
            // 右侧区：向右吸附，操作与正字
            HStack(alignment: .center, spacing: 4) {
                ZhengView(count: item.count)
                
                if isRecording {
                    HStack(spacing: 0) {
                        Button(action: {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            updateCount(-1)
                        }) {
                            Image(systemName: "minus").font(.system(size: 16, weight: .bold)).frame(width: 32, height: 32)
                                .foregroundColor(.red).background(Color(UIColor.secondarySystemBackground))
                        }.buttonStyle(ScaleButtonStyle())
                        
                        TextField("0", text: $countInputStr)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(minWidth: 36, idealWidth: 40)
                            .fixedSize(horizontal: true, vertical: false)
                            .frame(height: 32)
                            .background(Color(UIColor.systemBackground))
                            .onChange(of: countInputStr) { newValue in
                                if let val = Int(newValue), val >= 0 {
                                    if let idx = manager.records.firstIndex(where: { $0.id == item.id }) {
                                        manager.records[idx].count = val
                                        manager.saveData()
                                    }
                                }
                            }
                        
                        Button(action: {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            updateCount(1)
                        }) {
                            Image(systemName: "plus").font(.system(size: 22, weight: .heavy)).frame(width: 44, height: 38)
                                .foregroundColor(.blue)
                                .background(Color.blue.opacity(0.15))
                        }.buttonStyle(ScaleButtonStyle())
                    }.cornerRadius(6).overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(UIColor.systemGray4), lineWidth: 1))
                } else {
                    Text("\(item.count) 根").font(.system(size: 16, weight: .bold)).foregroundColor(Color(UIColor.tertiaryLabel))
                }
            }
            .layoutPriority(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1)
        .onAppear { countInputStr = "\(item.count)"; priceInputStr = item.manualPrice }
        .onChange(of: item.count) { newCount in if countInputStr != "\(newCount)" { countInputStr = "\(newCount)" } }
    }
    
    func updateCount(_ delta: Int) {
        if let idx = manager.records.firstIndex(where: { $0.id == item.id }) {
            let newC = manager.records[idx].count + delta
            if newC >= 0 { manager.records[idx].count = newC; manager.saveData() }
        }
    }
}

// ----------------- 规则界面 -----------------
struct RuleModalView: View {
    var projId: String
    @EnvironmentObject var manager: DataManager
    @Environment(\.dismiss) var dismiss
    
    @State private var ruleLen = ""
    @State private var ruleMin = ""
    @State private var ruleMax = ""
    @State private var rulePrice = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                VStack(spacing: 8) {
                    TextField("规格长度 (多长度用 / 分隔)", text: $ruleLen).textFieldStyle(RoundedBorderTextFieldStyle())
                    HStack {
                        TextField("最小径级(cm)", text: $ruleMin).keyboardType(.numberPad).textFieldStyle(RoundedBorderTextFieldStyle())
                        Text("至").font(.caption).foregroundColor(.gray)
                        TextField("最大(留空=及以上)", text: $ruleMax).keyboardType(.numberPad).textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    TextField("设定单价(元/方)", text: $rulePrice).keyboardType(.decimalPad).textFieldStyle(RoundedBorderTextFieldStyle())
                    Button(action: addRule) {
                        Text("➕ 批量生成规则").font(.system(size: 14, weight: .bold)).frame(maxWidth: .infinity).padding(8)
                            .background(Color.orange).foregroundColor(.white).cornerRadius(6)
                    }
                }
                .padding().background(Color(uiColor: .secondarySystemBackground)).cornerRadius(8).padding(.horizontal)
                
                let rules = (manager.projects.first(where: { $0.id == projId })?.priceRules ?? []).sorted {
                    if (Double($0.length) ?? 0) != (Double($1.length) ?? 0) { return (Double($0.length) ?? 0) < (Double($1.length) ?? 0) }
                    return (Double($0.minDia) ?? 0) < (Double($1.minDia) ?? 0)
                }
                List {
                    ForEach(rules) { r in
                        HStack {
                            Text("\(r.length)m").bold().foregroundColor(.blue)
                            Text("径级:\(r.minDia)-\(r.maxDia.isEmpty ? "及以上" : r.maxDia)").font(.caption).foregroundColor(.gray)
                            Spacer()
                            Text("¥\(r.price)").bold().foregroundColor(.red)
                        }
                    }
                    .onDelete { offsets in
                        if let pIdx = manager.projects.firstIndex(where: { $0.id == projId }) {
                            for idx in offsets { manager.projects[pIdx].priceRules.removeAll { $0.id == rules[idx].id } }
                            manager.saveData()
                        }
                    }
                }
            }
            .navigationTitle("项目统一定价库")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { dismiss() } } }
        }
    }
    func addRule() {
        guard !ruleLen.isEmpty, !ruleMin.isEmpty, !rulePrice.isEmpty else { return }
        let lengths = ruleLen.replacingOccurrences(of: "，", with: "/").split(separator: "/").map { String($0) }
        if let pIdx = manager.projects.firstIndex(where: { $0.id == projId }) {
            for l in lengths { manager.projects[pIdx].priceRules.append(PriceRule(length: l, minDia: ruleMin, maxDia: ruleMax, price: rulePrice)) }
            manager.saveData()
            ruleLen = ""; ruleMin = ""; ruleMax = ""; rulePrice = ""
        }
    }
}

// 🌟 数据汇总概览卡片
struct GlobalStatsView: View {
    @EnvironmentObject var manager: DataManager
    
    var body: some View {
        let allStats = manager.getStats(for: manager.records)
        let globalAvg = allStats.vol > 0 ? allStats.amount / allStats.vol : 0
        
        VStack(spacing: 0) {
            VStack(spacing: 14) {
                HStack {
                    VStack { Text("\(allStats.count)").font(.title2).bold(); Text("总计根数").font(.caption) }
                    Spacer()
                    VStack { Text(TimberCalculator.formatSum(allStats.vol)).font(.title2).bold(); Text("总方数(m³)").font(.caption) }
                    Spacer()
                    VStack { Text("¥\(formatPriceOmitZero(allStats.amount))").font(.title2).bold(); Text("总金额").font(.caption) }
                }
                if globalAvg > 0 {
                    Divider().background(Color.white.opacity(0.5))
                    HStack {
                        Text("全盘综合均价:")
                        Text("¥\(formatPriceOmitZero(globalAvg)) / m³").bold()
                    }.font(.system(size: 14))
                }
            }
            .padding().background(Color.blue).foregroundColor(.white).cornerRadius(10).padding()
            
            List {
                ForEach(manager.projects) { p in
                    let pRecs = manager.records.filter { $0.projectId == p.id && $0.count > 0 }
                    let pSt = manager.getStats(for: pRecs)
                    let pAvg = pSt.vol > 0 ? pSt.amount / pSt.vol : 0
                    
                    NavigationLink(destination: ProjectReportDetailView(projId: p.id).environmentObject(manager)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("📁 \(p.name)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                            
                            HStack {
                                Text("\(pSt.count)根 | \(TimberCalculator.formatSum(pSt.vol))m³")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("¥\(formatPriceOmitZero(pSt.amount))")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.red)
                            }
                            
                            if pAvg > 0 {
                                Text("项目均价: ¥\(formatPriceOmitZero(pAvg)) / m³")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}

// 🌟 项目详细多维报表 (模块顺序已优化调整)
struct ProjectReportDetailView: View {
    var projId: String
    @EnvironmentObject var manager: DataManager
    
    var body: some View {
        let proj = manager.projects.first(where: { $0.id == projId })
        let pRecs = manager.records.filter { $0.projectId == projId && $0.count > 0 }
        let allSt = manager.getStats(for: pRecs)
        let allAvg = allSt.vol > 0 ? allSt.amount / allSt.vol : 0
        
        let dates = Array(Set(pRecs.map { $0.date })).sorted(by: >)
        let allDias = Array(Set(pRecs.compactMap { Double($0.dia) })).sorted()
        
        List {
            if pRecs.isEmpty {
                Text("该项目暂无盘点数据")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                
                // 第 1 区：整体数据汇总 (保持在顶部)
                Section(header: Text("🌲 整体数据汇总").font(.headline)) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("项目总金额").font(.caption).foregroundColor(.gray)
                                Text("¥\(formatPriceOmitZero(allSt.amount))").font(.title3).bold().foregroundColor(.red)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("项目综合均价").font(.caption).foregroundColor(.gray)
                                Text("¥\(formatPriceOmitZero(allAvg)) / m³").font(.system(size: 16, weight: .bold)).foregroundColor(.orange)
                            }
                        }
                        Divider()
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("总计根数").font(.caption).foregroundColor(.gray)
                                Text("\(allSt.count) 根").font(.system(size: 15, weight: .bold))
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("总计材积").font(.caption).foregroundColor(.gray)
                                Text("\(TimberCalculator.formatSum(allSt.vol)) m³").font(.system(size: 15, weight: .bold))
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
                
                // 第 2 区：日期汇总与明细 (移到中间)
                Section(header: Text("📅 日期汇总与明细").font(.headline)) {
                    ForEach(dates, id: \.self) { dateStr in
                        let dRecs = pRecs.filter { $0.date == dateStr }
                        let dSt = manager.getStats(for: dRecs)
                        let dAvg = dSt.vol > 0 ? dSt.amount / dSt.vol : 0
                        let dDias = Array(Set(dRecs.compactMap { Double($0.dia) })).sorted()
                        
                        DisclosureGroup {
                            ForEach(dDias, id: \.self) { dVal in
                                let dStr = dVal.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", dVal) : String(dVal)
                                let subRecs = dRecs.filter { Double($0.dia) == dVal }
                                let subSt = manager.getStats(for: subRecs)
                                
                                HStack {
                                    Text("▸ \(dStr)cm").font(.system(size: 14, weight: .bold)).foregroundColor(.blue)
                                    Spacer()
                                    Text("\(subSt.count)根 | \(TimberCalculator.formatSum(subSt.vol))m³ | ¥\(formatPriceOmitZero(subSt.amount))")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(dateStr).font(.system(size: 15, weight: .bold)).foregroundColor(.primary)
                                    Spacer()
                                    Text("¥\(formatPriceOmitZero(dSt.amount))").font(.system(size: 15, weight: .bold)).foregroundColor(.red)
                                }
                                HStack {
                                    Text("\(dSt.count)根 | \(TimberCalculator.formatSum(dSt.vol))m³")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    if dAvg > 0 {
                                        Text("均价: ¥\(formatPriceOmitZero(dAvg))").font(.system(size: 12, weight: .bold)).foregroundColor(.orange)
                                    }
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
                
                // 第 3 区：全盘径级统计 (移到最后)
                Section(header: Text("📏 全盘径级统计").font(.headline)) {
                    ForEach(allDias, id: \.self) { dVal in
                        let dStr = dVal.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", dVal) : String(dVal)
                        let dRecs = pRecs.filter { Double($0.dia) == dVal }
                        let st = manager.getStats(for: dRecs)
                        
                        HStack {
                            Text("\(dStr)cm")
                                .font(.system(size: 16, weight: .heavy))
                                .foregroundColor(.blue)
                                .frame(width: 55, alignment: .leading)
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(st.count)根 | \(TimberCalculator.formatSum(st.vol))m³")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                Text("¥\(formatPriceOmitZero(st.amount))")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(proj?.name ?? "项目详细报表")
        .navigationBarTitleDisplayMode(.inline)
    }
}
