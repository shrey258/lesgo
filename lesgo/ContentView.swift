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
                
                // Controls Area - Click Wheel Simulation
                ZStack {
                    // White Click Wheel
                    Circle()
                        .fill(Color.white)
                        .frame(width: 250, height: 250)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    // Click Wheel Labels (Static for aesthetic)
                    VStack {
                        Text("MENU")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.gray)
                            .offset(y: -80)
                    }
                    HStack {
                        Image(systemName: "backward.end.alt.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .offset(x: -80)
                        Spacer()
                        Image(systemName: "forward.end.alt.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .offset(x: 80)
                    }
                    .frame(width: 250)
                    
                    VStack {
                        Image(systemName: "playpause.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .offset(y: 80)
                    }

                    // Mic Button - Center Button
                    Button(action: {
                        if speechRecognizer.isRecording {
                            speechRecognizer.stopTranscribing()
                        } else {
                            speechRecognizer.startTranscribing()
                        }
                    }) {
                        Image(systemName: speechRecognizer.isRecording ? "stop.circle.fill" : "mic.fill")
                            .font(.system(size: 30))
                            .contentTransition(.symbolEffect(.replace)) // Smooth icon transition
                            .foregroundColor(.white)
                            .padding(24)
                            .background(
                                Circle()
                                    .fill(Color.blue)
                                    .shadow(color: Color.blue.opacity(0.5), radius: 10, x: 0, y: 5)
                            )
                            // Simple pulsing effect when recording
                            .animation(speechRecognizer.isRecording ? Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default, value: speechRecognizer.isRecording)
                    }
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

// Helper to make String conform to Identifiable for Alert item
extension String: Identifiable {
    public var id: String { self }
}

#Preview {
    ContentView()
}
