#!/usr/bin/env python3
"""Збирає index.html з src/index.html: кожен рядок <div data-include="src/..."></div>
замінюється вмістом файлу (рекурсивно). JS і CSS лишаються окремими файлами (<script src>/<link>).

Запуск:  python3 build.py
Редагуйте файли в src/, потім перезбирайте. index.html у корені — згенерований, руками не правити.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.abspath(__file__))
TEMPLATE = os.path.join(ROOT, 'src', 'index.html')
OUTPUT = os.path.join(ROOT, 'index.html')
INCLUDE = re.compile(r'^([ \t]*)<div data-include="([^"]+)"></div>[ \t]*$')


def expand(path, stack=()):
    if path in stack:
        sys.exit('build.py: циклічний include: ' + ' -> '.join(stack + (path,)))
    with open(os.path.join(ROOT, path), encoding='utf-8') as f:
        text = f.read()
    out = []
    for line in text.split('\n'):
        m = INCLUDE.match(line)
        if not m:
            out.append(line)
            continue
        inc = m.group(2)
        if not os.path.isfile(os.path.join(ROOT, inc)):
            sys.exit('build.py: файл не знайдено: %s (у %s)' % (inc, path))
        body = expand(inc, stack + (path,))
        if body.endswith('\n'):
            body = body[:-1]
        out.append(body)
    return '\n'.join(out)


def main():
    html = expand(os.path.relpath(TEMPLATE, ROOT))
    with open(OUTPUT, 'w', encoding='utf-8') as f:
        f.write(html)
    print('index.html зібрано (%d KB)' % (len(html.encode('utf-8')) // 1024))


if __name__ == '__main__':
    main()
