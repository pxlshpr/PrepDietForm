import Foundation
import PrepDataTypes

public struct Goal: Identifiable, Hashable, Codable {
    public let type: GoalType
    public var lowerBound: Double?
    public var upperBound: Double?
    
    public var isAutoGenerated: Bool
    
    public init(
        type: GoalType,
        lowerBound: Double? = nil,
        upperBound: Double? = nil,
        isAutoGenerated: Bool = false
    ) {
        self.type = type
        self.lowerBound = lowerBound
        self.upperBound = upperBound
        self.isAutoGenerated = isAutoGenerated
    }
    
    public var id: String {
        type.identifyingHashValue
    }
}

extension Array where Element == Goal {
    func goalViewModels(goalSet: GoalSetViewModel, isForMeal: Bool) -> [GoalViewModel] {
        map {
            GoalViewModel(
                goalSet: goalSet,
                isForMeal: isForMeal,
//                id: $0.id,
                type: $0.type,
                lowerBound: $0.lowerBound,
                upperBound: $0.upperBound,
                isAutoGenerated: $0.isAutoGenerated
            )
        }
    }
}

extension Goal {
    func equivalentUnitString(userUnits: UserUnits) -> String? {
        switch type {
        case .energy(let type):
            switch type {
            default:
                return userUnits.energyUnit.shortDescription
            }
        case .macro(let type, _):
            switch type {
            case .quantityPerWorkoutDuration:
                return type.description(nutrientUnit: .g)
            default:
                return NutrientUnit.g.shortDescription
            }
        case .micro(let type, _, let nutrientUnit):
            switch type {
            case .quantityPerWorkoutDuration:
                return type.description(nutrientUnit: nutrientUnit)
            default:
                return nutrientUnit.shortDescription
            }
        }
    }
}

extension Goal {
    
    func calculateLowerBound(with params: GoalCalcParams) -> Double? {
        
        guard !type.isEnergy else {
            return calculateEnergyValue(
                from: lowerBound,
                deficitBound: largerBound ?? lowerBound,
                tdee: params.bodyProfile?.tdeeInUnit
            )
        }
        
        let energyValue = energyGoalLowerOrUpper(with: params)
        
        switch type {
        case .macro:
            return calculateMacroValue(
                from: trueLowerBound,
                energy: energyValue,
                bodyProfile: params.bodyProfile,
                userUnits: params.userUnits
            )

        case .micro:
            return calculateMicroValue(
                from: trueLowerBound,
                energy: energyValue,
                bodyProfile: params.bodyProfile,
                userUnits: params.userUnits
            )
        default:
            return nil
        }
    }
    
    func calculateUpperBound(with params: GoalCalcParams) -> Double? {
        
        guard !type.isEnergy else {
            return calculateEnergyValue(
                from: upperBound,
                deficitBound: smallerBound ?? upperBound,
                tdee: params.bodyProfile?.tdeeInUnit
            )
        }
        
        let energyValue = energyGoalUpperOrLower(with: params)

        switch type {
        case .macro:
            return calculateMacroValue(
                from: trueUpperBound,
                energy: energyValue,
                bodyProfile: params.bodyProfile,
                userUnits: params.userUnits
            )
        case .micro:
            return calculateMicroValue(
                from: trueUpperBound,
                energy: energyValue,
                bodyProfile: params.bodyProfile,
                userUnits: params.userUnits
            )
        default:
            return nil
        }
    }
}

extension Goal {
    
    func energyGoalLowerOrUpper(with params: GoalCalcParams) -> Double? {
        guard let energyGoal = params.energyGoal else { return nil }
        return energyGoal.calculateLowerBound(with: params)
            ?? energyGoal.calculateUpperBound(with: params)
    }
    
    func energyGoalUpperOrLower(with params: GoalCalcParams) -> Double? {
        guard let energyGoal = params.energyGoal else { return nil }
        return energyGoal.calculateUpperBound(with: params)
            ?? energyGoal.calculateLowerBound(with: params)
    }

    var trueLowerBound: Double? {
        guard let lowerBound else { return nil }
        guard let upperBound else { return lowerBound }
        if upperBound == lowerBound {
            return nil
        }
        if upperBound < lowerBound {
            return upperBound
        }
        return lowerBound
    }
    
    var trueUpperBound: Double? {
        guard let upperBound else { return nil }
        guard let lowerBound else { return upperBound }
        if upperBound == lowerBound {
            return upperBound
        }
        if lowerBound > upperBound {
            return lowerBound
        }
        return upperBound
    }
    
    var largerBound: Double? {
        if let upperBound {
            if let lowerBound {
                return upperBound > lowerBound ? upperBound : lowerBound
            } else {
                return upperBound
            }
        } else {
            return lowerBound
        }
    }
    
    var smallerBound: Double? {
        if let upperBound {
            if let lowerBound {
                return upperBound < lowerBound ? upperBound : lowerBound
            } else {
                return upperBound
            }
        } else {
            return lowerBound
        }
    }
}

extension Goal {

//    func lowerOrUpper(with params: GoalCalcParams) -> Double? {
//        calculateLowerBound(with: params) ?? calculateUpperBound(with: params)
//    }
    
    func upperOrLower(with params: GoalCalcParams) -> Double? {
        calculateUpperBound(with: params) ?? calculateLowerBound(with: params)
    }
 
    func calculateEnergyValue(
        from value: Double?,
        deficitBound: Double?,
        tdee: Double?
    ) -> Double? {
        guard let value, let energyGoalType else { return nil }
        
        guard !energyGoalType.isFixed else {
            return value
        }
        
        guard let deficitBound, let tdee else { return nil }
        
        switch energyGoalType {
        case .fromMaintenance(_, let delta):
            switch delta {
            case .deficit:
                return tdee - deficitBound
            case .surplus:
                return tdee + value
            }
            
        case .percentFromMaintenance(let delta):
            switch delta {
            case .deficit:
                return tdee - ((deficitBound/100) * tdee)
            case .surplus:
                return tdee + ((value/100) * tdee)
            }
            
        default:
            return nil
        }
    }
    
    func calculateMacroValue(
        from value: Double?,
        energy: Double?,
        bodyProfile: BodyProfile?,
        userUnits: UserUnits
    ) -> Double? {
        
        guard let nutrientGoalType, nutrientGoalType.isPercentageOfEnergy else {
            return calculateNutrientValue(
                from: value,
                energy: energy,
                bodyProfile: bodyProfile,
                userUnits: userUnits
            )
        }
        
        guard let macro,
              let value,
              let energyInKcal = convertEnergyToKcal(
                    energy,
                    usingBodyProfile: bodyProfile,
                    orUserUnits: userUnits
              )
        else { return nil }
        
        return macro.grams(equallingPercent: value, of: energyInKcal)
    }
    
    func calculateMicroValue(
        from value: Double?,
        energy: Double?,
        bodyProfile: BodyProfile?,
        userUnits: UserUnits
    ) -> Double? {
        
        guard let nutrientGoalType, nutrientGoalType.isPercentageOfEnergy else {
            return calculateNutrientValue(
                from: value,
                energy: energy,
                bodyProfile: bodyProfile,
                userUnits: userUnits
            )
        }

        guard let nutrientType,
              let value,
              let energyInKcal = convertEnergyToKcal(
                    energy,
                    usingBodyProfile: bodyProfile,
                    orUserUnits: userUnits
              )
        else { return nil }
        
        return nutrientType.grams(equallingPercent: value, of: energyInKcal)
    }
    
    func calculateNutrientValue(
        from value: Double?,
        energy: Double?,
        bodyProfile: BodyProfile?,
        userUnits: UserUnits
    ) -> Double? {
        guard let value, let nutrientGoalType else { return nil }
        
        switch nutrientGoalType {
            
        case .quantityPerBodyMass(let bodyMass, let weightUnit):
            switch bodyMass {
            case .weight:
                guard let weight = bodyProfile?.weight(in: weightUnit)
                else { return nil }
                return value * weight
                
            case .leanMass:
                guard let lbm = bodyProfile?.lbm(in: weightUnit)
                else { return nil}
                return value * lbm
                
            }
            
        case .quantityPerEnergy(let perEnergy, let energyUnit):
            guard let goalEnergyKcal = convertEnergyToKcal(
                energy,
                usingBodyProfile: bodyProfile,
                orUserUnits: userUnits
            ) else {
                return nil
            }
            
            let perEnergyInKcal: Double
            if energyUnit == .kcal {
                perEnergyInKcal = perEnergy
            } else {
                perEnergyInKcal = EnergyUnit.convertToKilocalories(fromKilojules: perEnergy)
            }
            return (value * goalEnergyKcal) / perEnergyInKcal
        
        case .fixed:
            return value
            
        default:
            return nil
        }
    }
    
    //MARK: - Helpers
    func convertEnergyToKcal(
        _ energy: Double?,
        usingBodyProfile bodyProfile: BodyProfile?,
        orUserUnits userUnits: UserUnits
    ) -> Double? {
        guard let energy else { return nil }
        let energyUnit = bodyProfile?.parameters.energyUnit ?? userUnits.energyUnit
        return energyUnit == .kcal ? energy : energy * KcalsPerKilojule
    }

    var energyGoalType: EnergyGoalType? {
        switch type {
        case .energy(let type):
            return type
        default:
            return nil
        }
    }
    
    var nutrientGoalType: NutrientGoalType? {
        switch type {
        case .macro(let type, _):
            return type
        case .micro(let type, _, _):
            return type
        default:
            return nil
        }
    }
    
    var macro: Macro? {
        switch type {
        case .macro(_, let macro):
            return macro
        default:
            return nil
        }
    }

    var nutrientType: NutrientType? {
        switch type {
        case .micro(_, let nutrientType, _):
            return nutrientType
        default:
            return nil
        }
    }

}
