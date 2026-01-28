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
    
    // Suggestion State
    @State private var suggestionProgress: CGFloat = 0.0
    @State private var hasTriggeredSuggestion = false
    @State private var showConfirmedText = false
    
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
                            getFormattedTranscript(for: speechRecognizer.transcript)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentTransition(.interpolate) // Wave-like interpolation
                                .animation(.default, value: speechRecognizer.transcript)
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
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: speechRecognizer.isRecording ? 30 : 60)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                            
                            // Timer Progress Overlay
                            if speechRecognizer.isRecording && hasTriggeredSuggestion && !showConfirmedText {
                                GeometryReader { geometry in
                                    RoundedRectangle(cornerRadius: 30)
                                        .fill(Color.indigo.opacity(0.2)) // Stronger visual cue
                                        .frame(width: geometry.size.width * suggestionProgress, alignment: .leading) // Left-to-Right
                                        .animation(.linear(duration: 2.0), value: suggestionProgress)
                                }
                                .transition(.opacity) // Fade out smoothly when done
                            }
                        }
                        .frame(maxWidth: speechRecognizer.isRecording ? .infinity : 200)
                        .frame(height: speechRecognizer.isRecording ? 120 : 200)
                        
                        // Content
                        HStack(spacing: 20) {
                            MicButton(isRecording: speechRecognizer.isRecording) {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0)) {
                                    if speechRecognizer.isRecording {
                                        speechRecognizer.stopTranscribing()
                                        // Reset state on stop
                                        suggestionProgress = 0
                                        hasTriggeredSuggestion = false
                                        showConfirmedText = false
                                    } else {
                                        speechRecognizer.startTranscribing()
                                    }
                                }
                            }
                            // Important to trigger layout changes for the button position
                            .matchedGeometryEffect(id: "mic", in: animation)
                            
                            if speechRecognizer.isRecording {
                                Text(hasTriggeredSuggestion ? "Suggested: in a meeting" : "Suggested on your gibberish")
                                    .font(.system(.headline, design: .default)) // Modern System Font
                                    .fontWeight(showConfirmedText ? .black : (hasTriggeredSuggestion ? .bold : .regular))
                                    .foregroundColor(showConfirmedText ? .indigo : (hasTriggeredSuggestion ? .black : .black.opacity(0.8)))
                                    .transition(.move(edge: .trailing).combined(with: .opacity))
                                    .lineLimit(1)
                                    .contentTransition(.interpolate) // Smooth text change
                                    .scaleEffect(showConfirmedText ? 1.1 : 1.0) // Stronger Delight bounce
                                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: showConfirmedText)
                            }
                        }
                        .padding(speechRecognizer.isRecording ? 20 : 0)
                    }
                    .padding(.horizontal, 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0), value: speechRecognizer.isRecording)
                }
                .frame(height: 200) // Fixed height to prevent vertical jumping
                .padding(.bottom, 60)
            }
        }
        .onChange(of: speechRecognizer.transcript) { newTranscript in
            let keyword = "in a meeting"
            if newTranscript.localizedCaseInsensitiveContains(keyword) {
                if !hasTriggeredSuggestion {
                    hasTriggeredSuggestion = true
                    // Start Timer
                    // Ensure we start from 0
                    suggestionProgress = 0
                    withAnimation(.linear(duration: 2.0)) {
                        suggestionProgress = 1.0
                    }
                    
                    // Trigger Delight after timer
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation {
                            showConfirmedText = true
                        }
                    }
                }
            } else {
                // If text is cleared or changed significantly, maybe reset? 
                // For now, keep it simple. If we cleared manually, isRecording check handles reset.
            }
        }
        .alert(isPresented: Binding<Bool>(
            get: { speechRecognizer.errorMessage != nil },
            set: { _ in speechRecognizer.errorMessage = nil }
        )) {
            Alert(title: Text("Error"), message: Text(speechRecognizer.errorMessage ?? ""), dismissButton: .default(Text("OK")))
        }
    }
    
    // Helper to format transcript with keyword highlighting
    func getFormattedTranscript(for text: String) -> Text {
        let keyword = "in a meeting"
        var combinedText = Text("")
        var currentIndex = text.startIndex
        
        // Find all occurrences of the keyword (case-insensitive)
        while let range = text.range(of: keyword, options: .caseInsensitive, range: currentIndex..<text.endIndex) {
            // Append text BEFORE the match
            let prefix = text[currentIndex..<range.lowerBound]
            if !prefix.isEmpty {
                combinedText = combinedText + Text(String(prefix))
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.medium)
                    .foregroundColor(.black.opacity(0.9))
            }
            
            // Append the MATCHED keyword (preserve original case from text, but style it)
            let match = text[range]
            combinedText = combinedText + Text(String(match))
                .font(.system(.title2, design: .default)) // Modern System Font
                .fontWeight(.black) // Heavy/Black weight
                .foregroundStyle(
                    LinearGradient(
                        colors: [.red, .orange, .yellow, .green, .blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            // Move search index forward
            currentIndex = range.upperBound
        }
        
        // Append remaining text AFTER the last match
        let suffix = text[currentIndex..<text.endIndex]
        if !suffix.isEmpty {
            combinedText = combinedText + Text(String(suffix))
                .font(.system(.title2, design: .monospaced))
                .fontWeight(.medium)
                .foregroundColor(.black.opacity(0.9))
        }
        
        return combinedText
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

#Preview {
    ContentView()
}
