import os, glob

replacements = {
    "tealPrimary": "primary",
    "teal50": "primary50",
    "teal100": "primary100",
    "teal200": "primary200",
    "teal400": "primary400",
    "teal800": "primary800",
    "teal900": "primary900",
    "AppColors.orange": "AppColors.accent",
    "AppColors.purple": "AppColors.accent",
    "purple200": "accent200",
}

count = 0
for filepath in glob.glob('lib/**/*.dart', recursive=True):
    with open(filepath, 'r') as f:
        content = f.read()
    
    new_content = content
    for old, new in replacements.items():
        new_content = new_content.replace(old, new)
        
    if new_content != content:
        with open(filepath, 'w') as f:
            f.write(new_content)
        count += 1
        print(f"Updated {filepath}")
print(f"Total files updated: {count}")
