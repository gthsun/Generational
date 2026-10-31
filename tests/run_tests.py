#!/usr/bin/env python3
"""Run headless fixtures, treating Godot errors as failures even with exit code 0."""
import argparse
from pathlib import Path
import shutil
import subprocess
import sys


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', default=shutil.which('godot') or shutil.which('godot4'))
    parser.add_argument('--timeout', type=float, default=30)
    parser.add_argument('tests', nargs='*', help='Optional test filenames within tests/')
    args = parser.parse_args()
    if not args.godot:
        parser.error('Provide --godot /path/to/godot')
    root = Path(__file__).resolve().parent.parent
    tests = [root / 'tests' / name for name in args.tests] if args.tests else sorted((root / 'tests').glob('*test.gd'))
    if not tests:
        parser.error('No tests found')
    reports = root / 'test-results'
    reports.mkdir(exist_ok=True)
    failed = 0
    for test in tests:
        try:
            result = subprocess.run([args.godot, '--headless', '--path', str(root), '--script', str(test), '--max-fps', '120'],
                                    capture_output=True, text=True, timeout=max(args.timeout, 90) if test.name == "boss_victory_audio_test.gd" else args.timeout)
            output = result.stdout + result.stderr
            passed = result.returncode == 0 and 'PASS:' in output and 'ERROR:' not in output
        except subprocess.TimeoutExpired as error:
            output = 'TIMEOUT\n' + (error.stdout or b'').decode(errors='replace') + (error.stderr or b'').decode(errors='replace')
            passed = False
        (reports / (test.stem + '.log')).write_text(output)
        print(('PASS' if passed else 'FAIL') + ': ' + test.name, flush=True)
        if not passed:
            failed += 1
            print(output.strip(), flush=True)
    print(f'{len(tests) - failed}/{len(tests)} tests passed. Logs: {reports}')
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main())
