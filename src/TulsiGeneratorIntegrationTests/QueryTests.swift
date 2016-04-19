// Copyright 2016 The Tulsi Authors. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import XCTest
@testable import TulsiGenerator


// Tests for the Bazel query extractor.
class QueryTests_PackageRuleExtraction: BazelIntegrationTestCase {
  var infoExtractor: BazelQueryInfoExtractor! = nil

  override func setUp() {
    super.setUp()
    infoExtractor = BazelQueryInfoExtractor(bazelURL: bazelURL,
                                            workspaceRootURL: workspaceRootURL!,
                                            localizedMessageLogger: localizedMessageLogger)
  }

  func testSimple() {
    installBUILDFile("Simple", intoSubdirectory: "tulsi_test")
    let infos = infoExtractor.extractTargetRulesFromPackages(["tulsi_test"])

    XCTAssertEqual(infos.count, 5)
    let checker = InfoChecker(ruleInfos: infos)

    checker.assertThat("//tulsi_test:Application")
        .hasType("ios_application")
        .hasNoLinkedTargetLabels()
        .hasNoDependencies()

    checker.assertThat("//tulsi_test:Binary")
        .hasType("objc_binary")
        .hasNoLinkedTargetLabels()
        .hasNoDependencies()

    checker.assertThat("//tulsi_test:Library")
        .hasType("objc_library")
        .hasNoLinkedTargetLabels()
        .hasNoDependencies()

    checker.assertThat("//tulsi_test:XCTest")
        .hasType("ios_test")
        .hasExactlyOneLinkedTargetLabel(BuildLabel("//tulsi_test:Application"))
        .hasNoDependencies()

    checker.assertThat("//tulsi_test:XCTestWithDefaultHost")
        .hasType("ios_test")
        .hasNoLinkedTargetLabels()
        .hasNoDependencies()
  }


  func testComplexSingle() {
    installBUILDFile("ComplexSingle", intoSubdirectory: "tulsi_test")
    let infos = infoExtractor.extractTargetRulesFromPackages(["tulsi_test"])

    XCTAssertEqual(infos.count, 16)
    let checker = InfoChecker(ruleInfos: infos)

    checker.assertThat("//tulsi_test:Application")
        .hasType("ios_application")
        .hasNoLinkedTargetLabels()
        .hasNoDependencies()

    checker.assertThat("//tulsi_test:Binary")
        .hasType("objc_binary")
        .hasNoLinkedTargetLabels()
        .hasNoDependencies()

    checker.assertThat("//tulsi_test:CoreDataResources")
        .hasType("objc_library")
        .hasNoLinkedTargetLabels()
        .hasNoDependencies()

    checker.assertThat("//tulsi_test:Library")
        .hasType("objc_library")
        .hasNoLinkedTargetLabels()
        .hasNoDependencies()

    checker.assertThat("//tulsi_test:ObjCProtoLibrary")
        .hasType("objc_proto_library")
        .hasNoLinkedTargetLabels()
        .hasNoDependencies()

    checker.assertThat("//tulsi_test:ProtoLibrary")
        .hasType("proto_library")
        .hasNoLinkedTargetLabels()
        .hasNoDependencies()

    checker.assertThat("//tulsi_test:SubLibrary")
        .hasType("objc_library")
        .hasNoLinkedTargetLabels()
        .hasNoDependencies()

    checker.assertThat("//tulsi_test:SubLibraryWithDefines")
        .hasType("objc_library")
        .hasNoLinkedTargetLabels()
        .hasNoDependencies()

    checker.assertThat("//tulsi_test:SubLibraryWithDifferentDefines")
        .hasType("objc_library")
        .hasNoLinkedTargetLabels()
        .hasNoDependencies()

    checker.assertThat("//tulsi_test:XCTest")
        .hasType("ios_test")
        .hasExactlyOneLinkedTargetLabel(BuildLabel("//tulsi_test:Application"))
        .hasNoDependencies()
  }
}


// Tests for test_suite support.
class QueryTests_TestSuiteExtraction: BazelIntegrationTestCase {
  var infoExtractor: BazelQueryInfoExtractor! = nil
  let testDir = "TestSuite"

  override func setUp() {
    super.setUp()
    infoExtractor = BazelQueryInfoExtractor(bazelURL: bazelURL,
                                            workspaceRootURL: workspaceRootURL!,
                                            localizedMessageLogger: localizedMessageLogger)
    installBUILDFile("TestSuiteRoot",
                     intoSubdirectory: testDir,
                     fromResourceDirectory: "TestSuite")
    installBUILDFile("TestOne",
                     intoSubdirectory: "\(testDir)/One",
                     fromResourceDirectory: "TestSuite/One")
    installBUILDFile("TestTwo",
                     intoSubdirectory: "\(testDir)/Two",
                     fromResourceDirectory: "TestSuite/Two")
    installBUILDFile("TestThree",
                     intoSubdirectory: "\(testDir)/Three",
                     fromResourceDirectory: "TestSuite/Three")
  }

  func testTestSuite_ExplicitXCTests() {
    let infos = infoExtractor.extractTestSuiteRules([BuildLabel("//\(testDir):explicit_XCTests")])
    XCTAssertEqual(infos.count, 1)
    let checker = InfoChecker(infos: infos)

    checker.assertThat("//\(testDir):explicit_XCTests")
        .hasType("test_suite")
        .hasNoLinkedTargetLabels()
        .hasDependencies(["//\(testDir)/One:XCTest",
                          "//\(testDir)/Two:XCTest",
                          "//\(testDir)/Three:XCTest"])
  }

  func testTestSuite_ExplicitNonXCTests() {
    let infos = infoExtractor.extractTestSuiteRules([BuildLabel("//\(testDir):explicit_NonXCTests")])
    XCTAssertEqual(infos.count, 1)
    let checker = InfoChecker(infos: infos)

    checker.assertThat("//\(testDir):explicit_NonXCTests")
        .hasType("test_suite")
        .hasNoLinkedTargetLabels()
        .hasDependencies(["//\(testDir)/One:NonXCTest",
                          "//\(testDir)/Two:NonXCTest",
                          "//\(testDir)/Three:NonXCTest"])
  }

  func testTestSuite_LocalTaggedTests() {
    let infos = infoExtractor.extractTestSuiteRules([BuildLabel("//\(testDir):local_tagged_tests")])
    XCTAssertEqual(infos.count, 1)
    let checker = InfoChecker(infos: infos)

    // Tagged tests are expected to return all *_test rules in the same package, regardless of the
    // actual tagging.
    checker.assertThat("//\(testDir):local_tagged_tests")
        .hasType("test_suite")
        .hasNoLinkedTargetLabels()
        .hasDependencies(["//\(testDir):TestSuiteXCTest",
                          "//\(testDir):TestSuiteNonXCTest",
                          "//\(testDir):TestSuiteXCTestNotTagged"])
  }

  func testTestSuite_RecursiveTestSuites() {
    let infos = infoExtractor.extractTestSuiteRules([BuildLabel("//\(testDir):recursive_test_suite")])
    XCTAssertEqual(infos.count, 2)
    let checker = InfoChecker(infos: infos)

    checker.assertThat("//\(testDir):recursive_test_suite")
        .hasType("test_suite")
        .hasNoLinkedTargetLabels()
        .hasDependencies(["//\(testDir):TestSuiteXCTest",
                          "//\(testDir)/Three:tagged_tests"])

    // Tagged tests are expected to return all *_test rules in the same package, regardless of the
    // actual tagging.
    checker.assertThat("//\(testDir)/Three:tagged_tests")
        .hasType("test_suite")
        .hasNoLinkedTargetLabels()
        .hasDependencies(["//\(testDir)/Three:NonXCTest",
                          "//\(testDir)/Three:XCTest"])
  }
}


private class InfoChecker {
  let infoMap: [BuildLabel: (RuleInfo, Set<BuildLabel>)]

  init(infos: [RuleInfo: Set<BuildLabel>]) {
    var infoMap = [BuildLabel: (RuleInfo, Set<BuildLabel>)]()
    for (info, dependencies) in infos {
      infoMap[info.label] = (info, dependencies)
    }
    self.infoMap = infoMap
  }

  convenience init(ruleInfos: [RuleInfo]) {
    var infoDict = [RuleInfo: Set<BuildLabel>]()
    for info in ruleInfos {
      infoDict[info] = Set<BuildLabel>()
    }
    self.init(infos: infoDict)
  }

  func assertThat(targetLabel: String, line: UInt = #line) -> Context {
    guard let (ruleInfo, dependencies) = infoMap[BuildLabel(targetLabel)] else {
      XCTFail("No rule with the label \(targetLabel) was found", line: line)
      return Context(ruleInfo: nil, dependencies: nil, infoMap: infoMap)
    }

    return Context(ruleInfo: ruleInfo, dependencies: dependencies, infoMap: infoMap)
  }

  /// Context allowing checks against a single RuleInfo.
  class Context {
    let ruleInfo: RuleInfo?
    let dependencies: Set<BuildLabel>?
    let infoMap: [BuildLabel: (RuleInfo, Set<BuildLabel>)]

    init(ruleInfo: RuleInfo?,
         dependencies: Set<BuildLabel>?,
         infoMap: [BuildLabel: (RuleInfo, Set<BuildLabel>)]) {
      self.ruleInfo = ruleInfo
      self.dependencies = dependencies
      self.infoMap = infoMap
    }

    // Does nothing as "assertThat" already asserted the existence of the associated ruleInfo.
    func exists() -> Context {
      return self
    }

    /// Asserts that the contextual RuleInfo has the given type.
    func hasType(type: String, line: UInt = #line) -> Context {
      guard let ruleInfo = ruleInfo else { return self }
      XCTAssertEqual(ruleInfo.type, type, line: line)
      return self
    }

    /// Asserts that the contextual RuleInfo has the given set of linked target labels.
    func hasLinkedTargetLabels(labels: Set<BuildLabel>, line: UInt = #line) -> Context {
      guard let ruleInfo = ruleInfo else { return self }
      XCTAssertEqual(ruleInfo.linkedTargetLabels, labels, line: line)
      return self
    }

    /// Asserts that the contextual RuleInfo has the given linked target label and no others.
    func hasExactlyOneLinkedTargetLabel(label: BuildLabel, line: UInt = #line) -> Context {
      return hasLinkedTargetLabels(Set<BuildLabel>([label]), line: line)
    }

    /// Asserts that the contextual RuleInfo has no linked target labels.
    func hasNoLinkedTargetLabels(line: UInt = #line) -> Context {
      guard let ruleInfo = ruleInfo else { return self }
      if !ruleInfo.linkedTargetLabels.isEmpty {
        XCTFail("Expected no linked targets but found \(ruleInfo.linkedTargetLabels)", line: line)
      }
      return self
    }

    /// Asserts that the contextual RuleInfo has the given set of dependent labels.
    func hasDependencies(dependencies: Set<BuildLabel>, line: UInt = #line) -> Context {
      guard let ruleDeps = self.dependencies else { return self }
      XCTAssertEqual(ruleDeps, dependencies, line: line)
      return self
    }

    /// Asserts that the contextual RuleInfo has the given set of dependent labels.
    func hasDependencies(dependencies: [String], line: UInt = #line) -> Context {
      let labels = dependencies.map() { BuildLabel($0) }
      return hasDependencies(Set<BuildLabel>(labels), line: line)
    }

    /// Asserts that the contextual RuleInfo has no dependent labels.
    func hasNoDependencies(line: UInt = #line) -> Context {
      if let ruleDeps = self.dependencies where !ruleDeps.isEmpty {
        XCTFail("Expected no dependencies but found \(ruleDeps)", line: line)
      }
      return self
    }
  }
}
