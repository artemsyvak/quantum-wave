import 'dart:math';

class FFT {
  // Function to perform FFT with zero-padding
  List<Complex> fft(List<Complex> x) {
    int N = x.length;

    // Pad with zeros if N is not a power of 2
    if (!_isPowerOf2(N)) {
      int newSize = _nextPowerOf2(N);
      x = _padWithZeros(x, newSize);
      N = newSize;
    }

    // Base case
    if (N <= 1) return x;

    // Divide: Calculate FFT of even and odd indices
    List<Complex> even = List.generate(N ~/ 2, (i) => x[i * 2]);
    List<Complex> odd = List.generate(N ~/ 2, (i) => x[i * 2 + 1]);

    List<Complex> fftEven = fft(even);
    List<Complex> fftOdd = fft(odd);

    // Combine: Calculate the combined FFT
    List<Complex> combined = List.generate(N, (i) => Complex(0, 0));

    for (int k = 0; k < N ~/ 2; k++) {
      Complex t = Complex.polar(1.0, -2 * pi * k / N) * fftOdd[k];
      combined[k] = fftEven[k] + t;
      combined[k + N ~/ 2] = fftEven[k] - t;
    }

    return combined;
  }

  // Check if a number is a power of 2
  bool _isPowerOf2(int x) {
    return (x & (x - 1)) == 0;
  }

  // Get the next power of 2 greater than or equal to x
  int _nextPowerOf2(int x) {
    return pow(2, (log(x) / log(2)).ceil()).toInt();
  }

  // Pad the list with zeros to make its size a power of 2
  List<Complex> _padWithZeros(List<Complex> x, int newSize) {
    return List<Complex>.from(x)
      ..addAll(List.generate(newSize - x.length, (i) => Complex(0, 0)));
  }
}

class Complex {
  final double real;
  final double imaginary;

  Complex(this.real, this.imaginary);

  // Addition
  Complex operator +(Complex other) {
    return Complex(real + other.real, imaginary + other.imaginary);
  }

  // Subtraction
  Complex operator -(Complex other) {
    return Complex(real - other.real, imaginary - other.imaginary);
  }

  // Multiplication
  Complex operator *(Complex other) {
    return Complex(
      real * other.real - imaginary * other.imaginary,
      real * other.imaginary + imaginary * other.real,
    );
  }

  // Complex number from polar coordinates
  static Complex polar(double magnitude, double phase) {
    return Complex(magnitude * cos(phase), magnitude * sin(phase));
  }

  double magnitude() => sqrt(real * real + imaginary * imaginary);

  @override
  String toString() => '($real + ${imaginary}i)';
}
