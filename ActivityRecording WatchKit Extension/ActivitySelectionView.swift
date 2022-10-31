/*

Abstract:
SwiftUI View displaying the type of activities to record.
*/

import SwiftUI

struct Activities {
    static let writing: String = "Writing"
    static let walking: String = "Walking"
    static let standing: String = "Standing"
    static let climbing: String = "Climbing Stairs"
    static let sitting: String = "Sitting"
}

class SelectionModel: ObservableObject {
    var activity: String = ""
    var onBtnPress: (() -> Void)!
}

struct ActivitySelectionView: View {
    
    @ObservedObject var model: SelectionModel
    
    func setActivity(activity: String) -> () -> () {
        return {
            model.activity = activity
            model.onBtnPress()
        }
    }
    
    var body: some View {
        List {
            
            // Writing
            Button(action: setActivity(activity: Activities.writing)) {
                Image(systemName: "pencil.line")
                    .font(.system(size: 50))
                Text(Activities.writing)
            }
            .frame(width: 100, height: 120)
            
            // Walking
            Button(action: setActivity(activity: Activities.walking)) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 50))
                Text(Activities.walking)
            }
            .frame(width: 100, height: 120)
            
            // Standing
            Button(action: setActivity(activity: Activities.standing)) {
                Image(systemName: "figure.stand")
                    .font(.system(size: 50))
                Text(Activities.standing)
            }
            .frame(width: 100, height: 120)
            
            // Stairs
            Button(action: setActivity(activity: Activities.climbing)) {
                Image(systemName: "figure.stairs")
                    .font(.system(size: 50))
                Text(Activities.climbing)
            }
            .frame(width: 100, height: 120)
            
            // Sitting
            Button(action: setActivity(activity: Activities.sitting)) {
                Image(systemName: "chair")
                    .font(.system(size: 50))
                Text(Activities.sitting)
            }
            .frame(width: 100, height: 120)
        }
        .listStyle(.carousel)
    }
}

class SelectionHostingController: WKHostingController<ActivitySelectionView> {
    
    var model = SelectionModel()
    
    override var body: ActivitySelectionView {
        return ActivitySelectionView(model: model)
    }
    
    override func awake(withContext context: Any?) {
        
        model.onBtnPress = { [] in
            if (WorkoutManager.sharedInstance.checkAuthorization() == false) {
                print("WorkoutManager not authorized")
                return
            }
            
            WKInterfaceController.reloadRootPageControllers(
                withNames: ["ProgressController"],
                contexts: [self.model.activity],
                orientation: .horizontal,
                pageIndex: 0) 
        }
    }
    
}
