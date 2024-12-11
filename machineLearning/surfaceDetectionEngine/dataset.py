# dataset.py

import csv
import torch
from torch.utils.data import Dataset

class RoadSurfaceDataset(Dataset):
    def __init__(self, csv_file, feature_cols, mode="train"):
        self.feature_cols = feature_cols
        self.mode = mode
        self.samples = []
        self.labels = []
        self.label2idx = {}
        self.idx2label = {}
        
        # We'll store rows for predict mode to output predictions later
        # For training mode, we just store features and labels
        with open(csv_file, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                st = row["surfaceType"]
                if not st.strip():
                    continue
                if self.mode == "train":
                    if st == "none":
                        continue
                elif self.mode == "predict":
                    if st != "none":
                        continue

                # Extract features
                skip_row = False
                feature_values = []
                for col in feature_cols:
                    val_str = row[col].strip()
                    if val_str == "":
                        skip_row = True
                        break
                    try:
                        val = float(val_str)
                        feature_values.append(val)
                    except ValueError:
                        skip_row = True
                        break
                if skip_row:
                    continue

                if self.mode == "train":
                    label = st
                    if label not in self.label2idx:
                        self.label2idx[label] = len(self.label2idx)
                        self.idx2label[self.label2idx[label]] = label
                    self.samples.append((feature_values, label))
                else:
                    # For predict mode, store entire row for final output
                    self.samples.append((feature_values, row))

        if self.mode == "train":
            self.num_classes = len(self.label2idx)
        else:
            self.num_classes = None

    def __len__(self):
        return len(self.samples)

    def __getitem__(self, idx):
        if self.mode == "train":
            features, lbl = self.samples[idx]
            features = torch.tensor(features, dtype=torch.float32)
            label_idx = self.label2idx[lbl]
            return features, label_idx
        else:
            features, row = self.samples[idx]
            features = torch.tensor(features, dtype=torch.float32)
            return features, row
