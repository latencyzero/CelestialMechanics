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
		let json = Data("[\"vesta\"]".utf8)
		let decoded = try JSONDecoder().decode([BodyIdentifier].self, from: json)

		#expect(decoded == [.unknown("vesta")])
		#expect(decoded[0].isKnown == false)
		#expect(try JSONEncoder().encode(decoded) == json)
	}

	//	The wire format is `Placement`’s default enum synthesis around the string…

	@Test("An ephemeris placement keeps its wire format, and tolerates a body it doesn’t know")
	func placementWireFormat()
		throws
	{
		let moon = Data("{\"ephemeris\":{\"_0\":\"moon\"}}".utf8)
		let vesta = Data("{\"ephemeris\":{\"_0\":\"vesta\"}}".utf8)

		#expect(try JSONDecoder().decode(Placement.self, from: moon) == .ephemeris(.moon))
		#expect(try JSONDecoder().decode(Placement.self, from: vesta) == .ephemeris(.unknown("vesta")))
		#expect(try JSONEncoder().encode(Placement.ephemeris(.moon)) == moon)
	}

	@Test("Only the eight planets are planets")
	func planets()
	{
		#expect(BodyIdentifier.planets.count == 8)
		#expect(BodyIdentifier.planets.allSatisfy { $0.isPlanet })
		#expect(BodyIdentifier.moon.isPlanet == false)
		#expect(BodyIdentifier.unknown("vesta").isPlanet == false)
		#expect(BodyIdentifier.pluto.isPlanet == false)
		#expect(BodyIdentifier.sun.isPlanet == false)
	}

	@Test("Every known body is listed once, and only moons have a parent")
	func knownBodies()
	{
		#expect(Set(BodyIdentifier.known).count == BodyIdentifier.known.count)
		#expect(BodyIdentifier.known.count == 1 + 8 + 1 + 13)
		#expect(BodyIdentifier.moons.allSatisfy { $0.isMoon && $0.parent?.isPlanet == true })
		#expect(BodyIdentifier.known.filter { $0.isMoon } == BodyIdentifier.moons)
		#expect(BodyIdentifier.unknown("vesta").parent == nil)
		#expect(BodyIdentifier.titan.parent == .saturn)
		#expect(BodyIdentifier.io.parent == .jupiter)
		#expect(BodyIdentifier.moon.parent == .earth)
	}
}
