import XCTest

/// 데모 영상용 자동 시나리오.
/// `scripts/record_demo.sh` 가 시뮬레이터 녹화를 켠 상태에서 이 테스트를 실행한다.
/// 각 단계 사이의 `pause` 는 영상에서 화면 전환·애니메이션이 보이도록 하는 대기 시간이다.
final class DemoRecordingUITests: XCTestCase {
    private let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = true
        app.launchArguments = ["--demo-reset"]
    }

    func testFullDemoFlow() throws {
        app.launch()

        onboardingAndLogin()
        homeNotifications()
        homeCheckIn()
        homeEmergency()
        family()
        health()
        stats()

        tap(id: "tab.홈")
        pause(5)                         // 종료 여백(스크립트가 마지막 3초를 잘라냄)
    }

    // MARK: - 단계

    private func onboardingAndLogin() {
        // 스플래시(1.8초) → 온보딩
        pause(2.5)
        for _ in 0..<2 where button("다음").waitForExistence(timeout: 5) {
            pause(1.4)
            button("다음").tap()
        }
        if button("시작하기").waitForExistence(timeout: 5) {
            pause(1.4)
            button("시작하기").tap()
        }
        // 소셜(카카오) 목업 로그인
        wait(button("카카오로 계속하기"))
        pause(1.5)
        button("카카오로 계속하기").tap()
        wait(app.buttons["home.checkButton"], timeout: 10)
        pause(2)
    }

    private func homeNotifications() {
        tap(id: "header.bell")
        pause(2)
        tap(id: "notifications.readAll")
        pause(1.5)
        tap(button("닫기"))
        pause(1)
    }

    private func homeCheckIn() {
        tap(id: "home.checkButton")
        pause(1.5)
        tap(id: "mood.아주 좋아요")
        pause(1)
        tap(id: "mood.confirm")
        pause(3.5)                       // 축하 애니메이션 + 토스트
        tap(id: "home.calendar")
        pause(2.5)
        tap(button("닫기"))
        pause(1)
    }

    private func homeEmergency() {
        tap(id: "home.demoMenu")
        tap(button("위험 감지 시나리오 (02·12)"))
        pause(3)                         // 위험 감지 모달
        tap(button("안전 확인"))
        pause(2.5)
        tap(id: "home.demoMenu")
        tap(button("비상 연락 진행중 (03)"))
        pause(15)                        // 1순위 부재중(6초) → 2순위 응답(12초) → 종료
    }

    private func family() {
        tap(id: "tab.가족")
        pause(2)

        // 초대: 잘못된 코드 → 오류/흔들림, 데모 코드 → 참여 성공
        tap(id: "family.invite")
        pause(1.5)
        for digit in ["0", "0", "0", "0"] { tap(id: "pad.\(digit)"); pause(0.35) }
        pause(0.6)
        tap(id: "invite.join")
        pause(2)
        for _ in 0..<4 { tap(id: "pad.delete"); pause(0.3) }
        pause(0.5)
        tap(id: "invite.demo.1234-5678")
        pause(1)
        tap(id: "invite.join")
        pause(3)                         // 성공 카드 → 자동 닫힘

        // 가족 상세 → 안부 보내기
        tap(id: "family.member.엄마")
        pause(2)
        tap(id: "member.greet")
        pause(1.8)
        tap(id: "member.close")
        pause(1)

        // 채팅: 빠른 답장 → 입력중 표시 → 자동 응답
        tap(id: "family.chat")
        pause(1.5)
        tap(id: "chat.quick.오늘 체크했어요!")
        pause(5)
        tap(button("닫기"))
        pause(1)
    }

    private func health() {
        tap(id: "tab.건강")
        pause(2)
        tap(id: "health.overview")
        pause(2)
        swipeUp()
        tap(id: "health.connect")
        pause(4.5)                       // 연결 중 → 연결됨, 실시간 심박
        swipeDown()
        pause(1.5)

        tap(id: "health.heartRate")
        pause(2)
        tap(id: "detail.previous"); pause(1.5)
        tap(id: "detail.previous"); pause(1.5)
        tap(id: "detail.back")
        pause(1)

        tap(id: "health.sleep")
        pause(2)
        tap(id: "detail.previous"); pause(1.5)
        tap(id: "detail.next"); pause(1.5)
        tap(id: "detail.back")
        pause(1)

        tap(id: "health.stress")
        pause(2)
        tap(id: "detail.previous"); pause(1.5)
        swipeUp()
        tap(id: "stress.startBreathing")
        pause(1.5)
        tap(id: "breathing.start")
        pause(14)                        // 들이쉬기/내쉬기 사이클
        tap(id: "breathing.stop")
        pause(1)
        tap(id: "breathing.back")
        pause(1)
        tap(id: "detail.back")
        pause(1)
        tap(id: "health.back")
        pause(1)
    }

    private func stats() {
        tap(id: "tab.통계")
        pause(2)
        tap(id: "dateNav.previous"); pause(1.5)
        tap(id: "dateNav.previous"); pause(1.5)
        tap(id: "segment.월기"); pause(2)
        tap(id: "dateNav.previous"); pause(1.5)
        tap(id: "segment.년기"); pause(2)
        tap(id: "segment.주기"); pause(1.5)
    }

    // MARK: - 도우미

    private func button(_ label: String) -> XCUIElement { app.buttons[label] }

    private func tap(id: String, timeout: TimeInterval = 6) {
        let element = app.descendants(matching: .any).matching(identifier: id).firstMatch
        tap(element, timeout: timeout)
    }

    private func tap(_ element: XCUIElement, timeout: TimeInterval = 6) {
        guard element.waitForExistence(timeout: timeout) else {
            XCTFail("요소를 찾을 수 없음: \(element)")
            return
        }
        if !element.isHittable { swipeUp() }
        if !element.isHittable { swipeDown(); swipeDown() }
        element.tap()
    }

    @discardableResult
    private func wait(_ element: XCUIElement, timeout: TimeInterval = 6) -> Bool {
        let ok = element.waitForExistence(timeout: timeout)
        if !ok { XCTFail("요소를 기다리다 시간 초과: \(element)") }
        return ok
    }

    private func swipeUp() {
        app.swipeUp(velocity: .slow)
        pause(0.8)
    }

    private func swipeDown() {
        app.swipeDown(velocity: .slow)
        pause(0.8)
    }

    private func pause(_ seconds: TimeInterval) {
        RunLoop.current.run(until: Date(timeIntervalSinceNow: seconds))
    }
}
