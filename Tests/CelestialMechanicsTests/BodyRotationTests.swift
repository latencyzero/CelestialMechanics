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
	@Test("Axes are orthonormal", arguments: PlanetIdentifier.allCases)
	func axesAreOrthonormal(_ inPlanet: PlanetIdentifier)
	{
		let orientation = BodyRotation.orientation(of: inPlanet, atDate: Self.date)

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
				(PlanetIdentifier.earth, 23.44),
				(.mars, 25.19),
				(.jupiter, 3.13),
				(.saturn, 26.73),
				(.uranus, 82.23),
				(.neptune, 28.32),
				(.venus, 2.64),
			])
	func axialTilt(_ inPlanet: PlanetIdentifier, _ inExpectedDegrees: Double)
	{
		let pole = BodyRotation.orientation(of: inPlanet, atDate: Self.date).northPole
		let orbitNormal = Self.orbitNormal(of: inPlanet)
		let tilt = acos(Self.dot(pole, orbitNormal)) * 180.0 / .pi

		#expect(abs(tilt - inExpectedDegrees) < 0.5)
	}

	//	At noon UTC the Sun is near Greenwich’s meridian, give or take the
	//	equation of time (about −7½ minutes, or 2°, around the March equinox)…

	@Test("Earth’s prime meridian faces the Sun at noon UTC")
	func earthPrimeMeridianAtNoon()
	{
		let noon = Date(timeIntervalSince1970: 1_774_008_000.0)		//	2026-03-20 12:00 UTC
		let orientation = BodyRotation.orientation(of: .earth, atDate: noon)
		let earth = OrbitalElements.position(ofKind: .fixedBody(.earth), atDate: noon)
		let towardSun = (-1.0 / earth.magnitude) * earth

		//	Compare them in Earth’s equatorial plane…

		let pole = orientation.northPole
		let sunInEquator = towardSun - Self.dot(towardSun, pole) * pole
		let cosAngle = Self.dot(sunInEquator, orientation.primeMeridian) / sunInEquator.magnitude
		let angle = acos(min(cosAngle, 1.0)) * 180.0 / .pi

		#expect(angle < 4.0)
	}

	private
	static
	func
	orbitNormal(of inPlanet: PlanetIdentifier) -> CartesianPosition
	{
		let now = OrbitalElements.position(ofKind: .fixedBody(inPlanet), atDate: Self.date)
		let later = OrbitalElements.position(ofKind: .fixedBody(inPlanet), atDate: Self.date.addingTimeInterval(86_400.0))
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

	private	static	let	date	:	Date	=	Date(timeIntervalSince1970: 1_791_460_800.0)		//	2026-10-08 12:00 UTC
}
