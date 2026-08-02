import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async'; // Needed for the timer

class SmartFaceCamera extends StatefulWidget {
  final List<CameraDescription> cameras;
  const SmartFaceCamera({super.key, required this.cameras});

  @override
  _SmartFaceCameraState createState() => _SmartFaceCameraState();
}

class _SmartFaceCameraState extends State<SmartFaceCamera> {
  late CameraController _controller;
  bool _isInitialized = false;
  bool _isRecording = false;
  
  // New State Variables for the Guided Scanner
  int _currentStep = 0;
  double _progress = 0.0;
  Timer? _phaseTimer;

  // The exact instructions the user will see
  final List<String> _instructions = [
    "Position face in the oval",
    "Look straight at the camera...",
    "Slowly turn head to the LEFT...",
    "Now turn head to the RIGHT...",
    "Processing..."
  ];

  @override
  void initState() {
    super.initState();
    // Initialize the front camera (usually index 1)
    _controller = CameraController(widget.cameras[1], ResolutionPreset.high);
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _isInitialized = true;
      });
    });
  }

  // THE UPGRADED GUIDED RECORDING SEQUENCE
  Future<void> _startRecordingSequence() async {
    if (_controller.value.isRecordingVideo) return;

    await _controller.startVideoRecording();
    
    setState(() {
      _isRecording = true;
      _currentStep = 1; // Phase 1: Look Straight
      _progress = 0.33; // 33% complete
    });

    // Each phase gives the user 2.5 seconds to complete the head movement
    const int phaseDurationMs = 2500; 

    _phaseTimer = Timer.periodic(const Duration(milliseconds: phaseDurationMs), (timer) async {
      setState(() {
        _currentStep++;
      });

      if (_currentStep == 2) {
        setState(() => _progress = 0.66); // 66% complete
      } 
      else if (_currentStep == 3) {
        setState(() => _progress = 1.0); // 100% complete
      } 
      else if (_currentStep >= 4) {
        // Sequence Finished. Stop recording and return the video.
        timer.cancel();
        XFile videoFile = await _controller.stopVideoRecording();
        
        setState(() {
          _isRecording = false;
        });
        
        Navigator.pop(context, videoFile.path); 
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _phaseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CameraPreview(_controller),
          ),
          
          ColorFiltered(
            colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcOut),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: 280,
                    height: 380,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(200),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Positioned(
            bottom: 80,
            child: Column(
              children: [
                // Dynamic Instruction Text
                Text(
                  _instructions[_currentStep],
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 20, 
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black, blurRadius: 10)]
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                
                GestureDetector(
                  onTap: _isRecording ? null : _startRecordingSequence,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: CircularProgressIndicator(
                          value: _isRecording ? _progress : 0.0,
                          strokeWidth: 8,
                          // Progress bar turns blue while scanning, green when done
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _progress == 1.0 ? Colors.green : Colors.blueAccent
                          ),
                          backgroundColor: Colors.white24,
                        ),
                      ),
                      Icon(
                        _isRecording ? Icons.face : Icons.camera_alt,
                        color: Colors.white,
                        size: 40,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}