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
    @Namespace private var animation // For smooth transitions
    
    var body: some View {
        ZStack {
            // Background - Metallic Silver Casing
            Color(white: 0.9)
                .ignoresSafeArea()
            
            VStack {
                // Speech Text Container - Retro LCD Screen
                VStack(alignment: .leading) {
                    ScrollView {
                        if speechRecognizer.transcript.isEmpty {
                            Text("Tap the mic and start speaking...")
                                .font(.system(.title2, design: .monospaced)) // Monospaced for retro feel
                                .fontWeight(.medium)
                                .foregroundColor(.black.opacity(0.6))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text(speechRecognizer.transcript)
                                .font(.system(.title2, design: .monospaced))
                                .fontWeight(.medium)
                                .foregroundColor(.black.opacity(0.9))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(red: 0.75, green: 0.85, blue: 0.75)) // Retro Greenish LCD
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.black, lineWidth: 3) // Thinner dark border
                        )
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2) // Inner depth simulation
                )
                .padding(.horizontal, 20)
                .padding(.top, 60)
 
                Spacer()
                
                // Controls Area - Dynamic Widget
                VStack {
                    // Single Adaptive Widget
                    ZStack(alignment: speechRecognizer.isRecording ? .leading : .center) {
                        // Background
                        RoundedRectangle(cornerRadius: speechRecognizer.isRecording ? 30 : 60)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                            .frame(maxWidth: speechRecognizer.isRecording ? .infinity : 200)
                            .frame(height: speechRecognizer.isRecording ? 120 : 200)
                        
                        // Content
                        HStack(spacing: 20) {
                            MicButton(isRecording: speechRecognizer.isRecording) {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0)) {
                                    if speechRecognizer.isRecording {
                                        speechRecognizer.stopTranscribing()
                                    } else {
                                        speechRecognizer.startTranscribing()
                                    }
                                }
                            }
                            // Important to trigger layout changes for the button position
                            .matchedGeometryEffect(id: "mic", in: animation)
                            
                            if speechRecognizer.isRecording {
                                Text("Suggested on your gibberish")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundColor(.black.opacity(0.8))
                                    .transition(.move(edge: .trailing).combined(with: .opacity))
                                    .lineLimit(1)
                            }
                        }
                        .padding(speechRecognizer.isRecording ? 20 : 0)
                    }
                    .padding(.horizontal, 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0), value: speechRecognizer.isRecording)
                }
                .padding(.bottom, 60)
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

struct MicButton: View {
    let isRecording: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if isRecording {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 30))
                        .transition(.opacity.animation(.easeInOut(duration: 0.1)).combined(with: .scale(scale: 0.9)))
                } else {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 30))
                        .transition(.opacity.animation(.easeInOut(duration: 0.1)).combined(with: .scale(scale: 0.9)))
                }
            }
            .foregroundColor(.white)
            .padding(24)
            .background(
                Circle()
                    .fill(
                        isRecording ?
                        AnyShapeStyle(
                            LinearGradient(colors: [.indigo, .purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                        ) :
                        AnyShapeStyle(Color.blue)
                    )
                    .shadow(color: (isRecording ? Color.purple : Color.blue).opacity(0.5), radius: 10, x: 0, y: 5)
            )
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
