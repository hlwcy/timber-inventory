# 木材量方登记 Timber Inventory

一套用来**现场记录木材规格、自动计算材积（方量）和金额**的小工具，包含两个版本：

| 版本 | 位置 | 说明 |
| --- | --- | --- |
| 网页版（正字量方登记） | [`index.html`](./index.html) | 单文件网页，手机浏览器打开即用，数据存在本机浏览器里 |
| iOS 版（盘点登记） | [`TimberInventory/`](./TimberInventory) | SwiftUI 原生 App，支持项目、日期、价格规则、统计报表 |

> 这是我用 AI 辅助开发的个人项目，用来练习"把真实业务需求变成可用的应用"。

## 功能

### 网页版 `index.html`
- 按 **树种 / 长度(m) / 直径(cm) / 客户或车牌** 添加规格
- 每个规格用"**正**"字笔画计数，支持 `+1` / `-1` / `+5` 快速增减
- 圆柱公式估算单根方量，或选择"只记根数"
- 汇总：总根数、总方量
- 新批次、保存、**导出 CSV**、**复制汇总文字**
- 数据保存在浏览器 `localStorage`，无需服务器
- 提供"添加到主屏幕"提示，可当作手机上的轻量 App 使用

### iOS 版 `TimberInventory`
- 两个标签页：**盘点登记**、**统计报表**
- 项目 → 实测日期 → 长度规格组 → 径级 的层级管理，首次进入某天会预填 1–4m、4–22cm 的径级
- 为不同长度/径级范围设置**价格规则**（可批量生成），也可对单条手动改价
- 单根材积按分段公式计算（代码注释标注为国标 GB/T 144），见 [`TimberCalculator.swift`](./TimberInventory/TimberApp/TimberCalculator.swift)
- 统计：总根数、总方数(m³)、总金额、综合均价，按项目、日期、径级汇总
- 用 SwiftUI 的 Shape 画出"正"字笔画（[`ZhengView.swift`](./TimberInventory/TimberApp/ZhengView.swift)）
- 数据用 `Codable` 编码后存入 `UserDefaults`

## 技术栈

- 网页版：HTML + CSS + 原生 JavaScript（无框架、无依赖）
- iOS 版：Swift 5 / SwiftUI（`TabView`、`NavigationStack`）

## 如何运行

**网页版**：直接用浏览器打开 `index.html`；想在手机上用，可以开启 GitHub Pages，再用手机浏览器打开并"添加到主屏幕"。

**iOS 版**：
1. 用 Xcode 打开 `TimberInventory/TimberInventory.xcodeproj`
2. 在 *Signing & Capabilities* 里选择你自己的开发团队（仓库里已清空团队 ID，Bundle ID 为占位值 `com.example.TimberInventory`）
3. 选择模拟器或真机，点击 Run

## 目录结构

```
index.html                      网页版（单文件）
TimberInventory/
├── TimberInventory.xcodeproj   Xcode 工程
└── TimberApp/
    ├── TimberApp.swift         App 入口
    ├── ContentView.swift       主界面：项目、日期、规格、价格规则、统计
    ├── Models.swift            数据模型：Project / PriceRule / Record
    ├── DataManager.swift       数据存取与统计
    ├── TimberCalculator.swift  材积与金额计算
    └── ZhengView.swift         "正"字笔画绘制
```

## 我如何用 AI 辅助开发

- 我负责提出需求、描述真实使用场景（现场记数、按径级定价、汇总报表），并在手机/模拟器上验收
- 用 AI 编程工具生成和修改代码，我测试、指出问题，再让 AI 迭代
- 在这个过程中我在学习：如何把需求拆成小任务、怎样写清楚的提示词、怎样读懂并检查 AI 写出来的代码

## 后续计划

- [ ] 补充真实截图
- [ ] iOS 版增加数据导出（CSV）
- [ ] 为材积公式补充单元测试
