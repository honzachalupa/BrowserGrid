import Foundation

func normalizeUrlString(_ urlString: String) -> URL? {
    if (urlString.starts(with: "http")) {
        return URL(string: urlString)
    } else {
        return URL(string: "http://" + urlString)
    }
}
