import librosa

def load_audio(file_path):
    y, sr = librosa.load(file_path, sr=22050)
    return y, sr