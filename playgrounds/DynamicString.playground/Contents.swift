import Cocoa

@dynamicMemberLookup
protocol DynamicProtocol {}
extension DynamicProtocol {
    subscript(dynamicMember member: String) -> String {
        return "\(self)" + member
    }
}

extension String: DynamicProtocol {}

print("H".e.ll, "W".o.r.l.d)
