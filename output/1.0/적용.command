#!/bin/zsh
set -euo pipefail
cd -- "${0:A:h}"
path=(/opt/homebrew/bin /usr/local/bin $path)
command -v xdelta3 >/dev/null 2>&1 || { print 'xdelta3가 필요합니다. Homebrew: brew install xdelta'; exit 1; }
source_iso="${1:-}"
result_iso="${2:-}"
if [[ -z "$source_iso" ]]; then
  print '일본판 지온독립전쟁기 본편 원본 ISO의 전체 경로를 입력하세요:'
  read -r source_iso
fi
if [[ -z "$result_iso" ]]; then
  print '새 결과 ISO의 전체 경로를 입력하세요 (기존 파일 덮어쓰기 금지):'
  read -r result_iso
fi
[[ -f "$source_iso" ]] || { print '원본 ISO를 찾을 수 없습니다.'; exit 1; }
[[ -n "$result_iso" && ! -e "$result_iso" && ! -L "$result_iso" ]] || { print '결과 경로가 비어 있거나 이미 존재합니다.'; exit 1; }
source_sha=$(shasum -a 256 "$source_iso" | awk '{print $1}')
[[ "$source_sha" == '2c120554db2c93725f8eefda17f4c1a6fa80218bb546bf25ec9438d3208c91ef' ]] || { print '지원 원본 SHA-256과 다릅니다. 일본판 본편 원본 ISO에 적용하세요.'; exit 1; }
shasum -a 256 -c SHA256SUMS.txt
patch_tmp=$(mktemp "${TMPDIR:-/tmp}/giren-1.0-patch.XXXXXX")
result_tmp=''
trap 'rm -f -- "$patch_tmp"; if [[ -n "$result_tmp" ]]; then rm -f -- "$result_tmp"; fi' EXIT
cat SLPS-25120_ko_v1.0.xdelta.part01 SLPS-25120_ko_v1.0.xdelta.part02 SLPS-25120_ko_v1.0.xdelta.part03 > "$patch_tmp"
patch_sha=$(shasum -a 256 "$patch_tmp" | awk '{print $1}')
[[ "$patch_sha" == '0f0fce9cbdf47f34356aa7d60930f991ce4d0e0c2d9b023573eea430ea18d9e9' ]] || { print '패치 조각의 결합 SHA-256이 다릅니다.'; exit 1; }
result_tmp=$(mktemp "${result_iso}.partial.XXXXXX")
xdelta3 -d -c -s "$source_iso" "$patch_tmp" > "$result_tmp"
result_sha=$(shasum -a 256 "$result_tmp" | awk '{print $1}')
[[ "$result_sha" == 'd98b198cd9b8e88f6300c22bb3bf7d2d84b2ed0a748396dbf677bda32dad99c1' ]] || { print '결과 SHA-256이 다릅니다. 적용을 중단합니다.'; exit 1; }
ln -- "$result_tmp" "$result_iso"
print 'ver.1.0 적용 완료. 결과 ISO의 SHA-256이 일치합니다.'
