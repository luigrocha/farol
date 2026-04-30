import re

def parse_map(content, lang):
    # This is a bit hacky since it's a Dart file, not JSON
    # We want to find the block for the given lang
    # and then extract all 'key': 'value' pairs.
    
    # Find the start of the language block
    start_pattern = "'" + lang + "': {"
    start_index = content.find(start_pattern)
    if start_index == -1:
        return None
    
    # Find the end of the language block (next language block or end of map)
    # We look for the next lang block or the very last }
    
    # Let's find all language blocks
    langs = re.findall(r"'([a-z]{2})': \{", content)
    
    current_lang_index = langs.index(lang)
    
    if current_lang_index < len(langs) - 1:
        next_lang_start = content.find("'" + langs[current_lang_index+1] + "': {", start_index)
        end_index = next_lang_start
    else:
        # It's the last one, find the closing brace of the main map
        block_content = content[start_index:]
        brace_count = 0
        end_index = 0
        for i, char in enumerate(block_content):
            if char == '{':
                brace_count += 1
            elif char == '}':
                brace_count -= 1
                if brace_count == 0:
                    end_index = start_index + i + 1
                    break
    
    if end_index == 0:
        return None

    block = content[start_index:end_index]
    
    # Extract key-value pairs
    # Pattern: 'key': 'value' OR 'key': [ ... ]
    keys = re.findall(r"'([^']+)'\s*:\s*(?:'[^']*'|\[)", block)
    return set(keys)

def main():
    with open('lib/core/i18n/app_localizations.dart', 'r') as f:
        content = f.read()

    en_keys = parse_map(content, 'en')
    es_keys = parse_map(content, 'es')
    pt_keys = parse_map(content, 'pt')

    if en_keys is None:
        print("Could not parse English keys")
        return

    print(f"English keys count: {len(en_keys)}")
    
    if es_keys is not None:
        print(f"Spanish keys count: {len(es_keys)}")
        missing_in_es = en_keys - es_keys
        if missing_in_es:
            print(f"Missing in Spanish ({len(missing_in_es)}):")
            for k in sorted(missing_in_es):
                print(f"  {k}")
        else:
            print("Spanish is complete (all English keys present).")
    else:
        print("Could not parse Spanish keys")

    if pt_keys is not None:
        print(f"Portuguese keys count: {len(pt_keys)}")
        missing_in_pt = en_keys - pt_keys
        if missing_in_pt:
            print(f"Missing in Portuguese ({len(missing_in_pt)}):")
            for k in sorted(missing_in_pt):
                print(f"  {k}")
        else:
            print("Portuguese is complete (all English keys present).")
    else:
        print("Could not parse Portuguese keys")

if __name__ == "__main__":
    main()
