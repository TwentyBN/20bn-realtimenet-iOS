import UIKit
import VideoToolbox

protocol WorkoutModelDelegate {
    func showDebugImage(_ resizedPixelBuffer: CVPixelBuffer, transform:CGAffineTransform)
    func showPrediction(label: String, score: String)
}

protocol WorkoutPreviewDelegate: AnyObject {
    func cameraPermissionManager()
}

class ViewController: UIViewController, WorkoutModelDelegate {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var score: UILabel!
    let model = InferenceModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        model.delegate = self
        cameraPermissionManager()
        model.startInference()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        model.frameExtractor.stop()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if model.inferenceStarted {
            model.frameExtractor.start()
        }
    }
    
    
    private func navigateToCameraPermission() {
        guard let cameraPermissionVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "cameraTurnedOffViewController") as? CameraTurnedOffViewController else {
            return
        }
        navigationController?.pushViewController(cameraPermissionVC, animated: true)
        // needed in order to prevent to be stuck if dismiss this cameraPermission
    }
    
    func showDebugImage(_ resizedPixelBuffer: CVPixelBuffer, transform:CGAffineTransform) {
        DispatchQueue.main.async {
            var debugImage: CGImage?
            let img = UIImage.init(ciImage: CIImage(cvPixelBuffer: resizedPixelBuffer), scale:1, orientation:UIImage.Orientation.upMirrored)
            VTCreateCGImageFromCVPixelBuffer(resizedPixelBuffer, options: nil, imageOut: &debugImage)
            self.imageView.image = img
            // flip the image
            self.imageView.transform = transform
        }
    }
    
    func showPrediction(label: String, score: String) {
        DispatchQueue.main.async {
            self.label.text = label
            self.score.text = score
        }
    }
}

extension ViewController: WorkoutPreviewDelegate {
    func cameraPermissionManager() {
        // case to show tutorial or camera permission
        switch self.model.cameraPermission {
        case .authorized:
            self.model.setUpCamera()
            self.model.startInference()
        case .notDetermined:
            self.model.requestCameraAccess { granted in
                DispatchQueue.main.sync {
                    if granted {
                        self.model.setUpCamera()
                        self.model.startInference()
                    } else {
                        self.navigationController?.setNavigationBarHidden(false, animated: false)
                        self.navigateToCameraPermission()
                    }
                }
            }
        default:
            self.navigationController?.setNavigationBarHidden(false, animated: false)
            navigateToCameraPermission()
        }
    }
}



