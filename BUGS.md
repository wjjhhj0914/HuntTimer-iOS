# HuntTimer — 구현 중 마주한 버그 및 기술적 의사결정 기록

> 커밋 히스토리에서 추출한 실제 문제와 설계 결정 목록입니다.
> 빌드/런타임 크래시 → 데이터·로직 오류 → UI/UX → 구현 과정의 기술적 결정 순으로 정리했습니다.

---

## 빌드 / 런타임 크래시

### 1. 타이머 화면 진입 시 간헐적 EXC_BAD_ACCESS 크래시

**상황**

원형 게이지 타이머 화면(`CircularTimerView`)을 구현한 직후, 화면 진입 시 간헐적으로 앱이 `EXC_BAD_ACCESS`로 종료되는 문제가 발생했습니다. 재현 조건이 일정하지 않아 원인을 특정하기 어려웠습니다.

**원인 분석**

크래시 스택 트레이스를 확인하니 UIKit 렌더링 과정에서 이미 해제된 메모리에 접근하고 있었습니다. `CircularTimerView`의 코드를 추적한 결과 다음 흐름에서 문제가 발생함을 발견했습니다.

1. `CircularTimerView`는 `layoutSubviews()`가 호출될 때마다 `setupLayers()`를 실행합니다.
2. `setupLayers()` 내부에서 `layer.sublayers?.forEach { $0.removeFromSuperlayer() }`로 **모든 sublayer를 일괄 제거**합니다.
3. 타이머 레이블(`timerLabels`)은 `CircularTimerView` 내부에 자식 뷰로 배치되어 있었고, 모든 `UIView`는 자신의 `CALayer`(backing layer)를 가집니다.
4. `setupLayers()`가 sublayer를 제거할 때 `timerLabels`의 backing layer도 함께 파괴되고, 이후 UIKit이 해당 레이어에 접근하는 시점에 `EXC_BAD_ACCESS`가 발생했습니다.

회전, 키보드 표시 등 레이아웃 변경이 일어날 때마다 `layoutSubviews()`가 재호출되어 간헐적으로 재현되는 이유도 이 구조로 설명할 수 있었습니다.

**해결**

`timerLabels`를 `CircularTimerView`(`gaugeView`) 내부에서 꺼내, 이를 감싸는 래퍼 뷰(`gaugeWrapper`)의 자식으로 이동했습니다. `gaugeWrapper`는 `setupLayers()`의 영향을 받지 않으므로 `timerLabels`의 backing layer가 안전하게 유지됩니다. 시각적으로는 `gaugeWrapper`가 `gaugeView`와 동일한 크기를 가지기 때문에 기존 레이아웃을 그대로 유지할 수 있었습니다.

```
// 수정 전
gaugeView (CircularTimerView)
└── timerLabels  ← setupLayers() 호출 시 backing layer 파괴

// 수정 후
gaugeWrapper (UIView)
├── gaugeView (CircularTimerView)  ← sublayer 재생성 범위
└── timerLabels  ← 영향권 밖, backing layer 보존
```

**배운 점**

`layoutSubviews()`가 단순히 "레이아웃을 갱신하는 메서드"가 아니라 조건에 따라 반복 호출되는 사이클임을 직접 경험했습니다. 또한 `CALayer` 기반 커스텀 뷰를 설계할 때 UIView 계층과 CALayer 계층을 분리해서 사고하는 습관이 생겼습니다.

---

### 2. 실기기에서만 발생하는 앱 시작 즉시 크래시 — Swift 6 빌드 플래그

**상황**

개발 중 시뮬레이터에서는 정상 동작하던 앱이, 실기기(iOS 17.6)에서는 런치 스크린조차 표시되지 않고 즉시 종료되는 문제가 발생했습니다.

**원인 분석**

Xcode 콘솔 로그에서 `dyld: Symbol not found` 메시지를 확인했습니다. `project.pbxproj`를 분석한 결과, Xcode가 자동으로 삽입한 Swift 6 관련 빌드 플래그 3개 — `SWIFT_DEFAULT_ACTOR_ISOLATION`, `SWIFT_APPROACHABLE_CONCURRENCY`, `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY` — 가 iOS 26.2 SDK 전용 Swift 런타임 심볼을 참조하고 있었습니다. 해당 심볼이 iOS 17.6 기기에는 존재하지 않아 동적 링커(dyld)가 앱 실행 전에 크래시를 발생시키는 구조였습니다. 최신 Xcode가 SDK 전용 플래그를 프로젝트에 조용히 삽입한다는 점을 인지하지 못한 것이 근본 원인이었습니다.

**해결**

`project.pbxproj`의 Debug/Release 빌드 설정 양쪽에서 해당 플래그 3개를 제거하고, `SWIFT_VERSION`은 `5.0`으로 명시적으로 유지했습니다. 이후 iOS 17.6 실기기에서 정상 실행을 확인했습니다.

**배운 점**

시뮬레이터와 실기기의 런타임 환경이 다르다는 점, 그리고 Xcode가 프로젝트 설정을 자동으로 변경할 수 있다는 점을 인식하게 됐습니다. 이후 빌드 설정을 직접 확인하는 습관이 생겼습니다.

---

### 3. 장난감 칩 버튼 생성 시 런타임 크래시 — SnapKit 뷰 계층 순서 오류

**상황**

타이머 화면에서 장난감 태그를 칩(chip) 형태의 버튼으로 구성하던 중, 해당 버튼이 포함된 화면 진입 시 런타임 크래시가 발생했습니다.

**원인 분석**

SnapKit의 `makeConstraints` 내부 동작을 추적한 결과, 제약 설치 시점에 뷰가 공통 조상(common ancestor)을 공유하지 않으면 SnapKit이 `NSLayoutConstraint` 관련 메서드를 잘못된 대상에 전송한다는 것을 확인했습니다. 문제가 된 코드는 `iconView.snp.makeConstraints`를 `addSubview` 이전에 호출하고 있었습니다. 즉 `iconView → chipStack → btn`으로 이어지는 뷰 계층이 완성되기 전에 제약을 설치하려 해서 공통 조상 탐색에 실패한 것이었습니다.

**해결**

`addSubview` 호출 순서와 `makeConstraints` 호출 순서를 맞췄습니다. `iconView`를 `chipStack`에 추가하고, `chipStack`을 `btn`에 추가한 뒤, 마지막에 `iconView.snp.makeConstraints`를 호출하도록 순서를 교정했습니다.

**배운 점**

SnapKit(Auto Layout)의 제약 설치는 뷰 계층이 완성된 이후에 이루어져야 한다는 전제를 명확히 인식했습니다. 이후 제약 코드를 작성할 때 항상 `addSubview` 완료 후 제약을 설치하는 순서를 지키게 됐습니다.

---

### 4. 고양이 삭제 후 앱 크래시 — Realm invalidated 객체 접근

**상황**

홈 화면 편집 모드에서 고양이를 삭제하면 앱이 즉시 크래시되는 문제가 발생했습니다. 삭제 자체는 Realm에 정상 반영되고 있었습니다.

**원인 분석**

Realm 객체는 `realm.delete()` 실행 후 **invalidated** 상태로 전환되어 어떤 프로퍼티에도 접근할 수 없습니다. 문제가 된 코드는 `realm.write { realm.delete(managed) }` 직후 `selectedCatIds.remove(cat.id)`를 호출하고 있었는데, 이 시점의 `cat`은 이미 invalidated 상태였습니다. 크래시 원인이 삭제 로직 자체가 아니라 삭제 이후의 접근에 있다는 것을 Realm 객체 생명주기 문서를 통해 확인했습니다.

**해결**

`realm.write` 블록 진입 전 `let catId = cat.id`로 ID를 값 타입(String)으로 미리 복사했습니다. 삭제 이후 로직은 `cat` 대신 `catId`만 사용하도록 변경하고, 목록 갱신도 새 Realm 인스턴스를 통한 재조회로 교체했습니다.

```swift
// Before (crash)
try realm.write { realm.delete(managed) }
selectedCatIds.remove(cat.id)   // cat은 이미 invalidated

// After (fix)
let catId = cat.id              // 값 타입으로 복사
try realm.write { realm.delete(managed) }
selectedCatIds.remove(catId)    // 값 타입, 안전
```

**배운 점**

Realm 관리 객체는 삭제 후 참조를 유지해도 접근이 불가능하다는 생명주기 규칙을 직접 경험했습니다. 이후 Realm 객체를 삭제하는 코드를 작성할 때 항상 필요한 값을 먼저 추출하는 습관이 생겼습니다.

---

## 데이터 / 로직 오류

### 5. alpha 포함 hex 색상 코드가 보라색으로 렌더링되는 버그

**상황**

앱 전반에 걸쳐 사용하는 커스텀 `UIColor(hex:)` 이니셜라이저에서, `"#ffbf6cff"`처럼 alpha 채널이 포함된 8자리 hex 코드를 사용하면 의도한 주황 계열 대신 보라색이 표시되는 문제가 발생했습니다.

**원인 분석**

기존 파서가 6자리 `RRGGBB` 형식만 처리하도록 구현되어 있었습니다. 8자리 문자열이 입력되면 처음 6자리만 파싱하므로, `"ffbf6c"` 중 `6c`까지만 읽혀야 할 Blue 채널이 이후 `"ff"`(= alpha byte)까지 흡수하여 Blue = 0xFF로 계산됩니다. 결과적으로 R·G는 낮고 B만 최대치가 되어 보라색으로 렌더링되었습니다.

**해결**

파서에 문자열 길이 분기를 추가했습니다. 8자리일 경우 `RRGGBBAA`로, 6자리일 경우 기존 `RRGGBB`(alpha = 1.0 고정)로 파싱하도록 처리했습니다.

**배운 점**

유틸리티 코드는 입력 다양성을 명시적으로 처리해야 한다는 점을 인식했습니다. 이후 파서 계열 함수를 작성할 때 경계값과 포맷 변형을 먼저 정의하게 됐습니다.

---

### 6. 재빌드 후 배너 이미지 소실 — iOS 앱 샌드박스 컨테이너 경로

**상황**

고양이 배너 이미지를 등록하면 정상 표시되지만, 시뮬레이터에서 앱을 재빌드하거나 재설치하면 이미지가 사라지는 문제가 반복됐습니다. Realm에 저장된 데이터는 유지되는데 이미지만 사라지는 상황이었습니다.

**원인 분석**

Realm에 저장된 이미지 경로를 확인하니 `/Users/.../Containers/Data/Application/[UUID]/Documents/banner.jpg` 형태의 절대 경로였습니다. iOS 시뮬레이터는 재빌드 시 앱 컨테이너 UUID를 변경하므로, 저장된 절대 경로가 매 빌드마다 무효화되고 있었습니다. 실기기에서도 앱 재설치 시 동일한 문제가 발생할 수 있는 구조였습니다.

**해결**

Realm에는 파일명(`lastPathComponent`)만 저장하고, 런타임에 `FileManager`로 현재 `Documents` 디렉토리 경로를 조회한 뒤 조합해 전체 경로를 재구성하도록 변경했습니다. 기존에 절대 경로가 저장된 경우의 하위 호환도 `lastPathComponent` 추출을 통해 처리했습니다.

**배운 점**

iOS 앱 샌드박스에서 `Documents` 디렉토리의 절대 경로는 빌드·설치 환경에 따라 변할 수 있다는 것을 직접 경험했습니다. 이후 파일 시스템을 다루는 코드에서 절대 경로 대신 상대 식별자(파일명)를 저장하는 원칙을 지키게 됐습니다.

---

### 7. 사냥 완료 후 캘린더 탭 전환이 동작하지 않는 버그

**상황**

사냥 세션이 완료되고 저장 모달을 닫으면 캘린더 탭으로 자동 이동해야 하는데, 탭 전환이 일어나지 않고 이전 화면에 그대로 머무는 문제가 발생했습니다.

**원인 분석**

해당 코드는 `popViewController` 이후 `self.tabBarController?.selectedIndex = 2`를 호출하는 구조였습니다. `UIViewController`의 `tabBarController` 프로퍼티는 뷰 계층 탐색으로 반환되는데, `popViewController` 실행 후 `self.parent`가 `nil`이 되면서 `self.tabBarController`도 `nil`을 반환하고 있었습니다. 즉 탭 전환 코드 자체는 올바르지만 실행 시점에 이미 참조가 무효화된 상황이었습니다.

**해결**

`popViewController` 호출 이전에 `let tabBar = self.tabBarController`로 참조를 로컬 변수에 미리 캡처했습니다. pop 이후에는 캡처해둔 `tabBar`를 통해 탭 전환을 수행했습니다.

```swift
// Before (no-op)
self.navigationController?.popViewController(animated: false)
self.tabBarController?.selectedIndex = 2   // 이미 nil

// After (fix)
let tabBar = self.tabBarController          // pop 전 캡처
self.navigationController?.popViewController(animated: false)
tabBar?.selectedIndex = 2
```

**배운 점**

UIKit 뷰 계층은 `pop` 시점에 즉시 해제될 수 있으며, 이후 `self`를 통한 계층 탐색은 신뢰할 수 없다는 것을 경험했습니다. 뷰 계층 기반 참조가 필요한 경우 해제 이전에 캡처해두는 습관이 생겼습니다.

---

### 8. 재생 버튼 연타 시 타이머가 비정상적으로 빨라지는 버그

**상황**

타이머 재생 버튼을 짧은 간격으로 여러 번 탭하면, 타이머가 1초에 여러 번 증가하며 비정상적으로 빠르게 진행되는 문제가 발생했습니다.

**원인 분석**

`startTimer()`는 내부에서 `Timer.scheduledTimer`로 새 타이머 인스턴스를 생성합니다. 그런데 진입 시 기존 타이머를 정리하는 코드가 없어, 버튼을 N번 탭하면 N개의 타이머가 동시에 RunLoop에 등록됐습니다. 각 타이머가 독립적으로 1초마다 콜백을 호출하므로 N배속으로 동작하는 것처럼 보인 것이었습니다.

**해결**

`startTimer()` 진입 시 `timer?.invalidate(); timer = nil`을 먼저 실행해 기존 타이머를 정리하도록 했습니다. 이후 새 타이머가 생성되므로, 어떤 순서로 호출되더라도 항상 하나의 타이머만 활성 상태를 유지합니다.

**배운 점**

`Timer`는 `invalidate()` 없이 참조를 덮어써도 RunLoop에 여전히 살아있는 상태로 남는다는 것을 직접 확인했습니다. 이후 타이머를 시작하기 전 항상 기존 타이머를 명시적으로 정리하는 습관이 생겼습니다.

---

## UI / UX 버그

### 9. 메모 입력 시 키보드가 저장 버튼을 가리는 문제

**상황**

세션 저장 모달에서 메모 텍스트필드를 탭하면 키보드가 올라오면서 저장 버튼을 완전히 덮어, 키보드를 내리지 않으면 저장할 수 없는 문제가 발생했습니다.

**원인 분석**

모달 카드의 레이아웃이 `centerY.equalToSuperview()`로 화면 정중앙에 고정되어 있었습니다. UIKit은 키보드 표시 시 콘텐츠를 자동으로 회피하지 않으므로, 키보드 높이만큼 카드를 위로 이동시키는 처리가 별도로 필요했습니다.

**해결**

카드의 `centerY` 제약을 `Constraint` 타입 변수로 노출하고, `UIKeyboardWillShowNotification` / `UIKeyboardWillHideNotification` 노티피케이션을 구독했습니다. 키보드 표시 시 `userInfo`에서 키보드 높이를 추출해 `updateCardOffset()`으로 제약 오프셋을 갱신하고, 키보드 해제 시 원위치로 복귀하는 애니메이션을 적용했습니다.

**배운 점**

UIKit에서 키보드 회피는 자동으로 처리되지 않는다는 것을 경험했습니다. `KeyboardLayoutGuide`(iOS 15+)나 노티피케이션 기반 오프셋 조정이 필요한 상황을 직접 구현하면서, 키보드 높이 추출 및 애니메이션 연동 방식을 익혔습니다.

---

### 10. 캘린더 스크롤 시 날짜 셀에 잘못된 사진이 표시되고 스크롤이 끊기는 문제

**상황**

캘린더 화면에서 날짜 셀(`DayCell`)을 빠르게 스크롤하면, 다른 날짜의 사진이 표시되거나 스크롤이 일시적으로 멈추는 두 가지 문제가 동시에 발생했습니다.

**원인 분석**

두 가지 독립적인 원인이 복합적으로 작용하고 있었습니다.

첫 번째로, `AsyncImageView`를 사용해 이미지를 로드하고 있었는데 셀이 재사용될 때 이전 비동기 요청을 취소하지 않았습니다. 결과적으로 빠른 스크롤 시 이전 요청이 뒤늦게 완료되면서 현재 셀에 다른 날짜의 사진이 표시되는 경쟁 조건(race condition)이 발생했습니다.

두 번째로, 이미지 파일을 메인 스레드에서 동기 로드하고 있어, 이미지 크기가 클수록 스크롤 중 UI가 순간적으로 프리징됐습니다.

**해결**

`AsyncImageView`를 `UIImageView`로 교체하고 `DispatchQueue.global(qos: .userInitiated)`에서 비동기로 파일을 읽도록 변경했습니다. 경쟁 조건을 방지하기 위해 `currentDay` 프로퍼티를 도입하여, 비동기 로딩이 완료되는 시점에 `currentDay != targetDay`이면 결과를 폐기하도록 처리했습니다. `prepareForReuse()`에서는 이미지와 상태 아이콘을 초기화해 스크롤 방향 전환 시 잔상이 남지 않도록 했습니다.

**배운 점**

셀 재사용 패턴에서 비동기 작업을 다룰 때는 요청 식별자가 반드시 필요하다는 것을 직접 경험했습니다. 또한 파일 I/O처럼 잠재적으로 느릴 수 있는 작업은 항상 백그라운드 스레드에서 처리해야 스크롤 성능이 유지된다는 원칙을 체득했습니다.

---

## 구현 과정의 기술적 결정

### 11. 백그라운드 진입 시 타이머 경과 시간이 멈추는 문제

**상황**

`Timer.scheduledTimer`로 1초마다 `elapsedSeconds`를 증가시키는 방식으로 타이머를 구현했습니다. 그런데 앱이 백그라운드에 진입하면 RunLoop가 일시 중단되어 Timer 콜백이 호출되지 않고, 포그라운드로 돌아왔을 때 경과 시간이 실제보다 훨씬 적게 기록되는 문제가 발생했습니다.

**원인 분석**

iOS에서 `Timer`는 앱이 백그라운드 상태가 되면 실행이 중단됩니다. 화면을 잠그거나 다른 앱으로 전환하는 것만으로도 타이머가 멈추기 때문에, 단순 카운팅 방식은 실제 경과 시간을 신뢰할 수 없었습니다.

**해결**

타이머가 시작되거나 재개될 때 `timerResumedAt = Date()`로 기준 시각을 저장하고, 포그라운드로 복귀할 때 `Date().timeIntervalSince(timerResumedAt)`로 실제 경과 시간을 계산해 `elapsedSeconds`를 보정했습니다. 또한 타이머 종료 시각에 맞춰 로컬 알림을 예약해, 백그라운드에서도 목표 시간 도달을 사용자에게 알릴 수 있게 했습니다.

```swift
// 포그라운드 복귀 시 실제 경과 시간으로 보정
let elapsed = Int(Date().timeIntervalSince(timerResumedAt))
elapsedSeconds = elapsedBeforePause + elapsed
```

**배운 점**

`Timer`는 경과 시간을 추적하는 도구가 아니라 주기적 콜백을 등록하는 도구라는 것을 인식했습니다. 시간 측정이 목적이라면 `Date` 기반의 절대 시각 차이를 사용해야 한다는 원칙을 체득했습니다.

---

### 12. 카메라 권한 설정 이동 시 세션 데이터 소실 문제

**상황**

사냥 세션이 종료되고 저장 모달에서 사진을 추가하려 할 때, 카메라 권한이 없으면 설정 앱으로 이동하는 분기가 있습니다. 그런데 설정 앱으로 이동하는 순간 앱이 백그라운드 상태가 되고, 이후 권한을 허용하고 앱으로 돌아오면 세션 저장 모달의 데이터(세션 시간, 고양이, 장난감 정보)가 모두 사라지는 문제가 발생했습니다.

**원인 분석**

설정 앱으로 이동하기 전에 모달 데이터를 어딘가에 보존하는 처리가 없었습니다. 메모리에만 존재하던 모달 상태는 앱이 백그라운드에 오래 머물거나 시스템에 의해 종료될 경우 복구할 수 없었습니다.

**해결**

설정으로 이동하기 직전에 `PendingSessionDraft` 구조체로 세션 메타데이터를 JSON 인코딩해 UserDefaults에 저장하는 `saveDraft()` 메서드를 구현했습니다. 앱 재실행 시 `HomeViewController`의 `viewWillAppear`에서 드래프트 존재 여부를 확인하고, 있을 경우 복구 여부를 묻는 알럿을 표시해 이전 데이터를 그대로 모달에 채워 보여주는 방식으로 해결했습니다.

**배운 점**

사용자가 앱을 떠나는 모든 경로를 미리 파악하고 상태를 보존하는 처리가 필요하다는 것을 인식했습니다. 특히 권한 요청처럼 시스템이 앱을 백그라운드로 보내는 상황은 개발자가 명시적으로 대응하지 않으면 데이터 유실로 이어진다는 점을 직접 경험했습니다.

---

### 13. 세션 저장 시마다 같은 알림이 중복 발송되는 문제

**상황**

목표 달성 알림 시스템을 구현하면서, 하루 중 세션을 여러 번 저장하면 "목표를 달성했어요!" 알림이 저장할 때마다 반복 발송되는 문제가 발생했습니다.

**원인 분석**

세션 저장 직후 `checkGoalProgressAndNotify()`를 호출해 오늘 누적 시간을 계산하고 알림을 발송하는 구조였는데, 알림을 이미 보냈는지 추적하는 상태 관리가 없었습니다. 하루에 세션을 5번 저장하면 같은 알림이 5번 울리는 상황이었습니다.

**해결**

플래그 키에 날짜 문자열(`yyyyMMdd`)을 포함해 UserDefaults에 저장하는 방식으로 해결했습니다. 예를 들어 `"nf_goalAchieved_20260414"` 같은 키가 없을 때만 알림을 발송하고 키를 기록합니다. 날짜가 바뀌면 키도 바뀌기 때문에 별도의 만료 처리 없이 다음 날 자동으로 초기화됩니다.

```swift
private func hasFlag(_ key: String) -> Bool {
    UserDefaults.standard.bool(forKey: "\(key)_\(dateKey)")
}
```

**배운 점**

알림은 한 번 발송되면 취소할 수 없기 때문에, 발송 조건과 중복 방지 로직을 설계 단계에서 함께 고려해야 한다는 것을 배웠습니다. 날짜 기반 키는 만료 시간을 별도로 관리할 필요 없이 자연스럽게 초기화되는 패턴으로, 이후에도 자주 활용하게 됐습니다.

---

### 14. Realm 초기화가 첫 화면보다 늦게 완료되는 문제

**상황**

앱을 처음 실행하거나 스키마가 변경된 상태에서 실행하면, 첫 화면이 표시된 직후 Realm 데이터에 접근하는 과정에서 간헐적으로 오류가 발생했습니다.

**원인 분석**

Realm 설정을 `SceneDelegate`에서 처리하고 있었는데, UIScene이 연결되고 첫 화면이 구성되는 시점이 Realm 파일 생성 및 마이그레이션보다 빠를 수 있었습니다. 특히 스키마 변경 후 첫 실행에서 마이그레이션이 완료되기 전에 데이터를 조회하면 오류가 발생했습니다.

**해결**

Realm 초기화 로직을 `AppDelegate.application(_:didFinishLaunchingWithOptions:)`로 이동해, UIScene이 생성되기 전에 Realm 파일 생성과 마이그레이션이 반드시 완료되도록 순서를 보장했습니다.

**배운 점**

앱 초기화 순서(`AppDelegate` → `SceneDelegate` → `ViewController`)를 명확히 이해하고, 다른 화면에서 의존하는 리소스는 항상 가장 이른 시점에 준비해두어야 한다는 원칙을 체득했습니다.

---

### 15. 개발 중 Realm 스키마 변경 시 데이터가 전부 삭제되는 문제

**상황**

개발 초기에는 `deleteRealmIfMigrationNeeded: true` 설정을 사용했습니다. 모델에 프로퍼티를 추가할 때마다 Realm이 기존 데이터를 전부 삭제하고 새로 생성했고, 테스트 데이터가 반복적으로 사라지는 불편함이 있었습니다. 더 큰 문제는, 이 설정을 실수로 배포 버전에 적용하면 사용자 데이터가 모두 소실된다는 위험이었습니다.

**해결**

`migrationBlock`을 명시적으로 작성하고 `schemaVersion`을 상수로 관리하는 구조로 전환했습니다. 모델이 변경될 때마다 버전을 1씩 올리고 해당 버전에 맞는 마이그레이션 로직을 블록 안에 기록하는 방식으로, 데이터를 보존하면서 스키마를 안전하게 업데이트할 수 있게 했습니다.

```swift
private static let currentSchemaVersion: UInt64 = 2

let config = Realm.Configuration(
    schemaVersion: currentSchemaVersion,
    migrationBlock: migrate
)
```

**배운 점**

`deleteRealmIfMigrationNeeded`는 개발 편의를 위한 옵션일 뿐, 출시 전 반드시 `migrationBlock` 기반 구조로 전환해야 한다는 것을 배웠습니다. 데이터베이스 스키마는 처음부터 버전 관리 대상으로 다루는 습관이 중요하다는 점을 인식하게 됐습니다.

---

### 16. 기록 삭제 선택 후 타이머가 재개되는 버그

**상황**

사냥 진행 중 종료 버튼을 눌러 저장 모달이 표시된 상태에서 "기록 삭제"를 선택하면, 모달이 닫힌 후 타이머가 다시 재개되는 버그가 있었습니다.

**원인 분석**

저장 모달을 표시하기 전 타이머를 일시정지하고, `onCancel` 콜백에서 `resumeOnCancel` 플래그 값에 따라 타이머를 재개할지 결정하는 구조였습니다. 그런데 종료 시점(`huntFinished`)에도 동일한 모달을 호출하면서 `resumeOnCancel: false`를 전달해야 했는데, 이를 누락하면 취소 시 타이머가 재개되는 문제가 발생했습니다. 플래그 하나로 두 가지 경우를 분기하는 구조 자체가 버그를 유발하기 쉬운 형태였습니다.

**해결**

`resumeOnCancel` 플래그를 제거하고, `onCancel`은 항상 `resetSession()`을 호출하도록 단일화했습니다. `resetSession()`은 타이머를 정지하고 세션 상태를 모두 초기화해 사냥 준비 상태로 되돌립니다. 분기를 없애 버그 발생 경로 자체를 차단했습니다.

**배운 점**

플래그 하나로 여러 경우를 분기하는 방식은 호출 측에서 올바른 값을 전달해야 한다는 암묵적 전제를 만들고, 이는 쉽게 실수로 이어진다는 것을 경험했습니다. 가능하면 분기를 줄이고 각 경로가 명확한 단일 동작을 하도록 설계하는 것이 유지보수에 훨씬 유리하다는 점을 배웠습니다.
