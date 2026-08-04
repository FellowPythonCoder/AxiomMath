import Foundation
import Combine
import AVFoundation

enum VoicePhrases {
    static let questionIntros: [String] = [
        "Take your time. What is",
        "Here's your next question:",
        "Whenever you're ready, what is",
        "Let's try this one:",
        "No rush — what is",
        "Next up:",
        "See what you think of this:",
        "Here's one for you:"
    ]

    static let correctResponses: [String] = [
        "That's right. Well done.",
        "Nicely done — that's correct.",
        "You've got it. Great work.",
        "That's correct.",
        "Right on. Good thinking."
    ]

    static let wrongResponses: [String] = [
        "Not quite — the answer was",
        "Close. The right answer is",
        "Good try. It was actually",
        "Not this time. It's",
        "Almost — the correct answer is"
    ]

    static func randomIntro(question: String) -> String {
        let intro = questionIntros.randomElement() ?? "What is"
        return "\(intro) \(question)?"
    }

    static func randomCorrect(answer: String) -> String {
        let prefix = correctResponses.randomElement() ?? "Correct!"
        return "\(prefix) The answer is \(answer)."
    }

    static func randomWrong(answer: String) -> String {
        let prefix = wrongResponses.randomElement() ?? "The answer was"
        return "\(prefix) \(answer)."
    }
}

class ElevenLabsManager: ObservableObject {
    static let shared = ElevenLabsManager()
    private var audioPlayer: AVAudioPlayer?
    private let synthesizer = AVSpeechSynthesizer()

    private let apiKey: String = Bundle.main.object(forInfoDictionaryKey: "ElevenLabsAPIKey") as? String ?? ""
    private let voiceID = "EXAVITQu4vr4xnSDxMaL"

    private init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {}
    }

    func speak(_ text: String) {
        audioPlayer?.stop()
        synthesizer.stopSpeaking(at: .immediate)

        let cleanedText = cleanForSpeech(text)
        guard !apiKey.isEmpty,
              let url = URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(voiceID)") else {
            fallbackToAppleVoice(text: cleanedText)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("audio/mpeg", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15

        let body: [String: Any] = [
            "text": cleanedText,
            "model_id": "eleven_turbo_v2_5",
            "voice_settings": [
                "stability": 0.75,
                "similarity_boost": 0.85,
                "style": 0.12,
                "use_speaker_boost": true
            ]
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            fallbackToAppleVoice(text: cleanedText)
            return
        }
        request.httpBody = httpBody

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data, error == nil else {
                self.fallbackToAppleVoice(text: cleanedText)
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
                self.fallbackToAppleVoice(text: cleanedText)
                return
            }
            if let jsonString = String(data: data, encoding: .utf8), jsonString.hasPrefix("{") {
                self.fallbackToAppleVoice(text: cleanedText)
                return
            }
            DispatchQueue.main.async {
                do {
                    self.audioPlayer = try AVAudioPlayer(data: data)
                    self.audioPlayer?.volume = 1.0
                    self.audioPlayer?.prepareToPlay()
                    self.audioPlayer?.play()
                } catch {
                    self.fallbackToAppleVoice(text: cleanedText)
                }
            }
        }.resume()
    }

    private func cleanForSpeech(_ text: String) -> String {
        var s = text
        s = s.replacingOccurrences(of: "*", with: " times ")
        s = s.replacingOccurrences(of: " x ", with: " times ")
        s = s.replacingOccurrences(of: "×", with: " times ")
        s = s.replacingOccurrences(of: "+", with: " plus ")
        s = s.replacingOccurrences(of: "−", with: " minus ")
        s = s.replacingOccurrences(of: "-", with: " minus ")
        s = s.replacingOccurrences(of: "/", with: " divided by ")
        s = s.replacingOccurrences(of: "÷", with: " divided by ")
        s = s.replacingOccurrences(of: "=", with: " equals ")
        s = s.replacingOccurrences(of: "^", with: " to the power of ")
        return s
    }

    private func fallbackToAppleVoice(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        let preferredIDs = [
            "com.apple.voice.premium.en-US.Zoe",
            "com.apple.voice.premium.en-US.Ava",
            "com.apple.voice.enhanced.en-US.Samantha",
            "com.apple.voice.compact.en-US.Samantha"
        ]
        let voices = AVSpeechSynthesisVoice.speechVoices()
        utterance.voice = preferredIDs.compactMap { id in voices.first(where: { $0.identifier == id }) }.first
            ?? voices.first(where: { $0.quality == .enhanced && $0.language.hasPrefix("en") })
            ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.42
        utterance.pitchMultiplier = 0.96
        utterance.preUtteranceDelay = 0.12
        utterance.postUtteranceDelay = 0.08
        DispatchQueue.main.async {
            self.synthesizer.speak(utterance)
        }
    }

    func stop() {
        audioPlayer?.stop()
        synthesizer.stopSpeaking(at: .immediate)
    }
}
