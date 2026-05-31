# HuntTimer — 구현 중 마주한 버그 기록

> 커밋 히스토리에서 추출한 실제 버그 목록입니다.  
> 빌드/런타임 크래시 → 데이터·로직 오류 → UI/UX 순으로 정리했습니다.

---

## 빌드 / 런타임 크래시

### 1. iOS 17.6 dyld 크래시 — Swift 6 빌드 플래그
**커밋** `2dc26ef`  
**증상** 실기기(iOS 17.6) 에서 앱 실행 즉시 크래시, 시뮬레이터에서는 재현 안 됨  
**원인** Xcode가 자동 삽입한 Swift 6 관련 플래그 3개(`SWIFT_DEFAULT_ACTOR_ISOLATION`, `SWIFT_APPROACHABLE_CONCURRENCY`, `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY`)가 iOS 26.2 SDK 전용 Swift 런타임 심볼을 참조 → 구형 OS의 dyld가 심볼을 찾지 못해 크래시  
**해결** `project.pbxproj`의 Debug/Release 양쪽 설정에서 해당 플래그 3개 제거

---

### 2. `EXC_BAD_ACCESS` — `CircularTimerView` sublayer 파괴
**커밋** `4040488`  
**증상** 타이머 화면 진입 시 간헐적 `EXC_BAD_ACCESS` 크래시  
**원인** `CircularTimerView.setupLayers()`가 `layoutSubviews()` 호출마다 `layer.sublayers`를 전부 제거하는데, `timerLabels`가 `gaugeView`의 자식으로 배치되어 있어 backing layer가 함께 파괴된 뒤 접근 시도  
**해결** `timerLabels`를 `gaugeView` 내부가 아닌 `gaugeWrapper`(상위 래퍼 뷰)의 자식으로 이동 → sublayer 제거 사이클에 영향받지 않도록 격리

```
gaugeWrapper
├── gaugeView     ← layer.sublayers 반복 재생성 (여기만 영향)
└── timerLabels   ← gaugeWrapper 직속 → 안전
```

---

### 3. SnapKit `convertPoint` 크래시 — 뷰 계층 미완성 상태에서 제약 설치
**커밋** `0c2e8f8`  
**증상** 장난감 칩(chip) 버튼 생성 시 런타임 크래시  
**원인** `iconView.snp.makeConstraints`를 `addSubview` 이전에 호출하면 SnapKit이 공통 조상을 탐색하다 유효하지 않은 뷰 계층에 `NSLayoutConstraint` 메시지를 전송  
**해결** `iconView → chipStack → btn` 순으로 `addSubview` 완료 후 `makeConstraints` 호출하도록 순서 교정

---

### 4. Realm 고양이 삭제 크래시 — `invalidated` 객체 접근
**커밋** `d258a3e`  
**증상** 홈 화면에서 고양이를 삭제하면 앱 크래시  
**원인** `realm.delete(managed)` 실행 후 `cat`/`managed` 모두 **invalidated** 상태가 되는데, 바로 다음 줄 `selectedCatIds.remove(cat.id)`에서 invalidated 객체의 `.id` 프로퍼티에 접근  
**해결** `realm.write` 진입 전 `let catId = cat.id`로 ID를 값 타입 복사 → 삭제 후에는 `catId`만 사용, 목록 갱신도 새 Realm 인스턴스로 재조회

```swift
// Before (crash)
try realm.write { realm.delete(managed) }
selectedCatIds.remove(cat.id)   // ← cat이 이미 invalidated

// After (fix)
let catId = cat.id              // 값 복사
try realm.write { realm.delete(managed) }
selectedCatIds.remove(catId)    // ← 값 타입, 안전
```

---

## 데이터 / 로직 오류

### 5. UIColor hex 8자리 파싱 오류 — 색상이 보라색으로 렌더링
**커밋** `c27f2d3`  
**증상** `"#ffbf6cff"`(주황 계열) 같은 alpha 포함 hex를 사용하면 보라색으로 표시됨  
**원인** 기존 파서가 6자리 `RRGGBB`만 처리 → 8자리 입력 시 뒤 2자리(`AA`)를 B 채널로 잘못 읽어 Blue = 0xFF  
**해결** 문자열 길이 분기 추가: 8자리일 경우 `RRGGBBAA`로 파싱, 6자리는 기존 로직 유지

---

### 6. 배너 이미지 재빌드 후 소실 — 절대 경로 저장
**커밋** `228dce1`  
**증상** 시뮬레이터 재빌드 후 홈 배너 이미지가 사라짐  
**원인** Realm에 `Documents/` 절대 경로를 저장했는데, 재빌드 시 iOS 시뮬레이터 컨테이너 UUID가 변경되어 기존 경로가 유효하지 않게 됨  
**해결** 파일명(`lastPathComponent`)만 Realm에 저장하고, 런타임에 현재 `Documents` 디렉토리와 조합해 전체 경로 재구성 (구버전 호환: 절대 경로가 이미 저장된 경우 `lastPathComponent` 추출 후 동일 처리)

---

### 7. 사냥 완료 후 캘린더 탭 전환 실패
**커밋** `3959d5f`  
**증상** 사냥 세션 저장 후 캘린더 탭으로 이동하지 않음  
**원인** `popViewController(animated:)` 호출 후 `self.parent`가 `nil`이 되어 `self.tabBarController`도 `nil` 반환  
**해결** `popViewController` **이전**에 `let tabBar = self.tabBarController`로 참조 캡처 → pop 이후 `tabBar?.selectedIndex = 2`로 탭 전환

```swift
// Before (no-op)
self.navigationController?.popViewController(animated: false)
self.tabBarController?.selectedIndex = 2   // ← tabBarController가 이미 nil

// After (fix)
let tabBar = self.tabBarController          // pop 전에 캡처
self.navigationController?.popViewController(animated: false)
tabBar?.selectedIndex = 2
```

---

### 8. 타이머 중복 실행 — 재생 버튼 연타
**커밋** `f975a64`  
**증상** 타이머 재생 버튼을 빠르게 여러 번 탭하면 타이머가 비정상적으로 빨라짐  
**원인** `startTimer()` 진입 시 기존 `Timer` 인스턴스를 정리하지 않아, 연타 시 타이머가 중첩 생성됨  
**해결** `startTimer()` 진입 시 `timer?.invalidate(); timer = nil`로 기존 타이머를 먼저 정리

---

## UI / UX 버그

### 9. 키보드가 저장 버튼을 가리는 문제
**커밋** `83869ca`  
**증상** 세션 저장 모달에서 메모 텍스트필드를 탭하면 키보드가 저장 버튼을 완전히 덮음  
**원인** 모달 카드가 `centerY.equalToSuperview()`로 고정되어 키보드 높이를 고려하지 않음  
**해결** `centerY` 제약을 `Constraint` 변수로 노출 후, `UIKeyboardWillShow/Hide` 노티피케이션을 구독해 키보드 높이만큼 카드를 위로 올리는 `updateCardOffset()` 메서드 구현

---

### 10. DayCell 잔상 / UI 프리징 — 셀 재사용 + 비동기 이미지 로딩
**커밋** `57ff218`  
**증상** 캘린더 스크롤 시 날짜 셀에 잘못된 사진이 표시되거나 스크롤이 끊김  
**원인 1** `AsyncImageView`가 셀 재사용 시 이전 비동기 요청 결과를 취소하지 않아 stale 이미지가 새 셀에 렌더링  
**원인 2** 이미지를 메인 스레드에서 동기 로드해 UI 프리징 발생  
**해결**
- `UIImageView`로 교체 후 `DispatchQueue.global(qos: .userInitiated)`에서 비동기 로드
- `currentDay` 프로퍼티로 요청 식별: 완료 시 `currentDay != targetDay`이면 결과 폐기
- `prepareForReuse()`에서 이미지·아이콘 초기화로 잔상 제거
