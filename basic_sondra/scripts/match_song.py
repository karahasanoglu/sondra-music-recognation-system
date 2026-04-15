from __future__ import annotations

import os
import tempfile
import time
from collections import Counter, defaultdict
from typing import Any

import numpy as np
import psycopg2
import soundfile as sf

from core.audio_loader import load_audio
from core.fingerprint import generate_fingerprints, generate_hash
from core.peak_detection import get_peaks
from core.spectrogram import compute_spectrogram

SAMPLE_RATE = 22050
CHANNELS = 1
CHUNK_DURATION = 5
MAX_DURATION = 25

# Daha guvenli sonuc icin esik yukseltildi.
# 20-23 gibi skorlar loglarda yanlis pozitif uretiyordu.
MIN_SCORE = 35


def get_connection():
    return psycopg2.connect(
        host=os.getenv("SONDRA_DB_HOST", "127.0.0.1"),
        port=os.getenv("SONDRA_DB_PORT", "5432"),
        database=os.getenv("SONDRA_DB_NAME", "sondra"),
        user=os.getenv("SONDRA_DB_USER", "postgres"),
        password=os.getenv("SONDRA_DB_PASSWORD", "1234"),
        options="-c client_encoding=UTF8",
    )


def process_query(file_path: str):
    try:
        start = time.time()
        y, sr = load_audio(file_path)

        if y is None or len(y) == 0:
            raise ValueError("Audio bos veya okunamadi")

        S = compute_spectrogram(y)
        peaks = get_peaks(S)

        if len(peaks) == 0:
            raise ValueError("Peak bulunamadi")

        fingerprints = generate_fingerprints(peaks)

        if len(fingerprints) == 0:
            raise ValueError("Fingerprint uretilemedi")

        print(
            f"[PROCESS] sr={sr}, samples={len(y)}, peaks={len(peaks)}, "
            f"fingerprints={len(fingerprints)}, elapsed={time.time() - start:.2f}s"
        )

        return fingerprints

    except Exception as exc:
        print(f"[PROCESS ERROR] {exc}")
        return None


def match_song(cur, query_fingerprints, min_score: int = MIN_SCORE):
    matches = defaultdict(list)

    try:
        start = time.time()
        hash_to_times = defaultdict(list)
        hashes = []

        for f1, f2, dt, t_query in query_fingerprints:
            hash_value = generate_hash(int(f1), int(f2), int(dt))
            hashes.append(int(hash_value))
            hash_to_times[int(hash_value)].append(int(t_query))

        hashes = list(set(hashes))

        if not hashes:
            print("[MATCH] Hash olusmadi")
            return None, 0

        print(f"[MATCH] Unique hash count: {len(hashes)}")

        cur.execute(
            """
            SELECT song_id, time_offset, hash_value
            FROM fingerprints
            WHERE hash_value = ANY(%s)
            """,
            (hashes,),
        )

        results = cur.fetchall()
        print(f"[MATCH] Raw fingerprint db hits: {len(results)}")

        for song_id, t_song, hash_value in results:
            for t_query in hash_to_times.get(int(hash_value), []):
                delta = int(t_song) - int(t_query)
                matches[song_id].append(delta)

        best_song = None
        best_score = 0
        score_board = []

        for song_id, deltas in matches.items():
            if not deltas:
                continue

            counter = Counter(deltas)
            score = counter.most_common(1)[0][1]
            score_board.append((song_id, score))

            if score > best_score:
                best_score = score
                best_song = song_id

        score_board.sort(key=lambda x: x[1], reverse=True)
        print(f"[MATCH] Top candidates: {score_board[:5]}")
        print(
            f"[MATCH] Best candidate: song_id={best_song}, "
            f"score={best_score}, threshold={min_score}, elapsed={time.time() - start:.2f}s"
        )

        if best_song is None:
            return None, 0

        if best_score < min_score:
            print(
                f"[MATCH] Best score threshold altinda kaldi. "
                f"best_score={best_score}, required={min_score}"
            )
            return None, best_score

        return best_song, best_score

    except Exception as exc:
        print(f"[MATCH ERROR] {exc}")
        return None, 0


def fetch_song_metadata(cur, song_id: int) -> dict[str, Any] | None:
    cur.execute(
        "SELECT id, title, artist FROM songs WHERE id = %s",
        (song_id,),
    )
    row = cur.fetchone()

    if row is None:
        return None

    return {
        "song_id": row[0],
        "title": row[1],
        "artist": row[2],
    }


def identify_song_from_fingerprints(cur, fingerprints, min_score: int = MIN_SCORE):
    song_id, score = match_song(cur, fingerprints, min_score)

    if song_id is None:
        return {
            "found": False,
            "score": score,
            "message": "Guvenilir bir eslesme bulunamadi.",
        }

    metadata = fetch_song_metadata(cur, song_id)

    if metadata is None:
        return {
            "found": False,
            "score": score,
            "message": "Eslesme bulundu ama sarki bilgisi bulunamadi.",
        }

    return {
        "found": True,
        "score": score,
        "message": "Sarki bulundu.",
        **metadata,
    }


def identify_song_from_file(file_path: str, min_score: int = MIN_SCORE):
    total_start = time.time()
    print(f"[MATCH] identify_song_from_file started: {file_path}")

    fingerprints = process_query(file_path)

    if fingerprints is None:
        print("[MATCH] Audio analiz edilemedi veya fingerprint uretilemedi.")
        return {
            "found": False,
            "score": 0,
            "message": "Gelen ses analiz edilemedi.",
        }

    print(f"[MATCH] Fingerprint count: {len(fingerprints)}")

    conn = get_connection()
    cur = conn.cursor()

    try:
        result = identify_song_from_fingerprints(cur, fingerprints, min_score)
        print(f"[MATCH] Database match result: {result}")
        print(f"[MATCH] Total identify time: {time.time() - total_start:.2f}s")
        return result
    finally:
        cur.close()
        conn.close()


def save_temp(audio: np.ndarray):
    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=".wav")
    path = tmp.name
    tmp.close()

    sf.write(path, audio, SAMPLE_RATE)
    return path


def streaming_match():
    try:
        import sounddevice as sd
    except ImportError as exc:
        raise RuntimeError(
            "Canli mikrofon modu icin sounddevice kurulumu gerekli."
        ) from exc

    conn = get_connection()
    cur = conn.cursor()

    print("\nDinleme basladi...")

    start_time = time.time()
    buffer: list[np.ndarray] = []

    try:
        def callback(indata, frames, time_info, status):
            if status:
                print(f"[AUDIO STATUS] {status}")
            buffer.append(indata.copy())

        with sd.InputStream(
            samplerate=SAMPLE_RATE,
            channels=CHANNELS,
            callback=callback,
        ):
            while True:
                elapsed = time.time() - start_time

                if elapsed >= MAX_DURATION:
                    print("\nMaalesef sarki bulunamadi.")
                    break

                time.sleep(CHUNK_DURATION)

                if not buffer:
                    continue

                audio = np.concatenate(buffer, axis=0).flatten()
                print(f"\nAnaliz ediliyor... ({round(elapsed, 1)} sn)")

                temp_path = save_temp(audio)
                fingerprints = process_query(temp_path)

                os.remove(temp_path)
                buffer.clear()

                if fingerprints is None:
                    continue

                result = identify_song_from_fingerprints(cur, fingerprints, MIN_SCORE)

                if result["found"]:
                    print("\nBULUNDU!")
                    print(f"Muzik: {result['title']}")
                    print(f"Sanatci: {result['artist']}")
                    print(f"score={result['score']}")
                    return result

                print(
                    f"Dinleme devam ediyor... "
                    f"(score={result.get('score', 0)}, threshold={MIN_SCORE})"
                )

    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    streaming_match()