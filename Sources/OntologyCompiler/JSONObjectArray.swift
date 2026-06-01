import Foundation

extension Array where Element == JSONObject {
    func mapValuesById(_ transform: (JSONObject) -> JSONObject) -> JSONObject {
        var output = JSONObject()
        for item in self {
            if let id = item["id"] as? String {
                output[id] = transform(item)
            }
        }
        return output
    }
}
