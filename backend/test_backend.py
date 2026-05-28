#!/usr/bin/env python3
import json
import tempfile
import threading
import time
import unittest
import urllib.error
import urllib.request
from pathlib import Path

import kiezio_backend


class BackendTestCase(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp_dir = tempfile.TemporaryDirectory()
        cls.db_path = Path(cls.temp_dir.name) / "test.sqlite3"
        cls.port = 8791
        cls.thread = threading.Thread(
            target=kiezio_backend.run_server,
            kwargs={"host": "127.0.0.1", "port": cls.port, "db_path": cls.db_path},
            daemon=True,
        )
        cls.thread.start()
        cls.base_url = f"http://127.0.0.1:{cls.port}"
        for _ in range(40):
            try:
                cls.request("GET", "/health")
                return
            except Exception:
                time.sleep(0.1)
        raise RuntimeError("Backend did not start")

    @classmethod
    def tearDownClass(cls):
        cls.temp_dir.cleanup()

    @classmethod
    def request(cls, method, path, body=None, user_id="test-user"):
        data = None
        headers = {"X-Kiezio-User-ID": user_id}
        if body is not None:
            data = json.dumps(body).encode("utf-8")
            headers["Content-Type"] = "application/json"
        req = urllib.request.Request(cls.base_url + path, data=data, headers=headers, method=method)
        with urllib.request.urlopen(req, timeout=5) as response:
            return json.loads(response.read().decode("utf-8"))

    def test_health_and_seeded_feed(self):
        health = self.request("GET", "/health")
        self.assertTrue(health["ok"])

        posts = self.request("GET", "/posts")
        self.assertGreaterEqual(len(posts), 6)
        self.assertIn("replies", posts[0])

    def test_create_react_reply_report_and_export(self):
        post = self.request(
            "POST",
            "/posts",
            {
                "text": "Welche Baeckerei hat sonntags gute Broetchen?",
                "category": "Fragen",
                "spaceID": "questions",
                "reach": "Bezirk",
            },
        )
        self.assertEqual(post["authorID"], "test-user")

        reacted = self.request("POST", f"/posts/{post['id']}/reactions")
        self.assertTrue(reacted["hasCurrentUserReacted"])

        replied = self.request("POST", f"/posts/{post['id']}/replies", {"text": "Die am Markt ist ab 8 Uhr offen."})
        self.assertEqual(len(replied["replies"]), 1)

        reply_id = replied["replies"][0]["id"]
        reply_reacted = self.request("POST", f"/posts/{post['id']}/replies/{reply_id}/reactions")
        self.assertTrue(reply_reacted["replies"][0]["hasCurrentUserReacted"])

        report = self.request(
            "POST",
            "/reports",
            {"targetKind": "reply", "targetID": reply_id, "parentPostID": post["id"], "reason": "Spam"},
        )
        self.assertEqual(report["targetKind"], "reply")

        video_report = self.request(
            "POST",
            "/reports",
            {"targetKind": "videoCall", "targetID": post["id"], "parentPostID": post["id"], "reason": "Belästigung"},
        )
        self.assertEqual(video_report["status"], "visibleLimited")

        export = self.request("GET", "/me/export")
        self.assertEqual(export["userID"], "test-user")
        self.assertGreaterEqual(len(export["posts"]), 1)
        self.assertGreaterEqual(len(export["reports"]), 2)

    def test_controls_hide_and_account_delete(self):
        posts = self.request("GET", "/posts", user_id="control-user")
        target = posts[0]

        self.request("POST", "/controls", {"kind": "hide", "targetID": target["id"]}, user_id="control-user")
        hidden_feed = self.request("GET", "/posts", user_id="control-user")
        self.assertNotIn(target["id"], [post["id"] for post in hidden_feed])

        created = self.request(
            "POST",
            "/posts",
            {"text": "Bitte loeschen spaeter pruefen.", "category": "Fragen", "spaceID": "questions", "reach": "Bezirk"},
            user_id="delete-user",
        )
        result = self.request("DELETE", "/me", user_id="delete-user")
        self.assertTrue(result["deleted"])

        with self.assertRaises(urllib.error.HTTPError) as context:
            self.request(
                "POST",
                "/posts",
                {"text": "Darf nach Loeschung nicht entstehen.", "category": "Fragen", "spaceID": "questions", "reach": "Bezirk"},
                user_id="delete-user",
            )
        self.assertEqual(context.exception.code, 410)

        after_delete = self.request("GET", "/posts", user_id="fresh-user-after-delete")
        self.assertNotIn(created["id"], [post["id"] for post in after_delete])

    def test_rate_limit(self):
        user_id = "limited-user"
        for index in range(5):
            self.request(
                "POST",
                "/posts",
                {"text": f"Rate limit Test {index}", "category": "Fragen", "spaceID": "questions", "reach": "Bezirk"},
                user_id=user_id,
            )

        with self.assertRaises(urllib.error.HTTPError) as context:
            self.request(
                "POST",
                "/posts",
                {"text": "Ein Beitrag zu viel", "category": "Fragen", "spaceID": "questions", "reach": "Bezirk"},
                user_id=user_id,
            )
        self.assertEqual(context.exception.code, 429)


if __name__ == "__main__":
    unittest.main()
