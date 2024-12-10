# config.py

import os

# Global constants and configuration parameters
DATA_DIR = "/data"  # This is the mounted docker volume directory
DATA_FILE = os.path.join(DATA_DIR, "training_data_temp.csv")

# Hyperparameters
BATCH_SIZE = 32
NUM_EPOCHS = 10
LEARNING_RATE = 0.001
VALIDATION_SPLIT = 0.2
TEST_SPLIT = 0.1
SEED = 42

# Features we consider (numeric)
FEATURES = [
    "accelerometer.x",
    "accelerometer.y",
    "accelerometer.z",
    "gyroscope.x",
    "gyroscope.y",
    "gyroscope.z",
    "rmsAcceleration",
    "location.lat",
    "location.lon"
]

SEQ_LEN = 100  # length of sequence to use

# Model parameters
NUM_FEATURES = len(FEATURES)

# Output configuration
MODEL_SAVE_PATH = os.path.join(DATA_DIR, "best_model.pth")
LOG_INTERVAL = 10
