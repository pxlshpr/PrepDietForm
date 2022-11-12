import SwiftUI
import SwiftUISugar
import SwiftHaptics

struct MaintenanceEnergySettings: View {
    
    @Environment(\.dismiss) var dismiss
    
    @State var equation: BMREquation = .mifflinStJeor
    @State var activityLevel: BMRActivityLevel = .moderatelyActive
    @State var useHealthKitActiveEnergy: Bool = true
    @State var manuallyEnterBMR: Bool = false
    @State var manuallyEnterTDEE: Bool = false
    @State var applyActivityScaleFactor: Bool = true
    @State var manuallyEnteredBMR: String = ""
    @State var manuallyEnteredTDEE: String = ""

    var body: some View {
        NavigationView {
            Form {
                manualEntrySection
                if !manuallyEnterTDEE {
                    bmrSection
                    bodyMeasurementsSection
                    tdeeSection
                }
                activeEnergySection
            }
            .navigationTitle("2,250 kcal")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { principalContent }
            .toolbar { trailingContent }
        }
    }
    
    var trailingContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                Haptics.feedback(style: .soft)
                dismiss()
            } label: {
                closeButtonLabel
            }
        }
    }
    
    var principalContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("Maintenance  Calculator")
//                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
    
    var bmrHeader: some View {
        HStack {
            Text("BMR")
            Text("•")
                .foregroundColor(Color(.quaternaryLabel))
            Text("Basal Metabolic Rate")
                .foregroundColor(Color(.tertiaryLabel))
        }
    }

    var tdeeHeader: some View {
        HStack {
            Text("TDEE")
            Text("•")
                .foregroundColor(Color(.quaternaryLabel))
            Text("Total Daily Energy Expenditure")
                .foregroundColor(Color(.tertiaryLabel))
        }
    }

    var bodyMeasurementsSection: some View {
        Section("Body Measurements") {
            Text("Gender")
            Text("Weight")
            Text("Height")
        }
    }
    
    var bmrSection: some View {
        Section(header: bmrHeader) {
            if manuallyEnterBMR {
                TextField("Enter BMR in kcal", text: $manuallyEnteredBMR)
            } else {
                Picker(selection: $equation) {
                    ForEach(BMREquation.allCases, id: \.self) {
                        Text($0.description).tag($0)
                    }
                } label: {
                    Text("Equation")
                }
            }
            Toggle(isOn: $manuallyEnterBMR) {
                VStack(alignment: .leading) {
                    Text("Enter Manually")
                }
            }
        }
    }
    
    var tdeeSection: some View {
        Section(header: tdeeHeader) {
            Toggle(isOn: $applyActivityScaleFactor) {
                VStack(alignment: .leading) {
                    Text("Apply Activity Scale Factor")
                }
            }
            if applyActivityScaleFactor {
                Picker(selection: $activityLevel) {
                    ForEach(BMRActivityLevel.allCases, id: \.self) {
                        Text($0.description).tag($0)
                    }
                } label: {
                    Text("Activity Level")
                }
            }
        }
    }
    
    var activeEnergySection: some View {
        Section("Active Energy") {
            Toggle(isOn: $useHealthKitActiveEnergy) {
                VStack(alignment: .leading) {
                    Text("HealthKit Active Energy")
                    Text(useHealthKitActiveEnergy ? "Include when available" : "Do not use")
                        .font(.callout)
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }
        }
    }
    
    var manualEntrySection: some View {
        Section {
            Toggle(isOn: $manuallyEnterTDEE) {
                VStack(alignment: .leading) {
                    Text("Enter Manually")
                }
            }
            if manuallyEnterTDEE {
                TextField("Enter TDEE in kcal", text: $manuallyEnteredTDEE)
            }
        }
    }
}

struct MaintenanceEnergySettingsPreview: View {
    var body: some View {
        MaintenanceEnergySettings()
    }
}

struct MaintenanceEnergySettings_Previews: PreviewProvider {
    static var previews: some View {
        MaintenanceEnergySettingsPreview()
    }
}