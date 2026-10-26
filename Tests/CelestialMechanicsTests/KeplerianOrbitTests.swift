//
//  KeplerianOrbitTests.swift
//  CelestialMechanicsTests
//

import Foundation
import Testing
@testable import CelestialMechanics

@Suite("Keplerian orbits")
struct KeplerianOrbitTests
{
	private	static	let	astronomicalUnit	:	Double	=	149_597_870_700.0

	//	Approximately 433 Eros, from JPL's Small-Body Database (epoch 2026-Jan-01)…

	private static func
	eros(meanAnomaly inMeanAnomaly: Double = 0.0) -> KeplerianOrbitElements
	{
		return KeplerianOrbitElements(semiMajorAxisInMeters: 1.4581 * Self.astronomicalUnit,
										eccentricity: 0.2229,
										inclination: 10.83,
										longitudeOfAscendingNode: 304.3,
										argumentOfPeriapsis: 178.9,
										meanAnomaly: inMeanAnomaly,
										orbitPeriodInDays: 643.2,
										epoch: JulianDate(2_461_041.5))
	}

	private static func
	distanceFromSun(of inElements: KeplerianOrbitElements, daysAfterEpoch inDays: Double) -> Double
	{
		let position = OrbitalElements.position(of: .keplerian(inElements),
												atDate: JulianDate(inElements.epoch.value + inDays).asDate)
		return position.distance(to: CartesianPosition())
	}

	@Test("Mean anomaly 0 is perihelion and 180° is aphelion")
	func perihelionAndAphelion()
	{
		let perihelion = Self.eros(meanAnomaly: 0.0)
		let aphelion = Self.eros(meanAnomaly: 180.0)
		let a = perihelion.semiMajorAxisInMeters

		#expect(abs(Self.distanceFromSun(of: perihelion, daysAfterEpoch: 0.0) - a * (1.0 - 0.2229)) < 1.0)
		#expect(abs(Self.distanceFromSun(of: aphelion, daysAfterEpoch: 0.0) - a * (1.0 + 0.2229)) < 1.0)
	}

	@Test("The body returns to the same place after one period")
	func periodic()
	{
		let elements = Self.eros(meanAnomaly: 77.0)

		//	Precession moves the frame slightly in a period, so compare the distance…

		let start = Self.distanceFromSun(of: elements, daysAfterEpoch: 10.0)
		let later = Self.distanceFromSun(of: elements, daysAfterEpoch: 10.0 + elements.orbitPeriodInDays)
		#expect(abs(start - later) < 1.0)
	}

	@Test("The orbit stays within the inclined plane's height")
	func inclination()
	{
		let elements = Self.eros()
		let maxZ = elements.semiMajorAxisInMeters * (1.0 + 0.2229) * sin(10.83 * .pi / 180.0)

		for day in stride(from: 0.0, through: 643.0, by: 20.0)
		{
			let position = OrbitalElements.position(of: .keplerian(elements), atDate: JulianDate(elements.epoch.value + day).asDate)
			#expect(abs(position.z) <= maxZ * 1.0001)
		}
	}

	@Test("Kepler's equation is solved across eccentricities")
	func keplerResidual()
	{
		for e in [0.0, 0.1, 0.2229, 0.5, 0.9, 0.99]
		{
			for m in stride(from: -3.1, through: 3.1, by: 0.3)
			{
				let anomaly = KeplerianOrbitElements.solveKepler(meanAnomaly: m, eccentricity: e)
				#expect(abs(anomaly - e * sin(anomaly) - m) < 1e-10)
			}
		}
	}

	@Test("A parent's position is added")
	func relativeToParent()
	{
		let elements = Self.eros()
		let date = elements.epoch.asDate
		let parent = CartesianPosition(x: 1.0e9, y: -2.0e9, z: 3.0e9)
		let alone = OrbitalElements.position(of: .keplerian(elements), atDate: date)
		let moved = OrbitalElements.position(of: .keplerian(elements), parentPosition: parent, atDate: date)

		#expect(moved.distance(to: alone + parent) < 1.0)
	}

	@Test("A keplerian placement is relative and survives encoding")
	func codable()
		throws
	{
		let placement = Placement.keplerian(Self.eros(meanAnomaly: 12.0))
		let decoded = try JSONDecoder().decode(Placement.self, from: JSONEncoder().encode(placement))

		#expect(decoded == placement)
		#expect(!placement.isAbsolute)
	}

	@Test("Out-of-range elements are invalid")
	func validity()
	{
		var elements = Self.eros()
		#expect(elements.isValid)

		elements.eccentricity = 1.2
		#expect(!elements.isValid)

		elements = Self.eros()
		elements.orbitPeriodInDays = 0.0
		#expect(!elements.isValid)
	}
}
