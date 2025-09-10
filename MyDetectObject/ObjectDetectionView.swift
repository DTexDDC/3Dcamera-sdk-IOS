import SwiftUI

struct ObjectDetectionView: View {

    @Binding var objectDetect: [ObjectDetect] // Two way binding. So any changes to this child view are reflected in the parent view ContentView where
                                              // this child view is called.

    
    var body: some View {
        ZStack { // Views are added on top of each other with the first  view at the bottom. E.g. Adding text and images over a background.

            ForEach(0..<objectDetect.count, id: \.self) { index in
                let objectDetect = objectDetect[index]
                let box = objectDetect.boundingBoxes
                ZStack {

                    Rectangle()
                        .stroke(Color.yellow, lineWidth: 3) // Colour of rectangle
                        .frame(width: box.width, height: box.height) // Width and height of rectangle
                        .position(x: box.midX, y: box.midY) // Position of centre of rectangle
                    
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // So this outer Zstack view should be the maximum size.
    }
}
