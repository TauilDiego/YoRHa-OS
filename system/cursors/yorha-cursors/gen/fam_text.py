"""Family B: text. The I-beam as a light plate with depth, with the four end dots as small dark
cores, like the original's dots."""
from style import Canvas, rotate_about

ATTRIBUTION = "YoRHa-OS cursor ({}). Shapes after NieR Cursors by Beinsezii (MIT)."


def _ibeam(name, deg):
    def fn():
        c = Canvas(ATTRIBUTION.format(name))
        center = (64, 64)
        w, top, bottom = 7, 20, 108
        bar = [(64 - w / 2, top), (64 + w / 2, top), (64 + w / 2, bottom), (64 - w / 2, bottom)]
        c.plate([rotate_about(p, center, deg) for p in bar])
        for x, y in ((52, 11), (76, 11), (52, 117), (76, 117)):
            c.core(rotate_about((x, y), center, deg), 5.2)
        return [(c.svg(), 0)]
    return fn


SHAPES = {
    "Selector": _ibeam("Selector", 0),
    "Selector_H": _ibeam("Selector_H", 90),
}
