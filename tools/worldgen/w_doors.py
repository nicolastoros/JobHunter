"""Door-opening animation data for enterable buildings.

The door painted on each building is animated in the game (the leaf swings open onto a dark doorway),
so it always matches the building art. Here we only record where that door is: its rectangle inside the
building image (measured on the sprites) and in the world."""

# (x, y, w, h) of the door leaf inside the building sprite (unflipped)
DOOR_RECTS = {
    "guild_hall": (63, 101, 21, 23),
    "house_red": (88, 97, 20, 28),
    "farmhouse": (49, 81, 16, 23),
    "fish_house": (45, 73, 11, 23),
    "fish_house2": (45, 73, 11, 23),
}


def door_leaf(door):
    """(image_path, region_in_image, world_rect, flip) for a door dict from w.doors, or None."""
    prop = door.get("prop")
    key = door.get("key")
    if prop is None or key not in DOOR_RECTS:
        return None
    x, y, w, h = DOOR_RECTS[key]
    rx0, ry0, rx1, ry1 = prop["rect"]
    pw = rx1 - rx0
    flip = bool(prop.get("flip"))
    left = prop["pos"][0] - prop["origin"][0]
    top = prop["pos"][1] - prop["origin"][1]
    wx = left + (pw - (x + w) if flip else x)
    region = (rx0 + x, ry0 + y, w, h)
    return prop["image"], region, (wx, top + y, w, h), flip
