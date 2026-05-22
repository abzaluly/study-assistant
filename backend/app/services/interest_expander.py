"""
Interest → Entity expansion database.
Maps a raw interest string to specific well-known entities,
a visual/prompt style, and API metadata for image retrieval.
"""

INTEREST_DB = {
    # ── Anime / Manga ─────────────────────────────────────────────────────────
    "anime": {
        "entities": ["Naruto Uzumaki", "Gojo Satoru", "Levi Ackerman", "Monkey D. Luffy", "Eren Yeager"],
        "style": "аниме кинематографичный",
        "prompt_context": "аниме персонажи и их миссии",
        "api": "jikan",
        "jikan_names": ["Naruto Uzumaki", "Gojo Satoru", "Levi Ackerman"],
    },
    "аниме": {
        "entities": ["Naruto Uzumaki", "Gojo Satoru", "Levi Ackerman", "Monkey D. Luffy", "Eren Yeager"],
        "style": "аниме кинематографичный",
        "prompt_context": "аниме персонажи и их миссии",
        "api": "jikan",
        "jikan_names": ["Naruto Uzumaki", "Gojo Satoru", "Levi Ackerman"],
    },
    "naruto": {
        "entities": ["Naruto Uzumaki", "Sasuke Uchiha", "Kakashi Hatake", "Minato Namikaze"],
        "style": "аниме ниндзя",
        "prompt_context": "мир Наруто — ниндзя, чакра, миссии",
        "api": "jikan",
        "jikan_names": ["Naruto Uzumaki", "Sasuke Uchiha", "Kakashi Hatake"],
    },
    "one piece": {
        "entities": ["Monkey D. Luffy", "Roronoa Zoro", "Nami", "Sanji"],
        "style": "аниме приключения",
        "prompt_context": "мир One Piece — пираты и Гранд-Лайн",
        "api": "jikan",
        "jikan_names": ["Monkey D. Luffy", "Roronoa Zoro", "Sanji"],
    },

    # ── Football / Soccer ────────────────────────────────────────────────────
    "football": {
        "entities": ["Cristiano Ronaldo", "Lionel Messi", "Kylian Mbappe", "Erling Haaland", "Vinicius Jr"],
        "style": "спортивный кинематографичный",
        "prompt_context": "футбольные матчи, голы, тактика",
        "api": "wikipedia",
        "wiki_pages": ["Cristiano_Ronaldo", "Lionel_Messi", "Kylian_Mbappé", "Erling_Haaland"],
    },
    "футбол": {
        "entities": ["Криштиану Роналду", "Лионель Месси", "Килиан Мбаппе", "Эрлинг Холанд"],
        "style": "спортивный кинематографичный",
        "prompt_context": "футбольные матчи, голы, тактика",
        "api": "wikipedia",
        "wiki_pages": ["Cristiano_Ronaldo", "Lionel_Messi", "Kylian_Mbappé", "Erling_Haaland"],
    },
    "soccer": {
        "entities": ["Cristiano Ronaldo", "Lionel Messi", "Kylian Mbappe", "Erling Haaland"],
        "style": "спортивный кинематографичный",
        "prompt_context": "футбольные матчи, голы, тактика",
        "api": "wikipedia",
        "wiki_pages": ["Cristiano_Ronaldo", "Lionel_Messi", "Kylian_Mbappé"],
    },

    # ── Basketball ────────────────────────────────────────────────────────────
    "basketball": {
        "entities": ["LeBron James", "Stephen Curry", "Giannis Antetokounmpo", "Kevin Durant", "Kobe Bryant"],
        "style": "NBA динамичный",
        "prompt_context": "баскетбол NBA, броски, командная игра",
        "api": "wikipedia",
        "wiki_pages": ["LeBron_James", "Stephen_Curry", "Giannis_Antetokounmpo", "Kevin_Durant"],
    },
    "баскетбол": {
        "entities": ["ЛеБрон Джеймс", "Стефен Карри", "Янис Адетокунбо", "Кевин Дюрэнт"],
        "style": "NBA динамичный",
        "prompt_context": "баскетбол NBA, броски, командная игра",
        "api": "wikipedia",
        "wiki_pages": ["LeBron_James", "Stephen_Curry", "Giannis_Antetokounmpo"],
    },

    # ── Gaming ────────────────────────────────────────────────────────────────
    "gaming": {
        "entities": ["Mario", "Kratos", "Master Chief", "Geralt of Rivia", "Arthur Morgan"],
        "style": "гейминг кинематографичный",
        "prompt_context": "видеоигры, квесты, уровни, боссы",
        "api": "wikipedia",
        "wiki_pages": ["Mario", "Kratos_(God_of_War)", "Master_Chief_(Halo)"],
    },
    "игры": {
        "entities": ["Марио", "Кратос", "Мастер Чиф", "Геральт из Ривии"],
        "style": "гейминг кинематографичный",
        "prompt_context": "видеоигры, квесты, уровни, боссы",
        "api": "wikipedia",
        "wiki_pages": ["Mario", "Kratos_(God_of_War)", "Master_Chief_(Halo)"],
    },
    "minecraft": {
        "entities": ["Steve", "Creeper", "Enderman", "Herobrine"],
        "style": "Minecraft пиксельный",
        "prompt_context": "Minecraft — добыча ресурсов, крафт, постройки",
        "api": "wikipedia",
        "wiki_pages": ["Minecraft"],
    },
    "gta": {
        "entities": ["CJ", "Tommy Vercetti", "Trevor Philips", "Michael De Santa"],
        "style": "GTA открытый мир",
        "prompt_context": "GTA — задания, открытый мир, персонажи",
        "api": "wikipedia",
        "wiki_pages": ["Grand_Theft_Auto_V"],
    },

    # ── Cars / Motors ─────────────────────────────────────────────────────────
    "cars": {
        "entities": ["Ferrari", "Lamborghini Aventador", "Formula 1", "Lewis Hamilton", "Max Verstappen"],
        "style": "автомобильный кинематографичный",
        "prompt_context": "суперкары, гонки Формулы-1, тюнинг",
        "api": "wikipedia",
        "wiki_pages": ["Lewis_Hamilton", "Max_Verstappen", "Ferrari"],
    },
    "машины": {
        "entities": ["Ferrari", "Lamborghini", "Формула-1", "Льюис Хэмилтон", "Макс Ферстаппен"],
        "style": "автомобильный кинематографичный",
        "prompt_context": "суперкары, гонки Формулы-1, тюнинг",
        "api": "wikipedia",
        "wiki_pages": ["Lewis_Hamilton", "Max_Verstappen", "Ferrari"],
    },
    "авто": {
        "entities": ["Ferrari", "Lamborghini", "Formula 1", "Lewis Hamilton"],
        "style": "автомобильный кинематографичный",
        "prompt_context": "суперкары, гонки Формулы-1, тюнинг",
        "api": "wikipedia",
        "wiki_pages": ["Lewis_Hamilton", "Ferrari"],
    },

    # ── Boxing / MMA ──────────────────────────────────────────────────────────
    "boxing": {
        "entities": ["Muhammad Ali", "Mike Tyson", "Gennady Golovkin", "Canelo Alvarez", "Anthony Joshua"],
        "style": "бокс драматичный",
        "prompt_context": "боксёрские поединки, стратегия боя",
        "api": "wikipedia",
        "wiki_pages": ["Muhammad_Ali", "Mike_Tyson", "Gennady_Golovkin", "Canelo_Álvarez"],
    },
    "бокс": {
        "entities": ["Мухаммад Али", "Майк Тайсон", "Геннадий Головкин", "Александр Усик"],
        "style": "бокс драматичный",
        "prompt_context": "боксёрские поединки, стратегия боя",
        "api": "wikipedia",
        "wiki_pages": ["Muhammad_Ali", "Mike_Tyson", "Gennady_Golovkin"],
    },

    # ── Music ─────────────────────────────────────────────────────────────────
    "music": {
        "entities": ["Drake", "Travis Scott", "Kendrick Lamar", "The Weeknd", "J. Cole"],
        "style": "музыкальный кинематографичный",
        "prompt_context": "музыканты, концерты, треки",
        "api": "wikipedia",
        "wiki_pages": ["Drake_(musician)", "Travis_Scott", "Kendrick_Lamar"],
    },
    "музыка": {
        "entities": ["Дрейк", "Тревис Скотт", "Кендрик Ламар", "The Weeknd"],
        "style": "музыкальный кинематографичный",
        "prompt_context": "музыканты, концерты, треки",
        "api": "wikipedia",
        "wiki_pages": ["Drake_(musician)", "Travis_Scott", "Kendrick_Lamar"],
    },

    # ── Tech / Science ────────────────────────────────────────────────────────
    "technology": {
        "entities": ["Elon Musk", "Steve Jobs", "Mark Zuckerberg", "SpaceX", "Tesla"],
        "style": "технологичный футуристический",
        "prompt_context": "технологии, стартапы, инновации",
        "api": "wikipedia",
        "wiki_pages": ["Elon_Musk", "Steve_Jobs", "Mark_Zuckerberg"],
    },
    "технологии": {
        "entities": ["Илон Маск", "Стив Джобс", "Марк Цукерберг", "SpaceX", "Tesla"],
        "style": "технологичный футуристический",
        "prompt_context": "технологии, стартапы, инновации",
        "api": "wikipedia",
        "wiki_pages": ["Elon_Musk", "Steve_Jobs", "Mark_Zuckerberg"],
    },

    # ── Marvel / Movies ────────────────────────────────────────────────────────
    "marvel": {
        "entities": ["Iron Man", "Spider-Man", "Thor", "Captain America", "Black Panther"],
        "style": "Marvel супергерои",
        "prompt_context": "Marvel — супергерои, их суперспособности",
        "api": "wikipedia",
        "wiki_pages": ["Iron_Man", "Spider-Man", "Thor_(Marvel_Comics)"],
    },
    "crypto": {
        "entities": ["Bitcoin", "Ethereum", "Satoshi Nakamoto", "Vitalik Buterin"],
        "style": "криптовалютный цифровой",
        "prompt_context": "криптовалюты, блокчейн, трейдинг",
        "api": "wikipedia",
        "wiki_pages": ["Bitcoin", "Ethereum", "Vitalik_Buterin"],
    },
}

_FALLBACK = {
    "entities": [],
    "style": "кинематографичный",
    "prompt_context": "реальные сценарии из жизни",
    "api": "wikipedia",
    "wiki_pages": [],
}


def expand_interest(raw_interest: str) -> dict:
    """Return entity data for a raw interest string."""
    key = raw_interest.strip().lower()
    # Exact match
    if key in INTEREST_DB:
        return INTEREST_DB[key]
    # Partial match
    for db_key, data in INTEREST_DB.items():
        if db_key in key or key in db_key:
            return data
    # Fallback: unknown interest — return it as a generic entity
    return {
        **_FALLBACK,
        "entities": [raw_interest],
        "prompt_context": f"{raw_interest} — примеры из этой области",
    }


def expand_interests_to_context(interests: list) -> dict:
    """
    Given a list of raw interests, return a combined context dict:
    {
      "entities": [...],          # up to 6 specific entities
      "entities_str": "...",      # comma-separated for prompts
      "style": "...",             # visual style of primary interest
      "prompt_context": "...",    # description for GPT
      "primary_interest": "...",  # first interest raw string
      "primary_data": {...},      # full data for primary interest
    }
    """
    if not interests:
        interests = ["sport"]

    all_entities = []
    primary_data = None

    for raw in interests[:3]:
        data = expand_interest(raw)
        if primary_data is None:
            primary_data = data
        all_entities.extend(data["entities"][:3])

    # Deduplicate while preserving order
    seen = set()
    unique = []
    for e in all_entities:
        if e not in seen:
            seen.add(e)
            unique.append(e)

    return {
        "entities": unique[:6],
        "entities_str": ", ".join(unique[:6]),
        "style": primary_data["style"],
        "prompt_context": primary_data["prompt_context"],
        "primary_interest": interests[0],
        "primary_data": primary_data,
    }
