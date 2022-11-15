import SwiftUI
import SwiftUISugar

extension TDEEForm {
    var formFormula: some View {
        FormStyledScrollView {
            if !isEditing {
                viewingContents
            } else {
                editingContents
            }
        }
    }
    
    var editingContents: some View {
        Group {
            maintenanceSection
            Text("=")
                .matchedGeometryEffect(id: "equals", in: namespace)
                .font(.title)
                .foregroundColor(Color(.quaternaryLabel))
            formulaSectionNew
            Text("+")
                .matchedGeometryEffect(id: "plus", in: namespace)
                .font(.title)
                .foregroundColor(Color(.quaternaryLabel))
            activeHealthSection
//            restingHealthSection
        }
    }
    
    var viewingContents: some View {
        Group {
            promptSection
            arrowSection
            mainSection
                .padding(.top, 5)
                .padding(.bottom, 10)
            HStack(alignment: .firstTextBaseline) {
                appleHealthSymbol
                    .font(.caption2)
                Text("These components will be continuously updated as new data comes in from the Health App.")
            }
            .font(.footnote)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 17)
        }
    }
}
