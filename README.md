Edge Shake Anomaly Detector
I built this project to demonstrate an IoT sensor anomaly detection system that bridges edge computing with AWS cloud services. The core idea is to process sensor data locally on the device (the "edge") and only reach out to the cloud when something actually goes wrong.

What it does
Instead of constantly streaming data, the app simulates an IoT sensor (using your phone's accelerometer) and runs a local anomaly detection model. Normal movement is filtered out right on the device. When it detects a significant "shake", which represents an anomaly, it sends that specific event to the cloud.

Tech Stack
The Edge: A Flutter app that monitors sensor data in real-time.
The Cloud: An AWS API Gateway that triggers a Lambda function.
Storage: Detected anomalies are stored in DynamoDB for logging and analysis.
This approach is really about efficiency reducing bandwidth, cutting down latency, and making intelligent decisions locally without needing heavy hardware.
