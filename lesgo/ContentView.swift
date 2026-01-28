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
                                .font(.custom("Doto-Bold", size: 24))
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
                    ZStack(alignment: .leading) {
                        // Background (Parent Box)
                        RoundedRectangle(cornerRadius: speechRecognizer.isRecording ? 30 : 60)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                            .frame(maxWidth: speechRecognizer.isRecording ? .infinity : 150)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: speechRecognizer.isRecording)
                        
                        // Content Container
                        HStack(spacing: 16) {
                            MicButton(isRecording: speechRecognizer.isRecording) {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)) {
                                    if speechRecognizer.isRecording {
                                        speechRecognizer.stopTranscribing()
                                        suggestionProgress = 0
                                        hasTriggeredSuggestion = false
                                        showConfirmedText = false
                                    } else {
                                        speechRecognizer.startTranscribing()
                                    }
                                }
                            }
                            
                            if speechRecognizer.isRecording {
                                // Container for the Suggestion Card with push-up transition
                                ZStack {
                                    if showConfirmedText {
                                        suggestionCardView(text: "Status Set: In a meeting", isConfirmed: true)
                                            .id("confirmed")
                                            .transition(.asymmetric(
                                                insertion: .offset(y: 100).combined(with: .opacity).combined(with: .scale(scale: 0.9)),
                                                removal: .offset(y: -100).combined(with: .opacity)
                                            ))
                                    } else if hasTriggeredSuggestion {
                                        suggestionCardView(text: "Suggested: in a meeting", isConfirmed: false)
                                            .id("meeting")
                                            .transition(.asymmetric(
                                                insertion: .offset(y: 100).combined(with: .opacity).combined(with: .scale(scale: 0.9)),
                                                removal: .offset(y: -100).combined(with: .opacity)
                                            ))
                                    } else {
                                        suggestionCardView(text: "Suggested on your gibberish", isConfirmed: false)
                                            .id("loading")
                                            .transition(.asymmetric(
                                                insertion: .offset(y: 100).combined(with: .opacity).combined(with: .scale(scale: 0.9)),
                                                removal: .offset(y: -100).combined(with: .opacity)
                                            ))
                                    }
                                }
                                .animation(.spring(response: 0.6, dampingFraction: 0.85), value: hasTriggeredSuggestion)
                                .animation(.spring(response: 0.6, dampingFraction: 0.85), value: showConfirmedText)
                            }
                        }
                        .padding(speechRecognizer.isRecording ? 16 : 0)
                        .frame(maxWidth: speechRecognizer.isRecording ? .infinity : 150)
                        .clipped() // Parent box clips the sliding cards
                    }
                    .frame(height: 150)
                    .padding(.horizontal, 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: speechRecognizer.isRecording)
                }
                .frame(height: 200)
                .padding(.bottom, 60)
            }
        }
        .onChange(of: speechRecognizer.transcript) { newTranscript in
            let keyword = "in a meeting"
            if newTranscript.localizedCaseInsensitiveContains(keyword) {
                if !hasTriggeredSuggestion {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        hasTriggeredSuggestion = true
                        suggestionProgress = 0
                    }
                    // Start Timer
                    withAnimation(.linear(duration: 2.0)) {
                        suggestionProgress = 1.0
                    }
                    
                    // Trigger Delight after timer
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showConfirmedText = true
                        }
                    }
                }
            }
        }
        .alert(isPresented: Binding<Bool>(
            get: { speechRecognizer.errorMessage != nil },
            set: { _ in speechRecognizer.errorMessage = nil }
        )) {
            Alert(title: Text("Error"), message: Text(speechRecognizer.errorMessage ?? ""), dismissButton: .default(Text("OK")))
        }
    }
    
    // Extracted view for the suggestion card to maintain consistency and simplify transitions
    @ViewBuilder
    private func suggestionCardView(text: String, isConfirmed: Bool) -> some View {
        VStack {
            Text(text)
                .font(.system(.headline, design: .default))
                .fontWeight(isConfirmed ? .black : .bold)
                .foregroundColor(isConfirmed ? .indigo : .black)
                .lineLimit(1)
                .contentTransition(.interpolate)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 30)
        .frame(maxWidth: .infinity)
        .background(
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.black.opacity(0.1), lineWidth: 1.5)
                    .background(Color.white.cornerRadius(20))
                
                // Timer Progress Overlay inside the card (only for matching state)
                if hasTriggeredSuggestion && !showConfirmedText && text.contains("meeting") {
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.indigo.opacity(0.15))
                            .frame(width: geometry.size.width * suggestionProgress)
                    }
                }
            }
        )
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
                    .font(.custom("Doto-Bold", size: 22))
                    .foregroundColor(.black.opacity(0.9))
            }
            
            // Append the MATCHED keyword (preserve original case from text, but style it)
            let match = text[range]
            combinedText = combinedText + Text(String(match))
                .font(.custom("Doto-Bold", size: 22))
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
                .font(.custom("Doto-Bold", size: 22))
                .foregroundColor(.black.opacity(0.9))
        }
        
        return combinedText
    }
}

struct MicButton: View {
    let isRecording: Bool
    let action: () -> Void
    
    var body: some View {
        ZStack {
            // 1. Stop Icon (Visible when recording)
            Image(systemName: "stop.circle.fill")
                .font(.system(size: 30))
                .blur(radius: isRecording ? 0 : 10)
                .opacity(isRecording ? 1 : 0)
                .scaleEffect(isRecording ? 1 : 0.7)
            
            // 2. Mic Icon (Visible when NOT recording)
            Image(systemName: "mic.fill")
                .font(.system(size: 30))
                .blur(radius: isRecording ? 10 : 0)
                .opacity(isRecording ? 0 : 1)
                .scaleEffect(isRecording ? 0.5 : 1)
        }
        .frame(width: 30, height: 30) // Fixed frame for icons
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
        // Apply animation at the very end of the button view
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isRecording) 
        .contentShape(Circle())
        .onTapGesture {
            action()
        }
    }
}

#Preview {
    ContentView()
}
