import SwiftUI
import PrepDataTypes

extension Array where Element == Goal {
    func goalViewModels(isForMeal: Bool) -> [GoalViewModel] {
        map {
            GoalViewModel(
                isForMeal: isForMeal,
                id: $0.id,
                type: $0.type,
                lowerBound: $0.lowerBound,
                upperBound: $0.upperBound
            )
        }
    }
}
extension GoalSetForm {
    class ViewModel: ObservableObject {
        @Published var emoji: String
        @Published var name: String
        @Published var isMealProfile = false
        @Published var goals: [GoalViewModel] = []
        @Published var currentTDEEProfile: TDEEProfile?

        let existingGoalSet: GoalSet?
        
        init(isMealProfile: Bool, existingGoalSet existing: GoalSet?, currentTDEEProfile: TDEEProfile? = nil) {
            self.isMealProfile = isMealProfile
            self.currentTDEEProfile = currentTDEEProfile
            self.existingGoalSet = existing
            self.emoji = existing?.emoji ?? randomEmoji(forMealProfile: isMealProfile)
            self.name = existing?.name ?? ""
            self.goals = existing?.goals.goalViewModels(isForMeal: isMealProfile) ?? []
        }
    }
}

extension GoalSetForm.ViewModel {
    func containsMacro(_ macro: Macro) -> Bool {
        goals.containsMacro(macro)
    }
    
    func containsMicro(_ micro: NutrientType) -> Bool {
        goals.containsMicro(micro)
    }
    
    func didAddNutrients(pickedEnergy: Bool, pickedMacros: [Macro], pickedMicros: [NutrientType]) {
        if pickedEnergy, !goals.containsEnergy {
            goals.append(GoalViewModel(
                isForMeal: isMealProfile, type: .energy(.fixed(.kcal))
            ))
        }
        for macro in pickedMacros {
            if !goals.containsMacro(macro) {
                goals.append(GoalViewModel(
                    isForMeal: isMealProfile,
                    type: .macro(.fixed, macro)
                ))
            }
        }
        for nutrientType in pickedMicros {
            if !goals.containsMicro(nutrientType) {
                goals.append(GoalViewModel(
                    isForMeal: isMealProfile,
                    type: .micro(.fixed, nutrientType, nutrientType.units.first ?? .g)
                ))
            }
        }
    }
    
    var energyGoal: GoalViewModel? {
        get {
            goals.first(where: { $0.type.isEnergy })
        }
        set {
            guard let newValue else {
                //TODO: maybe use this to remove it by setting it to nil?
                return
            }
            self.goals.update(with: newValue)
        }
    }
    
    var macroGoals: [GoalViewModel] {
        get {
            goals
                .filter({ $0.type.isMacro })
                .sorted(by: {
                    ($0.type.macro?.sortOrder ?? 0) < ($1.type.macro?.sortOrder ?? 0)
                })
        }
    }
    
    var microGoals: [GoalViewModel] {
        get {
            goals
                .filter({ $0.type.isMicro })
                .sorted(by: {
                    ($0.type.nutrientType?.rawValue ?? 0) < ($1.type.nutrientType?.rawValue ?? 0)
                })
        }
    }
}

extension Macro {
    var sortOrder: Int {
        switch self {
        case .carb:     return 1
        case .fat:      return 2
        case .protein:  return 3
        }
    }
}

let dietEmojis = "⤵️⤴️🍽️⚖️🏝🏋🏽🚴🏽🍩🍪🥛"
let mealProfileEmojis = "🤏🙌🏋🏽🚴🏽🍩🍪⚖️🥛"

func randomEmoji(forMealProfile: Bool) -> String {
    let array = forMealProfile ? mealProfileEmojis : dietEmojis
    guard let character = array.randomElement() else {
        return "⚖️"
    }
    return String(character)
}


