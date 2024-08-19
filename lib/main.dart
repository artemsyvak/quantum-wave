import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:audio_streamer/audio_streamer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quantum_wave/wave_painter.dart';

import 'consts/drum_notes.dart';
import 'consts/guitar_notes.dart';
import 'fft.dart';

void main() => runApp(const AudioStreamingApp());

class AudioStreamingApp extends StatefulWidget {
  const AudioStreamingApp({super.key});

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
  String currentGuitarNote = '';
  String currentDrumInstrument = '';
  String currentDrumNote = '';
  double dominantFrequency = 0.0;

  /// Check if microphone permission is granted.
  Future<bool> checkPermission() async => await Permission.microphone.isGranted;

  /// Request the microphone permission.
  Future<void> requestPermission() async =>
      await Permission.microphone.request();

  // Call-back on audio data.
  void onAudio(List<double> buffer) async {
    print('hello');
    print(buffer.length);
     List<double> _generateWaveSamples() {
    // Generate samples based on min/max amplitude
    return List.generate(100, (index) => Random().nextDouble() * 2 - 1);
  }
    
    FFT fft = FFT();
    List<Complex> result =
        fft.fft(buffer.map((value) => Complex(value, 0.0)).toList());

    double samplingRate = (await AudioStreamer().actualSampleRate) + .0;
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

    String closestNote = findClosestGuitarNote(dominantFrequency);

    print('Dominant Frequency: $dominantFrequency Hz');
    print('Low');
    print(latestBuffer?.reduce(min));
    print('Max');
    print(latestBuffer?.reduce(max));
    print('Closest Guitar Note: $closestNote');

    setState(() {
      dominantFrequency = dominantFrequency;
      currentGuitarNote = closestNote;
    });

    findDrumBumAndNote(dominantFrequency);

    // Timer.periodic(Duration(milliseconds: 2000), (Timer timer) {

      // if(!isRecording){
      //   timer.cancel();
      // }

    // Timer.periodic(Duration(milliseconds: 400), (Timer timer) {
    //   if (!isRecording) {
    //     timer.cancel();
    //   }
      // int chunkSize = 256;     
      // for (int i = 0; i < buffer.length; i += chunkSize) {
      //   List<double> chunk = buffer.sublist(
      //       i, i + chunkSize > buffer.length ? buffer.length : i + chunkSize);        
      // }
      double minValue = buffer.reduce(min);
      double maxValue = buffer.reduce(max);

        setState(() {
          latestBuffer = buffer;
          samples = latestBuffer!
              .map((value) => (value - minValue) / (maxValue - minValue))
              .toList();
        });
    // });
  }

// Find the closest guitar note
  String findClosestGuitarNote(double frequency) {
    String closestNote = '';
    double minDifference = double.infinity;

    guitarNotes.forEach((note, noteFrequency) {
      double difference = (noteFrequency - frequency).abs();
      if (difference < minDifference) {
        minDifference = difference;
        closestNote = note;
      }
    });

    return closestNote;
  }

  String findDrumBumAndNote(double frequency) {
    // Map to hold all drum instruments with their corresponding notes
    final Map<String, Map<String, double>> drumInstruments = {
      "Bass Drum": bassDrumNotes,
      "Snare Drum": snareDrumNotes,
      "High Tom": highTomNotes,
      "Mid Tom": midTomNotes,
      "Low Tom": lowTomNotes,
      "Hi-Hat": hiHatNotes,
      "Ride Cymbal": rideCymbalNotes,
      "Crash Cymbal": crashCymbalNotes,
      "China Cymbal": chinaCymbalNotes,
      "Splash Cymbal": splashCymbalNotes,
    };

    String closestDrum = "Unknown";
    String closestNote = "Unknown";
    double minDiff = double.infinity;

    // Iterate through each drum instrument
    drumInstruments.forEach((drumInstrument, notes) {
      // Iterate through each note in the current drum instrument
      notes.forEach((note, noteFrequency) {
        double diff = (frequency - noteFrequency).abs();
        if (diff < minDiff) {
          minDiff = diff;
          closestDrum = drumInstrument;
          closestNote = note;
        }
      });
    });
    String result =
        "Drum Instrument: $closestDrum, Frequency: $frequency Hz, Closest Note: $closestNote";

    setState(() {
      currentDrumInstrument = closestDrum;
      currentDrumNote = closestNote;
    });

    print(result);
    return "Drum Instrument: $closestDrum, Frequency: $frequency Hz, Closest Note: $closestNote";
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
    // AudioStreamer().sampleRate = 22100;
    // AudioStreamer().sampleRate = 1000;

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
                  child: Text(
                    'Guitar Note: ${currentGuitarNote}',
                    style: const TextStyle(
                        fontSize: 25, color: Colors.deepOrangeAccent),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(25),
                  child: Text(
                    'Drum Instrument: ${currentDrumInstrument}',
                    style: const TextStyle(
                        fontSize: 18, color: Colors.deepOrangeAccent),
                  ),
                ),
                Container(
                    margin: const EdgeInsets.all(25),
                    // child: Text(
                    //   '${currentDrumInstrument} Note: ${currentDrumNote}',
                    //   style: const TextStyle(
                    //       fontSize: 18, color: Colors.deepOrangeAccent),
                    // ),
                    // ),
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
