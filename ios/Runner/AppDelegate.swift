import Flutter
import UIKit
import Vision

public class OcrPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.navidzamankhan.theshelf/ocr", binaryMessenger: registrar.messenger())
    let instance = OcrPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "recognizeText" {
      guard let args = call.arguments as? [String: Any],
            let imagePath = args["imagePath"] as? String,
            let image = UIImage(contentsOfFile: imagePath),
            let cgImage = image.cgImage else {
        result(FlutterError(code: "INVALID_ARGS", message: "Invalid image path", details: nil))
        return
      }
      
      let request = VNRecognizeTextRequest { (req, err) in
        if let err = err {
          DispatchQueue.main.async {
            result(FlutterError(code: "OCR_ERROR", message: err.localizedDescription, details: nil))
          }
          return
        }
        guard let observations = req.results as? [VNRecognizedTextObservation] else {
          DispatchQueue.main.async {
            result("")
          }
          return
        }
        let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
        DispatchQueue.main.async {
          result(text)
        }
      }
      request.recognitionLevel = .accurate
      request.usesLanguageCorrection = true
      
      DispatchQueue.global(qos: .userInitiated).async {
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
          try handler.perform([request])
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(code: "EXEC_ERROR", message: error.localizedDescription, details: nil))
          }
        }
      }
    } else {
      result(FlutterMethodNotImplemented)
    }
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    OcrPlugin.register(with: self.registrar(forPlugin: "OcrPlugin")!)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
