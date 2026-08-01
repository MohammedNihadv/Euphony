import os
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageEnhance

def get_font(name, size):
    font_paths = [
        f"C:\\Windows\\Fonts\\{name}",
        "C:\\Windows\\Fonts\\segoeuib.ttf",
        "C:\\Windows\\Fonts\\segoeui.ttf",
        "C:\\Windows\\Fonts\\arialbd.ttf",
        "C:\\Windows\\Fonts\\arial.ttf",
    ]
    for fp in font_paths:
        if os.path.exists(fp):
            try:
                return ImageFont.truetype(fp, size)
            except Exception:
                continue
    return ImageFont.load_default()

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
    
    # Elegant sleek dark bezel with subtle highlight
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
    height = 1080
    
    # 1. Velvety Obsidian-Indigo background with ambient glowing lights
    banner = Image.new("RGBA", (width, height), (10, 10, 16, 255))
    draw = ImageDraw.Draw(banner)
    
    for y in range(height):
        for x in range(width):
            # Top-left purple/violet ambient glow
            d1 = math.hypot(x - 250, y - 250)
            g1 = max(0, 1.0 - d1 / 850.0) ** 1.5
            
            # Center-right golden/warm ambient glow behind phones
            d2 = math.hypot(x - 1300, y - 550)
            g2 = max(0, 1.0 - d2 / 950.0) ** 1.8
            
            # Bottom-right violet glow
            d3 = math.hypot(x - 1700, y - 900)
            g3 = max(0, 1.0 - d3 / 800.0) ** 1.5
            
            r = int(10 + g1 * 65 + g2 * 45 + g3 * 35)
            g = int(10 + g1 * 25 + g2 * 30 + g3 * 20)
            b = int(16 + g1 * 110 + g2 * 25 + g3 * 90)
            banner.putpixel((x, y), (min(255, r), min(255, g), min(255, b), 255))
            
    # 2. Left Side Branding
    font_title = get_font("segoeuib.ttf", 96)
    font_sub = get_font("segoeui.ttf", 34)
    font_quote = get_font("segoeui.ttf", 28)
    font_badge = get_font("segoeuib.ttf", 20)
    
    left_margin = 130
    top_margin = 240
    
    # App Icon with luminous aura
    icon_path = "assets/app_icon.png"
    if not os.path.exists(icon_path):
        icon_path = "assets/images/app.icon.png"
    if os.path.exists(icon_path):
        app_icon = Image.open(icon_path).convert("RGBA")
        app_icon = app_icon.resize((136, 136), Image.Resampling.LANCZOS)
        icon_shadow = add_shadow(app_icon, offset=(0, 10), blur_radius=25, shadow_color=(106, 75, 232, 160))
        banner.paste(icon_shadow, (left_margin - 25, top_margin - 25), icon_shadow)
    
    # Title: Euphony
    title_y = top_margin + 160
    draw.text((left_margin, title_y), "Euphony", font=font_title, fill=(255, 255, 255, 255))
    
    # Subtitle
    sub_y = title_y + 125
    draw.text((left_margin, sub_y), "Open Source Neo-Brutalist Music Player", font=font_sub, fill=(215, 210, 235, 255))
    
    # Tagline
    quote_y = sub_y + 60
    draw.text((left_margin, quote_y), '"Music deserves better than interruptions."', font=font_quote, fill=(175, 160, 230, 255))
    
    # Badges
    badges = [
        ("Flutter 3.44+", (106, 75, 232), (255, 255, 255)),
        ("Light & Dark Mode", (245, 197, 24), (20, 20, 25)),
        ("GPL-3.0 License", (38, 38, 50), (220, 220, 235))
    ]
    
    bx = left_margin
    by = quote_y + 80
    for text, bg_color, text_color in badges:
        bbox = font_badge.getbbox(text)
        tw = bbox[2] - bbox[0]
        th = bbox[3] - bbox[1]
        pw = tw + 36
        ph = 42
        draw.rounded_rectangle((bx, by, bx + pw, by + ph), radius=21, fill=bg_color, outline=(255, 255, 255, 30), width=1)
        draw.text((bx + 18, by + 9), text, font=font_badge, fill=text_color)
        bx += pw + 16
        
    # 3. Right Side: 4 Real Phone Mockups (All 4 different screens: Home, Library, Search, Settings - Dark/Light alternating!)
    screenshots = [
        ("docs/screenshots/dark_mode/home.jpg", 325, 80),        # Dark Home (back left)
        ("docs/screenshots/light_mode/library.jpg", 325, 190),   # Light Library (front middle-left)
        ("docs/screenshots/dark_mode/search.jpg", 325, 120),     # Dark Search (back middle-right)
        ("docs/screenshots/light_mode/settings.jpg", 325, 230)   # Light Settings (front right)
    ]
    
    start_x = 730
    spacing = 265
    
    for i, (path, w, y_offset) in enumerate(screenshots):
        phone = make_phone_mockup(path, target_width=w)
        phone_with_shadow = add_shadow(phone, offset=(18, 32), blur_radius=50, shadow_color=(0, 0, 0, 230))
        px = start_x + i * spacing
        py = y_offset
        banner.paste(phone_with_shadow, (px, py), phone_with_shadow)
        
    out_dir = "docs/screenshots"
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, "banner.png")
    banner.save(out_path, "PNG", quality=95)
    print(f"Successfully generated banner at {out_path}")

if __name__ == "__main__":
    generate_banner()
