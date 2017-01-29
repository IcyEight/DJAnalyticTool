//
//  ViewController.swift
//  DJAnalytics
//
//  Created by Brandon Morton on 1/28/17.
//  Copyright © 2017 App Lab. All rights reserved.
//

import UIKit
import AVFoundation
import Foundation
import SwiftyJSON

class ViewController: UIViewController {

    
    @IBOutlet weak var listenBtn: UIButton!                 // Listen button
    var recordingTime = 8                                   // Recording time in seconds
    var recording = false                                   // Whether app is recording
    var audioBuffer = [Float]()                             // Holds audio samples
    let audioEngine  = AVAudioEngine()                      // Audio engine
    private let kSamplesPerBuffer: AVAudioFrameCount = 2048 // Size of samples captured by tap
    
    // audio format of input from mic
    private let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2)

    var timer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        view.backgroundColor = UIColor.black
        listenBtn.layer.cornerRadius = 3.0
        listenBtn.layer.borderWidth = 3.0
        listenBtn.layer.borderColor = UIColor.white.cgColor
        listenBtn.setTitleColor(UIColor.white, for: .normal)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func didPressListenBtn(_ sender: Any) {
        
        if !recording {
            print("Pressed")
            recording = true
            fillBuffer()
//            timer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(fillBuffer), userInfo: nil, repeats: true)
            listenBtn.setTitle("Stop Listening", for: .normal)
        }
        else {
            recording = false
            timer.invalidate()
            listenBtn.setTitle("Start Listening", for: .normal)
        }
    }
    
    func stopRecording() {
        let inputNode = audioEngine.inputNode
        let bus = 0
        inputNode?.removeTap(onBus: bus)
        audioEngine.stop()
    }
    
    func fillBuffer() {
        
        // Get mic input
        let inputNode = audioEngine.inputNode
        let bus = 0
        inputNode!.installTap(onBus: bus, bufferSize: 2048, format: inputNode!.inputFormat(forBus: bus)) {
            (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
            
            // Fill the buffer with samples.
            let channels = UnsafeBufferPointer(start: buffer.floatChannelData, count: Int(buffer.format.channelCount))
            let floats = UnsafeBufferPointer(start: channels[0], count: Int(buffer.frameLength))
            
            if ((self.audioBuffer.count + floats.count) < (self.recordingTime * 44100)) {
                for i in 0..<floats.count {
                    self.audioBuffer.append(floats[i])
                }
            }
            else {
                self.stopRecording()
//                _ = self.saveAudio()
                self.submitData()
            }
        }
        
        // Start audio engine
        audioEngine.prepare()
        do{
            try audioEngine.start()
        }catch{
            
            print("Error")
            
        }
        
    }
    
    func JSONStringify(value: AnyObject, prettyPrinted: Bool = false) -> String {
        let options = prettyPrinted ? JSONSerialization.WritingOptions.prettyPrinted : nil
        if JSONSerialization.isValidJSONObject(value) {
            let data = try! JSONSerialization.data(withJSONObject: value, options: options!)
            
            if let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                return string as String
            }
        }
        return ""
    }
    
    func submitData() {
        
        let myUrl = URL(string: "http://34.198.100.16:3000/catch")
        var request = URLRequest(url:myUrl!)
        request.httpMethod = "POST"// Compose a query string
        
        do {
            let data = ["data": self.audioBuffer] as [String: Any]
            let jsonObj = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            request.httpBody = jsonObj
            request.addValue("application/json",forHTTPHeaderField: "Content-Type")
            request.addValue("application/json",forHTTPHeaderField: "Accept")
        }catch{
            print(error)
        }


        
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            
            if error != nil
            {
                print("error=\(error)")
                return
            }
            
            // You can print out response object
            print("response = \(response)")
        }
        
        task.resume()
        
    }
    
    func saveAudio() -> String{
        
        // Get date and time of first sample in buffer
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy_dd_MM_HH_m_s"
        
        // Create audio buffer
        let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2)
        let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(self.audioBuffer.count))
        
        // Add samples to the buffer
        let leftChannel = audioBuffer.floatChannelData?[0]
        let rightChannel = audioBuffer.floatChannelData?[1]
        for sampleIndex in 0..<self.audioBuffer.count
        {
            leftChannel?[sampleIndex] = self.audioBuffer[sampleIndex]
            rightChannel?[sampleIndex] = self.audioBuffer[sampleIndex]
        }
        
        audioBuffer.frameLength = AVAudioFrameCount(self.audioBuffer.count)
        
        // Create audio file where buffer will be saved
        let DocumentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        
        let result = formatter.string(from: date)
        let fileURL = DocumentDirURL.appendingPathComponent("\(result).m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            let audioFile = try AVAudioFile(forWriting: fileURL, settings: settings)
            try audioFile.write(from: audioBuffer)
        }catch {
            print("Can't save audio file")
        }
        
        return fileURL.path
    }
    
    
}

