# CHPerfectTwitter

Twitter support for Perfect.

Perfect is server-side swift implementation. https://github.com/PerfectlySoft/Perfect

## Usage

### Init

```
let CONSUMER_KEY = "YOUR_CONSUMER_KEY"
let CONSUMER_SECRET = "YOUR_CONSUMER_SECRET"
let CALLBACK = "YOUR_SITE_CALLBACK"
let twitter = Twitter(consumerKey: CONSUMER_KEY, consumerSecret: CONSUMER_SECRET)
```

### Authentication

```
routes.add(method: .get, uri: "/twitter", handler: { request, response in    
    twitter.loadAuthUrl(callback: CALLBACK) { (url, err) in
        if let url = url {
            response.status = .found
            response.setHeader(.location, value: url.absoluteString)
            response.completed()
        } else {
            response.setHeader(.contentType, value: "text/html")
            response.appendBody(string: "<html><title>test</title><body><pre>\(err?.localizedDescription ?? "failed.")</pre></body></html>")
            response.completed()
        }
    }
})
```

### Handle Authentication Callback

and verify user.

```
routes.add(method: .get, uri: "/twitter_callback", handler: { request, response in
    twitter.authCallback(params: request.params()) { (token, err) in
        if let token = token {
            twitter.verifyCredentials(accessToken: token) { (json, err) in
                if let json = json {
                    response.setHeader(.contentType, value: "text/html")
                    response.appendBody(string: "<html><title>test</title><body><pre>\(json)</pre></body></html>")
                    response.completed()
                } else {
                    response.setHeader(.contentType, value: "text/html")
                    response.appendBody(string: "<html><title>test</title><body><pre>\(err?.localizedDescription ?? "failed.")</pre></body></html>")
                    response.completed()
                }
            }
        } else {
            response.setHeader(.contentType, value: "text/html")
            response.appendBody(string: "<html><title>test</title><body><pre>\(err?.localizedDescription ?? "failed.")</pre></body></html>")
            response.completed()
        }
    }
})
```

## Other APIs?

Not yet.

But, you can use authorize() method for adding authorization header to any request.
