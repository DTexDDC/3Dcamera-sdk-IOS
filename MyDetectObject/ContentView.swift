
import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject var sdk = DetectObjectSDK.shared
    @EnvironmentObject var objectDetectionHelper: ObjectDetectionHelper
    
    @State private var showCamera: Bool = false
    @State private var objectDetect: [ObjectDetect] = []
    @State private var startingOffset: CGFloat = UIScreen.main.bounds.height * 0.80
    @State private var currentOffset:CGFloat = 0
    @State private var endOffset:CGFloat = 0
    @State private var showItemsSheet = false
    @State private var showReviewSheet = false
    @State private var showClearAlert = false
    @State var showMovementWarning = false
    
    private var buttonColour = Color(
        red: 238.0 / 255.0,
        green: 111.0 / 255.0,
        blue: 31.0 / 255.0
    )

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                ARViewContainer(objectDetect: $objectDetect, showCamera: $showCamera, showMovementWarning: $showMovementWarning)
                    .environmentObject(objectDetectionHelper)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                if showMovementWarning {
                                VStack {
                                    Text("📱 Too much movement\nPlease keep still")
                                        .multilineTextAlignment(.center)
                                        .font(.headline)
                                        .padding()
                                        .background(Color.black.opacity(0.7))
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                        .padding(.top, 50)
                                    
                                    Spacer()
                                }
                                .transition(.opacity)
                                .animation(.easeInOut, value: showMovementWarning)
                            }
//                ObjectDetectionView(objectDetect: $objectDetect)
//                ARComponents(objectDetect: $objectDetect)
//                    .environmentObject(objectDetectionHelper)
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//                SwitchCameraRepresentable(
//                    onStop: {
//                        print("Stop AR functionality")
//                        // Add your logic to start AR functionality here
//                    },
//                    onStart: {
//                        print("Start AR functionality")
//                        // Add your logic to stop AR functionality here
//                    })
//                StartStopRepresentable(showCamera: $showCamera)
//                    .frame(width: 200, height: 80)
////                    .position(x: UIScreen.main.bounds.width/2, y:UIScreen.main.bounds.height - 250 + currentOffset)
                RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .frame(width: UIScreen.main.bounds.width, height: 200) // slightly bigger than the button
                HStack(spacing: 20) {
                                // Start / Pause Button
                                Button(action: {
                                    showCamera.toggle()
                                    
                                    if showCamera {
                                        print("Scanning started")
                                    } else {
                                        let overviewImage = objectDetectionHelper.sceneImage
                                        let objectsCopy = objectDetect
                                        DispatchQueue.global(qos: .background).async {
                                            sdkSendData.send(binding: objectsCopy, overviewImage: overviewImage)
                                        }
                                        let lock = NSLock()
                                        lock.lock()
                                        objectDetect.removeAll()
                                        lock.unlock()
                                        print("Scanning paused")
                                    }
                                }) {
                                    Text(showCamera ? "Pause" : "Start")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(width: 120, height: 60)
                                        .background(buttonColour)
                                        .cornerRadius(12)
                                }
                                
                                // Clear Button
                                Button(action: {
                                    let lock = NSLock()
                                    lock.lock()
                                    objectDetect.removeAll()
                                    lock.unlock()

                                    lock.lock()
                                    objectDetectionHelper.detectedProducts.removeAll()
                                    lock.unlock()
                                    
                                    showClearAlert = true
                                    print("Cleared")
                                }) {
                                    Text("Clear")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(width: 120, height: 60)
                                        .background(buttonColour)
                                        .cornerRadius(12)
                                }
                            }
                            .padding(.bottom, 100) // move buttons up a bit from bottom
                Button(action: {
                                // 1. Send "finished" event to host app
                    self.objectDetectionHelper.detectedProducts.removeAll()
                    self.objectDetect.removeAll()
                    print(self.objectDetectionHelper.detectedProducts, self.objectDetect)
                    sdk.onEvent?(["type": "finished"])

//                                // 2. Close the SDK UI
//                                dismiss()
                            }) {
                                Text("Finish")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .frame(width: 350, height: 70)
                                    .background(Color(
                                        red: 240.0 / 255.0,
                                        green: 240.0 / 255.0,
                                        blue: 240.0 / 255.0
                                    ))
                                    .cornerRadius(17)
                            }
                            .padding(.bottom, 10)
//                  DraggableView(showItemsSheet: $showItemsSheet, showReviewSheet: $showReviewSheet)
//                    .offset(y:startingOffset)
//                    .offset(y:currentOffset)
//                    .offset(y:endOffset)
//                    .gesture(
//                        DragGesture()
//                            .onChanged{ value in
//                                withAnimation(.spring()){
//                                    currentOffset = value.translation.height
//                                }
//                            }
//                            .onEnded{ value in
//                                withAnimation(.spring()){
//                                    if currentOffset < -150{
//                                        //                                                endOffset = -startingOffset
//                                        endOffset = UIScreen.main.bounds.height * -0.3
//                                    } else if endOffset != 0 && currentOffset > 150 {
//                                        endOffset = .zero
//                                    }
//                                    currentOffset = 0
//                                }
//                            }
//                    ).environmentObject(objectDetectionHelper)
//                    .onReceive(objectDetectionHelper.objectWillChange) { _ in
//                        objectDetectionHelper.setup()
//                        print("Setting up")
//                    }
            }
            .navigationBarItems(trailing: NavigationLink(destination: ItemsListView().environmentObject(objectDetectionHelper)) {
                Text("Show Items").foregroundColor(.blue)
            })
            .alert(isPresented: $showClearAlert) {
                Alert(
                    title: Text("Cleared"),
                    message: Text("All detections have been cleared."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

#Preview {
    ContentView()
}

struct DraggableView: View {
    @EnvironmentObject var objectDetectionHelper: ObjectDetectionHelper
    @Binding var showItemsSheet: Bool
    @Binding var showReviewSheet: Bool
    let options = ["Option 1", "Option 2", "Option 3"]

    var body: some View {
        VStack(spacing: 15) {
            Capsule()
                .fill(Color.gray)
                .frame(width: 40, height: 6)
                .padding(.top, 20)
                .padding(.bottom, 30)
            HStack(alignment: .center, spacing: 5) {
                Text("ML Model")
                    .font(.subheadline)
                    .foregroundColor(.black)
                    .padding(.leading, 20)
                Spacer()
                Picker("Select an option", selection: $objectDetectionHelper.modelType) {
                    ForEach(ModelType.allCases, id: \.self) { option in
                        Text(option.title).tag(option)
                    }
                }
                .frame(height: 20)
                .pickerStyle(MenuPickerStyle())
                .padding()
                .background(Color.gray.opacity(0.2).cornerRadius(10))
                .padding(.horizontal)
            }	
            
            // Row cho tỷ lệ với nhãn
            HStack(alignment: .center, spacing: 10) {
                Text("Threshold")
                    .font(.subheadline)
                    .foregroundColor(.black)
                    .padding(.leading, 20)
                Spacer()
                HStack {
                    Button(action: {
                        if objectDetectionHelper.scoreThreshold > 0 { objectDetectionHelper.scoreThreshold = max(0, objectDetectionHelper.scoreThreshold - 0.1) }
                    }) {
                        Image(systemName: "minus.circle")
                            .font(.title)
                            .foregroundColor(.black)
                    }
                    
                    Text(String(format: "   %.1f   ", objectDetectionHelper.scoreThreshold))
                        .font(.subheadline)
                        .foregroundColor(.black)
//                        .padding(.horizontal)
                    
                    Button(action: {
                        if objectDetectionHelper.scoreThreshold < 1 { objectDetectionHelper.scoreThreshold = min(1, objectDetectionHelper.scoreThreshold + 0.1) }
                    }) {
                        Image(systemName: "plus.circle")
                            .font(.title)
                            .foregroundColor(.black)
                    }
                }
                .padding(.trailing, 40)
                
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.white.cornerRadius(30))
        .padding()
    }
}


struct ItemsListView: View {
    @EnvironmentObject var objectDetectionHelper: ObjectDetectionHelper
    
    var body: some View {
        NavigationView {
            VStack {
                if objectDetectionHelper.detectedProducts.isEmpty {
                    Text("No products were detected.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    let groupedItems = Dictionary(grouping: objectDetectionHelper.detectedProducts, by: { $0.name })
                    let sortedGroupedItems = groupedItems.sorted { $0.key < $1.key }
                    
                    List(sortedGroupedItems, id: \.key) { group in
                        HStack {
                            Text(group.key)
                                .bold()
                            Spacer()
                            Text("Count: \(group.value.count)")
                                .foregroundColor(.gray)
                                .font(.body)
                        }
                        .padding(.vertical, 5)
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .padding()
        }
        .navigationTitle("List of items")
        .navigationBarItems(trailing: Button(action: {
            objectDetectionHelper.clearDetectedProducts()
        }) {
            Text("Clear")
                .foregroundColor(.red)
        })
    }
}

struct ReviewARImageView: View {
    @EnvironmentObject var objectDetectionHelper: ObjectDetectionHelper
    var body: some View {
        VStack {
            Text("Review AR Image")
                .font(.headline)
                .padding()
            if let image = objectDetectionHelper.imagePreview {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
                    .padding()
            } else {
                Text("No Image")
            }

            Button("Close") {
            }
            .font(.subheadline)
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white, lineWidth: 2)
            )
        }
    }
}
