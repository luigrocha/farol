#!/usr/bin/env bash
set -euo pipefail

FLUTTER=/Users/lgrocha/development/flutter/bin/flutter
DART=/Users/lgrocha/development/flutter/bin/dart

echo "==> Clean"
$FLUTTER clean

echo "==> Pub get"
$FLUTTER pub get

echo "==> Build runner"
$DART run build_runner build --delete-conflicting-outputs

echo "==> Flutter build web (html renderer)"
$FLUTTER build web --release --web-renderer html \
  --dart-define=SUPABASE_URL=https://placeholder.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=placeholder

echo "==> Build succeeded"
