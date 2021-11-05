//
//  Derived from SwiftyURLProtocol: https://github.com/vovasty/SwiftyURLProtocol
//
//  Copyright © 2017 Solomenchuk, Vlad (http://aramzamzam.net/).
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
import IPtProxy

open class MeekURLProtocol: URLProtocol, HTTPConnectionDelegate {

    private static let passHeader = "X-MeekURLProtocol-Pass"

    private var httpConnection: HTTPConnection?

    open class func start() {
        IPtProxyStartObfs4Proxy("DEBUG", false, false, nil)
        URLProtocol.registerClass(self)
    }

    open class func stop() {
        URLProtocol.unregisterClass(self)
        IPtProxyStopObfs4Proxy()
    }


    override open class func canInit(with request: URLRequest) -> Bool {
        return URLProtocol.property(forKey: Self.passHeader, in: request) == nil
    }

    override init(request: URLRequest, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
        guard let request = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            assert(false)
            super.init(request: URLRequest(url: URL(string: "about:blank")!),
                       cachedResponse: cachedResponse,
                       client: client)
            return
        }

        URLProtocol.setProperty(true, forKey: Self.passHeader, in: request)

        super.init(request: request as URLRequest, cachedResponse: cachedResponse, client: client)
    }

    override open class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override open func startLoading() {
        let conf = URLSessionConfiguration.default
        conf.tlsMinimumSupportedProtocolVersion = .TLSv10

        conf.connectionProxyDictionary = [
            kCFProxyTypeKey as AnyHashable: kCFProxyTypeSOCKS,
            kCFStreamPropertySOCKSVersion: kCFStreamSocketSOCKSVersion5,
            kCFStreamPropertySOCKSProxyHost: "127.0.0.1",
            kCFStreamPropertySOCKSProxyPort: IPtProxyMeekPort(),
            kCFStreamPropertySOCKSUser: "url=https://moat.torproject.org.global.prod.fastly.net/;",
            kCFStreamPropertySOCKSPassword: "front=cdn.sstatic.net",
        ]

        httpConnection = HTTPConnection(request: request, configuration: conf)
        httpConnection?.delegate = self
        httpConnection?.start()
    }

    override open func stopLoading() {
        httpConnection?.invalidateAndStop()
        httpConnection = nil
    }

    deinit {
        stopLoading()
    }


    // MARK: HTTPConnectionDelegate

    func http(connection: HTTPConnection, didReceiveResponse response: URLResponse) {
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: URLCache.StoragePolicy.allowed)
    }

    func http(connection: HTTPConnection, didReceiveData data: Data) {
        client?.urlProtocol(self, didLoad: data)
    }

    func http(connection: HTTPConnection, didCompleteWithError error: Error?) {
        if let error = error {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    func http(connection: HTTPConnection,
              willPerformHTTPRedirection response: HTTPURLResponse,
              newRequest request: URLRequest) {
        guard let redirectRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            assert(false)
            client?.urlProtocol(self, didFailWithError: NSError(domain: NSCocoaErrorDomain, code: -1, userInfo: nil))
            return
        }

        URLProtocol.removeProperty(forKey: Self.passHeader, in: redirectRequest)
        // Tell the client about the redirect.

        client?.urlProtocol(self, wasRedirectedTo: redirectRequest as URLRequest, redirectResponse: response)

        // Stop our load.  The CFNetwork infrastructure will create a new NSURLProtocol instance to run
        // the load of the redirect.

        // The following ends up calling -URLSession:task:didCompleteWithError: with 
        // NSURLErrorDomain / NSURLErrorCancelled,
        // which specificallys traps and ignores the error.

        connection.invalidateAndStop()

        let error = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)
        client?.urlProtocol(self, didFailWithError: error)
    }
}

extension URLRequest {
    var httpMessage: CFHTTPMessage? {
        guard let httpMethod = httpMethod, let url = url else {
            return nil
        }

        let result = CFHTTPMessageCreateRequest(nil,
                                                httpMethod as CFString,
                                                url as CFURL, kCFHTTPVersion1_1).takeRetainedValue()

        for header in allHTTPHeaderFields ?? [:] {
            CFHTTPMessageSetHeaderFieldValue(result,
                                             header.key as CFString,
                                             header.value as CFString)
        }

        if let cookies = HTTPCookieStorage.shared.cookies(for: url), !cookies.isEmpty {
            let cookieHeaders = HTTPCookie.requestHeaderFields(with: cookies)
            for cookieHeader in cookieHeaders {
                CFHTTPMessageSetHeaderFieldValue(result,
                                                 cookieHeader.key as CFString,
                                                 cookieHeader.value as CFString)
            }
        }

        if let body = self.httpBody {
            CFHTTPMessageSetBody(result, body as CFData)
        }

        return result
    }
}

extension HTTPURLResponse {

    convenience init?(url: URL, message: CFHTTPMessage) {
        let statusCode = CFHTTPMessageGetResponseStatusCode(message)
        let httpVersion = CFHTTPMessageCopyVersion(message).takeRetainedValue() as String
        let headerFields = CFHTTPMessageCopyAllHeaderFields(message)?.takeRetainedValue() as? [String: String]

        self.init(url: url, statusCode: statusCode, httpVersion: httpVersion, headerFields: headerFields)
    }
}

protocol HTTPConnectionDelegate: AnyObject {

    func http(connection: HTTPConnection, didReceiveResponse: URLResponse)

    func http(connection: HTTPConnection, didReceiveData: Data)

    func http(connection: HTTPConnection,
              willPerformHTTPRedirection response: HTTPURLResponse,
              newRequest request: URLRequest)

    func http(connection: HTTPConnection, didCompleteWithError error: Error?)
}

class HTTPConnection: NSObject, StreamDelegate {

    public let request: URLRequest

    public let configuration: URLSessionConfiguration

    var httpStream: InputStream?

    var haveReceivedResponse = false

    var runLoop = RunLoop.main

    var runLoopMode = RunLoop.Mode.default

    private var buf = [UInt8](repeating: 0, count: 1024)

    weak var delegate: HTTPConnectionDelegate?

    init(request: URLRequest, configuration: URLSessionConfiguration) {
        self.request = request
        self.configuration = configuration
    }

    func start() {
        assert(httpStream == nil)

        guard let httpMessage = request.httpMessage else {
            let error = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)
            delegate?.http(connection: self, didCompleteWithError: error)
            return
        }

        httpStream = HTTPConnection.createHttpStream(request: request, httpMessage: httpMessage)
        setupSSL()
        setupProxy()

        httpStream?.delegate = self
        httpStream?.schedule(in: runLoop, forMode: runLoopMode)
        httpStream?.open()
    }

    private class func createHttpStream(request: URLRequest, httpMessage: CFHTTPMessage) -> InputStream {
        let httpStream: InputStream

        if let httpBodyStream = request.httpBodyStream {
            httpStream = CFReadStreamCreateForStreamedHTTPRequest(
                kCFAllocatorDefault, httpMessage, httpBodyStream).takeRetainedValue()
        }
        else {
            httpStream = CFReadStreamCreateForHTTPRequest(
                kCFAllocatorDefault, httpMessage).takeRetainedValue()
        }

        CFReadStreamSetProperty(
            httpStream,
            CFStreamPropertyKey(kCFStreamPropertyHTTPAttemptPersistentConnection),
            kCFBooleanTrue)

        return httpStream
    }

    private func setupSSL() {
        // SSL/TLS hardening -- this is a TLS request
        if request.url?.scheme?.lowercased() == "https" {
            var sslOptions = [CFString: CFString]()

            // Enforce TLS version
            // https://developer.apple.com/library/ios/technotes/tn2287/_index.html#//apple_ref/doc/uid/DTS40011309

            switch configuration.tlsMinimumSupportedProtocolVersion {

            case .TLSv10, .TLSv11, .TLSv12, .TLSv13:
                sslOptions[kCFStreamSSLLevel] = kCFStreamSocketSecurityLevelTLSv1

            default:
                break
            }

            CFReadStreamSetProperty(httpStream,
                                    CFStreamPropertyKey(rawValue: kCFStreamPropertySSLSettings),
                                    sslOptions as CFDictionary)
        }
    }

    private func setupProxy() {
        guard let proxy = configuration.connectionProxyDictionary else {
            return
        }

        let key: CFStreamPropertyKey

        guard let type = proxy[kCFProxyTypeKey] as! CFString? else {
            return
        }

        if type == kCFProxyTypeHTTP {
            guard proxy[kCFNetworkProxiesHTTPEnable] as? Bool ?? false else {
                return
            }

            key = CFStreamPropertyKey(kCFNetworkProxiesHTTPProxy)
        }
        else if type == kCFProxyTypeSOCKS {
            key = CFStreamPropertyKey(kCFStreamPropertySOCKSProxy)
        }
        else {
            return
        }

        CFReadStreamSetProperty(httpStream, key, proxy as CFDictionary)
    }

    func invalidateAndStop() {
        delegate = nil
        httpStream?.delegate = nil
        httpStream?.remove(from: runLoop, forMode: runLoopMode)
        httpStream?.close()
        httpStream = nil
    }

    deinit {
        invalidateAndStop()
    }


    // MARK: StreamDelegate

    public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        assert(aStream == httpStream)

        // Handle the response as soon as it's available
        if !haveReceivedResponse,
            let response = aStream.property(forKey: Stream.PropertyKey(kCFStreamPropertyHTTPResponseHeader as String)),
            CFHTTPMessageIsHeaderComplete(response as! CFHTTPMessage),
            let url = aStream.property(forKey: Stream.PropertyKey(kCFStreamPropertyHTTPFinalURL as String)) as? URL,
            let urlResponse = HTTPURLResponse(url: url, message: response as! CFHTTPMessage)
        {
            // By reaching this point, the response was not a valid request for authentication,
            // so go ahead and report it
            haveReceivedResponse = true

            /* Handle redirects */
            if [301, 302, 307].contains(urlResponse.statusCode),
                let newURL = urlResponse.allHeaderFields["Location"] as? String {

                var newRequest = request
                newRequest.httpShouldUsePipelining = true
                newRequest.url = URL(string: newURL, relativeTo: request.url)
                if request.mainDocumentURL == request.url {
                    // Previous request *was* the maindocument request.
                    newRequest.mainDocumentURL = newRequest.url
                }

                delegate?.http(connection: self, willPerformHTTPRedirection: urlResponse, newRequest: newRequest)
            }
            else {
                delegate?.http(connection: self, didReceiveResponse: urlResponse)
            }
        }

        // Next course of action depends on what happened to the stream.
        switch eventCode {

        // Report an error in the stream as the operation failing
        case Stream.Event.errorOccurred:
            delegate?.http(connection: self, didCompleteWithError: aStream.streamError)

        // Report the end of the stream to the delegate
        case Stream.Event.endEncountered:
            delegate?.http(connection: self, didCompleteWithError: nil)

        case Stream.Event.hasBytesAvailable:
            guard let aStream = aStream as? InputStream else {
                return
            }

            var data = Data(capacity: 1024)

            while aStream.hasBytesAvailable {
                let count = aStream.read(&buf, maxLength: 1024)
                data.append(buf, count: count)
            }

            delegate?.http(connection: self, didReceiveData: data)

        default:
            break
        }
    }
}
