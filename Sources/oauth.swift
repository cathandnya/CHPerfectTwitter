//
//  oauth.swift
//  PerfectTemplate
//
//  Created by nya on 12/26/16.
//
//

import Foundation
import COpenSSL


fileprivate func encode(_ s: String) -> String {
    var set = CharacterSet.alphanumerics
    set.insert(charactersIn: "-_.~")
    return s.addingPercentEncoding(withAllowedCharacters: set)!
}

fileprivate func hmacSha1(string: String, key: String) -> String? {
    guard let cKey = key.cString(using: .utf8), let cData = string.cString(using: .utf8) else {
        return nil
    }
    var result = [CUnsignedChar](repeating: 0, count: Int(SHA_DIGEST_LENGTH + 1))
    var resultLen = UInt32(SHA_DIGEST_LENGTH)
    HMAC(EVP_sha1(), cKey, Int32(strlen(cKey)), cData.map({ UInt8($0) }), Int(strlen(cData)), &result, &resultLen)
    let hmacData = Data(bytes: result, count: (Int(resultLen)))
    let hmacBase64 = hmacData.base64EncodedString(options: .lineLength76Characters)
    return String(hmacBase64)
}

func OAuthAuthorizationSignature(url: String, method: String, params: [(String, String)], consumerSecret: String, oauthTokenSecret: String? = nil) -> String? {
    let params = params.sorted { (l: (key: String, value: String), r: (key: String, value: String)) -> Bool in
        return l.key < r.key
    }
    
    var paramsStr = ""
    var flag = false
    params.forEach { (key, val) in
        if flag {
            paramsStr += "&"
        }
        flag = true
        paramsStr += key + "=" + val
    }
    
    let signStr = method + "&" + encode(url) + "&" + encode(paramsStr)
    let key = encode(consumerSecret) + "&" + (oauthTokenSecret ?? "")
    return hmacSha1(string: signStr, key: key)
    
}

func OAuthAuthorizationHeader(params: [(String, String)]) -> String {
    var str = "OAuth "
    var flag = false
    params.sorted { (l: (key: String, value: String), r: (key: String, value: String)) -> Bool in
        return l.key < r.key
    }.forEach { (key, val) in
        if flag {
            str += ", "
        }
        flag = true
        str += key + "=\"" + encode(val) + "\""
    }
    return str
}

func OAuthAuthorizationHeader(url: String, method: String, params: [(String, String)], consumerSecret: String, oauthTokenSecret: String? = nil) -> String? {
    guard let signature = OAuthAuthorizationSignature(url: url, method: method, params: params, consumerSecret: consumerSecret, oauthTokenSecret: oauthTokenSecret) else {
        return nil
    }
    var params = params
    params.append(("oauth_signature", signature))
    return OAuthAuthorizationHeader(params: params)
}


