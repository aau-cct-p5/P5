# train.py

import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, Subset
import numpy as np
import copy

def train_and_evaluate(model, dataset, num_epochs, batch_size, lr, val_split, test_split, seed, device, model_save_path, log_interval=10):
    # Set seed
    torch.manual_seed(seed)
    np.random.seed(seed)

    # Create indices for train/val/test split
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
            running_corrects += torch.sum(preds == labels.data).item()
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
                val_running_corrects += torch.sum(preds == labels.data).item()
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
    test_running_corrects = 0
    test_total = 0
    with torch.no_grad():
        for inputs, labels in test_loader:
            inputs, labels = inputs.to(device), labels.to(device)
            outputs = model(inputs)
            _, preds = torch.max(outputs, 1)
            test_running_corrects += torch.sum(preds == labels.data).item()
            test_total += labels.size(0)
    test_acc = test_running_corrects / test_total
    print(f"Test Accuracy with best model: {test_acc:.4f}")

    # Save best model
    torch.save(model.state_dict(), model_save_path)

    return test_acc
