import Foundation

struct FeatureFlags {
    private static func boolValue(for key: String, default defaultValue: Bool) -> Bool {
        // First, try Config.plist
        if let configPath = Bundle.main.path(forResource: "Config", ofType: "plist"),
           let configDict = NSDictionary(contentsOfFile: configPath),
           let value = configDict[key] as? NSNumber {
            return value.boolValue
        }
        // Next, Info.plist (environment variable style not applicable for bool, but support string "true"/"false")
        if let anyValue = Bundle.main.infoDictionary?[key] {
            if let num = anyValue as? NSNumber { return num.boolValue }
            if let str = anyValue as? String { return (str as NSString).boolValue }
        }
        return defaultValue
    }
    
    // detour.system_picker: Implement new system picker behind this flag (default OFF)
    static var detourSystemPicker: Bool {
        return boolValue(for: "DETOUR_SYSTEM_PICKER", default: false)
    }
    
    // ads.enabled: Toggle for showing ads (default ON)
    static var adsEnabled: Bool {
        return boolValue(for: "ADS_ENABLED", default: true)
    }
}