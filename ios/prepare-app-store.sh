#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo 'Uso: bash ios/prepare-app-store.sh NUMERO_DO_BUILD [VERSAO]'
  echo 'Confira no App Store Connect o maior número de build já enviado e use um maior.'
  echo 'A versão padrão é 1.0.0, correspondente à versão 1.0 da ficha atual.'
}

if [[ ${1:-} == --help ]]; then
  usage
  exit 0
fi

build_number=${1:-}
version=${2:-1.0.0}
if [[ $# -gt 2 || ! $build_number =~ ^[1-9][0-9]*$ || ! $version =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
  usage >&2
  exit 2
fi

if [[ $(uname -s) != Darwin ]]; then
  echo 'Execute este script no Mac com Xcode, Flutter e CocoaPods instalados.' >&2
  exit 1
fi

cd "$(dirname "$0")/.."
for tool in flutter pod xcodebuild; do
  command -v "$tool" >/dev/null || { echo "Comando indisponível: $tool" >&2; exit 1; }
done
xcodebuild -version
xcrun --sdk iphoneos --show-sdk-version

release_dir="$PWD/build/app-store/$version-$build_number"
archive="$release_dir/AgsurPainel.xcarchive"
if [[ -e $release_dir ]]; then
  echo "Já existe uma saída em $release_dir. Confira o resultado ou escolha outro número de build." >&2
  exit 1
fi

defines=(--dart-define=APP_ENV=production "--dart-define=APP_RELEASE=agsur-painel@$(git rev-parse --short HEAD)")
if [[ -n ${SUPABASE_URL:-} && -n ${SUPABASE_ANON_KEY:-} ]]; then
  defines+=("--dart-define=SUPABASE_URL=$SUPABASE_URL" "--dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY")
elif [[ -n ${SUPABASE_URL:-} || -n ${SUPABASE_ANON_KEY:-} ]]; then
  echo 'Defina SUPABASE_URL e SUPABASE_ANON_KEY juntas, ou use a configuração padrão do app.' >&2
  exit 1
fi
if [[ -n ${SENTRY_DSN:-} ]]; then
  defines+=("--dart-define=SENTRY_DSN=$SENTRY_DSN")
fi

flutter pub get
flutter build ios --release --no-codesign --build-name="$version" \
  --build-number="$build_number" "${defines[@]}"

mkdir -p "$release_dir"
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$archive" \
  -allowProvisioningUpdates DEVELOPMENT_TEAM=XYYV8DTFFV CODE_SIGN_STYLE=Automatic archive

app_plist="$archive/Products/Applications/Runner.app/Info.plist"
if [[ $(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app_plist") != com.agsur.painel ||
      $(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$app_plist") != "$build_number" ||
      $(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app_plist") != "$version" ]]; then
  echo 'O archive gerado não corresponde ao bundle, versão ou build solicitados.' >&2
  exit 1
fi

echo "Archive pronto: $archive"
echo 'No Xcode Organizer, escolha Distribute App > App Store Connect > Upload.'
open "$archive"
