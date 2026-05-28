#!/usr/bin/env python3
import argparse
import json
import sqlite3
import time
import uuid
from datetime import datetime, timedelta, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse


DEFAULT_DB_PATH = Path(__file__).with_name("kiezio.sqlite3")
DATABASE_PATH = DEFAULT_DB_PATH


def now_iso():
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def iso_in(hours=0):
    return (datetime.now(timezone.utc) + timedelta(hours=hours)).isoformat().replace("+00:00", "Z")


def new_id():
    return str(uuid.uuid4()).upper()


def connect():
    conn = sqlite3.connect(DATABASE_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def initialize_database(db_path=DEFAULT_DB_PATH):
    global DATABASE_PATH
    DATABASE_PATH = Path(db_path)
    DATABASE_PATH.parent.mkdir(parents=True, exist_ok=True)
    with connect() as conn:
        create_schema(conn)
        seed_data(conn)


def create_schema(conn):
    conn.executescript(
        """
        CREATE TABLE IF NOT EXISTS users (
            id TEXT PRIMARY KEY,
            display_name TEXT NOT NULL,
            trust_score REAL NOT NULL DEFAULT 0.72,
            helpful_actions INTEGER NOT NULL DEFAULT 0,
            negative_signals INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            deleted_at TEXT
        );

        CREATE TABLE IF NOT EXISTS posts (
            id TEXT PRIMARY KEY,
            author_id TEXT NOT NULL,
            author_display_name TEXT NOT NULL,
            space_id TEXT NOT NULL,
            text TEXT NOT NULL,
            category TEXT NOT NULL,
            reach TEXT NOT NULL,
            created_at TEXT NOT NULL,
            reactions INTEGER NOT NULL DEFAULT 0,
            quality_score REAL NOT NULL DEFAULT 0.65,
            author_trust REAL NOT NULL DEFAULT 0.72,
            report_count INTEGER NOT NULL DEFAULT 0,
            moderation_status TEXT NOT NULL DEFAULT 'visible',
            removal_reason TEXT,
            deleted_at TEXT
        );

        CREATE TABLE IF NOT EXISTS replies (
            id TEXT PRIMARY KEY,
            post_id TEXT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
            author_id TEXT NOT NULL,
            text TEXT NOT NULL,
            created_at TEXT NOT NULL,
            reactions INTEGER NOT NULL DEFAULT 0,
            author_trust REAL NOT NULL DEFAULT 0.72,
            deleted_at TEXT
        );

        CREATE TABLE IF NOT EXISTS reactions (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            target_kind TEXT NOT NULL,
            target_id TEXT NOT NULL,
            created_at TEXT NOT NULL,
            UNIQUE(user_id, target_kind, target_id)
        );

        CREATE TABLE IF NOT EXISTS reports (
            id TEXT PRIMARY KEY,
            reporter_id TEXT NOT NULL,
            target_kind TEXT NOT NULL,
            target_id TEXT NOT NULL,
            parent_post_id TEXT,
            reason TEXT NOT NULL,
            created_at TEXT NOT NULL,
            status TEXT NOT NULL,
            sla_due_at TEXT NOT NULL,
            resolved_at TEXT
        );

        CREATE TABLE IF NOT EXISTS controls (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            control_kind TEXT NOT NULL,
            target_id TEXT NOT NULL,
            created_at TEXT NOT NULL,
            UNIQUE(user_id, control_kind, target_id)
        );

        CREATE TABLE IF NOT EXISTS audit_log (
            id TEXT PRIMARY KEY,
            actor_id TEXT NOT NULL,
            action TEXT NOT NULL,
            target_kind TEXT,
            target_id TEXT,
            detail_json TEXT NOT NULL,
            created_at TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS rate_limits (
            id TEXT PRIMARY KEY,
            actor_id TEXT NOT NULL,
            action TEXT NOT NULL,
            created_at REAL NOT NULL
        );

        CREATE TABLE IF NOT EXISTS account_deletions (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            created_at TEXT NOT NULL,
            completed_at TEXT NOT NULL
        );
        """
    )


def ensure_user(conn, user_id, display_name=None):
    row = conn.execute("SELECT id, deleted_at FROM users WHERE id = ?", (user_id,)).fetchone()
    if row:
        return row
    conn.execute(
        """
        INSERT INTO users(id, display_name, trust_score, helpful_actions, negative_signals, created_at)
        VALUES (?, ?, 0.72, 8, 1, ?)
        """,
        (user_id, display_name or "Du im Kiez", now_iso()),
    )
    audit(conn, user_id, "user.created", "user", user_id, {})
    return conn.execute("SELECT id, deleted_at FROM users WHERE id = ?", (user_id,)).fetchone()


def require_active_user(conn, user_id):
    row = ensure_user(conn, user_id)
    if row["deleted_at"]:
        raise ApiError(
            410,
            "account_deleted",
            "Dieser Account wurde geloescht. Bitte mit einer neuen lokalen Identitaet fortfahren.",
        )
    return row


def seed_data(conn):
    ensure_user(conn, "demo-user", "Du im Kiez")
    count = conn.execute("SELECT COUNT(*) AS count FROM posts").fetchone()["count"]
    if count:
        return

    seed_users = [
        ("author-cafe", "Kiezio Nachbar", 0.78),
        ("author-events", "Event Scout", 0.81),
        ("author-bike", "Werkbank", 0.70),
        ("author-transit", "Pendlerblick", 0.83),
        ("author-running", "Laufgruppe", 0.76),
        ("author-humor", "Kiezmoment", 0.66),
    ]
    for user_id, display_name, trust in seed_users:
        conn.execute(
            """
            INSERT OR IGNORE INTO users(id, display_name, trust_score, helpful_actions, negative_signals, created_at)
            VALUES (?, ?, ?, 0, 0, ?)
            """,
            (user_id, display_name, trust, now_iso()),
        )

    now = datetime.now(timezone.utc)
    posts = [
        ("author-cafe", "author-cafe", "Kiezio Nachbar", "questions", "Kennt jemand ein gutes Cafe zum Arbeiten in der Naehe? Ruhig, gutes WLAN und nicht zu voll waere perfekt.", "Fragen", "Bezirk", -900, 12, 0.84, 0.78),
        ("author-events", "author-events", "Event Scout", "events", "Heute Abend kleiner Flohmarkt im Kiez, ab 18 Uhr im Innenhof bei der alten Druckerei.", "Events", "N\u00e4he", -2600, 21, 0.79, 0.81),
        ("author-bike", "author-bike", "Werkbank", "recommendations", "Hat jemand Erfahrungen mit Fahrradwerkstatt XY? Suche faire Preise fuer eine Schaltungseinstellung.", "Empfehlungen", "Stadt", -5600, 8, 0.68, 0.70),
        ("author-transit", "author-transit", "Pendlerblick", "mobility", "Achtung: S-Bahn faellt teilweise aus. Zwischen Hauptbahnhof und Ostkreuz faehrt gerade Ersatzverkehr.", "Warnungen", "Stadt", -1400, 34, 0.91, 0.83),
        ("author-running", "author-running", "Laufgruppe", "help", "Suche jemanden fuer eine lockere Laufgruppe, 5 km, eher entspannt als Leistungssport.", "Hilfe", "Bezirk", -9200, 17, 0.74, 0.76),
        ("author-humor", "author-humor", "Kiezmoment", "area", "Der Moment, wenn man nur kurz Broetchen holen will und mit drei Nachbarschaftsnews zurueckkommt.", "Humor", "N\u00e4he", -7200, 29, 0.62, 0.66),
    ]
    post_ids = {}
    for stable_id, author_id, author_name, space_id, text, category, reach, offset, reactions, quality, trust in posts:
        post_id = new_id()
        post_ids[stable_id] = post_id
        created_at = (now + timedelta(seconds=offset)).isoformat().replace("+00:00", "Z")
        conn.execute(
            """
            INSERT INTO posts(id, author_id, author_display_name, space_id, text, category, reach, created_at, reactions, quality_score, author_trust)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (post_id, author_id, author_name, space_id, text, category, reach, created_at, reactions, quality, trust),
        )

    replies = [
        (post_ids["author-cafe"], "author-events", "Das kleine Cafe am Markt ist morgens super ruhig. Nach 15 Uhr wird es voller.", -420, 5, 0.86),
        (post_ids["author-transit"], "author-bike", "Bus 142 ist gerade die schnellste Alternative.", -800, 9, 0.88),
    ]
    for post_id, author_id, text, offset, reactions, trust in replies:
        created_at = (now + timedelta(seconds=offset)).isoformat().replace("+00:00", "Z")
        conn.execute(
            """
            INSERT INTO replies(id, post_id, author_id, text, created_at, reactions, author_trust)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            (new_id(), post_id, author_id, text, created_at, reactions, trust),
        )
    audit(conn, "system", "seed.created", "system", None, {"posts": len(posts)})


def audit(conn, actor_id, action, target_kind=None, target_id=None, detail=None):
    conn.execute(
        """
        INSERT INTO audit_log(id, actor_id, action, target_kind, target_id, detail_json, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        """,
        (new_id(), actor_id, action, target_kind, target_id, json.dumps(detail or {}, sort_keys=True), now_iso()),
    )


def moderation_result(text):
    normalized = text.lower()
    blocked = ["idiot", "arsch", "hass", "dummkopf"]
    threats = ["ich finde dich", "ich mache dich fertig", "du wirst sehen", "drohung", "schlag dich"]
    privacy = ["adresse", "telefonnummer", "handynummer", "wohnort", "wohnt in", "klarname"]
    sexual = ["nacktbild", "sexuell", "belästige", "belaestige"]
    repeated_links = normalized.count("http")

    if any(term in normalized for term in threats):
        return {"isFlagged": True, "reason": "Drohung", "severity": 0.94}
    if any(term in normalized for term in privacy) or any(ch.isdigit() for ch in normalized) and len([ch for ch in normalized if ch.isdigit()]) >= 8:
        return {"isFlagged": True, "reason": "Private Daten", "severity": 0.86}
    if any(term in normalized for term in sexual):
        return {"isFlagged": True, "reason": "Sexuelle Belaestigung", "severity": 0.88}
    if any(term in normalized for term in blocked):
        return {"isFlagged": True, "reason": "Beleidigung", "severity": 0.72}
    if repeated_links > 1 or normalized.count("!") > 6:
        return {"isFlagged": True, "reason": "Spam", "severity": 0.62}
    return {"isFlagged": False, "reason": None, "severity": 0.0}


def check_rate_limit(conn, actor_id, action, limit, window_seconds):
    cutoff = time.time() - window_seconds
    conn.execute("DELETE FROM rate_limits WHERE created_at < ?", (cutoff - 3600,))
    count = conn.execute(
        "SELECT COUNT(*) AS count FROM rate_limits WHERE actor_id = ? AND action = ? AND created_at >= ?",
        (actor_id, action, cutoff),
    ).fetchone()["count"]
    if count >= limit:
        raise ApiError(429, "rate_limited", f"Rate limit fuer {action} erreicht.")
    conn.execute(
        "INSERT INTO rate_limits(id, actor_id, action, created_at) VALUES (?, ?, ?, ?)",
        (new_id(), actor_id, action, time.time()),
    )


def post_to_json(conn, post_row, user_id):
    replies = [
        reply_to_json(conn, reply, user_id)
        for reply in conn.execute(
            "SELECT * FROM replies WHERE post_id = ? AND deleted_at IS NULL ORDER BY created_at ASC",
            (post_row["id"],),
        ).fetchall()
    ]
    reacted = conn.execute(
        "SELECT id FROM reactions WHERE user_id = ? AND target_kind = 'post' AND target_id = ?",
        (user_id, post_row["id"]),
    ).fetchone() is not None
    return {
        "id": post_row["id"],
        "authorID": post_row["author_id"],
        "authorDisplayName": post_row["author_display_name"],
        "spaceID": post_row["space_id"],
        "text": post_row["text"],
        "category": post_row["category"],
        "reach": post_row["reach"],
        "createdAt": post_row["created_at"],
        "reactions": post_row["reactions"],
        "replies": replies,
        "qualityScore": post_row["quality_score"],
        "authorTrust": post_row["author_trust"],
        "reportCount": post_row["report_count"],
        "moderationStatus": post_row["moderation_status"],
        "removalReason": post_row["removal_reason"],
        "hasCurrentUserReacted": reacted,
    }


def reply_to_json(conn, reply_row, user_id):
    reacted = conn.execute(
        "SELECT id FROM reactions WHERE user_id = ? AND target_kind = 'reply' AND target_id = ?",
        (user_id, reply_row["id"]),
    ).fetchone() is not None
    return {
        "id": reply_row["id"],
        "text": reply_row["text"],
        "createdAt": reply_row["created_at"],
        "reactions": reply_row["reactions"],
        "authorTrust": reply_row["author_trust"],
        "hasCurrentUserReacted": reacted,
    }


def list_posts(conn, user_id):
    hidden = {
        row["target_id"]
        for row in conn.execute("SELECT target_id FROM controls WHERE user_id = ? AND control_kind = 'hide'", (user_id,))
    }
    muted = {
        row["target_id"]
        for row in conn.execute("SELECT target_id FROM controls WHERE user_id = ? AND control_kind IN ('mute', 'block')", (user_id,))
    }
    rows = conn.execute(
        """
        SELECT * FROM posts
        WHERE deleted_at IS NULL AND moderation_status != 'removed'
        ORDER BY quality_score + author_trust - CASE moderation_status WHEN 'underReview' THEN 0.7 ELSE 0 END DESC, created_at DESC
        """
    ).fetchall()
    return [
        post_to_json(conn, row, user_id)
        for row in rows
        if row["id"] not in hidden and row["author_id"] not in muted
    ]


def find_post(conn, post_id, user_id):
    row = conn.execute("SELECT * FROM posts WHERE id = ? AND deleted_at IS NULL", (post_id,)).fetchone()
    if not row:
        raise ApiError(404, "not_found", "Beitrag nicht gefunden.")
    return post_to_json(conn, row, user_id)


def create_post(conn, user_id, data):
    check_rate_limit(conn, user_id, "create_post", 5, 3600)
    text = str(data.get("text", "")).strip()
    if len(text) < 2 or len(text) > 280:
        raise ApiError(422, "invalid_text", "Beitraege muessen 2 bis 280 Zeichen haben.")

    user = conn.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
    mod = moderation_result(text)
    status = "underReview" if mod["severity"] >= 0.85 else "visible"
    post_id = new_id()
    conn.execute(
        """
        INSERT INTO posts(id, author_id, author_display_name, space_id, text, category, reach, created_at, reactions, quality_score, author_trust, moderation_status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?, ?)
        """,
        (
            post_id,
            user_id,
            user["display_name"],
            data.get("spaceID", "area"),
            text,
            data.get("category", "Fragen"),
            data.get("reach", "Bezirk"),
            now_iso(),
            max(0.45, user["trust_score"]),
            user["trust_score"],
            status,
        ),
    )
    audit(conn, user_id, "post.created", "post", post_id, {"moderation": mod})
    return find_post(conn, post_id, user_id)


def add_reply(conn, user_id, post_id, data):
    check_rate_limit(conn, user_id, "create_reply", 20, 3600)
    text = str(data.get("text", "")).strip()
    if len(text) < 2 or len(text) > 280:
        raise ApiError(422, "invalid_text", "Antworten muessen 2 bis 280 Zeichen haben.")
    if not conn.execute("SELECT id FROM posts WHERE id = ? AND deleted_at IS NULL", (post_id,)).fetchone():
        raise ApiError(404, "not_found", "Beitrag nicht gefunden.")
    user = conn.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
    reply_id = new_id()
    mod = moderation_result(text)
    conn.execute(
        """
        INSERT INTO replies(id, post_id, author_id, text, created_at, reactions, author_trust)
        VALUES (?, ?, ?, ?, ?, 0, ?)
        """,
        (reply_id, post_id, user_id, text, now_iso(), user["trust_score"]),
    )
    conn.execute(
        "UPDATE posts SET quality_score = MIN(1, quality_score + 0.03) WHERE id = ?",
        (post_id,),
    )
    audit(conn, user_id, "reply.created", "reply", reply_id, {"postID": post_id, "moderation": mod})
    return find_post(conn, post_id, user_id)


def toggle_reaction(conn, user_id, target_kind, target_id):
    check_rate_limit(conn, user_id, "toggle_reaction", 120, 3600)
    existing = conn.execute(
        "SELECT id FROM reactions WHERE user_id = ? AND target_kind = ? AND target_id = ?",
        (user_id, target_kind, target_id),
    ).fetchone()
    table = "posts" if target_kind == "post" else "replies"
    if existing:
        conn.execute("DELETE FROM reactions WHERE id = ?", (existing["id"],))
        conn.execute(f"UPDATE {table} SET reactions = MAX(0, reactions - 1) WHERE id = ?", (target_id,))
        action = "reaction.removed"
    else:
        conn.execute(
            "INSERT INTO reactions(id, user_id, target_kind, target_id, created_at) VALUES (?, ?, ?, ?, ?)",
            (new_id(), user_id, target_kind, target_id, now_iso()),
        )
        conn.execute(f"UPDATE {table} SET reactions = reactions + 1 WHERE id = ?", (target_id,))
        if target_kind == "post":
            conn.execute("UPDATE posts SET quality_score = MIN(1, quality_score + 0.02) WHERE id = ?", (target_id,))
        action = "reaction.added"
    audit(conn, user_id, action, target_kind, target_id, {})


def create_report(conn, user_id, data):
    check_rate_limit(conn, user_id, "report", 30, 3600)
    target_kind = data.get("targetKind", "post")
    target_id = data.get("targetID")
    reason = data.get("reason", "Spam")
    parent_post_id = data.get("parentPostID")
    if not target_id:
        raise ApiError(422, "invalid_target", "Meldeziel fehlt.")
    status = "visibleLimited" if reason in ["Bel\u00e4stigung", "Hate Speech", "Sexuelle Bel\u00e4stigung", "Datenschutz"] or target_kind == "videoCall" else "queued"
    report_id = new_id()
    conn.execute(
        """
        INSERT INTO reports(id, reporter_id, target_kind, target_id, parent_post_id, reason, created_at, status, sla_due_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (report_id, user_id, target_kind, target_id, parent_post_id, reason, now_iso(), status, iso_in(24 if status == "visibleLimited" else 72)),
    )
    if target_kind == "post":
        conn.execute("UPDATE posts SET report_count = report_count + 1 WHERE id = ?", (target_id,))
        count = conn.execute("SELECT report_count FROM posts WHERE id = ?", (target_id,)).fetchone()["report_count"]
        if status == "visibleLimited" or count >= 2:
            conn.execute("UPDATE posts SET moderation_status = 'underReview' WHERE id = ?", (target_id,))
        if count >= 4:
            conn.execute(
                "UPDATE posts SET moderation_status = 'removed', removal_reason = ? WHERE id = ?",
                (f"Dieser Beitrag wurde nach mehreren Meldungen wegen {reason} entfernt.", target_id),
            )
            conn.execute("UPDATE reports SET status = 'removed' WHERE id = ?", (report_id,))
    audit(conn, user_id, "report.created", target_kind, target_id, {"reason": reason, "status": status})
    return report_to_json(conn.execute("SELECT * FROM reports WHERE id = ?", (report_id,)).fetchone())


def report_to_json(row):
    return {
        "id": row["id"],
        "targetKind": row["target_kind"],
        "targetID": row["target_id"],
        "parentPostID": row["parent_post_id"],
        "reason": row["reason"],
        "createdAt": row["created_at"],
        "status": row["status"],
        "slaDueAt": row["sla_due_at"],
        "resolvedAt": row["resolved_at"],
    }


def set_control(conn, user_id, kind, target_id):
    check_rate_limit(conn, user_id, f"control_{kind}", 120, 3600)
    conn.execute(
        """
        INSERT OR IGNORE INTO controls(id, user_id, control_kind, target_id, created_at)
        VALUES (?, ?, ?, ?, ?)
        """,
        (new_id(), user_id, kind, target_id, now_iso()),
    )
    audit(conn, user_id, f"control.{kind}", "control", target_id, {})
    return {"kind": kind, "targetID": target_id}


def export_user_data(conn, user_id):
    rows = conn.execute("SELECT * FROM controls WHERE user_id = ? ORDER BY created_at DESC", (user_id,)).fetchall()
    reports = conn.execute("SELECT * FROM reports WHERE reporter_id = ? ORDER BY created_at DESC", (user_id,)).fetchall()
    audit_rows = conn.execute("SELECT * FROM audit_log WHERE actor_id = ? ORDER BY created_at DESC LIMIT 200", (user_id,)).fetchall()
    authored_posts = conn.execute("SELECT * FROM posts WHERE author_id = ? AND deleted_at IS NULL ORDER BY created_at DESC", (user_id,)).fetchall()
    return {
        "userID": user_id,
        "exportedAt": now_iso(),
        "posts": [post_to_json(conn, row, user_id) for row in authored_posts],
        "reports": [report_to_json(row) for row in reports],
        "controls": [dict(row) for row in rows],
        "auditLog": [dict(row) for row in audit_rows],
    }


def delete_account(conn, user_id):
    completed = now_iso()
    conn.execute("UPDATE users SET deleted_at = ?, display_name = 'Geloeschter Account' WHERE id = ?", (completed, user_id))
    conn.execute("UPDATE posts SET deleted_at = ? WHERE author_id = ?", (completed, user_id))
    conn.execute("UPDATE replies SET deleted_at = ? WHERE author_id = ?", (completed, user_id))
    conn.execute("DELETE FROM reactions WHERE user_id = ?", (user_id,))
    conn.execute("DELETE FROM controls WHERE user_id = ?", (user_id,))
    conn.execute(
        "INSERT INTO account_deletions(id, user_id, created_at, completed_at) VALUES (?, ?, ?, ?)",
        (new_id(), user_id, completed, completed),
    )
    audit(conn, user_id, "account.deleted", "user", user_id, {"completedAt": completed})
    return {"deleted": True, "completedAt": completed}


class ApiError(Exception):
    def __init__(self, status, code, message):
        super().__init__(message)
        self.status = status
        self.code = code
        self.message = message


class KiezioHandler(BaseHTTPRequestHandler):
    server_version = "KiezioBackend/0.1"

    def do_GET(self):
        self.handle_request("GET")

    def do_POST(self):
        self.handle_request("POST")

    def do_DELETE(self):
        self.handle_request("DELETE")

    def handle_request(self, method):
        parsed = urlparse(self.path)
        path = parsed.path.rstrip("/") or "/"
        user_id = self.headers.get("X-Kiezio-User-ID", "demo-user")
        try:
            body = self.read_json()
            with connect() as conn:
                if method == "DELETE" and path == "/me":
                    ensure_user(conn, user_id)
                elif not (method == "GET" and path == "/health"):
                    require_active_user(conn, user_id)
                result = self.route(conn, method, path, parse_qs(parsed.query), body, user_id)
            self.send_json(200, result)
        except ApiError as error:
            self.send_json(error.status, {"error": error.code, "message": error.message})
        except Exception as error:
            self.send_json(500, {"error": "internal_error", "message": str(error)})

    def route(self, conn, method, path, query, body, user_id):
        parts = [part for part in path.split("/") if part]
        if method == "GET" and path == "/health":
            return {"ok": True, "time": now_iso()}
        if method == "GET" and path == "/posts":
            return list_posts(conn, user_id)
        if method == "POST" and path == "/posts":
            return create_post(conn, user_id, body)
        if method == "POST" and len(parts) == 3 and parts[0] == "posts" and parts[2] == "reactions":
            toggle_reaction(conn, user_id, "post", parts[1])
            return find_post(conn, parts[1], user_id)
        if method == "POST" and len(parts) == 3 and parts[0] == "posts" and parts[2] == "replies":
            return add_reply(conn, user_id, parts[1], body)
        if method == "POST" and len(parts) == 5 and parts[0] == "posts" and parts[2] == "replies" and parts[4] == "reactions":
            toggle_reaction(conn, user_id, "reply", parts[3])
            return find_post(conn, parts[1], user_id)
        if method == "POST" and path == "/reports":
            return create_report(conn, user_id, body)
        if method == "GET" and path == "/moderation/reports":
            rows = conn.execute("SELECT * FROM reports ORDER BY created_at DESC").fetchall()
            return {"reports": [report_to_json(row) for row in rows], "count": len(rows)}
        if method == "POST" and path == "/controls":
            return set_control(conn, user_id, body.get("kind", "hide"), body.get("targetID"))
        if method == "GET" and path == "/me/export":
            return export_user_data(conn, user_id)
        if method == "DELETE" and path == "/me":
            return delete_account(conn, user_id)
        if method == "GET" and path == "/audit":
            rows = conn.execute("SELECT * FROM audit_log ORDER BY created_at DESC LIMIT 200").fetchall()
            return {"auditLog": [dict(row) for row in rows]}
        raise ApiError(404, "not_found", "Endpoint nicht gefunden.")

    def read_json(self):
        length = int(self.headers.get("Content-Length", "0"))
        if length == 0:
            return {}
        raw = self.rfile.read(length)
        return json.loads(raw.decode("utf-8"))

    def send_json(self, status, payload):
        data = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, format, *args):
        print("%s - %s" % (self.address_string(), format % args))


def run_server(host="127.0.0.1", port=8787, db_path=DEFAULT_DB_PATH):
    initialize_database(db_path)
    server = ThreadingHTTPServer((host, port), KiezioHandler)
    print(f"Kiezio backend listening on http://{host}:{port} using {DATABASE_PATH}")
    server.serve_forever()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8787)
    parser.add_argument("--db", default=str(DEFAULT_DB_PATH))
    args = parser.parse_args()
    run_server(args.host, args.port, Path(args.db))


if __name__ == "__main__":
    main()
