import numpy as np
from scipy.ndimage import maximum_filter

def get_peaks(S):
    neighborhood = maximum_filter(S, size=20)
    peaks = np.where(S == neighborhood)
    return list(zip(peaks[0], peaks[1]))