//
//  Twitter.swift
//  PerfectTemplate
//
//  Created by nya on 12/26/16.
//
//

import Foundation


public class Twitter {
    
    static let API_BASE = "https://api.twitter.com/1.1"
    
    var consumerKey: String
    var consumerSecret: String
    
    public init(consumerKey: String, consumerSecret: String) {
        self.consumerKey = consumerKey
        self.consumerSecret = consumerSecret
    }
    
    class func parseAuthReault(string: String) -> [String: String] {
        var results = [String: String]()
        string.components(separatedBy: "&").forEach {
            let comps = $0.components(separatedBy: "=")
            if comps.count == 2 {
                results[comps[0]] = comps[1]
            }
        }
        return results
    }
    
    func baseAuthHeader() -> [(String, String)] {
        return [
            ("oauth_consumer_key", consumerKey),
            ("oauth_signature_method", "HMAC-SHA1"),
            ("oauth_timestamp", "\(Int(Date().timeIntervalSince1970))"),
            ("oauth_nonce", "\(arc4random())"),
            ("oauth_version", "1.0"),
        ]
    }
    
    // MARK:-

    public func loadAuthUrl(callback: String, completion: @escaping (URL?, Error?) -> Void) {
        let url = "https://api.twitter.com/oauth/request_token"
        var header = baseAuthHeader()
        header.append(("oauth_callback", callback))

        guard let signature = OAuthAuthorizationSignature(url: url, method: "POST", params: header, consumerSecret: consumerSecret) else {
            completion(nil, NSError(domain: "loadTwitterAuthUrl", code: -1, userInfo: nil))
            return
        }
        header.append(("oauth_signature", signature))
        
        var req = URLRequest(url: URL(string: url)!)
        req.httpMethod = "POST"
        req.addValue(OAuthAuthorizationHeader(params: header), forHTTPHeaderField: "Authorization")
        req.httpBody = ("oauth_callback=" + callback).data(using: .utf8)
        URLSession.shared.dataTask(with: req) { (data, res, err) in
            if let data = data, let str = String(data: data, encoding: .utf8) {
                var results = Twitter.parseAuthReault(string: str)
                if let oauth_token = results["oauth_token"] {
                    let redirect_url = URL(string: "https://api.twitter.com/oauth/authenticate?oauth_token=" + oauth_token)
                    completion(redirect_url, nil)
                } else {
                    completion(nil, NSError(domain: "loadTwitterAuthUrl", code: -2, userInfo: nil))
                }
            } else if let err = err {
                completion(nil, err)
            }
        }.resume()
    }
    
    public func authCallback(params: [(String, String)], completion: @escaping ((token: String, tokenSecret: String)?, Error?) -> Void) {
        guard let oauth_token = params.filter({ $0.0 == "oauth_token" }).first?.1, let oauth_verifier = params.filter({ $0.0 == "oauth_verifier" }).first?.1 else {
            completion(nil, NSError(domain: "loadTwitterAuthUrl", code: -1, userInfo: nil))
            return
        }
        
        let url = "https://api.twitter.com/oauth/access_token"
        var header = baseAuthHeader()
        
        guard let signature = OAuthAuthorizationSignature(url: url, method: "POST", params: header, consumerSecret: consumerSecret) else {
            completion(nil, NSError(domain: "loadTwitterAuthUrl", code: -1, userInfo: nil))
            return
        }
        header.append(("oauth_signature", signature))
        header.append(("oauth_token", oauth_token))

        var req = URLRequest(url: URL(string: url)!)
        req.httpMethod = "POST"
        req.addValue(OAuthAuthorizationHeader(params: header), forHTTPHeaderField: "Authorization")
        req.httpBody = ("oauth_verifier=" + oauth_verifier).data(using: .utf8)
        URLSession.shared.dataTask(with: req) { (data, res, err) in
            if let data = data, let str = String(data: data, encoding: .utf8) {
                var results = Twitter.parseAuthReault(string: str)
                if let oauth_token = results["oauth_token"], let oauth_token_secret = results["oauth_token_secret"] {
                    completion((oauth_token, oauth_token_secret), nil)
                } else {
                    completion(nil, NSError(domain: "loadTwitterAuthUrl", code: -2, userInfo: nil))
                }
            } else if let err = err {
                completion(nil, err)
            }
        }.resume()
    }
    
    // MARK:-
    
    public func authorize(request: inout URLRequest, accessToken: (token: String, tokenSecret: String)?) -> Bool {
        guard let accessToken = accessToken else {
            return false
        }
        var header = baseAuthHeader()
        header.append(("oauth_token", accessToken.token))
        guard let url = request.url?.absoluteString, let auth = OAuthAuthorizationHeader(url: url, method: request.httpMethod ?? "GET", params: header, consumerSecret: consumerSecret, oauthTokenSecret: accessToken.tokenSecret) else {
            return false
        }
        
        request.addValue(auth, forHTTPHeaderField: "Authorization")
        return true
    }
    
    public func verifyCredentials(accessToken: (token: String, tokenSecret: String), completion: @escaping (Any?, Error?) -> Void) {
        var req = URLRequest(url: URL(string: Twitter.API_BASE + "/account/verify_credentials.json")!)
        let _ = authorize(request: &req, accessToken: accessToken)
        URLSession.shared.dataTask(with: req) { (data, res, err) in
            if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) {
                completion(json, nil)
            } else {
                completion(nil, err)
            }
        }.resume()
    }
}
