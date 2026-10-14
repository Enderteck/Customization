import re
import os

# Path to your linked gtk-4.0 configuration
path = os.path.expanduser('~/.config/gtk-4.0/')
files = ['gtk.css', 'gtk-dark.css']

for file in files:
    filepath = os.path.join(path, file)
    if not os.path.exists(filepath): 
        continue
    
    with open(filepath, 'r') as f:
        css = f.read()
        
    # Strip the broken GNOME 50 classes
    css = re.sub(r'\.sidebar-label|\.sidebar-icon', '', css)
    
    # Fix leftover comma artifacts to prevent broken syntax blocks
    css = re.sub(r',\s*,', ',', css)         # Double commas
    css = re.sub(r',\s*\{', ' {', css)       # Trailing commas before brackets
    css = re.sub(r'^\s*,', '', css, flags=re.MULTILINE) # Leading commas on new lines
    
    with open(filepath, 'w') as f:
        f.write(css)
        
print("Orchis CSS files patched successfully!")
