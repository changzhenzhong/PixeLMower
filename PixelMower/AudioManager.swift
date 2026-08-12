import AVFoundation

struct AudioManager {
    static func playSound(_ soundID: SystemSoundID = 1104) {
        AudioServicesPlaySystemSound(soundID)
    }
    
    static func playCoin() { AudioServicesPlaySystemSound(1104) }
    static func playPickup() { AudioServicesPlaySystemSound(1105) }
    static func playDrop() { AudioServicesPlaySystemSound(1106) }
}
