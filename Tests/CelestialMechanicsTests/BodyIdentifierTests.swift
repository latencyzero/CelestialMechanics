//
//  BodyIdentifierTests.swift
//  CelestialMechanicsTests
//

import Foundation
import Testing
@testable import CelestialMechanics

@Suite("Body Identifier")
struct
BodyIdentifierTests
{
	@Test("Known bodies encode as their plain case name", arguments: BodyIdentifier.known)
	func encodesAsPlainString(_ inBody: BodyIdentifier)
		throws
	{
		let data = try JSONEncoder().encode([inBody])
		let text = try #require(String(data: data, encoding: .utf8))

		#expect(text == "[\"\(inBody.rawValue)\"]")
	}

	@Test("Known bodies round-trip", arguments: BodyIdentifier.known)
	func roundTrips(_ inBody: BodyIdentifier)
		throws
	{
		let data = try JSONEncoder().encode([inBody])

		#expect(try JSONDecoder().decode([BodyIdentifier].self, from: data) == [inBody])
		#expect(BodyIdentifier(rawValue: inBody.rawValue) == inBody)
		#expect(inBody.isKnown)
	}

	//	A client that predates a body must still decode the Location that names it,
	//	and send the same string back…

	@Test("An unrecognized string decodes as .unknown and encodes back unchanged")
	func unknownRoundTrips()
		throws
	{
		let json = Data("[\"io\"]".utf8)
		let decoded = try JSONDecoder().decode([BodyIdentifier].self, from: json)

		#expect(decoded == [.unknown("io")])
		#expect(decoded[0].isKnown == false)
		#expect(try JSONEncoder().encode(decoded) == json)
	}

	//	The wire format is `Placement`’s default enum synthesis around the string…

	@Test("An ephemeris placement keeps its wire format, and tolerates a body it doesn’t know")
	func placementWireFormat()
		throws
	{
		let moon = Data("{\"ephemeris\":{\"_0\":\"moon\"}}".utf8)
		let io = Data("{\"ephemeris\":{\"_0\":\"io\"}}".utf8)

		#expect(try JSONDecoder().decode(Placement.self, from: moon) == .ephemeris(.moon))
		#expect(try JSONDecoder().decode(Placement.self, from: io) == .ephemeris(.unknown("io")))
		#expect(try JSONEncoder().encode(Placement.ephemeris(.moon)) == moon)
	}

	@Test("Only the eight planets are planets")
	func planets()
	{
		#expect(BodyIdentifier.planets.count == 8)
		#expect(BodyIdentifier.planets.allSatisfy { $0.isPlanet })
		#expect(BodyIdentifier.moon.isPlanet == false)
		#expect(BodyIdentifier.unknown("io").isPlanet == false)
		#expect(BodyIdentifier.known == BodyIdentifier.planets + [.moon])
	}
}
