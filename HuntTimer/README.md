#  HuntTimer - 반려묘 사냥 놀이 타이머

## Project Overview
- **Service Name**: HuntTimer (반려묘 사냥 놀이 타이머)
- **Subtitle**: 데이터 기반 반려묘 활동량 관리 및 습관 형성 앱
- **Core Value**: 반려묘 건강 케어 | 집사 습관 형성 | 정량적 데이터 관리 | 집사 힐링 경험
- **Configuration**: iOS 16.0+ | Portrait Only | iPhone | Light Mode Optimized

---

## Target Audience
1. **Primary**: 권장 사냥 놀이 시간(**75분**) 준수에 어려움을 느끼는 사용자  
   *(기준: 수의학 및 반려묘 행동학에서 권장하는 하루 평균 사냥 시간)*
2. **Secondary**: 반려묘와의 일상을 사진과 함께 타임라인으로 남기고 싶은 사용자

---

## Key Features (v1.0)

| 구분 | 상세 기능 명세 |
| :--- | :--- |
| **놀이 타이머** | - **Custom Circular UI**: SwiftUI Animation 기반 원형 게이지<br>- **초침 UI**: 고양이 발바닥 애니메이션 적용<br>- **Live Activities**: 진행 상태 실시간 표시 및 백그라운드 지원<br>- **Flow**: 선(先) 타이머 실행 후 후(後) 고양이/데이터 매칭 지원 |
| **기록 관리** | - **Realm DB**: 세션 종료 시 자동 저장 및 장난감 태그 기반 분류<br>- **Multimedia**: UIImagePickerController 연동 (사진 촬영 및 앨범 선택)<br>- **Timeline**: FSCalendar 기반 사진 중심 시각적 히스토리 탐색<br>- **다중 반려묘 매칭**: 세션 종료 시 한 명 혹은 여러 명의 고양이를 선택하여 기록<br> |
| **통계 및 분석** | - 일/주 단위 활동 시간 집계 및 시간대별 패턴 분석<br>- **목표 달성 시각화**: 일일 목표(75분) 대비 현재 진척도 그래프(Charts) |
| **게임화 & 보상** | - **업적 시스템**: '초보 낚시꾼' → '전설의 사냥꾼' 칭호 부여<br>- **시각적 보상**: 연속 달성 시 고양이 캐릭터 성장 및 전용 뱃지 수여 |
| **알림 & 공유** | - **UserNotifications**: 사용자 패턴 기반 맞춤형 독려 알림<br>- **Share Sheet**: 놀이 기록 및 고양이 사진 외부 공유 기능 |
| **오디오 연동** | - 타이머 실행 시 Apple Music/Spotify 등 외부 앱 연동 (Open URL)<br>- 사용자의 즐거운 사냥 놀이 경험 유도 |

---

## Status-based Notifications
| 상황 | 알림/독려 메시지 예시 |
| :--- | :--- |
| **활동 전** | "오늘 아직 사냥 기록이 없어요 😿 짧게라도 시작해볼까요?" |
| **목표 미달** | "오늘 45분 놀아주셨어요 🐱 조금만 더 하면 목표 달성이에요!" |
| **달성 임박** | "거의 다 왔어요! 10분만 더 놀아주면 오늘 목표 완료! 👍" |
| **목표 달성** | "오늘 목표 달성! 감태가 오늘 정말 만족했을 거예요 😻" |
| **초과 달성** | "오늘은 완전 사냥 마스터네요 😼🔥 완벽한 하루예요!" |

---

## Tech Stack

### Architecture & Design Pattern
- **MVVM (Input-Output Pattern)**
- **Atomic Design Pattern** (UI Component Architecture)

### Core Stack
- **Reactive**: RxSwift
- **Frameworks**: UIKit, SwiftUI, ActivityKit, WidgetKit, UserNotifications
- **Database**: Realm
- **Networking**: Alamofire, Kingfisher

### Libraries & API
- **UI**: FSCalendar, Charts, Toasts
- **API**: 네이버 쇼핑 API, 유기동물 정보 공공 API

---

## Directory Structure (Planned)
- `Atoms`: Color, Font, Button, Icon 등 최하위 단위
- `Molecules`: StatCard, Tag, Badge 등 조합 단위
- `Organisms`: TimerBlock, Calendar, RecordList 등 복합 단위
- `Templates/Pages`: 각 메인 탭 화면 (홈, 플레이, 기록, 프로필, 쇼핑, 입양)
