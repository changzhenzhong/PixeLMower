import Foundation

struct UpgradeOption: Identifiable {
    let id: String
    let name: String
    let icon: String
    let description: String
    let currentLevel: Int
}

struct UpgradeManager {
    static let allUpgrades: [(id: String, name: String, icon: String, baseDesc: String)] = [
        ("damage", "攻击力提升", "💪", "攻击力 +25%"),
        ("speed", "攻击速度", "⚡", "旋转速度 +20%"),
        ("range", "攻击范围", "🎯", "剑刃范围 +20%"),
        ("move", "移动速度", "👟", "移动速度 +12%"),
        ("blades", "额外剑刃", "⚔️", "剑刃数量 +1"),
        ("exp", "经验加成", "💎", "经验获取 +25%"),
        ("crit", "暴击强化", "💥", "暴击率 +6%"),
        ("hp", "生命提升", "❤️", "最大生命 +30%（回满）"),
    ]

    static func generateOptions(currentLevels: [String: Int], count: Int) -> [UpgradeOption] {
        let available = allUpgrades.shuffled()
        var result: [UpgradeOption] = []
        for upgrade in available {
            if result.count >= count { break }
            let lv = currentLevels[upgrade.id] ?? 0
            result.append(UpgradeOption(
                id: upgrade.id,
                name: upgrade.name,
                icon: upgrade.icon,
                description: upgrade.baseDesc,
                currentLevel: lv
            ))
        }
        return result
    }
}
