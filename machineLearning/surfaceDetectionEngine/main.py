# main.py

import torch
from dataset import RoadSurfaceSequenceDataset
from model import Sequence1DCNN
from train import train_and_evaluate
from config import (DATA_FILE, FEATURES, NUM_EPOCHS, BATCH_SIZE, LEARNING_RATE, 
                    VALIDATION_SPLIT, TEST_SPLIT, SEED, MODEL_SAVE_PATH, NUM_FEATURES, SEQ_LEN)

if __name__ == "__main__":
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    # Load dataset
    dataset = RoadSurfaceSequenceDataset(csv_file=DATA_FILE, feature_cols=FEATURES, seq_len=SEQ_LEN)

    # Initialize model
    num_classes = dataset.num_classes
    model = Sequence1DCNN(num_features=NUM_FEATURES, num_classes=num_classes, seq_len=SEQ_LEN).to(device)

    # Train and evaluate
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

    print(f"Finished training. Best test accuracy: {best_test_acc:.4f}")
