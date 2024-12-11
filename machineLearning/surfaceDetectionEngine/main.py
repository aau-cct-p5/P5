# main.py

import torch
import csv
from dataset import RoadSurfaceDataset
from model import SimpleClassifier
from train import train_and_evaluate
from config import (DATA_FILE, FEATURES, NUM_EPOCHS, BATCH_SIZE, LEARNING_RATE, 
                    VALIDATION_SPLIT, TEST_SPLIT, SEED, MODEL_SAVE_PATH, NUM_FEATURES, 
                    MODE, PREDICTION_OUTPUT_FILE, PREDICTION_STAT_FILE)
import os
import collections

if __name__ == "__main__":
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    if MODE == "train":
        dataset = RoadSurfaceDataset(csv_file=DATA_FILE, feature_cols=FEATURES, mode="train")
        num_classes = dataset.num_classes
        model = SimpleClassifier(num_features=NUM_FEATURES, num_classes=num_classes).to(device)

        best_test_acc = train_and_evaluate(
            model=model,
            dataset=dataset,
            num_epochs=NUM_EPOCHS,
            batch_size=BATCH_SIZE,
            lr=LEARNING_RATE,
            val_split=VALIDATION_SPLIT,
            test_split=TEST_SPLIT,
            seed=SEED,
            device=device,
            model_save_path=MODEL_SAVE_PATH
        )
        print(f"Training finished. Best test accuracy: {best_test_acc:.4f}")

    elif MODE == "predict":
        dataset = RoadSurfaceDataset(csv_file=DATA_FILE, feature_cols=FEATURES, mode="predict")

        # Load model and label maps
        checkpoint = torch.load(MODEL_SAVE_PATH, map_location=device)
        label2idx = checkpoint['label2idx']
        idx2label = checkpoint['idx2label']
        num_classes = len(label2idx)

        model = SimpleClassifier(num_features=NUM_FEATURES, num_classes=num_classes).to(device)
        model.load_state_dict(checkpoint['model_state_dict'])
        model.eval()

        predictions = []
        predicted_classes = []
        total_samples = len(dataset)

        with torch.no_grad():
            for i in range(len(dataset)):
                features, original_row = dataset[i]
                features = features.unsqueeze(0).to(device)
                outputs = model(features)
                _, preds = torch.max(outputs, 1)
                pred_label = idx2label[preds.item()]
                new_row = dict(original_row)
                new_row["predicted_surfaceType"] = pred_label
                predictions.append(new_row)
                predicted_classes.append(pred_label)

        # Write predictions to CSV
        fieldnames = [
            "@timestamp",
            "rmsAcceleration",
            "surfaceType",
            "_id",
            "location_lat",
            "location_lon",
            "accelerometer_x",
            "accelerometer_y",
            "accelerometer_z",
            "gyroscope_x",
            "gyroscope_y",
            "gyroscope_z",
            "predicted_surfaceType"
        ]

        with open(PREDICTION_OUTPUT_FILE, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            for row in predictions:
                writer.writerow(row)

        # Create prediction stats
        pred_count = len(predictions)
        class_counter = collections.Counter(predicted_classes)

        with open(PREDICTION_STAT_FILE, "w", encoding="utf-8") as f:
            f.write(f"Total documents for prediction: {total_samples}\n")
            f.write(f"Total documents predicted: {pred_count}\n")
            f.write("Predicted class distribution:\n")
            for cls, cnt in class_counter.items():
                f.write(f"{cls}: {cnt}\n")

        print(f"Prediction finished. {pred_count}/{total_samples} documents predicted.")
        print(f"Prediction stats saved to {PREDICTION_STAT_FILE}")

    else:
        raise ValueError("MODE must be either 'train' or 'predict'.")
