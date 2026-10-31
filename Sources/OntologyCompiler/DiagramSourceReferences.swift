import Foundation

func diagramSource(_ ir: JSONObject, alias: String) -> JSONObject {
    ["id": ir["id"] as? String ?? "", "version": ir["version"] as? String ?? "",
     "namespace": ir["namespace"] as? String ?? "", "alias": alias,
     "sourceDigest": ir["sourceDigest"] as? String ?? "", "sourceByteDigest": ir["sourceByteDigest"] as? String ?? ""]
}

func diagramAttachSources(_ ir: JSONObject) -> JSONObject {
    var result = ir
    for section in ["classes", "relations", "protocols", "policies", "stateMachines"] {
        let records = ir[section] as? [JSONObject] ?? []
        result[section] = records.map { record in
            var record = record
            let pointer = "/spec/\(section)/\(diagramPointerComponent(record["id"] as? String ?? ""))"
            record["source"] = diagramDeclarationSource(ir, pointer: pointer)
            if section == "classes", let fields = record["fields"] as? [JSONObject] {
                record["fields"] = fields.map { field in
                    var field = field
                    let name = diagramPointerComponent(field["id"] as? String ?? "")
                    field["source"] = diagramDeclarationSource(ir, pointer: "\(pointer)/fields/\(name)")
                    return field
                }
            }
            return record
        }
    }
    return result
}

private func diagramDeclarationSource(_ ir: JSONObject, pointer: String) -> JSONObject {
    ["id": ir["id"] as? String ?? "", "version": ir["version"] as? String ?? "",
     "sourceDigest": ir["sourceDigest"] as? String ?? "", "sourceByteDigest": ir["sourceByteDigest"] as? String ?? "",
     "pointer": pointer]
}

private func diagramPointerComponent(_ value: String) -> String {
    value.replacingOccurrences(of: "~", with: "~0").replacingOccurrences(of: "/", with: "~1")
}
