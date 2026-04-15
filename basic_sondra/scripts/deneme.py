import psycopg2
import re

conn = psycopg2.connect(
    host="localhost",
    database="mydb",
    user="postgres",
    password="1234"
)
cur = conn.cursor()

cur.execute("SELECT id, title FROM songs WHERE artist = 'unknown'")
rows = cur.fetchall()

for song_id, title in rows:
    clean = title

    # 🔥 uzantıları sil (.wav, .mp3 vs)
    clean = re.sub(r'\.(wav|mp3)$', '', clean, flags=re.IGNORECASE)

    # 🔥 gereksiz etiketleri sil
    clean = re.sub(r'\(.*?\)', '', clean)   # ( ... )
    clean = re.sub(r'\[.*?\]', '', clean)   # [ ... ]

    clean = clean.strip()

    # 🔥 artist ayır
    if " - " in clean:
        artist, song = clean.split(" - ", 1)

        cur.execute(
            "UPDATE songs SET artist = %s, title = %s WHERE id = %s",
            (artist.strip(), song.strip(), song_id)
        )

        print(f"✔ {artist} - {song}")

    else:
        print(f"⚠ atlandı: {title}")

conn.commit()
cur.close()
conn.close()

print("DONE 🔥")