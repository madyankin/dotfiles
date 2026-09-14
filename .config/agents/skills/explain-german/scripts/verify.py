#!/usr/bin/env python3
"""Run schema, renderer, and offline/static checks for generated explainers."""
import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def embedded_data(text):
    start = text.index('const DATA = ') + len('const DATA = ')
    end = text.index('\n/* ============================================================================\n   RENDER', start)
    return json.loads(text[start:end].rstrip(' ;\n'))


def check_html(path):
    text = path.read_text()
    data = embedded_data(text)
    errors = []
    if re.search(r'https?://|<script[^>]+src=|<link[^>]+href=', text, re.I):
        errors.append('external dependency or URL found')
    if re.search(r'\b(TODO|FIXME|PLACEHOLDER)\b', text):
        errors.append('placeholder found')
    ids = {f['id'] for f in data['figuren']}
    mounted = [a.get('figure_id') for a in data['analyse'] if a.get('figure_id')]
    if set(mounted) != ids or len(mounted) != len(ids):
        errors.append('figures are not mounted exactly once beside analysis')
    if not any(q.get('figure_id') in ids for q in data['quiz']):
        errors.append('quiz has no question tied to a figure')
    positions = [next(i for i, o in enumerate(q['optionen']) if o['ok'])
                 for q in data['quiz'] if q['typ'] == 'wahl']
    if len(set(positions)) == 1:
        errors.append('correct choice stays in one position')
    for q in (x for x in data['quiz'] if x['typ'] == 'wahl'):
        lengths = [len(re.sub(r'<[^>]+>', '', o['t'])) for o in q['optionen']]
        correct = next(i for i, o in enumerate(q['optionen']) if o['ok'])
        others = [n for i, n in enumerate(lengths) if i != correct]
        if others and lengths[correct] > max(others) * 1.8:
            errors.append('correct option is conspicuously longer: ' + q['fokus'])
    if errors:
        raise ValueError('; '.join(errors))
    return f'{path.name}: static/offline/content links OK'


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('html', nargs='+', type=Path)
    args = ap.parse_args()
    subprocess.run([sys.executable, str(ROOT/'scripts/test_build.py')], check=True)
    for path in args.html:
        print(check_html(path))
    subprocess.run(['node', str(ROOT/'scripts/test_renderer.cjs'), *map(str, args.html)], check=True)
    print('Verifier: schema, renderer controls, quiz, and static offline checks passed.')


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, subprocess.CalledProcessError) as exc:
        raise SystemExit(f'Verification failed: {exc}')
