# 똑똑똑 (Knock) — iOS

매일 안전 체크인 · 비상 연락 · 가족 안부 · 건강/스트레스 통계를 제공하는 iOS 앱입니다.
Figma 시안(`제목 없음 9.15`)을 SwiftUI로 구현했습니다.

## 요구 사항

- Xcode 16 이상
- iOS 17.0 이상 (iPhone)

## 실행

1. `Knock.xcodeproj` 를 Xcode로 엽니다.
2. `Knock` 스킴을 선택하고 iPhone 시뮬레이터에서 실행합니다.

외부 의존성은 없습니다. 소스는 `Knock/` 폴더 기준으로 Xcode가 자동 동기화합니다.

## 데모 계정 / 동작

현재 백엔드 없이 `MockAuthService` 로 동작합니다.

| 항목 | 값 |
| --- | --- |
| 이메일 / 문자 인증번호 | `123456` |
| 아이디 로그인 | 아무 아이디 + 4자 이상 비밀번호 |
| 소셜 로그인 | 버튼 클릭 시 즉시 로그인 |

홈 화면 우측 하단 마법봉 버튼에서 **체크 완료 / 위험 감지(카운트다운 → 비상 연락) / 비상 연락 진행중** 시나리오를,
건강 탭 우측 하단 버튼에서 **건강 상태 양호 ↔ 이상** 전환을 바로 시뮬레이션할 수 있습니다.

## 구조

```
Knock/
├─ App/            진입점, 전역 상태(AppState), 라우팅
├─ DesignSystem/   색상·타이포·공용 컴포넌트(버튼, 입력, 헤더, 탭바)
├─ Models/         도메인 모델
├─ Services/       Auth / 알림 / 로컬 저장 (Mock 구현)
├─ Features/
│  ├─ Splash, Onboarding
│  ├─ Auth/        소셜·아이디·휴대폰 로그인, 이메일 가입, 아이디/비밀번호 찾기
│  ├─ Home/        체크인, 위험 감지, 비상 연락, 가족 지도, 안전 확인 팝업
│  ├─ Stats/       스트레스 주기/월기/년기 통계
│  ├─ Health/      건강 총괄, 수면·심박·스트레스 상세, Apple Watch 연동
│  ├─ Family/      가족 목록·상세·체크인 캘린더, 초대, 채팅, 활동 기록, 알림
│  └─ Settings/    내 정보, 아이디/비밀번호 변경, 비상 연락처, 체크인·알림 설정, 권한, 탈퇴
└─ Assets.xcassets 시안에서 추출한 일러스트/아바타
```

## 후속 연동 지점

- `AuthServicing` — 실제 인증 API
- `NotificationScheduling` — 서버 푸시
- `HealthView` 의 Apple Watch 카드 — HealthKit
- `FamilyMapCard` — 실시간 위치 공유
