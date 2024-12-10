# dataset.py

import csv
import torch
from torch.utils.data import Dataset

class RoadSurfaceSequenceDataset(Dataset):
    def __init__(self, csv_file, feature_cols, seq_len=100):
        self.feature_cols = feature_cols
        self.seq_len = seq_len
        self.data = []
        self.labels = []
        self.label2idx = {}
        self.idx2label = {}

        # Read entire CSV into memory
        rows = []
        with open(csv_file, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                rows.append(row)

        # Convert rows into numeric feature vectors and labels
        # We assume rows are in chronological order
        # We'll form sequences from these rows
        self.num_samples = len(rows)
        self.num_sequences = self.num_samples - self.seq_len + 1

        for i in range(self.num_sequences):
            seq = rows[i:i+self.seq_len]
            features_seq = []
            for r in seq:
                features = [float(r[col]) for col in feature_cols]
                features_seq.append(features)
            
            # Label is taken from the last row in the sequence
            label = seq[-1]["surfaceType"]
            if label not in self.label2idx:
                self.label2idx[label] = len(self.label2idx)
                self.idx2label[self.label2idx[label]] = label

            self.data.append(features_seq)
            self.labels.append(label)

        self.num_classes = len(self.label2idx)

    def __len__(self):
        return self.num_sequences

    def __getitem__(self, idx):
        features_seq = self.data[idx]          # shape: [seq_len, num_features]
        lbl = self.labels[idx]
        features_seq = torch.tensor(features_seq, dtype=torch.float32)  # (seq_len, num_features)
        # Transpose to (num_features, seq_len) so we have (batch, num_features, seq_len) for CNN
        features_seq = features_seq.transpose(0, 1)  # (num_features, seq_len)
        label_idx = self.label2idx[lbl]
        return features_seq, label_idx
