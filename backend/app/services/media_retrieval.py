"""
Image retrieval from Jikan (anime) and Wikipedia (everything else).
Returns base64-encoded image data suitable for embedding in pptxgenjs.
"""
import base64
import httpx
from concurrent.futures import ThreadPoolExecutor, as_completed, TimeoutError
from typing import Optional


HEADERS = {"User-Agent": "StudyAssistant/1.0 (educational project)"}
TIMEOUT = 8


def _fetch_bytes(url: str) -> Optional[bytes]:
    try:
        r = httpx.get(url, headers=HEADERS, timeout=TIMEOUT, follow_redirects=True)
        if r.status_code == 200 and len(r.content) > 1000:
            return r.content
    except Exception:
        pass
    return None


def _to_base64(data: bytes) -> str:
    return base64.b64encode(data).decode()


def get_jikan_image_url(character_name: str) -> Optional[str]:
    """Fetch a character image URL from Jikan (MyAnimeList) API."""
    try:
        r = httpx.get(
            "https://api.jikan.moe/v4/characters",
            params={"q": character_name, "limit": 1},
            headers=HEADERS,
            timeout=TIMEOUT,
        )
        data = r.json()
        chars = data.get("data", [])
        if chars:
            return chars[0]["images"]["jpg"]["image_url"]
    except Exception:
        pass
    return None


def get_wikipedia_image_url(wiki_page: str) -> Optional[str]:
    """Fetch thumbnail URL from Wikipedia REST API."""
    try:
        r = httpx.get(
            f"https://en.wikipedia.org/api/rest_v1/page/summary/{wiki_page}",
            headers=HEADERS,
            timeout=TIMEOUT,
        )
        data = r.json()
        thumb = data.get("thumbnail", {}).get("source")
        return thumb
    except Exception:
        pass
    return None


def fetch_entity_image(entity: str, interest_data: dict) -> Optional[dict]:
    """
    Try to get an image for `entity` using the preferred API in interest_data.
    Returns {"base64": "...", "ext": "jpg"} or None.
    """
    api = interest_data.get("api", "wikipedia")
    img_url = None

    if api == "jikan":
        # Find this entity in the jikan_names list if present, else use entity directly
        jikan_names = interest_data.get("jikan_names", [])
        search_name = entity if entity in jikan_names else jikan_names[0] if jikan_names else entity
        img_url = get_jikan_image_url(search_name)

    if img_url is None:
        # Fallback to Wikipedia
        wiki_pages = interest_data.get("wiki_pages", [])
        # Try to find a matching wiki page for this entity
        entity_clean = entity.replace(" ", "_")
        for wp in wiki_pages:
            if any(part.lower() in wp.lower() for part in entity.split()):
                img_url = get_wikipedia_image_url(wp)
                if img_url:
                    break
        if img_url is None and wiki_pages:
            img_url = get_wikipedia_image_url(wiki_pages[0])

    if img_url:
        raw = _fetch_bytes(img_url)
        if raw:
            ext = "jpg" if img_url.split("?")[0].endswith((".jpg", ".jpeg")) else "png"
            return {"base64": _to_base64(raw), "ext": ext}
    return None


def fetch_images_for_slides(slides: list, interest_data: dict) -> list:
    """
    Given slide list and interest_data, attach image base64 to each slide in parallel.
    Uses first entity in interest list for the image (one image per slide rotation).
    """
    entities = interest_data.get("entities", [])
    if not entities:
        return slides

    def _fetch_for_slide(i: int, slide: dict) -> tuple[int, Optional[dict]]:
        entity = entities[i % len(entities)]
        slide["entity"] = entity
        img = fetch_entity_image(entity, interest_data)
        return i, img

    enriched = list(slides)
    with ThreadPoolExecutor(max_workers=4) as pool:
        futures = {pool.submit(_fetch_for_slide, i, slide): i for i, slide in enumerate(enriched)}
        for future in as_completed(futures, timeout=25):
            try:
                i, img = future.result()
                if img:
                    enriched[i]["image_base64"] = img["base64"]
                    enriched[i]["image_ext"] = img["ext"]
            except Exception:
                pass

    return enriched
