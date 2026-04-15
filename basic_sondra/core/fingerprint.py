import hashlib

def generate_hash(f1, f2, dt):
    return int(hashlib.sha1(f"{f1}|{f2}|{dt}".encode()).hexdigest()[:15], 16)

def generate_fingerprints(peaks, fan_value=10):
    fingerprints = []

    for i in range(len(peaks)):
        for j in range(1, fan_value):
            if i + j < len(peaks):
                f1, t1 = peaks[i]
                f2, t2 = peaks[i + j]

                dt = t2 - t1

                if dt >= 0:
                    fingerprints.append((f1, f2, dt, t1))

    return fingerprints