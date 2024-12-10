# model.py

import torch
import torch.nn as nn
import torch.nn.functional as F

class Sequence1DCNN(nn.Module):
    def __init__(self, num_features, num_classes, seq_len=100):
        super(Sequence1DCNN, self).__init__()
        # Input shape: (batch, num_features, seq_len)
        # We apply 1D convolutions along the seq_len dimension
        self.conv1 = nn.Conv1d(in_channels=num_features, out_channels=64, kernel_size=3, padding=1)
        self.conv2 = nn.Conv1d(in_channels=64, out_channels=128, kernel_size=3, padding=1)
        # After these layers, shape: (batch, 128, seq_len)
        # Let's just flatten and use a linear layer
        self.fc = nn.Linear(128 * seq_len, num_classes)

    def forward(self, x):
        # x: (batch, num_features, seq_len)
        x = F.relu(self.conv1(x))    # (batch,64,seq_len)
        x = F.relu(self.conv2(x))    # (batch,128,seq_len)
        x = x.view(x.size(0), -1)    # flatten: (batch, 128*seq_len)
        x = self.fc(x)               # (batch, num_classes)
        return x
