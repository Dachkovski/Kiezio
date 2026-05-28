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

    def test_content_moderation_appeals(self):
        # 1. Create a post as appeal-user
        post = self.request(
            "POST",
            "/posts",
            {"text": "Dieser Beitrag wird gleich mehrfach gemeldet.", "category": "Fragen", "spaceID": "questions", "reach": "Bezirk"},
            user_id="appeal-user"
        )
        post_id = post["id"]

        # 2. Denying appeal on a visible post (returns 422)
        with self.assertRaises(urllib.error.HTTPError) as context:
            self.request(
                "POST",
                f"/posts/{post_id}/appeal",
                {"appealText": "Ich moechte Einspruch einlegen."},
                user_id="appeal-user"
            )
        self.assertEqual(context.exception.code, 422)

        # 3. Report the post 4 times to get it removed automatically
        for index in range(4):
            self.request(
                "POST",
                "/reports",
                {"targetKind": "post", "targetID": post_id, "reason": "Spam"},
                user_id=f"reporter-{index}"
            )

        # Check that the post is indeed removed
        feed = self.request("GET", "/posts", user_id="some-other-user")
        self.assertNotIn(post_id, [p["id"] for p in feed])

        # 4. Denying appeal by non-author (returns 403)
        with self.assertRaises(urllib.error.HTTPError) as context:
            self.request(
                "POST",
                f"/posts/{post_id}/appeal",
                {"appealText": "Ich bin nicht der Autor aber will Einspruch."},
                user_id="intruder-user"
            )
        self.assertEqual(context.exception.code, 403)

        # 5. Successfully submit appeal by author
        appeal = self.request(
            "POST",
            f"/posts/{post_id}/appeal",
            {"appealText": "Das ist eine legitime Frage ueber meinen Kiez und kein Spam."},
            user_id="appeal-user"
        )
        self.assertEqual(appeal["status"], "pending")
        self.assertEqual(appeal["postID"], post_id)
        self.assertEqual(appeal["userID"], "appeal-user")
        appeal_id = appeal["id"]

        # 6. Block duplicate pending appeals (returns 409)
        with self.assertRaises(urllib.error.HTTPError) as context:
            self.request(
                "POST",
                f"/posts/{post_id}/appeal",
                {"appealText": "Noch ein Einspruch."},
                user_id="appeal-user"
            )
        self.assertEqual(context.exception.code, 409)

        # Verify that a normal user cannot access the moderation appeal queue.
        with self.assertRaises(urllib.error.HTTPError) as context:
            self.request("GET", "/appeals", user_id="some-other-user")
        self.assertEqual(context.exception.code, 403)

        # Verify that GET /appeals returns the appeal for moderation actors.
        all_appeals = self.request("GET", "/appeals", user_id="admin-user")
        self.assertIn(appeal_id, [a["id"] for a in all_appeals["appeals"]])

        # Verify that export_user_data contains the appeal
        export = self.request("GET", "/me/export", user_id="appeal-user")
        self.assertIn(appeal_id, [a["id"] for a in export["appeals"]])

        # Non-moderators cannot decide appeals.
        with self.assertRaises(urllib.error.HTTPError) as context:
            self.request(
                "POST",
                f"/appeals/{appeal_id}/resolve",
                {"status": "approved", "decisionNotes": "Nicht autorisierte Entscheidung."},
                user_id="some-other-user"
            )
        self.assertEqual(context.exception.code, 403)

        # 7. Resolve the appeal as approved (restores post)
        resolved = self.request(
            "POST",
            f"/appeals/{appeal_id}/resolve",
            {"status": "approved", "decisionNotes": "Nach manueller Pruefung freigegeben."},
            user_id="moderator-user"
        )
        self.assertEqual(resolved["status"], "approved")
        self.assertEqual(resolved["decisionNotes"], "Nach manueller Pruefung freigegeben.")

        # Check that post is now visible again in the feed and report count reset
        feed_after = self.request("GET", "/posts", user_id="some-other-user")
        restored_post = next((p for p in feed_after if p["id"] == post_id), None)
        self.assertIsNotNone(restored_post)
        self.assertEqual(restored_post["moderationStatus"], "visible")
        self.assertEqual(restored_post["reportCount"], 0)

        # 8. Check that account deletion deletes the appeal
        result = self.request("DELETE", "/me", user_id="appeal-user")
        self.assertTrue(result["deleted"])

        # The appeal should no longer be returned in general appeals list
        all_appeals_after = self.request("GET", "/appeals", user_id="admin-user")
        self.assertNotIn(appeal_id, [a["id"] for a in all_appeals_after["appeals"]])


if __name__ == "__main__":
    unittest.main()
