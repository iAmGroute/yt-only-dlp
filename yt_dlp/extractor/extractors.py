from ..plugins import load_plugins

# NB: Must be before other imports so that plugins can be correctly injected
_PLUGIN_CLASSES = load_plugins('extractor', 'IE')

from ._extractors import *  # noqa: F403
_ALL_CLASSES = [  # noqa: F811
    klass
    for name, klass in globals().items()
    if name.endswith('IE') and name != 'GenericIE'
]

globals().update(_PLUGIN_CLASSES)
_ALL_CLASSES[:0] = _PLUGIN_CLASSES.values()

from .common import _PLUGIN_OVERRIDES  # noqa: F401
