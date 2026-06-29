enum SensorDataNoise {
  hrNoise(1.5),
  spo2Noise(0.4),
  tempNoise(0.05);

  const SensorDataNoise(this.value);

  final double value;
}

// Sensors (dataset) Constant noise of the readings
// the data +- this noise equals the same readings
// used to make a constant buffer for the data
