//
//  MoonTests.swift
//  CelestialMechanicsTests
//

import Foundation
import Testing
@testable import CelestialMechanics

@Suite("Moon")
struct
MoonTests
{
	//	Earth–Moon distance ranges from about 356,400 to 406,700 km: 1.19 to 1.36 s
	//	of light time…

	@Test("The Moon is about 1.2–1.4 light-seconds from Earth")
	func lightTimeToEarth()
	{
		for days in stride(from: 0.0, to: 28.0, by: 2.0)
		{
			let date = Self.date.addingTimeInterval(days * 86_400.0)
			let seconds = LightTime.seconds(fromPlacement: .ephemeris(.earth), toPlacement: .ephemeris(.moon), atDate: date)

			#expect(seconds > 1.15)
			#expect(seconds < 1.40)
		}
	}

	@Test("The Moon goes around Earth in about 27 days")
	func period()
	{
		//	Its direction from Earth is back where it started after a sidereal month…

		let start = Self.direction(of: .moon, from: .earth, atDate: Self.date)
		let end = Self.direction(of: .moon, from: .earth, atDate: Self.date.addingTimeInterval(27.321661 * 86_400.0))
		let angle = acos(min(start.x * end.x + start.y * end.y + start.z * end.z, 1.0)) * 180.0 / .pi

		#expect(angle < 6.0)		//	The orbit isn't circular, so it's not exact
	}

	@Test("The Moon is within about 5° of the ecliptic")
	func nearEcliptic()
	{
		let earth = OrbitalElements.position(of: .ephemeris(.earth), atDate: Self.date)
		let moon = OrbitalElements.position(of: .ephemeris(.moon), atDate: Self.date)
		let offset = moon - earth

		#expect(abs(asin(offset.z / offset.magnitude)) * 180.0 / .pi < 5.5)
	}

	//	An older client reads a newer server’s body as `.unknown`…

	@Test("A body this build doesn’t know sits at its parent’s position")
	func unknownBodyIsAtParent()
	{
		let parent = CartesianPosition(x: 1.0e11, y: 2.0e10, z: -3.0e9)
		let position = OrbitalElements.position(of: .ephemeris(.unknown("vesta")), parentPosition: parent, atDate: Self.date)

		#expect(position == parent)
		#expect(OrbitalElements.position(of: .ephemeris(.unknown("vesta")), atDate: Self.date) == CartesianPosition())
	}

	//	A city at 0° N, 0° E is on the near side, the side facing Earth…

	@Test("A surface location at the Moon’s prime meridian is on the side facing Earth")
	func surfaceOnNearSide()
	{
		let earth = OrbitalElements.position(of: .ephemeris(.earth), atDate: Self.date)
		let moon = OrbitalElements.position(of: .ephemeris(.moon), atDate: Self.date)
		let city = OrbitalElements.position(of: .surface(SurfaceCoordinates(latitude: 0.0, longitude: 0.0)),
											parentPosition: moon,
											parentPlacement: .ephemeris(.moon),
											atDate: Self.date)

		let radius = SolarSystemData.meanRadiusInMeters[.moon] ?? 0.0

		#expect(abs(city.distance(to: moon) - radius) < 1.0)
		#expect(city.distance(to: earth) < moon.distance(to: earth))
	}

	private
	static
	func
	direction(of inBody: BodyIdentifier, from inOrigin: BodyIdentifier, atDate inDate: Date) -> CartesianPosition
	{
		let origin = OrbitalElements.position(of: .ephemeris(inOrigin), atDate: inDate)
		let body = OrbitalElements.position(of: .ephemeris(inBody), atDate: inDate)
		let offset = body - origin

		return (1.0 / offset.magnitude) * offset
	}

	private	static	let	date	:	Date	=	Date(timeIntervalSince1970: 1_791_460_800.0)		//	2026-10-08 12:00 UTC
}
