import numpy as np
import librosa

def compute_spectrogram(y):
    return np.abs(librosa.stft(y))