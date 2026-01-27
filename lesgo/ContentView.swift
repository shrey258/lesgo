//
//  ContentView.swift
//  lesgo
//
//  Created by Shreyansh Gupta on 27/01/26.
//

import SwiftUI
import Speech

struct ContentView: View {
    @StateObject private var speechRecognizer = SpeechRecognizer()
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2), // Dark midnight blue/purple
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack {
                // Speech Text Container
                VStack(alignment: .leading) {
                    ScrollView {
                        if speechRecognizer.transcript.isEmpty {
                            Text("Tap the mic and start speaking...")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.6))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text(speechRecognizer.transcript)
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .frame(height: 300) // Fixed height for now
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .padding(.horizontal)
                .padding(.top, 60)

                Spacer()
                
                // Mic Button
                Button(action: {
                    if speechRecognizer.isRecording {
                        speechRecognizer.stopTranscribing()
                    } else {
                        speechRecognizer.startTranscribing()
                    }
                }) {
                    Image(systemName: speechRecognizer.isRecording ? "stop.circle.fill" : "mic.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                        .padding(24)
                        .background(
                            Circle()
                                .fill(speechRecognizer.isRecording ? Color.red : Color.blue)
                                .shadow(color: (speechRecognizer.isRecording ? Color.red : Color.blue).opacity(0.5), radius: 10, x: 0, y: 5)
                        )
                        // Simple pulsing effect when recording
                        .scaleEffect(speechRecognizer.isRecording ? 1.1 : 1.0)
                        .animation(speechRecognizer.isRecording ? Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default, value: speechRecognizer.isRecording)
                }
                .padding(.bottom, 40)
            }
        }
        .alert(item: Binding<String?>(
            get: { speechRecognizer.errorMessage },
            set: { speechRecognizer.errorMessage = $0 }
        )) { message in
            Alert(title: Text("Error"), message: Text(message), dismissButton: .default(Text("OK")))
        }
    }
}

// Helper to make String conform to Identifiable for Alert item
extension String: Identifiable {
    public var id: String { self }
}

#Preview {
    ContentView()
}
