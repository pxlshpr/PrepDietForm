import PrepDataTypes

public extension Array where Element == Goal {
    func goalViewModels(goalSet: GoalSetViewModel, goalSetType: GoalSetType) -> [GoalViewModel] {
        map {
            GoalViewModel(
                goalSet: goalSet,
                goalSetType: goalSetType,
//                id: $0.id,
                type: $0.type,
                lowerBound: $0.lowerBound,
                upperBound: $0.upperBound,
                isAutoGenerated: $0.isAutoGenerated
            )
        }
    }
}
