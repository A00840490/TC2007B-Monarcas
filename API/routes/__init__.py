import os

_DOCS_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'docs')


def doc(name):
    """Absolute path of a Swagger file in API/docs/."""
    return os.path.join(_DOCS_DIR, name)
