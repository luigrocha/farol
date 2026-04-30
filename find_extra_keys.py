import re

def parse_map(content, lang):
    start_pattern = "'" + lang + "': {"
    start_index = content.find(start_pattern)
    if start_index == -1:
        return None
    
    langs = re.findall(r"'([a-z]{2})': \{", content)
    current_lang_index = langs.index(lang)
    
    if current_lang_index < len(langs) - 1:
        next_lang_start = content.find("'" + langs[current_lang_index+1] + "': {", start_index)
        end_index = next_lang_start
    else:
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
    keys = re.findall(r"'([^']+)'\s*:\s*(?:'[^']*'|\[)", block)
    return set(keys)

def main():
    with open('lib/core/i18n/app_localizations.dart', 'r') as f:
        content = f.read()

    en = parse_map(content, 'en')
    es = parse_map(content, 'es')
    pt = parse_map(content, 'pt')

    print("ES - EN:", es - en)
    print("PT - EN:", pt - en)
    print("EN - ES:", en - es)
    print("EN - PT:", en - pt)

if __name__ == "__main__":
    main()
