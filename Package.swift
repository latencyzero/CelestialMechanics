// swift-tools-version:5.9
import PackageDescription

//	NOTE: SwiftAA's own Package.swift declares macOS 10.15 / iOS 13 as its floor, and
//	builds a C++ target (AA+) plus a C bridge (AABridge) underneath the Swift API. That
//	C++ target is the one open question for the Vapor server side: SwiftAA is documented
//	as Linux-capable, but that hasn't been verified by actually building this package on
//	Linux. Worth a quick `swift build` on the server's target OS before relying on it there.

let package = Package(
	name: "CelestialMechanics",
	platforms:
	[
		.iOS(.v16),
		.macOS(.v13),
	],
	products:
	[
		.library(name: "CelestialMechanics", targets: ["CelestialMechanics"]),
	],
	dependencies:
	[
		.package(url: "https://github.com/onekiloparsec/SwiftAA.git", from: "3.0.1"),
	],
	targets:
	[
		.target(
			name: "CelestialMechanics",
			dependencies:
			[
				.product(name: "SwiftAA", package: "SwiftAA"),
			]),
		.testTarget(
			name: "CelestialMechanicsTests",
			dependencies:
			[
				"CelestialMechanics",
			]),
	]
)
