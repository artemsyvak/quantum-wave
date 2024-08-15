import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:audio_streamer/audio_streamer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quantum_wave/wave_painter.dart';

import 'fft.dart';

void main() => runApp(new AudioStreamingApp());

class AudioStreamingApp extends StatefulWidget {
  @override
  AudioStreamingAppState createState() => AudioStreamingAppState();
}

class AudioStreamingAppState extends State<AudioStreamingApp> {
  int? sampleRate;
  bool isRecording = false;
  List<double> audio = [];
  List<double>? latestBuffer;
  List<double> samples = [];
  double? recordingTime;
  StreamSubscription<List<double>>? audioSubscription;
  Map<String, double> guitarNotes = {
    'E4': 329.63,
    'A4': 440.00,
    'D5': 587.33,
    'G5': 783.99,
    'B5': 987.77,
    'E6': 1318.51,
  };

  /// Check if microphone permission is granted.
  Future<bool> checkPermission() async => await Permission.microphone.isGranted;

  /// Request the microphone permission.
  Future<void> requestPermission() async =>
      await Permission.microphone.request();

  Timer? _throttleTimer;

  // Call-back on audio data.
  void onAudio(List<double> buffer) async {
    FFT fft = FFT();
    List<Complex> result =
        fft.fft(buffer.map((value) => Complex(value, 0.0)).toList());

    // double samplingRate = 44100.0; // Adjust this according to your setup
    double samplingRate = (await AudioStreamer().actualSampleRate) + .0;  // Adjust this according to your setup
    int N = result.length;

    // Find the frequency with the maximum magnitude
    double maxMagnitude = 0.0;
    int maxIndex = 0;

    for (int i = 0; i < N ~/ 2; i++) {
      double magnitude = result[i].magnitude();
      if (magnitude > maxMagnitude) {
        maxMagnitude = magnitude;
        maxIndex = i;
      }
    }

    double dominantFrequency = maxIndex * samplingRate / N;

    // Find the closest guitar note
    String closestNote = '';
    double minDifference = double.infinity;

    guitarNotes.forEach((note, frequency) {
      double difference = (frequency - dominantFrequency).abs();
      if (difference < minDifference) {
        minDifference = difference;
        closestNote = note;
      }
    });

    print('Dominant Frequency: $dominantFrequency Hz');
    print('Closest Guitar Note: $closestNote');

    if (_throttleTimer != null && _throttleTimer!.isActive) {
      return;
    }

    _throttleTimer = Timer(Duration(microseconds: 10), () {
      int chunkSize = 256;
      for (int i = 0; i < buffer.length; i += chunkSize) {
        List<double> chunk = buffer.sublist(
            i, i + chunkSize > buffer.length ? buffer.length : i + chunkSize);

        double minValue = chunk.reduce(min);
        double maxValue = chunk.reduce(max);

        setState(() {
          latestBuffer = chunk;
          samples = latestBuffer!
              .map((value) => (value - minValue) / (maxValue - minValue))
              .toList();
        });
      }
    });
  }

  /// Call-back on error.
  void handleError(Object error) {
    setState(() => isRecording = false);
    print(error);
  }

  /// Start audio sampling.
  void start() async {
    // Check permission to use the microphone.
    //
    // Remember to update the AndroidManifest file (Android) and the
    // Info.plist and pod files (iOS).
    if (!(await checkPermission())) {
      await requestPermission();
    }

    // Set the sampling rate - works only on Android.
    // AudioStreamer().sampleRate = 22100;

    // Start listening to the audio stream.
    audioSubscription =
        AudioStreamer().audioStream.listen(onAudio, onError: handleError);

    setState(() => isRecording = true);
  }

  /// Stop audio sampling.
  void stop() async {
    audioSubscription?.cancel();
    setState(() => isRecording = false);
  }

  // utils for pitch detection!!!
  List<double> autocorrelate(List<double> signal) {
    int n = signal.length;
    List<double> autocorrelation = List.filled(n, 0.0);

    for (int lag = 0; lag < n; lag++) {
      double sum = 0.0;
      for (int i = 0; i < n - lag; i++) {
        sum += signal[i] * signal[i + lag];
      }
      autocorrelation[lag] = sum;
    }
    return autocorrelation;
  }

  int findPeak(List<double> autocorrelation) {
    int peakIndex = 0;
    double maxValue = 0.0;

    for (int i = 1; i < autocorrelation.length; i++) {
      if (autocorrelation[i] > maxValue) {
        maxValue = autocorrelation[i];
        peakIndex = i;
      }
    }

    return peakIndex;
  }

  double lagToFrequency(int lag, double sampleRate) {
    if (lag == 0) return 0.0;
    return sampleRate / lag;
  }

  void processAudio(List<double> buffer, double sampleRate) {
    // Apply autocorrelation to the audio buffer
    List<double> autocorrelation = autocorrelate(buffer);

    // Find the peak in the autocorrelation
    int peakLag = findPeak(autocorrelation);

    // Convert lag to frequency
    double frequency = lagToFrequency(peakLag, sampleRate);

    // Map frequency to note
    String note = frequencyToNote(frequency);

    print("Detected frequency: $frequency Hz");
    print("Detected note: $note");
  }

  String frequencyToNote(double frequency) {
    // Implement frequency to note conversion logic
    // This example assumes standard tuning notes
    const tuningFrequencies = {
      "E2": 82.41,
      "A2": 110.00,
      "D3": 146.83,
      "G3": 196.00,
      "B3": 246.94,
      "E4": 329.63
    };

    String closestNote = "Unknown";
    double closestDiff = double.infinity;

    tuningFrequencies.forEach((note, freq) {
      double diff = (frequency - freq).abs();
      if (diff < closestDiff) {
        closestDiff = diff;
        closestNote = note;
      }
    });

    return closestNote;
  }

  List<double> applyHammingWindow(List<double> signal) {
    int n = signal.length;
    List<double> windowedSignal = List.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      windowedSignal[i] = signal[i] * (0.54 - 0.46 * cos(2 * pi * i / (n - 1)));
    }
    return windowedSignal;
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          body: Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                Container(
                    margin: const EdgeInsets.all(25),
                    child: Column(children: [
                      Container(
                        margin: const EdgeInsets.only(top: 20),
                        child: Text(isRecording ? "Mic: ON" : "Mic: OFF",
                            style: const TextStyle(
                                fontSize: 25, color: Colors.indigoAccent)),
                      ),
                      const Text(''),
                      Text('Max amp: ${latestBuffer?.reduce(max)}'),
                      Text('Min amp: ${latestBuffer?.reduce(min)}'),
                      Text(
                          '${recordingTime?.toStringAsFixed(2)} seconds recorded.'),
                    ])),
                Container(
                    margin: const EdgeInsets.all(25),
                    child: WaveAnimation(
                      samples: samples,
                    )),
                // child: WaveAnimation()),
              ])),
          floatingActionButton: FloatingActionButton(
            backgroundColor: isRecording
                ? Colors.deepOrangeAccent[700]
                : Colors.deepPurple[600],
            onPressed: isRecording ? stop : start,
            child: isRecording ? const Icon(Icons.stop) : const Icon(Icons.mic),
          ),
        ),
      );
}
