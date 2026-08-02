from pathlib import Path
p = Path('lib/screens/vendor_registration_screen.dart')
text = p.read_text(encoding='utf-16', errors='replace')
Path('vendor_registration_dump.txt').write_text(text, encoding='utf-8')
print('dumped')
