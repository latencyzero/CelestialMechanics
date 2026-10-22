//
//  PlacementTests.swift
//  CelestialMechanicsTests
//

import Foundation
import Testing
@testable import CelestialMechanics

@Suite("Placement")
struct PlacementTests
{
	private	static	let	date	:	Date	=	Date(timeIntervalSince1970: 1_791_460_800.0)		//	2026-10-08 12:00 UTC

	@Test("A surface location is a body radius (plus altitude) from the body’s center")
	func surfaceDistanceFromCenter()
		throws
	{
		let earth = OrbitalElements.position(of: .ephemeris(.earth), atDate: Self.date)
		let radius = try #require(SolarSystemData.meanRadiusInMeters[.earth])

		for (lat, lon) in [(0.0, 0.0), (34.0, -118.0), (-90.0, 0.0), (51.5, 0.0)]
		{
			let city = OrbitalElements.position(of: .surface(SurfaceCoordinates(latitude: lat, longitude: lon, altitude: 1_000.0)),
													parentPosition: earth,
													parentPlacement: .ephemeris(.earth),
													atDate: Self.date)
			#expect(abs(city.distance(to: earth) - (radius + 1_000.0)) < 1.0)
		}
	}

	@Test("Opposite longitudes on the equator are two radii apart")
	func oppositeLongitudes()
		throws
	{
		let earth = OrbitalElements.position(of: .ephemeris(.earth), atDate: Self.date)
		let radius = try #require(SolarSystemData.meanRadiusInMeters[.earth])

		let a = OrbitalElements.position(of: .surface(SurfaceCoordinates(latitude: 0.0, longitude: 0.0)), parentPosition: earth, parentPlacement: .ephemeris(.earth), atDate: Self.date)
		let b = OrbitalElements.position(of: .surface(SurfaceCoordinates(latitude: 0.0, longitude: 180.0)), parentPosition: earth, parentPlacement: .ephemeris(.earth), atDate: Self.date)
		#expect(abs(a.distance(to: b) - 2.0 * radius) < 1.0)
	}

	@Test("The north pole location lies along the body’s pole")
	func poleLocation()
	{
		let earth = OrbitalElements.position(of: .ephemeris(.earth), atDate: Self.date)
		let pole = OrbitalElements.position(of: .surface(SurfaceCoordinates(latitude: 90.0, longitude: 0.0)), parentPosition: earth, parentPlacement: .ephemeris(.earth), atDate: Self.date)
		let up = BodyRotation.orientation(of: .earth, atDate: Self.date).northPole
		let direction = (1.0 / pole.distance(to: earth)) * (pole - earth)

		#expect(direction.distance(to: up) < 1e-9)
	}

	@Test("A surface location rotates with its body")
	func surfaceRotates()
	{
		let earth = OrbitalElements.position(of: .ephemeris(.earth), atDate: Self.date)
		let coordinates = SurfaceCoordinates(latitude: 0.0, longitude: 0.0)
		let now = OrbitalElements.position(of: .surface(coordinates), parentPosition: earth, parentPlacement: .ephemeris(.earth), atDate: Self.date)

		//	Half a sidereal day later it’s on the other side (the parent position is held fixed to isolate rotation)…

		let later = Self.date.addingTimeInterval(86_164.0905 / 2.0)
		let then = OrbitalElements.position(of: .surface(coordinates), parentPosition: earth, parentPlacement: .ephemeris(.earth), atDate: later)
		#expect(now.distance(to: then) > 1.9 * (SolarSystemData.meanRadiusInMeters[.earth] ?? 0.0))
	}

	@Test("A surface location on a non-body parent sits at the parent")
	func surfaceOnNonBody()
	{
		let parent = CartesianPosition(x: 1.0, y: 2.0, z: 3.0)
		let p = OrbitalElements.position(of: .surface(SurfaceCoordinates(latitude: 10.0, longitude: 10.0)), parentPosition: parent, parentPlacement: .attached(CartesianPosition()), atDate: Self.date)
		#expect(p == parent)
	}

	@Test("An orbit is measured from its parent")
	func orbitAroundParent()
	{
		let parent = OrbitalElements.position(of: .ephemeris(.jupiter), atDate: Self.date)
		let elements = CircularOrbitElements(orbitRadiusInMeters: 4.2e8, orbitPeriodInDays: 1.76, startingAngle: 0.0, epoch: JulianDate(date: Self.date))
		let station = OrbitalElements.position(of: .orbit(elements), parentPosition: parent, parentPlacement: .ephemeris(.jupiter), atDate: Self.date)
		#expect(abs(station.distance(to: parent) - 4.2e8) < 1.0)
	}

	@Test("Attached adds its offset to the parent")
	func attachedOffset()
	{
		let parent = CartesianPosition(x: 10.0, y: 0.0, z: 0.0)
		let p = OrbitalElements.position(of: .attached(CartesianPosition(x: 1.0, y: 2.0, z: 3.0)), parentPosition: parent, atDate: Self.date)
		#expect(p == CartesianPosition(x: 11.0, y: 2.0, z: 3.0))
	}

	@Test("Placement and LocalTimeRule round-trip through JSON")
	func codable()
		throws
	{
		let placements: [Placement] =
		[
			.ephemeris(.mars),
			.surface(SurfaceCoordinates(latitude: 18.4, longitude: 77.5, altitude: -2_600.0)),
			.attached(CartesianPosition()),
		]
		for placement in placements
		{
			let data = try JSONEncoder().encode(placement)
			#expect(try JSONDecoder().decode(Placement.self, from: data) == placement)
		}

		let rules: [LocalTimeRule] =
		[
			.iana("America/Los_Angeles"),
			.localMeanSolar,
			.bodyZone(offsetInHours: -3.0),
			.cycle(dayLengthInSeconds: 88_775.244, midnightEpoch: JulianDate(2_461_000.0)),
		]
		for rule in rules
		{
			let data = try JSONEncoder().encode(rule)
			#expect(try JSONDecoder().decode(LocalTimeRule.self, from: data) == rule)
		}
	}

	@Test("Validation rejects out-of-range values")
	func validation()
	{
		#expect(SurfaceCoordinates(latitude: 91.0, longitude: 0.0).isValid == false)
		#expect(SurfaceCoordinates(latitude: 0.0, longitude: 181.0).isValid == false)
		#expect(SurfaceCoordinates(latitude: 0.0, longitude: 0.0, altitude: .nan).isValid == false)
		#expect(SurfaceCoordinates(latitude: 45.0, longitude: -120.0, altitude: 100.0).isValid)

		#expect(LocalTimeRule.iana("Not/AZone").isValid == false)
		#expect(LocalTimeRule.iana("Europe/London").isValid)
		#expect(LocalTimeRule.cycle(dayLengthInSeconds: 0.0, midnightEpoch: JulianDate(0.0)).isValid == false)
		#expect(LocalTimeRule.bodyZone(offsetInHours: 30.0).isValid == false)
	}
}
