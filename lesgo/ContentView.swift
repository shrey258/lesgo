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
    @State private var isGoingForward = true // Tracks animation direction
    @State private var suggestionTimerId = 0 // Used to invalidate pending timers
    @State private var lastKeywordLength = 0 // Tracks transcript length when keyword was processed
    
    // Apple Intelligence Glow Animation
    @State private var highlightPhase: CGFloat = 0
    @State private var glowPulse: CGFloat = 0.6
    private let siriColors: [Color] = [
        Color(red: 0.64, green: 0.48, blue: 1.0), // #A47BFF
        Color(red: 0.9, green: 0.32, blue: 1.0),  // #E552FF
        Color(red: 0.31, green: 0.65, blue: 1.0), // #50A7FF
        Color(red: 1.0, green: 0.7, blue: 0.28), // #FFB347
        Color(red: 1.0, green: 0.4, blue: 0.47)  // #FF6778
    ]
    
    var body: some View {
        ZStack {
            // Background - Brushed Aluminum Casing
            LinearGradient(
                colors: [
                    Color(red: 0.88, green: 0.90, blue: 0.93), // Cool blue-gray at top
                    Color(red: 0.90, green: 0.88, blue: 0.87), // Neutral mid
                    Color(red: 0.92, green: 0.86, blue: 0.84)  // Warm rose-gold at bottom
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Circular Brushed Metal Texture (Radial highlight)
            RadialGradient(
                colors: [
                    Color.white.opacity(0.2),
                    Color.clear,
                    Color.black.opacity(0.03)
                ],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            // Option B: Ambient Light Orbs (Bokeh effect)
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 150, height: 150)
                    .blur(radius: 40)
                    .offset(x: -80, y: -200)
                
                Circle()
                    .fill(Color(red: 1.0, green: 0.9, blue: 0.85).opacity(0.2))
                    .frame(width: 100, height: 100)
                    .blur(radius: 35)
                    .offset(x: 120, y: -100)
                
                Circle()
                    .fill(Color(red: 0.9, green: 0.85, blue: 1.0).opacity(0.15))
                    .frame(width: 120, height: 120)
                    .blur(radius: 38)
                    .offset(x: -60, y: 300)
            }
            .drawingGroup() // GPU rasterization for blur performance
            .ignoresSafeArea()
            .allowsHitTesting(false)
            
            // Subtle Noise/Grain Texture
            Canvas { context, size in
                for _ in 0..<3000 {
                    let x = CGFloat.random(in: 0...size.width)
                    let y = CGFloat.random(in: 0...size.height)
                    let opacity = Double.random(in: 0.02...0.06)
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: 1.5, height: 1.5)),
                        with: .color(Color.black.opacity(opacity))
                    )
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            
            // Option C: Dynamic Recording Glow (emanates from mic button area)
            if speechRecognizer.isRecording {
                RadialGradient(
                    colors: [
                        Color(red: 1.0, green: 0.6, blue: 0.5).opacity(0.15 * glowPulse),
                        Color(red: 1.0, green: 0.7, blue: 0.6).opacity(0.08 * glowPulse),
                        Color.clear
                    ],
                    center: .init(x: 0.5, y: 0.85), // Near mic button
                    startRadius: 20,
                    endRadius: 300
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
            
            // Edge Highlighting - Left/Top lighter edge
            HStack {
                LinearGradient(
                    colors: [Color.white.opacity(0.4), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 20)
                Spacer()
            }
            .ignoresSafeArea()
            
            VStack {
                LinearGradient(
                    colors: [Color.white.opacity(0.3), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 40)
                Spacer()
            }
            .ignoresSafeArea()
            
            // Edge Highlighting - Right/Bottom darker edge
            HStack {
                Spacer()
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.08)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 30)
            }
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 60)
            }
            .ignoresSafeArea()
            
            // Apple Intelligence Scrim (appears when suggestion is active)
            if hasTriggeredSuggestion && !showConfirmedText {
                ZStack {
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(
                            AngularGradient(
                                colors: siriColors + siriColors,
                                center: .center,
                                angle: .degrees(highlightPhase * 360)
                            ),
                            lineWidth: 6
                        )
                        .blur(radius: 8)
                    
                    // Inner sharper edge
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(
                            AngularGradient(
                                colors: siriColors + siriColors,
                                center: .center,
                                angle: .degrees(highlightPhase * 360)
                            ),
                            lineWidth: 3
                        )
                        .blur(radius: 3)
                }
                .drawingGroup() // GPU rasterization for blur performance
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
            
            VStack {
                // Speech Text Container - Retro LCD Screen
                VStack(alignment: .leading) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading) {
                                if speechRecognizer.transcript.isEmpty {
                                    Text("Tap the mic and start speaking...")
                                        .font(.custom("Doto-Bold", size: 40))
                                        .foregroundColor(.black.opacity(0.6))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                } else {
                                    getFormattedTranscript(for: speechRecognizer.transcript)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .contentTransition(.interpolate) // Wave-like interpolation
                                        .animation(.default, value: speechRecognizer.transcript)
                                }
                                
                                // Anchor for auto-scrolling
                                Color.clear
                                    .frame(height: 1)
                                    .id("bottom")
                            }
                        }
                        .onChange(of: speechRecognizer.transcript) { _ in
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
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
                        // Background (Parent Box) - Recessed Metallic Bezel
                        RoundedRectangle(cornerRadius: speechRecognizer.isRecording ? 30 : 60)
                            .fill(
                                LinearGradient(
                                    colors: [Color(white: 0.22), Color(white: 0.18)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: speechRecognizer.isRecording ? 30 : 60)
                                    .stroke(Color.black.opacity(0.6), lineWidth: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: speechRecognizer.isRecording ? 28 : 58)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    .padding(2)
                            )
                            .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4) // Outer depth
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
                                                insertion: .offset(y: isGoingForward ? 100 : -100).combined(with: .opacity).combined(with: .scale(scale: 0.9)),
                                                removal: .offset(y: isGoingForward ? -100 : 100).combined(with: .opacity)
                                            ))
                                    } else if hasTriggeredSuggestion {
                                        suggestionCardView(text: "Suggested: in a meeting", isConfirmed: false)
                                            .id("meeting")
                                            .transition(.asymmetric(
                                                insertion: .offset(y: isGoingForward ? 100 : -100).combined(with: .opacity).combined(with: .scale(scale: 0.9)),
                                                removal: .offset(y: isGoingForward ? -100 : 100).combined(with: .opacity)
                                            ))
                                    } else {
                                        suggestionCardView(text: "Suggested on your gibberish", isConfirmed: false)
                                            .id("loading")
                                            .transition(.asymmetric(
                                                insertion: .offset(y: isGoingForward ? 100 : -100).combined(with: .opacity).combined(with: .scale(scale: 0.9)),
                                                removal: .offset(y: isGoingForward ? -100 : 100).combined(with: .opacity)
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
            // Only check for keyword in NEW text (beyond what we already processed)
            let searchRange = newTranscript.count > lastKeywordLength ? 
                String(newTranscript.dropFirst(lastKeywordLength)) : ""
            
            if searchRange.localizedCaseInsensitiveContains(keyword) {
                if !hasTriggeredSuggestion {
                    lastKeywordLength = newTranscript.count // Mark as processed
                    suggestionTimerId += 1 // Increment timer ID
                    let currentTimerId = suggestionTimerId
                    
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        hasTriggeredSuggestion = true
                        suggestionProgress = 0
                    }
                    // Start Timer
                    withAnimation(.linear(duration: 7.0)) {
                        suggestionProgress = 1.0
                    }
                    
                    // Trigger Delight after timer (only if not cancelled)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) {
                        // Check if this timer is still valid (wasn't cancelled)
                        if suggestionTimerId == currentTimerId && hasTriggeredSuggestion {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showConfirmedText = true
                            }
                            
                            // Reset back to Listening after showing confirmation (forward direction)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                isGoingForward = true // Forward direction - comes from bottom
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    hasTriggeredSuggestion = false
                                    showConfirmedText = false
                                    suggestionProgress = 0
                                }
                            }
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
        .onAppear {
            withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                highlightPhase = 1.0
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowPulse = 1.0
            }
        }
    }
    
    // Extracted view for the suggestion card to maintain consistency and simplify transitions
    @ViewBuilder
    func suggestionCardView(text: String, isConfirmed: Bool) -> some View {
        let isListeningState = !isConfirmed && !text.contains("Suggested:")
        
        return HStack(spacing: 12) {
            // Leading Icon
            if isListeningState {
                // Animated waveform for listening state
                HStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(width: 3, height: 8 + CGFloat(index == 1 ? 8 : 4) * glowPulse)
                            .animation(
                                .easeInOut(duration: 0.4)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.15),
                                value: glowPulse
                            )
                    }
                }
                .frame(width: 18, height: 18)
            } else {
                Image(systemName: isConfirmed ? "checkmark.circle.fill" : "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(
                        isConfirmed ?
                        AnyShapeStyle(Color.green) :
                        AnyShapeStyle(
                            LinearGradient(
                                colors: [.purple, .pink, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    )
            }
            
            // Text with hierarchy
            VStack(alignment: .leading, spacing: 2) {
                if isConfirmed {
                    Text("Status Set")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green.opacity(0.8))
                    Text("Meeting with Shrey")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.green)
                } else if text.contains("Suggested:") {
                    Text("Suggested")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    Text("Create a meeting with Shrey?")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("Listening")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                    Text("Speak naturally...")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            Spacer()
            
            // Cancel Button (only for suggestion state, not confirmed)
            if !isConfirmed && text.contains("Suggested:") {
                Button(action: {
                    suggestionTimerId += 1 // Invalidate pending timer
                    lastKeywordLength = speechRecognizer.transcript.count // Mark current keyword as processed
                    isGoingForward = false // Reverse direction for cancel
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        hasTriggeredSuggestion = false
                        suggestionProgress = 0
                    }
                    // Reset direction after animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isGoingForward = true
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(minHeight: 56)
        .frame(maxWidth: .infinity)
        .background(
            ZStack(alignment: .leading) {
                // Frosted glass background
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.12), Color.white.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Apple Intelligence gradient border (for suggestion state)
                if !isConfirmed && text.contains("Suggested:") {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: siriColors,
                                startPoint: .init(x: -0.5 + highlightPhase, y: 0.5),
                                endPoint: .init(x: 0.5 + highlightPhase, y: 0.5)
                            ),
                            lineWidth: 2
                        )
                        .shadow(color: siriColors[0].opacity(0.3), radius: 6)
                        .shadow(color: siriColors[2].opacity(0.3), radius: 3)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.25), Color.white.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                }
                
                // Timer Progress Overlay inside the card (only for matching state)
                if hasTriggeredSuggestion && !showConfirmedText {
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.08))
                            .frame(width: geometry.size.width * suggestionProgress)
                    }
                }
            }
        )
    }
    
    // Helper to format transcript with Apple Intelligence Glow
    func getFormattedTranscript(for text: String) -> some View {
        let keyword = "in a meeting"
        
        return ZStack(alignment: .topLeading) {
            // Layer 1: Base text (Keywords are transparent)
            generateSegmentedText(for: text, keyword: keyword, mode: .base)
                .font(.custom("Doto-Bold", size: 36))
            
            // Layer 2: Glowing keywords (Emissive Light Effect)
            ZStack(alignment: .topLeading) {
                // Secondary glow (aura)
                generateSegmentedText(for: text, keyword: keyword, mode: .glow)
                    .font(.custom("Doto-Bold", size: 36))
                    .blur(radius: 8)
                    .opacity(0.4 * glowPulse)
                
                // Primary glow (core light)
                generateSegmentedText(for: text, keyword: keyword, mode: .glow)
                    .font(.custom("Doto-Bold", size: 36))
                    .blur(radius: 3)
                    .opacity(0.8 * glowPulse)
                
                // Sharp Core (preserving the letters)
                generateSegmentedText(for: text, keyword: keyword, mode: .glow)
                    .font(.custom("Doto-Bold", size: 36))
                    .opacity(glowPulse)
            }
            .drawingGroup() // GPU rasterization for blur performance
        }
    }
    
    enum TextMode { case base, glow }
    
    private func generateSegmentedText(for text: String, keyword: String, mode: TextMode) -> Text {
        var combinedText = Text("")
        var currentIndex = text.startIndex
        
        let siriGradient = LinearGradient(
            colors: siriColors,
            startPoint: .init(x: -0.5 + highlightPhase, y: 0.5),
            endPoint: .init(x: 0.5 + highlightPhase, y: 0.5)
        )
        
        while let range = text.range(of: keyword, options: .caseInsensitive, range: currentIndex..<text.endIndex) {
            // Text BEFORE the match
            let prefix = text[currentIndex..<range.lowerBound]
            if !prefix.isEmpty {
                combinedText = combinedText + Text(String(prefix))
                    .foregroundColor(mode == .base ? .black.opacity(0.9) : .clear)
            }
            
            // The MATCHED keyword
            let match = text[range]
            if mode == .glow {
                combinedText = combinedText + Text(String(match))
                    .foregroundStyle(siriGradient)
            } else {
                combinedText = combinedText + Text(String(match))
                    .foregroundColor(.clear)
            }
            
            currentIndex = range.upperBound
        }
        
        // Text AFTER the last match
        let suffix = text[currentIndex..<text.endIndex]
        if !suffix.isEmpty {
            combinedText = combinedText + Text(String(suffix))
                .foregroundColor(mode == .base ? .black.opacity(0.9) : .clear)
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
            ZStack {
                // Base metallic circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isRecording ? [Color(white: 0.35), Color(white: 0.25)] : [Color(white: 0.4), Color(white: 0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Inner highlight ring (tactile depth)
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.3), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 2
                    )
                    .padding(2)
                
                // Recording indicator glow
                if isRecording {
                    Circle()
                        .stroke(Color.red.opacity(0.6), lineWidth: 3)
                        .blur(radius: 4)
                }
            }
        )
        .shadow(color: .black.opacity(0.5), radius: 6, x: 0, y: 3)
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
