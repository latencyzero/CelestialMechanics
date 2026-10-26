//
//  BodyRotationTests.swift
//  CelestialMechanicsTests
//

import Foundation
import Testing
@testable import CelestialMechanics

@Suite("Body Rotation")
struct
BodyRotationTests
{
	@Test("Axes are orthonormal", arguments: BodyRotationTests.modeled)
	func axesAreOrthonormal(_ inBody: BodyIdentifier)
		throws
	{
		let orientation = try #require(BodyRotation.orientation(of: inBody, atDate: Self.date))

		#expect(abs(orientation.northPole.magnitude - 1.0) < 1.0e-12)
		#expect(abs(orientation.primeMeridian.magnitude - 1.0) < 1.0e-12)
		#expect(abs(orientation.east.magnitude - 1.0) < 1.0e-12)
		#expect(abs(Self.dot(orientation.northPole, orientation.primeMeridian)) < 1.0e-12)
	}

	//	Obliquity to the orbit, from the NASA Planetary Fact Sheet. The Fact
	//	Sheet gives 177.36° for Venus and 97.77° for Uranus, measured from the
	//	right-hand-rule pole, but the IAU’s north is the opposite pole for these
	//	retrograde rotators, so they’re 180° minus that here…

	@Test("Axial tilts are about right",
			arguments:
			[
				(BodyIdentifier.earth, 23.44),
				(.mars, 25.19),
				(.jupiter, 3.13),
				(.saturn, 26.73),
				(.uranus, 82.23),
				(.neptune, 28.32),
				(.venus, 2.64),
			])
	func axialTilt(_ inPlanet: BodyIdentifier, _ inExpectedDegrees: Double)
		throws
	{
		let pole = try #require(BodyRotation.orientation(of: inPlanet, atDate: Self.date)).northPole
		let orbitNormal = Self.orbitNormal(of: inPlanet)
		let tilt = acos(Self.dot(pole, orbitNormal)) * 180.0 / .pi

		#expect(abs(tilt - inExpectedDegrees) < 0.5)
	}

	//	Venus’s model is all constants and a linear W, so the generic form,
	//	given the same numbers, must agree with it…

	@Test("Orientation from constant elements matches a planet with constant elements")
	func orientationFromConstantElements()
		throws
	{
		let expected = try #require(BodyRotation.orientation(of: .venus, atDate: Self.date))
		let actual = BodyRotation.orientation(rightAscension: 272.76, declination: 67.16, w0: 160.20, spinRate: -1.4813688, atDate: Self.date)

		#expect(abs(actual.northPole.x - expected.northPole.x) < 1.0e-12)
		#expect(abs(actual.northPole.y - expected.northPole.y) < 1.0e-12)
		#expect(abs(actual.northPole.z - expected.northPole.z) < 1.0e-12)
		#expect(abs(actual.primeMeridian.x - expected.primeMeridian.x) < 1.0e-12)
		#expect(abs(actual.primeMeridian.y - expected.primeMeridian.y) < 1.0e-12)
		#expect(abs(actual.primeMeridian.z - expected.primeMeridian.z) < 1.0e-12)
	}

	//	At noon UTC the Sun is near Greenwich’s meridian, give or take the
	//	equation of time (about −7½ minutes, or 2°, around the March equinox)…

	@Test("Earth’s prime meridian faces the Sun at noon UTC")
	func earthPrimeMeridianAtNoon()
		throws
	{
		let noon = Date(timeIntervalSince1970: 1_774_008_000.0)		//	2026-03-20 12:00 UTC
		let orientation = try #require(BodyRotation.orientation(of: .earth, atDate: noon))
		let earth = OrbitalElements.position(of: .ephemeris(.earth), atDate: noon)
		let towardSun = (-1.0 / earth.magnitude) * earth

		//	Compare them in Earth’s equatorial plane…

		let pole = orientation.northPole
		let sunInEquator = towardSun - Self.dot(towardSun, pole) * pole
		let cosAngle = Self.dot(sunInEquator, orientation.primeMeridian) / sunInEquator.magnitude
		let angle = acos(min(cosAngle, 1.0)) * 180.0 / .pi

		#expect(angle < 4.0)
	}

	//	The Moon is tidally locked, so its prime meridian (0°) points at Earth, give
	//	or take libration (up to about 8° in all, and the IAU’s periodic terms
	//	that this leaves out are a good part of that)…

	@Test("The Moon’s prime meridian faces Earth")
	func moonPrimeMeridianFacesEarth()
		throws
	{
		for days in stride(from: 0.0, to: 28.0, by: 3.5)
		{
			let date = Self.date.addingTimeInterval(days * 86_400.0)
			let orientation = try #require(BodyRotation.orientation(of: .moon, atDate: date))
			let earth = OrbitalElements.position(of: .ephemeris(.earth), atDate: date)
			let moon = OrbitalElements.position(of: .ephemeris(.moon), atDate: date)
			let towardEarth = (1.0 / earth.distance(to: moon)) * (earth - moon)
			let cosAngle = Self.dot(towardEarth, orientation.primeMeridian)
			let angle = acos(min(cosAngle, 1.0)) * 180.0 / .pi

			#expect(angle < 10.0)
		}
	}

	//	The IAU’s constant pole is the Moon’s mean pole, which sits on the ecliptic
	//	pole to within a few hundredths of a degree. The 1.54° tilt of its equator
	//	from the ecliptic is in the periodic terms, which this leaves out…

	@Test("The Moon’s mean pole is the ecliptic pole")
	func moonMeanPole()
		throws
	{
		let pole = try #require(BodyRotation.orientation(of: .moon, atDate: Self.date)).northPole
		let tilt = acos(pole.z) * 180.0 / .pi

		#expect(tilt < 0.5)
	}

	@Test("A body this build doesn’t know has no orientation")
	func unknownBodyHasNoOrientation()
	{
		#expect(BodyRotation.orientation(of: .unknown("vesta"), atDate: Self.date) == nil)
	}

	private
	static
	func
	orbitNormal(of inPlanet: BodyIdentifier) -> CartesianPosition
	{
		let now = OrbitalElements.position(of: .ephemeris(inPlanet), atDate: Self.date)
		let later = OrbitalElements.position(of: .ephemeris(inPlanet), atDate: Self.date.addingTimeInterval(86_400.0))
		let n = CartesianPosition(x: now.y * later.z - now.z * later.y,
									y: now.z * later.x - now.x * later.z,
									z: now.x * later.y - now.y * later.x)

		return (1.0 / n.magnitude) * n
	}

	private
	static
	func
	dot(_ inA: CartesianPosition, _ inB: CartesianPosition) -> Double
	{
		return inA.x * inB.x + inA.y * inB.y + inA.z * inB.z
	}

	//	The planets and our Moon. The Sun, Pluto and the other moons have no model yet…

	static	let	modeled	:	[BodyIdentifier]	=	BodyIdentifier.planets + [.moon]

	private	static	let	date	:	Date	=	Date(timeIntervalSince1970: 1_791_460_800.0)		//	2026-10-08 12:00 UTC
}
