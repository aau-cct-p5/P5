# config.py

import os

DATA_DIR = "/data"
DATA_FILE = os.path.join(DATA_DIR, "training_data.csv")

# MODE can be "train" or "predict"
MODE = os.environ.get("MODE", "train")

BATCH_SIZE = 32
NUM_EPOCHS = 10
LEARNING_RATE = 0.001
VALIDATION_SPLIT = 0.2
TEST_SPLIT = 0.1
SEED = 42

# Note: do NOT include "_id" in the features.
FEATURES = [
    "rmsAcceleration",
    "location_lat",
    "location_lon",
    "accelerometer_x",
    "accelerometer_y",
    "accelerometer_z",
    "gyroscope_x",
    "gyroscope_y",
    "gyroscope_z"
]
NUM_FEATURES = len(FEATURES)

MODEL_SAVE_PATH = os.path.join(DATA_DIR, "best_model.pth")
PREDICTION_OUTPUT_FILE = os.path.join(DATA_DIR, "predictions.csv")
TRAIN_STAT_FILE = os.path.join(DATA_DIR, "train_stat.txt")
PREDICTION_STAT_FILE = os.path.join(DATA_DIR, "prediction_stat.txt")

LOG_INTERVAL = 10
