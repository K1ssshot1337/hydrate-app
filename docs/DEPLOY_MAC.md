# Hydrate App — Mac 端部署指南

## 准备工作

1. 打开 Terminal（终端）
2. 克隆项目：
```bash
git clone https://github.com/K1ssshot1337/hydrate-app.git
cd hydrate-app
```

## 第一步：创建 Xcode 项目

1. 打开 Xcode → **File → New → Project**
2. 选择 **iOS → App**，点 Next
3. 填写：
   - Product Name: `HydrateApp`
   - Team: 选你的 Apple ID（没有就先去 Xcode → Settings → Accounts 登录）
   - Organization Identifier: 留默认
   - Interface: **SwiftUI**
   - Language: **Swift**
   - ✅ 勾选 **Include watchOS App**
4. 保存位置选 `hydrate-app` 文件夹（覆盖已有的文件夹，确认即可）

## 第二步：添加 HydrateKit 共享包

1. **File → Add Package Dependencies**
2. 点左下角 **Add Local…** 按钮
3. 选择 `hydrate-app/HydrateKit` 文件夹
4. 点 **Add Package**

## 第三步：关联 Framework

1. 在左侧项目导航栏点最顶上的蓝色 `HydrateApp` 图标
2. 选 **HydrateApp** target → **General** → **Frameworks, Libraries, and Embedded Content**
3. 点 **+** → 选 `HydrateKit` → 点 **Add**
4. 同样操作给 **HydrateWatch** target 加上 `HydrateKit`

## 第四步：替换默认文件为我们的代码

Xcode 会自动生成一些默认 `.swift` 文件。全部删掉它们（选中后按 Delete → Move to Trash）。

然后把我们的文件加进来。在 Finder 中操作最方便：

1. 打开 Finder，进入 `hydrate-app/HydrateApp/` 文件夹
2. 把 `App.swift` 拖入 Xcode 左侧的 **HydrateApp** 组（不要拖到 HydrateWatch 那边）
3. 把 `Views/` 文件夹整个拖进去（包含 HomeView.swift、HistoryView.swift、SettingsView.swift、PortionPickerSheet.swift）
4. 把 `Intents/` 文件夹拖进去
5. 拖入时勾选 ✅ **Copy items if needed**，Target 只选 **HydrateApp**

Watch 部分同样操作：
1. Finder 进入 `hydrate-app/HydrateWatch/`
2. 把 `App.swift` 拖入 **HydrateWatch** 组
3. 把 `Views/` 文件夹拖进去
4. 把 `Complication/` 文件夹拖进去
5. Target 只选 **HydrateWatch**

## 第五步：配置 App Intents（Siri 功能）

1. 点 Xcode 顶部菜单 **File → New → Target**
2. 选 **watchOS** 或搜索 **App Intents Extension**
3. 如果有，创建一个；如果没有这个选项，跳到最后「备选方案」

## 第六步：配置 Capabilities（权限）

点 `HydrateApp` target → **Signing & Capabilities**：

添加以下（点 **+ Capability**）：
- **HealthKit** — 出现两个 Entitlement 文件后，确保 `com.apple.developer.healthkit` 下 Read 和 Write 都打勾
- **Background Modes** — 勾选 ✅ Background fetch 和 ✅ Background processing

## 第七步：配置 Info.plist 权限描述

在 `HydrateApp` target → **Info** 标签页添加：

| Key | Value |
|-----|-------|
| `Privacy - Health Share Usage Description` | 用于根据你的运动和体重数据调整饮水建议 |
| `Privacy - Health Update Usage Description` | 用于将你的饮水记录同步到 Apple Health |

## 第八步：运行！

1. 把 iPhone 用 USB 线连接 Mac，iPhone 解锁并点「信任此电脑」
2. Xcode 顶部 Scheme 选 **HydrateApp**，destination 选你的 iPhone
3. 按 **⌘R** 运行
4. Watch App 会自动随 iPhone App 安装到手表中

首次运行后，在 iPhone 上打开 App → 设置标签 → 点「请求 HealthKit 权限」→ 授权。

---

## 备选方案：Siri Intents 简化处理

如果找不到 App Intents Extension target，Siri 功能仍然可用，但需要把 `LogWaterIntent.swift` 直接放在 HydrateApp target 中（已经放了）。

确保 `HydrateApp` target 的 **Signing & Capabilities** 里有 **Siri** capability（点 + 添加）。

---

## 常见问题

**Q: 编译报 "No such module HydrateKit"？**
A: 检查第三步是否正确关联了 Framework。HydrateApp 和 HydrateWatch 两个 target 都要添加。

**Q: 推送到 Watch 失败？**
A: 需要在 iPhone 上的 Watch App 里先安装。iPhone App 安装成功后 Watch App 会自动推送。

**Q: 没有付费开发者账号怎么办？**
A: 免费 Apple ID 就可以侧载到自己设备。限制：每 7 天需要重新安装一次。
