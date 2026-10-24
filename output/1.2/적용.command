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
patch_file='SLPS-25120_ko_v1.2.xdelta'
result_tmp=''
trap 'if [[ -n "$result_tmp" ]]; then rm -f -- "$result_tmp"; fi' EXIT
result_tmp=$(mktemp "${result_iso}.partial.XXXXXX")
xdelta3 -d -c -s "$source_iso" "$patch_file" > "$result_tmp"
result_sha=$(shasum -a 256 "$result_tmp" | awk '{print $1}')
[[ "$result_sha" == '0519b1b2a5a7bb57821349e233afdc4ccff736cd598d540a6f16a82aec66be2e' ]] || { print '결과 SHA-256이 다릅니다. 적용을 중단합니다.'; exit 1; }
ln -- "$result_tmp" "$result_iso"
print 'ver.1.2 적용 완료. 결과 ISO의 SHA-256이 일치합니다.'
