//
//  ViewController.swift
//  Camara
//
//  Created by Pedro Alejandro on 11/24/20.
// simple code to make the camara appear and predict what is in the camaras frame
//

import UIKit
import AVKit
import Vision
import AVFoundation

//hand types
enum HandType {
    case none
    case OpenHand
    case Fist
}

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    //imageview variable
    @IBOutlet weak var HandImageView: UIImageView!
    var audioPlayer = AVAudioPlayer()
    
    //making the label to show  the data
    
    let identifierLabel: UILabel = {
        let label = UILabel()
//        label.backgroundColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.white
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //MARK: - Init the audio file
                    do{
                        audioPlayer = try AVAudioPlayer(contentsOf: URL.init(fileURLWithPath: Bundle.main.path(forResource: "Song", ofType: "mp3")!))
                    }
                    catch{
                        print(error)
                    }
                audioPlayer.prepareToPlay()
        
        SettingMyCamara()
        //call the stupid function
        setupIdentifierConfidenceLabel()
    }
    
        

    //function to capture output
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        print("Camara capture a frame", Date())
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else{return}
        
        
      
        
        //MARK: - My Core ML Model
        guard let model = try? VNCoreMLModel(for: MyIHandClassifier_1().model) else{return}
        let request = VNCoreMLRequest(model: model) { (FinishedReq, err) in
            
            
            guard let result = FinishedReq.results as? [VNClassificationObservation] else {return}
            guard let observation = result.first else {return}
//            print(observation.identifier, observation.confidence)
            DispatchQueue.main.async {
//                self.identifierLabel.text = "\(observation.identifier) \(observation.confidence * 100)"
                self.identifierLabel.text = "[\(observation.identifier)]"
            }
            
            //MARK: - Hand types Sets
            let bufferSize = 5
            var commandBuffer = [HandType]()
            var currentComand: HandType = .none{
                didSet{
                    commandBuffer.append(currentComand)
                    if commandBuffer.count == bufferSize{
                        if commandBuffer.filter({$0 == currentComand}).count == bufferSize{
                            self.ShowAndSendCommand(currentComand)
                        }
                        commandBuffer.removeAll()
                    }
                }
            }
            
            
            switch observation.identifier {
            case "None":
                currentComand = .none
                self.ShowAndSendCommand(.none)
                
                
            case "Open Hand":
                currentComand = .OpenHand
                self.ShowAndSendCommand(.OpenHand)
                
            
            case "Fist":
                currentComand = .Fist
                self.ShowAndSendCommand(.Fist)
                
            default:
                currentComand = .none
            }
        }
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
    
    
    func ShowAndSendCommand(_ command: HandType){
        DispatchQueue.main.async {
            
            if command == .OpenHand{
              
                self.HandImageView.image = UIImage(named: "OpenHand")
                self.view.addSubview(self.HandImageView)
                //calling the function addMusic returning the audio and a bool
                self.AddMusic(audio: self.audioPlayer, bool: true)
                
            }
            
            else if command == .Fist {
                //TODO: function to pause
              
                self.HandImageView.image = UIImage(named: "fist")
                self.view.addSubview(self.HandImageView)
                //calling the function addMusic returning the audio and a bool
                self.AddMusic(audio: self.audioPlayer, bool: false)

            }
            
            else {
                self.HandImageView.image = nil
                
            }
        }
    }
    
    
    func SettingMyCamara() {
        
        //start the session so we can start recording data
        let captureSession = AVCaptureSession()
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input  = try? AVCaptureDeviceInput(device: captureDevice) else {return}
        captureSession.addInput(input)
        captureSession.startRunning()
        
        //to show the camara
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        //get the output, what the camara is seeing
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "Video"))
        captureSession.addOutput(dataOutput)
        
        
    }
    
    
    
    //set the label in the view, adding the contraints manually without any storyboard
     func setupIdentifierConfidenceLabel() {
        view.addSubview(identifierLabel)
        identifierLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -32).isActive = true
        identifierLabel.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        identifierLabel.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        identifierLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    
    func AddMusic(audio: AVAudioPlayer,bool: Bool) {
        
        if bool == true{
            audio.play()
        }
        
        if bool == false{
            if audio.isPlaying{
            audio.pause()
            }
        }
    }
}


