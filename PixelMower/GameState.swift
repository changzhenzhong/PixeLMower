import Foundation

class GameState: ObservableObject {
    @Published var coins: Int = 0
    @Published var workerCount: Int = 1
    @Published var speedLevel: Int = 1
    
    @Published var currentBuildingIndex: Int = 0
    @Published var unlockedBuildings: [Bool] = [true, false, false]
    @Published var currentBuildingName: String = "小屋"
    @Published var currentBrickCount: Int = 0
    @Published var totalBrickCount: Int = 100
    
    private let buildings: [(name: String, cost: Int, totalBricks: Int, brickSize: CGFloat, layers: Int, perLayer: Int)] = [
        ("小屋", 0, 100, 10, 10, 10),
        ("住宅楼", 100, 300, 8, 15, 20),
        ("摩天大楼", 500, 500, 6, 20, 25)
    ]
    
    var buildingProgress: Double {
        totalBrickCount > 0 ? Double(currentBrickCount) / Double(totalBrickCount) : 0
    }
    
    var isBuildingComplete: Bool {
        currentBrickCount >= totalBrickCount
    }
    
    var allBuildingsUnlocked: Bool {
        unlockedBuildings.allSatisfy { $0 }
    }
    
    var nextBuildingCost: Int {
        guard let nextIndex = unlockedBuildings.firstIndex(where: { !$0 }) else { return 0 }
        return buildings[nextIndex].cost
    }
    
    var currentBonus: Int {
        return currentBuildingIndex + 1
    }
    
    func getCurrentBuildingStyle() -> (totalBricks: Int, brickSize: CGFloat, layers: Int, perLayer: Int) {
        let data = buildings[currentBuildingIndex]
        return (data.totalBricks, data.brickSize, data.layers, data.perLayer)
    }
    
    func unlockNextBuilding() -> Bool {
        guard let index = unlockedBuildings.firstIndex(where: { !$0 }) else { return false }
        let cost = buildings[index].cost
        guard coins >= cost else { return false }
        coins -= cost
        unlockedBuildings[index] = true
        currentBuildingIndex = index
        currentBuildingName = buildings[index].name
        let style = getCurrentBuildingStyle()
        totalBrickCount = style.totalBricks
        currentBrickCount = 0
        AudioManager.playUnlock()
        save()
        return true
    }
    
    func switchToBuilding(index: Int) {
        guard index < unlockedBuildings.count && unlockedBuildings[index] else { return }
        currentBuildingIndex = index
        currentBuildingName = buildings[index].name
        let style = getCurrentBuildingStyle()
        totalBrickCount = style.totalBricks
        currentBrickCount = 0
        save()
    }
    
    func addBrick() {
        guard currentBrickCount < totalBrickCount else { return }
        currentBrickCount += 1
        if isBuildingComplete {
            AudioManager.playUnlock()
        }
        save()
    }
    
    var workerCost: Int { 10 + workerCount * 5 }
    var speedCost: Int { 5 + speedLevel * 3 }
    
    func buyWorker() -> Bool {
        guard coins >= workerCost else { return false }
        coins -= workerCost
        workerCount += 1
        save()
        return true
    }
    
    func buySpeed() -> Bool {
        guard coins >= speedCost else { return false }
        coins -= speedCost
        speedLevel += 1
        save()
        return true
    }
    
    // MARK: - 存档
    func save() {
        let defaults = UserDefaults.standard
        defaults.set(coins, forKey: "coins")
        defaults.set(workerCount, forKey: "workerCount")
        defaults.set(speedLevel, forKey: "speedLevel")
        defaults.set(currentBuildingIndex, forKey: "currentBuildingIndex")
        defaults.set(unlockedBuildings, forKey: "unlockedBuildings")
        defaults.set(currentBrickCount, forKey: "currentBrickCount")
        defaults.set(totalBrickCount, forKey: "totalBrickCount")
    }
    
    func load() {
        let defaults = UserDefaults.standard
        coins = defaults.integer(forKey: "coins")
        workerCount = defaults.integer(forKey: "workerCount")
        if workerCount == 0 { workerCount = 1 }
        speedLevel = defaults.integer(forKey: "speedLevel")
        if speedLevel == 0 { speedLevel = 1 }
        currentBuildingIndex = defaults.integer(forKey: "currentBuildingIndex")
        if let unlocked = defaults.array(forKey: "unlockedBuildings") as? [Bool] {
            unlockedBuildings = unlocked
        }
        currentBrickCount = defaults.integer(forKey: "currentBrickCount")
        totalBrickCount = defaults.integer(forKey: "totalBrickCount")
        if totalBrickCount == 0 {
            // 如果存档不存在，设置初始值
            let style = getCurrentBuildingStyle()
            totalBrickCount = style.totalBricks
            currentBrickCount = 0
        }
        // 同步建筑名称
        currentBuildingName = buildings[currentBuildingIndex].name
    }
}
