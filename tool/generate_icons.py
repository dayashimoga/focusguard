import os
import struct
import zlib

def create_png(width, height, r=13, g=148, b=136, a=255): # Primary Teal: #0D9488
    # PNG signature
    png_sig = b'\x89PNG\r\n\x1a\n'
    
    # IHDR chunk
    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)
    ihdr_crc = struct.pack('>I', zlib.crc32(b'IHDR' + ihdr_data) & 0xffffffff)
    ihdr = struct.pack('>I', len(ihdr_data)) + b'IHDR' + ihdr_data + ihdr_crc
    
    # Scanlines
    raw_rows = bytearray()
    center_x = width / 2.0
    center_y = height / 2.0
    radius = min(width, height) * 0.45
    
    for y in range(height):
        raw_rows.append(0) # Filter byte 0: None
        for x in range(width):
            dx = x - center_x
            dy = y - center_y
            dist_sq = dx*dx + dy*dy
            # Draw rounded shield / circle
            if dist_sq <= radius * radius:
                # Shield background
                raw_rows.extend([r, g, b, a])
            else:
                raw_rows.extend([0, 0, 0, 0])
                
    compressed_data = zlib.compress(bytes(raw_rows))
    idat_crc = struct.pack('>I', zlib.crc32(b'IDAT' + compressed_data) & 0xffffffff)
    idat = struct.pack('>I', len(compressed_data)) + b'IDAT' + compressed_data + idat_crc
    
    # IEND chunk
    iend_crc = struct.pack('>I', zlib.crc32(b'IEND') & 0xffffffff)
    iend = struct.pack('>I', 0) + b'IEND' + iend_crc
    
    return png_sig + ihdr + idat + iend

icon_sizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

base_res = os.path.join(os.path.dirname(__file__), '..', 'android', 'app', 'src', 'main', 'res')

for folder, size in icon_sizes.items():
    dir_path = os.path.join(base_res, folder)
    os.makedirs(dir_path, exist_ok=True)
    file_path = os.path.join(dir_path, 'ic_launcher.png')
    data = create_png(size, size, 13, 148, 136, 255) # #0D9488
    with open(file_path, 'wb') as f:
        f.write(data)
    print(f"Generated {file_path} ({size}x{size})")
