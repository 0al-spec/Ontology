import OntologyRules
import XCTest

final class FoundationModelBytesSpecTests: XCTestCase {
    func testOnlyKnownVersionAndExactBytesMatch() {
        let spec = FoundationModelBytesSpec()
        let old = "sha256:7999a4ce110535c8093f177493532420a04ab7db9ff86492db802580531d7e48"
        let current = "sha256:2f43dbd772c8356de107e3ea48cd548405023edb6a641702ddbec52c4942033b"
        XCTAssertTrue(spec.isSatisfiedBy(.init(version: "0.1.0", digest: old)))
        XCTAssertTrue(spec.isSatisfiedBy(.init(version: "0.2.0", digest: current)))
        XCTAssertFalse(spec.isSatisfiedBy(.init(version: "0.1.0", digest: current)))
        XCTAssertFalse(spec.isSatisfiedBy(.init(version: "0.2.0", digest: "sha256:modified")))
        XCTAssertFalse(spec.isSatisfiedBy(.init(version: "0.3.0", digest: old)))
    }

    func testInputCountAndByteBounds() {
        let size = FoundationModelSizeSpec(), count = FoundationModelCountSpec()
        XCTAssertTrue(size.isSatisfiedBy(FoundationModelSizeSpec.maximum))
        XCTAssertFalse(size.isSatisfiedBy(FoundationModelSizeSpec.maximum + 1))
        XCTAssertFalse(size.isSatisfiedBy(-1))
        XCTAssertTrue(count.isSatisfiedBy(FoundationModelCountSpec.maximum))
        XCTAssertFalse(count.isSatisfiedBy(FoundationModelCountSpec.maximum + 1))
        XCTAssertFalse(count.isSatisfiedBy(-1))
    }
}
