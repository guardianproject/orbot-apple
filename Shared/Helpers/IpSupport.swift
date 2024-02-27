//
//  IpSupport.swift
//  IPtProxyUI
//
//  Created by Benjamin Erhart on 17.11.21.
//  Copyright © 2019-2022 Guardian Project. All rights reserved.
//

import Foundation

open class IpSupport {

	public enum Status {

		public static let asArguments = Transport.asArguments

		public static let asConf = Transport.asConf


		case dual
		case ipV4Only
		case ipV6Only
		case unavailable


		public func torConf<T>(_ transport: Transport, _ cv: (String, String) -> T) -> [T] {
			var conf = [T]()

			if self == .ipV6Only {
				conf.append(cv("ClientPreferIPv6ORPort", "1"))

				if transport == .none {
					// Switch off IPv4, if we're on a IPv6-only network.
					conf.append(cv("ClientUseIPv4", "0"))
				}
				else {
					// ...but not, when we're using a transport. The bridge
					// configuration lines are what is important, then.
					conf.append(cv("ClientUseIPv4", "1"))
				}
			}
			else {
				conf.append(cv("ClientPreferIPv6ORPort", "auto"))
				conf.append(cv("ClientUseIPv4", "1"))
			}

			conf.append(cv("ClientUseIPv6", "1"))

			return conf
		}
	}

	public typealias Changed = (Status) -> Void

	public static var shared = IpSupport()


	public private(set) var status = Status.unavailable


	private var reachability: Reachability?

	private var callbacks = [Changed]()


	private init() {
		NotificationCenter.default.addObserver(
			self, selector: #selector(reachabilityChanged),
			name: .reachabilityChanged, object: nil)

		reachability = try? Reachability()

		reachabilityChanged()
	}

	open func start(_ changed: @escaping Changed) {
		callbacks.append(changed)

		if reachability == nil {
			reachability = try? Reachability()
		}

		try? reachability?.startNotifier()
	}

	open func stop() {
		reachability?.stopNotifier()

		callbacks.removeAll()
	}

	deinit {
		stop()

		reachability = nil
	}

	@objc private func reachabilityChanged() {
		if reachability?.connection == .unavailable {
			status = .unavailable
			callbacks.forEach({ $0(.unavailable) })

			return
		}

		let (v4, v6) = getIpAddressesOfPublicInterfaces()

		let hasPublicV4 = !v4
			.filter({ !$0.hasPrefix("127.") && !$0.hasPrefix("0.") && !$0.hasPrefix("169.254.") && !$0.hasPrefix("255.") })
			.isEmpty
		let hasPublicV6 = !v6
			.filter({ $0 != "::1" && !$0.hasPrefix("fe80:") })
			.isEmpty

		let status: Status

		switch (hasPublicV4, hasPublicV6) {
		case (true, true):
			status = .dual

		case (true, false):
			status = .ipV4Only

		case (false, true):
			status = .ipV6Only

		default:
			status = .unavailable
		}

		self.status = status
		callbacks.forEach({ $0(status) })
	}

	private func getIpAddressesOfPublicInterfaces() -> ([String], [String]) {
		var v4 = [String]()
		var v6 = [String]()

		var ifaddrs: UnsafeMutablePointer<ifaddrs>? = nil

		guard getifaddrs(&ifaddrs) == 0,
			  let firstAddr = ifaddrs
		else {
			return (v4, v6)
		}

		for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
			let ifaddr = ifptr.pointee

			guard ifaddr.ifa_flags & UInt32(IFF_UP) != 0 else {
				continue
			}

			let ifName = String(cString: ifaddr.ifa_name)

			guard ifName.hasPrefix("en") || ifName.hasPrefix("pdp_ip") else {
				continue
			}

			let family = ifaddr.ifa_addr.pointee.sa_family

			if family == AF_INET {
				if let address = getIpAddress(ifaddr), !address.isEmpty {
					v4.append(address)
				}
			}
			else if family == AF_INET6 {
				if let address = getIpAddress(ifaddr), !address.isEmpty {
					v6.append(address)
				}
			}
		}

		freeifaddrs(ifaddrs)

		return (v4, v6)
	}

	private func getIpAddress(_ ifaddr: ifaddrs) -> String? {
		var buffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))

		let result = getnameinfo(
			ifaddr.ifa_addr, socklen_t(ifaddr.ifa_addr.pointee.sa_len),
			&buffer, socklen_t(buffer.count),
			nil, 0, NI_NUMERICHOST)

		return result == 0 ? String(cString: buffer) : nil
	}
}
