import os
import math
from PIL import Image, ImageDraw, ImageFilter

def create_rounded_mask(size, radius):
    mask = Image.new('L', size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size[0], size[1]), radius=radius, fill=255)
    return mask

def make_phone_mockup(img_path, target_width=330, corner_radius=32, border_width=10):
    if not os.path.exists(img_path):
        print(f"Warning: Missing screenshot {img_path}")
        return Image.new("RGBA", (target_width, int(target_width * 2.1)), (50, 50, 50, 255))

    img = Image.open(img_path).convert("RGBA")
    aspect = img.height / img.width
    target_height = int(target_width * aspect)
    img = img.resize((target_width, target_height), Image.Resampling.LANCZOS)

    frame_w = target_width + border_width * 2
    frame_h = target_height + border_width * 2

    frame = Image.new("RGBA", (frame_w, frame_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(frame)

    draw.rounded_rectangle(
        (0, 0, frame_w - 1, frame_h - 1),
        radius=corner_radius + border_width,
        fill=(18, 18, 24, 255),
        outline=(85, 75, 115, 255),
        width=2
    )

    screen_mask = create_rounded_mask((target_width, target_height), corner_radius)
    frame.paste(img, (border_width, border_width), screen_mask)

    # Speaker earpiece
    earpiece_w = 44
    earpiece_h = 4
    ex = (frame_w - earpiece_w) // 2
    ey = border_width // 2
    draw.rounded_rectangle((ex, ey, ex + earpiece_w, ey + earpiece_h), radius=2, fill=(50, 50, 65, 255))

    return frame

def add_shadow(img, offset=(18, 30), blur_radius=45, shadow_color=(0, 0, 0, 215)):
    total_w = img.width + abs(offset[0]) + blur_radius * 2
    total_h = img.height + abs(offset[1]) + blur_radius * 2

    shadow = Image.new("RGBA", (total_w, total_h), (0, 0, 0, 0))
    shadow_mask = Image.new("RGBA", (img.width, img.height), shadow_color)

    sx = blur_radius + max(0, offset[0])
    sy = blur_radius + max(0, offset[1])
    shadow.paste(shadow_mask, (sx, sy), img.split()[3])
    shadow = shadow.filter(ImageFilter.GaussianBlur(blur_radius))

    ix = blur_radius + max(0, -offset[0])
    iy = blur_radius + max(0, -offset[1])
    shadow.paste(img, (ix, iy), img)

    return shadow

def generate_banner():
    width = 1920
    height = 960  # Slightly shorter — phones fill the whole frame cleanly

    # === Background: velvety obsidian-indigo with ambient glowing lights ===
    banner = Image.new("RGBA", (width, height), (10, 10, 16, 255))

    for y in range(height):
        for x in range(width):
            # Left violet glow
            d1 = math.hypot(x - 100, y - height * 0.5)
            g1 = max(0, 1.0 - d1 / 900.0) ** 1.8

            # Center-top warm purple glow
            d2 = math.hypot(x - width * 0.5, y - height * 0.2)
            g2 = max(0, 1.0 - d2 / 850.0) ** 2.0

            # Right deep violet glow
            d3 = math.hypot(x - width * 0.95, y - height * 0.7)
            g3 = max(0, 1.0 - d3 / 750.0) ** 1.8

            r = int(10 + g1 * 55 + g2 * 50 + g3 * 40)
            g = int(10 + g1 * 20 + g2 * 25 + g3 * 15)
            b = int(16 + g1 * 105 + g2 * 100 + g3 * 95)
            banner.putpixel((x, y), (min(255, r), min(255, g), min(255, b), 255))

    # === 4 Phone Mockups — centered and filling the frame ===
    screenshots = [
        ("docs/screenshots/dark_mode/home.jpg",      340, 60),
        ("docs/screenshots/light_mode/library.jpg",  340, 170),
        ("docs/screenshots/dark_mode/search.jpg",    340, 100),
        ("docs/screenshots/light_mode/settings.jpg", 340, 230),
    ]

    num_phones = len(screenshots)
    phone_w_approx = 340 + 20 + 120  # phone width + border + shadow clearance
    total_phones_w = num_phones * phone_w_approx
    spacing = 270
    start_x = (width - (num_phones * spacing)) // 2

    for i, (path, w, y_offset) in enumerate(screenshots):
        phone = make_phone_mockup(path, target_width=w)
        phone_with_shadow = add_shadow(phone, offset=(16, 28), blur_radius=50, shadow_color=(0, 0, 0, 235))
        px = start_x + i * spacing
        py = y_offset
        banner.paste(phone_with_shadow, (px, py), phone_with_shadow)

    out_dir = "docs/screenshots"
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, "banner.png")
    banner.save(out_path, "PNG")
    print(f"Successfully generated banner at {out_path}")

if __name__ == "__main__":
    generate_banner()
