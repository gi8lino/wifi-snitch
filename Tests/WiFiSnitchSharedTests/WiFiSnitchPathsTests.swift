import XCTest
@testable import WiFiSnitchShared

final class WiFiSnitchPathsTests: XCTestCase {
  func testDefaultSocketPathMatchesExpectedLocation() {
    XCTAssertEqual(defaultWifiSnitchSocketPath(), "/tmp/wifi-snitch/wifi-snitch.sock")
  }

  func testDefaultLockDirectoryMatchesSocketParentDirectory() {
    XCTAssertEqual(defaultWifiSnitchLockDirectory(), "/tmp/wifi-snitch")
  }
}
