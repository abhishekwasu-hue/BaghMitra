"""Fixed feed wording shared by the feed API and the push alerts (addendum v1.4 §6)."""

from __future__ import annotations

# Information, not advice: every feed response and push ends with this.
FOOTER = {
    "en": "Check the official GR/portal before acting.",
    "mr": "कोणतीही कृती करण्यापूर्वी अधिकृत शासन निर्णय (GR) / पोर्टल तपासा.",
    "hi": "कोई भी कदम उठाने से पहले आधिकारिक GR / पोर्टल देखें।",
}
