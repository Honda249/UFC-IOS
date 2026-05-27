import IOSSecuritySuite
import LDSwiftEventSource
import Nuke
import TrustKit
import UUIDV7

/// Phase 0: ensures all SPM security/UI dependencies resolve and link.
enum PackageLinkage {
    static func verifyPackagesLinked() {
        _ = TrustKit.self
        _ = UUIDV7.self
        _ = EventSource.self
        _ = ImagePipeline.self
        _ = IOSSecuritySuite.self
    }
}
