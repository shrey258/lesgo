import Foundation
import Speech
import AVFoundation
import SwiftUI
import Combine

class SpeechRecognizer: ObservableObject {
    @Published var transcript: String = ""
    @Published var isRecording: Bool = false
    @Published var errorMessage: String? = nil
    
    private var audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let recognizer = SFSpeechRecognizer()
    
    init() {
        requestAuthorization()
    }
    
    private func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            // In a real app, you would handle the auth status (authorized, denied, restricted, notDetermined)
            // and update the UI accordingly.
            print("Speech recognition auth status: \(authStatus)")
        }
    }
    
    func startTranscribing() {
        guard !isRecording else { return }
        guard let recognizer = recognizer, recognizer.isAvailable else {
            self.errorMessage = "Speech recognizer is not available."
            return
        }
        
        do {
            // Configure the audio session for the app.
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            let request = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionTask = setupRecognitionTask(request: request) else {
                 self.errorMessage = "Could not setup recognition task."
                 return
            }
            
            self.request = request
            self.task = recognitionTask
            
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            // Check if format is actually valid to prevent crashes
            guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
                self.errorMessage = "Invalid audio format: \(recordingFormat)"
                return
            }
            
            inputNode.removeTap(onBus: 0) // Remove any existing tap safely
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
                self.request?.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            DispatchQueue.main.async {
                self.isRecording = true
                self.errorMessage = nil
            }
        } catch {
            self.errorMessage = "Error configuring audio: \(error.localizedDescription)"
            self.reset()
        }
    }
    
    private func setupRecognitionTask(request: SFSpeechAudioBufferRecognitionRequest) -> SFSpeechRecognitionTask? {
        request.shouldReportPartialResults = true
        
        return recognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                DispatchQueue.main.async {
                    self.transcript = result.bestTranscription.formattedString
                }
            }
            
            if error != nil || (result?.isFinal ?? false) {
                self.stopTranscribing()
            }
        }
    }
    
    func stopTranscribing() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        
        request = nil
        task = nil
        
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }
    
    func reset() {
        stopTranscribing()
        DispatchQueue.main.async {
            self.transcript = ""
            self.errorMessage = nil
        }
    }
}
