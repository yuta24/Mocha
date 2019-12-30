import XCTest

import MochaTests

var tests = [XCTestCaseEntry]()
tests += MochaTests.allTests()
XCTMain(tests)
