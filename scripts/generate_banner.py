import os
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

# ─── Fonts ────────────────────────────────────────────────────────────────────
def get_font(name, size):
    candidates = [
        f"C:\\Windows\\Fonts\\{name}",
        "C:\\Windows\\Fonts\\segoeuib.ttf",
        "C:\\Windows\\Fonts\\segoeui.ttf",
        "C:\\Windows\\Fonts\\arialbd.ttf",
        "C:\\Windows\\Fonts\\arial.ttf",
    ]
    for fp in candidates:
        if os.path.exists(fp):
            try:
                return ImageFont.truetype(fp, size)
            except Exception:
                continue
    return ImageFont.load_default()

# ─── Rounded mask ─────────────────────────────────────────────────────────────
def rounded_mask(size, radius):
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, *size), radius=radius, fill=255)
    return m

# ─── Drop shadow ──────────────────────────────────────────────────────────────
def add_shadow(img, offset=(12, 24), blur=40, color=(0, 0, 0, 200)):
    W = img.width  + abs(offset[0]) + blur * 2
    H = img.height + abs(offset[1]) + blur * 2
    base = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    mask = Image.new("RGBA", (img.width, img.height), color)
    sx = blur + max(0, offset[0])
    sy = blur + max(0, offset[1])
    base.paste(mask, (sx, sy), img.split()[3])
    base = base.filter(ImageFilter.GaussianBlur(blur))
    ix = blur + max(0, -offset[0])
    iy = blur + max(0, -offset[1])
    base.paste(img, (ix, iy), img)
    return base

# ─── Reflection ───────────────────────────────────────────────────────────────
def add_reflection(phone, height_frac=0.22, fade_start=0.05):
    """Flips the bottom of the phone and fades it out — premium glass-floor look."""
    ref_h = int(phone.height * height_frac)
    strip = phone.crop((0, phone.height - ref_h, phone.width, phone.height))
    strip = strip.transpose(Image.FLIP_TOP_BOTTOM)
    # Gradient alpha mask: top=semi-visible, bottom=fully transparent
    mask = Image.new("L", strip.size, 0)
    for y in range(ref_h):
        alpha = int(55 * (1.0 - y / ref_h))
        for x in range(strip.width):
            mask.putpixel((x, y), alpha)
    strip.putalpha(mask)
    return strip

# ─── Phone mockup ─────────────────────────────────────────────────────────────
def make_phone(img_path, w=310, corner=30, bezel=9):
    if not os.path.exists(img_path):
        return Image.new("RGBA", (w, int(w * 2.1)), (30, 30, 40, 255))
    img = Image.open(img_path).convert("RGBA")
    h = int(w * img.height / img.width)
    img = img.resize((w, h), Image.Resampling.LANCZOS)

    fw, fh = w + bezel * 2, h + bezel * 2
    frame = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
    draw  = ImageDraw.Draw(frame)

    # Outer bezel — dark with subtle violet rim
    draw.rounded_rectangle(
        (0, 0, fw - 1, fh - 1),
        radius=corner + bezel,
        fill=(14, 14, 20, 255),
        outline=(90, 70, 130, 255),
        width=2,
    )
    # Screen
    frame.paste(img, (bezel, bezel), rounded_mask((w, h), corner))

    # Earpiece pill
    ew, eh = 40, 4
    ex = (fw - ew) // 2
    draw.rounded_rectangle((ex, bezel // 2, ex + ew, bezel // 2 + eh), radius=2, fill=(45, 45, 60, 255))

    return frame

# ─── Background ───────────────────────────────────────────────────────────────
def make_bg(W, H):
    img = Image.new("RGBA", (W, H), (8, 8, 14, 255))
    arr = img.load()
    glows = [
        # (cx, cy, radius, r_add, g_add, b_add, power)
        (280,  280, 920, 60, 22, 115, 1.6),   # left violet
        (W,      0, 780, 40, 15,  90, 1.8),   # top-right accent
        (W * 0.7, H * 0.6, 860, 40, 28,  30, 2.0),  # centre-right warm
        (W,    H,   650, 30, 10,  80, 2.2),   # bottom-right deep
    ]
    for y in range(H):
        for x in range(W):
            r, g, b = 8, 8, 14
            for cx, cy, rad, ra, ga, ba, pw in glows:
                d = math.hypot(x - cx, y - cy)
                t = max(0.0, 1.0 - d / rad) ** pw
                r += t * ra
                g += t * ga
                b += t * ba
            arr[x, y] = (min(255, int(r)), min(255, int(g)), min(255, int(b)), 255)
    return img

# ─── Main ─────────────────────────────────────────────────────────────────────
def generate_banner():
    W, H = 1920, 1080

    # ── Background ──────────────────────────────────────────────────
    banner = make_bg(W, H)
    draw   = ImageDraw.Draw(banner)

    # Subtle horizontal divider line (very faint)
    for x in range(W):
        alpha = int(18 * math.sin(math.pi * x / W))
        draw.point((x, H // 2), fill=(140, 110, 220, alpha))

    # ── Left branding ───────────────────────────────────────────────
    LM   = 118   # left margin
    font_h1    = get_font("segoeuib.ttf", 100)
    font_sub   = get_font("segoeui.ttf",  32)
    font_quote = get_font("segoeui.ttf",  26)
    font_badge = get_font("segoeuib.ttf", 19)

    # App icon
    icon_path = "assets/app_icon.png"
    if not os.path.exists(icon_path):
        icon_path = "assets/images/app.icon.png"
    icon_y = 200
    if os.path.exists(icon_path):
        icon = Image.open(icon_path).convert("RGBA").resize((130, 130), Image.Resampling.LANCZOS)
        shadow = add_shadow(icon, offset=(0, 12), blur=28, color=(106, 75, 232, 150))
        banner.paste(shadow, (LM - 22, icon_y - 22), shadow)

    # Title
    title_y = icon_y + 155
    draw.text((LM, title_y), "Euphony", font=font_h1, fill=(255, 255, 255, 255))

    # Subtitle
    sub_y = title_y + 118
    draw.text((LM, sub_y), "Open Source · Neo-Brutalist Music Player", font=font_sub, fill=(200, 195, 230, 255))

    # Tagline
    tag_y = sub_y + 58
    draw.text((LM, tag_y), '"Music deserves better than interruptions."', font=font_quote, fill=(160, 148, 215, 255))

    # Badge pills
    badges = [
        ("Flutter 3.44+",   (100, 70, 225),  (255, 255, 255)),
        ("Light & Dark",    (240, 193, 20),   (18,  18,  24)),
        ("GPL-3.0",         (32,  32,  44),   (210, 210, 230)),
    ]
    bx, by, bh, br = LM, tag_y + 76, 40, 20
    for label, bg, fg in badges:
        bbox = font_badge.getbbox(label)
        bw   = bbox[2] - bbox[0] + 36
        draw.rounded_rectangle((bx, by, bx + bw, by + bh), radius=br, fill=bg)
        draw.text((bx + 18, by + 8), label, font=font_badge, fill=fg)
        bx += bw + 14

    # ── Right phone showcase (3 phones, elegant cascade) ─────────────
    #  Phone sizes and vertical offsets for a cascade depth effect
    screens = [
        # (path,                                       width, y_top, shadow_alpha)
        ("docs/screenshots/dark_mode/home.jpg",        295,   95,    210),   # back-left
        ("docs/screenshots/light_mode/library.jpg",    330,   175,   230),   # front-center
        ("docs/screenshots/dark_mode/search.jpg",      295,   115,   210),   # back-right
        ("docs/screenshots/light_mode/settings.jpg",   275,   230,   220),   # far-right peek
    ]

    # Tight horizontal spacing so phones overlap slightly (depth illusion)
    rx_start = 870
    x_step   = 268

    for i, (path, pw, py, sa) in enumerate(screens):
        phone = make_phone(path, w=pw)

        # Reflections beneath each phone
        ref = add_reflection(phone, height_frac=0.18)

        # Drop shadow
        with_shadow = add_shadow(phone, offset=(14, 28), blur=52, color=(0, 0, 0, sa))

        px = rx_start + i * x_step
        banner.paste(with_shadow, (px, py), with_shadow)

        # Paste reflection directly below phone
        phone_bottom = py + phone.height
        banner.paste(ref, (px + 52, phone_bottom - 2), ref)   # 52 = shadow left offset

    # ── Save ────────────────────────────────────────────────────────
    os.makedirs("docs/screenshots", exist_ok=True)
    banner.save("docs/screenshots/banner.png", "PNG")
    print("Banner saved to docs/screenshots/banner.png")

if __name__ == "__main__":
    generate_banner()
