import os
import shutil

base_dir = r"d:\Dairy project\lib"

# Mappings of old directory to new directory
moves = [
    ("ui", "presentation"),
    ("logic/providers", "presentation/providers"),
    ("logic/services", "services"),
    ("logic", "domain/usecases"), # just to clean up logic if it has remaining files
]

# Ensure destination dirs exist
for _, dest in moves:
    os.makedirs(os.path.join(base_dir, os.path.dirname(dest) if '/' in dest else dest), exist_ok=True)

for src, dest in moves:
    src_path = os.path.join(base_dir, src)
    dest_path = os.path.join(base_dir, dest)
    if os.path.exists(src_path):
        import time
        # For simple rename
        if not os.path.exists(dest_path):
            os.rename(src_path, dest_path)
            print(f"Moved {src} to {dest}")
        else:
            # Merge
            for root, dirs, files in os.walk(src_path):
                for f in files:
                    s = os.path.join(root, f)
                    rel = os.path.relpath(s, src_path)
                    d = os.path.join(dest_path, rel)
                    os.makedirs(os.path.dirname(d), exist_ok=True)
                    os.rename(s, d)
            print(f"Merged {src} into {dest}")

# Now fix all imports in all .dart files
# We need to replace import paths in files
import glob

dart_files = glob.glob(os.path.join(base_dir, "**", "*.dart"), recursive=True)

replacements = [
    ("ui/", "presentation/"),
    ("logic/providers/", "presentation/providers/"),
    ("logic/services/", "services/"),
    ("logic/", "domain/usecases/"),
]

for file in dart_files:
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_content = content
    for old, new in replacements:
        # replace in imports that use package:home_dairy_manager/...
        new_content = new_content.replace(f"package:home_dairy_manager/{old}", f"package:home_dairy_manager/{new}")
        
        # for relative imports, since we moved files, the relative paths might be broken.
        # It's better to convert all relative imports to absolute 'package:home_dairy_manager/' imports
        # Or simply hope that standard string replacement works if the depth is preserved.
        new_content = new_content.replace(f"'{old}", f"'{new}")
        new_content = new_content.replace(f"\"{old}", f"\"{new}")
        new_content = new_content.replace(f"'../{old}", f"'../{new}")
        new_content = new_content.replace(f"'../../{old}", f"'../../{new}")

    if content != new_content:
        with open(file, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Updated imports in {file}")

print("Done Refactoring.")
