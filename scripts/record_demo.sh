#!/usr/bin/env bash
# 데모 영상 자동 녹화:
#   1) 시뮬레이터 부팅(하드웨어 키보드 끔, 상태바 고정)
#   2) simctl 녹화 시작
#   3) KnockUITests/DemoRecordingUITests 가 앱 전체 시나리오를 자동으로 조작
#   4) 녹화 종료 → ffmpeg 가 있으면 앞뒤 여백을 잘라 mp4 정리
#
# 사용법: ./scripts/record_demo.sh [출력경로.mp4]
set -euo pipefail

cd "$(dirname "$0")/.."

OUT="${1:-build/demo/knock_demo.mp4}"
DEVICE="${SIM_DEVICE:-iPhone 17}"
OS="${SIM_OS:-27.0}"

if [ -d "/Applications/Xcode-27.0-RC.app" ]; then
  DEVELOPER_DIR="/Applications/Xcode-27.0-RC.app/Contents/Developer"
else
  DEVELOPER_DIR="$(xcode-select -p)"
fi
export DEVELOPER_DIR
XCODEBUILD="$DEVELOPER_DIR/usr/bin/xcodebuild"
SIMCTL="$DEVELOPER_DIR/usr/bin/simctl"

UDID="$("$SIMCTL" list devices available -j \
  | python3 -c "import json,sys; d=json.load(sys.stdin)['devices']
for rt,devs in d.items():
    if rt.endswith('iOS-${OS//./-}'):
        for x in devs:
            if x['name']=='$DEVICE': print(x['udid']); sys.exit(0)
sys.exit(1)")"

mkdir -p "$(dirname "$OUT")"
RAW="${OUT%.mp4}.raw.mp4"

# 소프트웨어 키보드가 항상 뜨도록 하드웨어 키보드 연결 해제
defaults write com.apple.iphonesimulator ConnectHardwareKeyboard -bool false

"$SIMCTL" boot "$UDID" 2>/dev/null || true
"$SIMCTL" bootstatus "$UDID" -b
open -a Simulator --args -CurrentDeviceUDID "$UDID"
"$SIMCTL" status_bar "$UDID" override --time "9:41" --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3

# 빌드(테스트용)를 먼저 끝내 두어 녹화에 빌드 시간이 들어가지 않게 함
"$XCODEBUILD" -project Knock.xcodeproj -scheme Knock \
  -destination "id=$UDID" -derivedDataPath build \
  build-for-testing | tail -n 3

TEST_LOG="${OUT%.mp4}.test.log"
rm -f "$RAW" "$TEST_LOG"
"$XCODEBUILD" -project Knock.xcodeproj -scheme Knock \
  -destination "id=$UDID" -derivedDataPath build \
  -only-testing:KnockUITests/DemoRecordingUITests/testFullDemoFlow \
  test-without-building > "$TEST_LOG" 2>&1 &
TEST_PID=$!

# xcodebuild 는 테스트 로그를 끝나야 출력하므로, 시뮬레이터의 앱 프로세스를 기준으로 녹화 구간을 잡는다.
app_running() { pgrep -qf "/Knock.app/Knock( |$)"; }

while kill -0 "$TEST_PID" 2>/dev/null && ! app_running; do sleep 0.1; done
"$SIMCTL" io "$UDID" recordVideo --codec h264 --force "$RAW" &
REC_PID=$!

# 앱이 종료되는(=테스트가 끝나는) 즉시 녹화를 멈춰 홈 화면/진단 수집 구간이 영상에 남지 않게 함
sleep 3
while kill -0 "$TEST_PID" 2>/dev/null && app_running; do sleep 0.2; done
kill -INT "$REC_PID"
wait "$REC_PID" || true
"$SIMCTL" status_bar "$UDID" clear

# 실패 시 xcodebuild 가 진단 수집으로 오래 머무를 수 있으므로 잠시만 기다린 뒤 정리
for _ in $(seq 1 60); do kill -0 "$TEST_PID" 2>/dev/null || break; sleep 1; done
kill "$TEST_PID" 2>/dev/null || true
grep -E "Test Case|error:" "$TEST_LOG" || true

if command -v ffmpeg >/dev/null 2>&1 && command -v ffprobe >/dev/null 2>&1; then
  # 앞부분(런치 전 정지 화면)과 뒷부분(앱 종료 직후)을 잘라내고 짝수 해상도로 정리
  DURATION="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$RAW")"
  LENGTH="$(python3 -c "print(max(1.0, float('$DURATION') - 0.5 - 3.0))")"
  ffmpeg -loglevel error -y -ss 0.5 -i "$RAW" -t "$LENGTH" \
    -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" -c:v libx264 -pix_fmt yuv420p -movflags +faststart "$OUT"
  rm -f "$RAW"
else
  mv "$RAW" "$OUT"
fi

echo "영상 저장: $OUT"
