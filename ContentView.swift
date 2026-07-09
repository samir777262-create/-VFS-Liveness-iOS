import SwiftUI
import AVFoundation
import UIKit

struct ContentView: View {
    @State private var capturedImage: UIImage? = nil
    @State private var showingCamera = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if capturedImage == nil {
                VStack(spacing: 30) {
                    Spacer()
                    
                    Image(systemName: "face.smiling")
                        .font(.system(size: 80))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("VFS Liveness")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("اضغط لفتح الكاميرا والتقاط سيلفي")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    Button(action: {
                        showingCamera = true
                    }) {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("التقط سيلفي")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                        .padding(.horizontal, 40)
                    }
                    .sheet(isPresented: $showingCamera) {
                        CameraView(capturedImage: $capturedImage)
                    }
                    
                    Spacer()
                }
            } else {
                VStack(spacing: 25) {
                    Text("تم التقاط السيلفي")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    if let image = capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 350)
                            .cornerRadius(16)
                            .shadow(radius: 15)
                    }
                    
                    HStack(spacing: 15) {
                        Button(action: { capturedImage = nil }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("إعادة")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray)
                            .cornerRadius(12)
                        }
                        
                        Button(action: saveToPhotos) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("حفظ")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                }
                .padding(.top, 50)
            }
        }
    }
    
    private func saveToPhotos() {
        guard let image = capturedImage else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        HapticFeedback.success()
    }
}

#Preview {
    ContentView()
}
