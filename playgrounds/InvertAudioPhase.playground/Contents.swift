import AVFoundation
import Accelerate

let inputUrl = URL(fileURLWithPath: <#input file path#>)
let outputUrl = URL(fileURLWithPath: <#output file path#>)

let input = try! AVAudioFile(forReading: inputUrl, commonFormat: .pcmFormatFloat32, interleaved: false)

guard let inputBuffer = AVAudioPCMBuffer(pcmFormat: input.processingFormat, frameCapacity: AVAudioFrameCount(input.length)),
      let outputBuffer = AVAudioPCMBuffer(pcmFormat: input.processingFormat, frameCapacity: AVAudioFrameCount(input.length)) else {
    fatalError()
}

// read audio data into `inputBuffer`
do {
    try input.read(into: inputBuffer)
} catch {
    print(error.localizedDescription)
}

// audio phase data array()
let inputFloat32ChannelData = inputBuffer.floatChannelData!
let outputFloat32ChannelData = outputBuffer.floatChannelData!

// invert phases
for channel in 0 ..< Int(inputBuffer.format.channelCount) {
    let input: UnsafeMutablePointer<Float32> = inputFloat32ChannelData[channel]
    let output: UnsafeMutablePointer<Float32> = outputFloat32ChannelData[channel]

    var scalar:Float = -1.0
    vDSP_vsmul(input, 1, &scalar, output, 1, vDSP_Length(inputBuffer.frameLength))
}

outputBuffer.frameLength = inputBuffer.frameLength

let settings: [String: Any] = [
    AVFormatIDKey: outputBuffer.format.settings[AVFormatIDKey] ?? kAudioFormatLinearPCM,
    AVNumberOfChannelsKey: outputBuffer.format.settings[AVNumberOfChannelsKey] ?? 2,
    AVSampleRateKey: outputBuffer.format.settings[AVSampleRateKey] ?? 44100,
    AVLinearPCMBitDepthKey: outputBuffer.format.settings[AVLinearPCMBitDepthKey] ?? 16
]

// write output data as `wav`
do {
    let output = try AVAudioFile(forWriting: outputUrl, settings: settings, commonFormat: .pcmFormatFloat32, interleaved: false)
    try output.write(from: outputBuffer)
}
catch {
    print(error.localizedDescription)
}

print("end")
