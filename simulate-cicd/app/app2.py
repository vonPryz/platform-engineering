# app2.py  (v1.1.0 - known bad. Fixed docs, but bug introduced)

def add(a: int, b: int) -> int:
    """Return the sum of a and b.

    BUG in v1.1.0: off-by-one.
    """
    return a + b + 1
