from __future__ import annotations

import os
import tempfile
import time
from pathlib import Path

from fastapi import FastAPI, File, HTTPException, Query, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from starlette.concurrency import run_in_threadpool

from scripts.match_song import identify_song_from_file

ROOT_DIR = Path(__file__).resolve().parents[1]
WEB_APP_PATH = ROOT_DIR / "web_app" / "index.html"

DEFAULT_MIN_SCORE = int(os.getenv("SONDRA_MIN_SCORE", "20"))

app = FastAPI(
    title="Sondra Mobile API",
    version="1.1.0",
    description="Mobile entrypoint for the existing fingerprint based song matcher.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("SONDRA_ALLOW_ORIGINS", "*").split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/", include_in_schema=False)
def app_shell():
    return FileResponse(WEB_APP_PATH)


@app.get("/app", include_in_schema=False)
def web_app_shell():
    return FileResponse(WEB_APP_PATH)


@app.get("/api/health")
def health_check():
    return {
        "status": "ok",
        "service": "sondra-mobile-api",
        "default_min_score": DEFAULT_MIN_SCORE,
    }


@app.post("/api/match")
async def match_uploaded_song(
    audio: UploadFile = File(...),
    min_score: int = Query(
        default=DEFAULT_MIN_SCORE,
        ge=1,
        le=9999,
        description="Daha dusuk deger daha kolay eslesme bulur. Test icin 20, daha guvenli sonuc icin 35+ kullan.",
    ),
):
    temp_path = ""
    api_start = time.time()
    suffix = Path(audio.filename or "capture.wav").suffix or ".wav"

    try:
        payload = await audio.read()

        if not payload:
            raise HTTPException(
                status_code=400,
                detail="Bos ses dosyasi gonderildi.",
            )

        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            temp_path = tmp.name
            tmp.write(payload)

        print(
            f"[API] /api/match request received: "
            f"filename={audio.filename}, bytes={len(payload)}, "
            f"temp_path={temp_path}, min_score={min_score}"
        )

        match_start = time.time()

        result = await run_in_threadpool(
            identify_song_from_file,
            temp_path,
            min_score,
        )

        elapsed_match = time.time() - match_start
        elapsed_total = time.time() - api_start

        print(f"[API] /api/match result: {result}")
        print(
            f"[API] /api/match timing: "
            f"match={elapsed_match:.2f}s total={elapsed_total:.2f}s"
        )

        response = {
            **result,
            "min_score_used": min_score,
            "processing_seconds": round(elapsed_total, 2),
        }

        return response

    except HTTPException:
        raise

    except Exception as exc:
        elapsed_total = time.time() - api_start
        print(f"[API ERROR] /api/match failed after {elapsed_total:.2f}s: {exc}")

        raise HTTPException(
            status_code=500,
            detail=f"Song match failed: {exc}",
        ) from exc

    finally:
        if temp_path:
            try:
                os.remove(temp_path)
                print(f"[API] Temp file removed: {temp_path}")
            except Exception as cleanup_exc:
                print(f"[API WARNING] Temp file cleanup failed: {cleanup_exc}")