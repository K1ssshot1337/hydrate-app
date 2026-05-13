# Hydrate App — 智能喝水提醒 设计文档

## 概述

一款原生 iOS/watchOS 应用，提供实时的智能喝水提醒、快速记录、历史统计与健康评估。个人自用。

## 技术栈

| 项目 | 选择 |
|------|------|
| 语言 | Swift |
| UI 框架 | SwiftUI |
| 数据持久化 | Core Data |
| 健康集成 | HealthKit（读写） |
| 手机-手表同步 | WatchConnectivity |
| 后台任务 | BGTaskScheduler |
| 通知 | UserNotifications |
| 语音 | Siri Intents |
| 最低系统 | iOS 18+ / watchOS 11+ |
| 分发 | 个人开发者账户侧载 |

## 项目结构

```
HydrateApp.xcodeproj
├── HydrateKit (共享 Swift Package)
│   ├── Models/
│   │   ├── WaterRecord.swift        — 单次饮水记录
│   │   ├── DailyGoal.swift          — 每日目标
│   │   ├── ReminderRule.swift       — 提醒规则
│   │   ├── CupPreset.swift          — 杯量预设 + 分量
│   │   └── WeeklyAssessment.swift   — 每周健康评估
│   ├── Storage/
│   │   ├── CoreDataStack.swift      — NSPersistentContainer
│   │   ├── WaterRecordStore.swift   — 记录的增删查
│   │   └── HealthKitService.swift   — HealthKit 读写
│   ├── ReminderEngine/
│   │   ├── ReminderScheduler.swift  — BGTask + UNNotification
│   │   └── AdaptiveCalculator.swift — 智能间隔计算
│   ├── SyncService/
│   │   └── WCManager.swift          — WatchConnectivity 双向同步
│   └── Assessment/
│       └── AssessmentEngine.swift   — 周/月评估生成
│
├── HydrateApp (iPhone Target)
│   ├── Views/
│   │   ├── HomeView.swift           — 进度环 + 快捷记录按钮
│   │   ├── HistoryView.swift        — 周/月趋势图 + 健康评估
│   │   └── SettingsView.swift       — 提醒时段、杯量、目标
│   ├── Intents/
│   │   └── LogWaterIntent.swift     — Siri 捷径
│   └── App.swift                    — @main 入口
│
├── HydrateWatch (Watch App Target)
│   ├── Views/
│   │   ├── WatchHomeView.swift      — 进度环 + 记录按钮
│   │   └── PortionPickerView.swift  — 矿泉水分量选择
│   ├── Complication/
│   │   └── WaterProgressRing.swift  — 表盘进度环
│   └── App.swift
│
└── WidgetExtension (锁屏/桌面小组件，可选)
```

## 数据模型

### WaterRecord — 单次喝水记录
```swift
struct WaterRecord {
    let id: UUID
    let amount: Double         // 毫升
    let timestamp: Date
    let source: Source         // .manual / .siri / .watch
}
```

### DailyGoal — 每日目标
```swift
struct DailyGoal {
    let date: Date
    let targetML: Double       // 默认 2000ml，可根据体重/运动调整
    let currentML: Double      // 当天已喝总量
}
```

### ReminderRule — 提醒规则
```swift
struct ReminderRule {
    let startTime: Date        // 如 09:00
    let endTime: Date          // 如 21:00
    let baseInterval: TimeInterval  // 基础间隔 45 分钟
    let enabledWeekdays: Set<Int>   // 1=周日...7=周六
}
```

### CupPreset — 饮水容器
```swift
enum ContainerMode {
    case oneTap                          // 点一下直接记录
    case portionSelect([Portion])        // 弹出分量选择
}

struct Portion {
    let name: String          // "1/5 瓶"
    let amount: Double        // 300ml
}

struct DrinkContainer {
    let name: String          // "保温杯" / "矿泉水"
    let totalAmount: Double?  // 矿泉水 1500ml 总容量（参考）
    let icon: String          // SF Symbol 名称
    let mode: ContainerMode
}
```

默认预设：
- 保温杯（480ml）：.oneTap，一点即记录
- 矿泉水（1500ml 总容量）：.portionSelect，包含 1/5 瓶(300ml)、1/4 瓶(375ml)、1/3 瓶(500ml)

### WeeklyAssessment — 每周健康评估
```swift
enum Grade: String {
    case a = "优秀"
    case b = "良好"
    case c = "需改善"
    case d = "严重不足"
}

enum Trend: String {
    case up = "↑"
    case stable = "→"
    case down = "↓"
}

struct WeeklyAssessment {
    let week: Date
    let avgDailyML: Double
    let goalMetDays: Int       // 达标天数
    let grade: Grade
    let trend: Trend
    let suggestion: String     // "运动日饮水量不足，建议运动后立即补水"
}
```

## 核心功能

### 1. 快捷记录（iPhone + Watch）
- 主界面两个大图标：保温杯 / 矿泉水
- 保温杯：点击直接记录 480ml
- 矿泉水：点击弹出分量选择器（1/5、1/4、1/3 瓶），选完记录
- 今日累计 = 所有记录毫升数累加

### 2. 智能提醒
- BGTaskScheduler 每 15 分钟后台唤醒
- 读取今日累计饮水、HealthKit 活动数据、当前时间
- 动态计算下次提醒时间：
  - 基础间隔 45 分钟
  - 如果当日累计 < 目标 50% 且时间过半 → 缩短至 30 分钟
  - 如果刚运动完（活动 ≥ 30min）→ 立即提醒 + 补水建议
  - 非提醒时段跳过
- 投递 UNNotification，通知附带"记录"操作按钮
- BGTask 被系统拒绝时：降级为固定间隔预排通知

### 3. HealthKit 集成
- 写入饮水数据到 Apple Health
- 读取体重、运动量、睡眠数据用于：
  - 动态调整每日饮水目标
  - 运动后主动补水提醒
  - 健康评估

### 4. iPhone ↔ Watch 同步
- WatchConnectivity `transferUserInfo`（保证送达，可排队）
- 增量同步，通过 SyncLog 表去重
- Watch 断连时记录暂存本地，重连后自动推送
- HealthKit 写入在 iPhone 侧集中完成（避免 Watch 侧权限问题）

### 5. 历史统计与健康评估
- 本周 / 本月饮水趋势图，日均达标率
- 每周日自动生成评估摘要
- 评估维度：饮水达标率 + 一致性 + 体重/运动关联
- 评分 A/B/C/D + 趋势箭头 + 一句话建议
- 可选的每周一推送上周评估

### 6. Siri 捷径
- "记录喝了杯水" 语音触发
- 默认记录保温杯量（480ml），可在捷径中设参数

### 7. Watch 表盘组件
- 圆形进度环，显示当日饮水完成百分比
- 点击跳转 WatchHomeView 直接记录

## 错误处理

| 场景 | 策略 |
|------|------|
| HealthKit 权限被拒 | 降级运行，关闭智能功能，仅用基础提醒 |
| Watch 断连 | 记录缓存 Watch 本地，重连后自动重推 |
| BGTask 被系统拒绝 | 降级为固定间隔 UNNotification 预排 |
| Siri 识别失败 | 引导用户打开 App 手动记录 |

## 测试策略

- **单元测试**：AdaptiveCalculator — 给定进度/时间 → 正确间隔
- **单元测试**：Portion 累加逻辑、每周评估算法
- **单元测试**：SyncLog 去重逻辑
- **UI 测试**：iPhone 快捷记录完整流程
- **UI 测试**：Watch 分量选择 → 记录 → 刷新
- **模拟测试**：WCManager 同步场景（断连/重连）

## 不包含（YAGNI）

- 多语言支持
- App Store 合规
- 数据导出/导入
- 社交分享
- 多用户/家庭共享
- 天气预报集成（运动后已足够智能化）
