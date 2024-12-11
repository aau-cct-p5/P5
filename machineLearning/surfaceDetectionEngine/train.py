# train.py

import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, Subset
import numpy as np
import copy
from sklearn.metrics import classification_report, confusion_matrix
from config import TRAIN_STAT_FILE

def train_and_evaluate(model, dataset, num_epochs, batch_size, lr, val_split, test_split, seed, device, model_save_path, log_interval=10):
    # Set seed
    torch.manual_seed(seed)
    np.random.seed(seed)

    dataset_size = len(dataset)
    indices = list(range(dataset_size))
    np.random.shuffle(indices)
    
    val_size = int(val_split * dataset_size)
    test_size = int(test_split * dataset_size)
    train_size = dataset_size - val_size - test_size

    train_indices = indices[:train_size]
    val_indices = indices[train_size:train_size+val_size]
    test_indices = indices[train_size+val_size:]

    train_subset = Subset(dataset, train_indices)
    val_subset = Subset(dataset, val_indices)
    test_subset = Subset(dataset, test_indices)

    train_loader = DataLoader(train_subset, batch_size=batch_size, shuffle=True)
    val_loader = DataLoader(val_subset, batch_size=batch_size, shuffle=False)
    test_loader = DataLoader(test_subset, batch_size=batch_size, shuffle=False)

    criterion = nn.CrossEntropyLoss()
    optimizer = optim.Adam(model.parameters(), lr=lr)

    best_model_wts = copy.deepcopy(model.state_dict())
    best_acc = 0.0

    for epoch in range(num_epochs):
        model.train()
        running_loss = 0.0
        running_corrects = 0
        train_total = 0

        for i, (inputs, labels) in enumerate(train_loader):
            inputs, labels = inputs.to(device), labels.to(device)
            optimizer.zero_grad()

            outputs = model(inputs)
            loss = criterion(outputs, labels)
            _, preds = torch.max(outputs, 1)

            loss.backward()
            optimizer.step()

            running_loss += loss.item() * inputs.size(0)
            running_corrects += torch.sum(preds == labels).item()
            train_total += labels.size(0)

            if (i % log_interval == 0) and (i > 0):
                print(f"Epoch [{epoch+1}/{num_epochs}], Step [{i}/{len(train_loader)}], Loss: {loss.item():.4f}")

        epoch_loss = running_loss / train_total
        epoch_acc = running_corrects / train_total
        print(f"Train Epoch [{epoch+1}/{num_epochs}] Loss: {epoch_loss:.4f} Acc: {epoch_acc:.4f}")

        # Validation
        model.eval()
        val_running_corrects = 0
        val_total = 0
        with torch.no_grad():
            for inputs, labels in val_loader:
                inputs, labels = inputs.to(device), labels.to(device)
                outputs = model(inputs)
                _, preds = torch.max(outputs, 1)
                val_running_corrects += torch.sum(preds == labels).item()
                val_total += labels.size(0)

        val_acc = val_running_corrects / val_total
        print(f"Validation Acc: {val_acc:.4f}")

        # save best model
        if val_acc > best_acc:
            best_acc = val_acc
            best_model_wts = copy.deepcopy(model.state_dict())

    # load best model weights
    model.load_state_dict(best_model_wts)

    # Test evaluation with the best model
    model.eval()
    test_preds = []
    test_targets = []
    with torch.no_grad():
        for inputs, labels in test_loader:
            inputs, labels = inputs.to(device), labels.to(device)
            outputs = model(inputs)
            _, preds = torch.max(outputs, 1)
            test_preds.extend(preds.cpu().numpy())
            test_targets.extend(labels.cpu().numpy())

    test_acc = np.mean(np.array(test_preds) == np.array(test_targets))
    print(f"Test Accuracy with best model: {test_acc:.4f}")

    # Save best model and label mappings
    torch.save({
        'model_state_dict': model.state_dict(),
        'label2idx': dataset.label2idx,
        'idx2label': dataset.idx2label
    }, model_save_path)

    # Produce classification report and confusion matrix
    report = classification_report(test_targets, test_preds, target_names=[dataset.idx2label[i] for i in range(len(dataset.idx2label))])
    cm = confusion_matrix(test_targets, test_preds)

    # Print classes identified
    print("Classes identified:", dataset.idx2label)
    print("Classification Report:\n", report)
    print("Confusion Matrix:\n", cm)

    # Save to train_stat.txt
    with open(TRAIN_STAT_FILE, "w", encoding="utf-8") as f:
        f.write("Classes identified:\n")
        for k,v in dataset.idx2label.items():
            f.write(f"{k}: {v}\n")
        f.write("\nClassification Report:\n")
        f.write(report)
        f.write("\nConfusion Matrix:\n")
        f.write(str(cm))
        f.write("\n")

    return test_acc
