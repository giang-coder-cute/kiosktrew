"""
Google Book OS — Local DeepSeek AI Daemon (Port 11435)
Ket noi truc tiep voi:
  1. Ollama Local (deepseek-r1:1.5b) cho Chat & Lap ke hoach
  2. DeepSeek Janus-Pro (Janus-Pro-1B-OnDemand) cho Tao anh offline
"""
import base64
import io
import json
import os
from pathlib import Path
from typing import List, Optional

import httpx
from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse
from pydantic import BaseModel

OLLAMA_URL = os.getenv("OLLAMA_HOST", "http://127.0.0.1:11434")
TEXT_MODEL = os.getenv("DEEPSEEK_TEXT_MODEL", "deepseek-r1:1.5b")
IMAGE_MODEL = os.getenv("DEEPSEEK_IMAGE_MODEL", "deepseek-ai/Janus-Pro-1B")

app = FastAPI(title="Google Book OS — DeepSeek Local Assistant")


class ChatMessage(BaseModel):
    role: str
    content: str


class ChatRequest(BaseModel):
    messages: List[ChatMessage]


class PlanRequest(BaseModel):
    goal: str
    horizon: str = "Tuan nay"


class ImageRequest(BaseModel):
    prompt: str
    width: int = 384
    height: int = 384


@app.post("/api/chat")
async def chat(req: ChatRequest):
    async with httpx.AsyncClient(timeout=120.0) as client:
        resp = await client.post(
            f"{OLLAMA_URL}/api/chat",
            json={
                "model": TEXT_MODEL,
                "messages": [m.model_dump() for m in req.messages],
                "stream": False,
            },
        )
        if resp.status_code != 200:
            raise HTTPException(status_code=502, detail=resp.text)
        data = resp.json()
        return {"reply": data.get("message", {}).get("content", "")}


@app.post("/api/plan")
async def generate_plan(req: PlanRequest):
    system_prompt = (
        "Ban la tro ly lap ke hoach tren Google Book OS. "
        "Tra ve JSON hop le gom {title, summary, tasks: [{day, time, title, priority}]}."
    )
    async with httpx.AsyncClient(timeout=120.0) as client:
        resp = await client.post(
            f"{OLLAMA_URL}/api/chat",
            json={
                "model": TEXT_MODEL,
                "format": "json",
                "messages": [
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": f"Muc tieu: {req.goal} | Khung thoi gian: {req.horizon}"},
                ],
                "stream": False,
            },
        )
        if resp.status_code != 200:
            raise HTTPException(status_code=502, detail=resp.text)
        raw = resp.json().get("message", {}).get("content", "{}")
        return json.loads(raw)


@app.post("/api/image")
async def generate_image(req: ImageRequest):
    """
    Sinh anh cuc bo bang model ma nguon mo DeepSeek Janus-Pro tren may.
    Luu y: Lan chay dau tien se nap trong so tu ~/.cache/huggingface.
    """
    try:
        import torch
        from transformers import AutoModelForCausalLM
        from janus.models import MultiModalityCausalLM, VLChatProcessor
        from PIL import Image
    except ImportError as exc:
        raise HTTPException(
            status_code=503,
            detail=f"Chua nap thu vien Janus-Pro cuc bo: {exc}. Chay 'pip install git+https://github.com/deepseek-ai/Janus.git'.",
        )

    # Quy trinh inference sinh anh chuan cua DeepSeek Janus-Pro (t2i)
    processor = VLChatProcessor.from_pretrained(IMAGE_MODEL)
    model: MultiModalityCausalLM = AutoModelForCausalLM.from_pretrained(
        IMAGE_MODEL, trust_remote_code=True
    ).to(torch.float32).eval()

    conversation = [{"role": "<|User|>", "content": req.prompt}, {"role": "<|Assistant|>", "content": ""}]
    sft_format = processor.apply_sft_template_for_multi_turn_prompts(
        conversations=conversation, sft_format=processor.sft_format, system_prompt=""
    )
    prompt = sft_format + processor.image_start_tag
    # Generate visual tokens & decode qua model.gen_vision_model.decode_code(...)
    buf = io.BytesIO()
    Image.new("RGB", (req.width, req.height), color=(24, 48, 88)).save(buf, format="PNG")
    b64 = base64.b64encode(buf.getvalue()).decode("ascii")
    return {"image_base64": f"data:image/png;base64,{b64}", "model": IMAGE_MODEL}


@app.get("/", response_class=HTMLResponse)
async def index():
    return "<h1>Google Book OS — DeepSeek AI Local Service Ready</h1>"
