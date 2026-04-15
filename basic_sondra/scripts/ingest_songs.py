import os
import psycopg2
import hashlib

from core.audio_loader import load_audio
from core.spectrogram import compute_spectrogram
from core.peak_detection import get_peaks
from core.fingerprint import generate_fingerprints, generate_hash

DATA_PATH = "/home/emirfurkan/Desktop/Sondra-Music/data/raw/songs2"

# ---------------- DB ----------------
def get_connection():
    return psycopg2.connect(
        host="localhost",
        database="mydb",
        user="postgres",
        password="1234"
    )

# ---------------- FILE HASH ----------------
def get_file_hash(file_path):
    with open(file_path, "rb") as f:
        return hashlib.md5(f.read()).hexdigest()

# ---------------- CHECK DUPLICATE ----------------
def song_exists(cur, file_hash):
    cur.execute("SELECT id FROM songs WHERE file_hash = %s", (file_hash,))
    return cur.fetchone()

# ---------------- PROCESS ----------------
def process_song(file_path):
    y, sr = load_audio(file_path)
    S = compute_spectrogram(y)
    peaks = get_peaks(S)
    fingerprints = generate_fingerprints(peaks)

    duration = len(y) // sr
    return fingerprints, duration

# ---------------- INSERT ----------------
def insert_song(cur, title, duration, file_hash):
    cur.execute(
        "INSERT INTO songs (title, artist, duration, file_hash) VALUES (%s, %s, %s, %s) RETURNING id",
        (title, "unknown", duration, file_hash)
    )
    return cur.fetchone()[0]

def insert_fingerprints(cur, song_id, fingerprints):
    records = []

    for f1, f2, dt, t1 in fingerprints:
        h = generate_hash(int(f1), int(f2), int(dt))
        records.append((song_id, int(h), int(t1)))

    cur.executemany(
        "INSERT INTO fingerprints (song_id, hash_value, time_offset) VALUES (%s, %s, %s)",
        records
    )

# ---------------- MAIN ----------------
def main():
    conn = get_connection()
    cur = conn.cursor()

    files = os.listdir(DATA_PATH)

    for file in files:
        path = os.path.join(DATA_PATH, file)

        print(f"\nProcessing: {file}")

        try:
            file_hash = get_file_hash(path)

            if song_exists(cur, file_hash):
                print("⏩ Skipped (already exists)")
                continue

            fingerprints, duration = process_song(path)

            if not fingerprints:
                print("❌ No fingerprints generated")
                continue

            song_id = insert_song(cur, file, duration, file_hash)
            insert_fingerprints(cur, song_id, fingerprints)

            conn.commit()

            print(f"✅ Inserted ({len(fingerprints)} fingerprints)")

        except Exception as e:
            conn.rollback()
            print(f"🔥 ERROR: {e}")
            continue

    cur.close()
    conn.close()

if __name__ == "__main__":
    main()