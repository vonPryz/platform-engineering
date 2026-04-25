# test_app.py
# A simple tester. Will catch the addition bug introduced in app2.py / v 1.1.0

from app import add


def test_add_basic():
    assert add(1, 1) == 2
