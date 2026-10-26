//
//  PlanetaryMoonsTests.swift
//  CelestialMechanicsTests
//

import Foundation
import Testing
@testable import CelestialMechanics

@Suite("Planetary moons")
struct
PlanetaryMoonsTests
{
	/**
		The orbits are nearly circular, so a moon is about its semi-major axis from its
		planet. That checks SwiftAA’s units (planetary radii) as well as the rotation
		out of the Earth-view frame, which can’t change a distance.
	*/

	@Test("A moon is about its semi-major axis from its planet", arguments: PlanetaryMoonsTests.moons)
	func distanceFromPlanet(_ inMoon: BodyIdentifier)
		throws
	{
		let planet = try #require(inMoon.parent)
		let axis = try #require(SolarSystemData.meanOrbitRadiusInMeters[inMoon])

		for days in stride(from: 0.0, to: 400.0, by: 7.3)
		{
			let date = Self.date.addingTimeInterval(days * 86_400.0)
			let offset = Self.offset(of: inMoon, from: planet, atDate: date)

			#expect(abs(offset.magnitude / axis - 1.0) < 0.12)
		}
	}

	/**
		The moons orbit near their planet’s equator, so they stay near its equatorial
		plane (Mimas’s 1.6° inclination is the most). A wrong axis would tilt the orbit by
		the planet’s tilt to the sky, and a wrong Z would run it backward. Iapetus is
		left out: its orbit is 15° off Saturn’s equator.
	*/

	@Test("The inner moons stay near their planet’s equator, and go around prograde", arguments: PlanetaryMoonsTests.equatorialMoons)
	func nearEquatorialPlane(_ inMoon: BodyIdentifier)
		throws
	{
		let planet = try #require(inMoon.parent)
		let pole = try #require(BodyRotation.orientation(of: planet, atDate: Self.date)?.northPole)
		let period = try #require(SolarSystemData.orbitPeriodInDays[inMoon])

		for days in stride(from: 0.0, to: 100.0, by: 3.1)
		{
			let date = Self.date.addingTimeInterval(days * 86_400.0)
			let offset = Self.offset(of: inMoon, from: planet, atDate: date)
			let later = Self.offset(of: inMoon, from: planet, atDate: date.addingTimeInterval(period / 100.0 * 86_400.0))

			#expect(abs(Self.dot(offset, pole)) / offset.magnitude < 0.04)

			//	Angular momentum along the planet’s north pole…

			let momentum = CartesianPosition(x: offset.y * later.z - offset.z * later.y,
												y: offset.z * later.x - offset.x * later.z,
												z: offset.x * later.y - offset.y * later.x)

			#expect(Self.dot(momentum, pole) > 0.0)
		}
	}

	@Test("A moon goes around its planet once in its period", arguments: PlanetaryMoonsTests.equatorialMoons)
	func period(_ inMoon: BodyIdentifier)
		throws
	{
		let planet = try #require(inMoon.parent)
		let period = try #require(SolarSystemData.orbitPeriodInDays[inMoon])

		let start = Self.offset(of: inMoon, from: planet, atDate: Self.date)
		let end = Self.offset(of: inMoon, from: planet, atDate: Self.date.addingTimeInterval(period * 86_400.0))
		let angle = acos(min(Self.dot(start, end) / (start.magnitude * end.magnitude), 1.0)) * 180.0 / .pi

		//	Not exact: the period is sidereal, and the planet’s moving, which turns the
		//	line the orbit is measured from…

		#expect(angle < 10.0)
	}

	//	The cheap offset is what a moon’s position is made of, so they agree…

	@Test("A moon’s offset from its parent is its position minus its planet’s", arguments: BodyIdentifier.moons)
	func offsetFromParent(_ inMoon: BodyIdentifier)
		throws
	{
		let planet = try #require(inMoon.parent)
		let offset = try #require(OrbitalElements.offsetFromParent(of: .ephemeris(inMoon), atDate: Self.date))

		#expect(offset.distance(to: Self.offset(of: inMoon, from: planet, atDate: Self.date)) < 1.0)
	}

	@Test("Only moons and orbits have an offset from a parent")
	func offsetFromParentOfOthers()
	{
		#expect(OrbitalElements.offsetFromParent(of: .ephemeris(.mars), atDate: Self.date) == nil)
		#expect(OrbitalElements.offsetFromParent(of: .ephemeris(.unknown("vesta")), atDate: Self.date) == nil)
		#expect(OrbitalElements.offsetFromParent(of: .attached(CartesianPosition()), atDate: Self.date) == nil)

		let elements = KeplerianOrbitElements(semiMajorAxisInMeters: 9_376_000.0, eccentricity: 0.0151, inclination: 1.08, longitudeOfAscendingNode: 49.0, argumentOfPeriapsis: 0.0, meanAnomaly: 0.0, orbitPeriodInDays: 0.31891, epoch: JulianDate(date: Self.date))
		let offset = OrbitalElements.offsetFromParent(of: .keplerian(elements), atDate: Self.date)

		#expect(offset == OrbitalElements.position(of: .keplerian(elements), atDate: Self.date))
	}

	@Test("The moons’ positions are heliocentric: planet plus offset")
	func absolute()
	{
		let planet = OrbitalElements.position(of: .ephemeris(.jupiter), atDate: Self.date)
		let io = OrbitalElements.position(of: .ephemeris(.io), atDate: Self.date)

		#expect(io.distance(to: planet) < 4.5e8)
		#expect(io.distance(to: planet) > 3.8e8)
	}

	@Test("Light time across a planet’s moons is seconds")
	func lightTime()
	{
		let seconds = LightTime.seconds(fromPlacement: .ephemeris(.jupiter), toPlacement: .ephemeris(.callisto), atDate: Self.date)

		#expect(seconds > 5.0)
		#expect(seconds < 7.5)
	}

	//	MARK: - The Sun and Pluto

	@Test("The Sun is the origin")
	func sun()
	{
		#expect(OrbitalElements.position(of: .ephemeris(.sun), atDate: Self.date) == CartesianPosition())
	}

	//	Pluto was near 36 AU in 2026, in the sky’s Aquarius (about 300°–310° ecliptic
	//	longitude)…

	@Test("Pluto is about 36 AU out, in the right part of the sky")
	func pluto()
	{
		let position = OrbitalElements.position(of: .ephemeris(.pluto), atDate: Self.date)
		let au = 149_597_870_700.0
		var longitude = atan2(position.y, position.x) * 180.0 / .pi

		if longitude < 0.0
		{
			longitude += 360.0
		}

		#expect(position.magnitude / au > 34.0)
		#expect(position.magnitude / au < 38.0)
		#expect(longitude > 298.0)
		#expect(longitude < 310.0)
		#expect(abs(position.z) < 0.35 * position.magnitude)
	}

	//	MARK: - Keplerian moons

	/**
		A moon on a `.keplerian` placement goes around whatever it’s `at`, wherever that
		is, like the real Deimos (a Mars moon, 23,463 km out, 1.263 days).
	*/

	@Test("A keplerian placement orbits a moving parent")
	func keplerianMoon()
	{
		let deimos = KeplerianOrbitElements(semiMajorAxisInMeters: 23_463_200.0, eccentricity: 0.0003, inclination: 1.8, longitudeOfAscendingNode: 49.0, argumentOfPeriapsis: 0.0, meanAnomaly: 0.0, orbitPeriodInDays: 1.263, epoch: JulianDate(date: Self.date))

		for days in stride(from: 0.0, to: 60.0, by: 1.7)
		{
			let date = Self.date.addingTimeInterval(days * 86_400.0)
			let mars = OrbitalElements.position(of: .ephemeris(.mars), atDate: date)
			let moon = OrbitalElements.position(of: .keplerian(deimos), parentPosition: mars, parentPlacement: .ephemeris(.mars), atDate: date)

			#expect(abs(moon.distance(to: mars) / 23_463_200.0 - 1.0) < 0.001)
		}
	}

	//	MARK: - Helpers

	private
	static
	func
	offset(of inMoon: BodyIdentifier, from inPlanet: BodyIdentifier, atDate inDate: Date) -> CartesianPosition
	{
		return OrbitalElements.position(of: .ephemeris(inMoon), atDate: inDate) - OrbitalElements.position(of: .ephemeris(inPlanet), atDate: inDate)
	}

	private
	static
	func
	dot(_ inA: CartesianPosition, _ inB: CartesianPosition) -> Double
	{
		return inA.x * inB.x + inA.y * inB.y + inA.z * inB.z
	}

	static	let	moons			:	[BodyIdentifier]	=	BodyIdentifier.moons.filter { $0 != .moon }
	static	let	equatorialMoons	:	[BodyIdentifier]	=	PlanetaryMoonsTests.moons.filter { $0 != .iapetus }

	private	static	let	date	:	Date	=	Date(timeIntervalSince1970: 1_791_460_800.0)		//	2026-10-08 12:00 UTC
}
