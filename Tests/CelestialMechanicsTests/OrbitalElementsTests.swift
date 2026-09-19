//
//  OrbitalElementsTests.swift
//  CelestialMechanicsTests
//

import XCTest
@testable import CelestialMechanics

final
class
OrbitalElementsTests : XCTestCase
{
	func testJulianDateRoundTrip()
	{
		let originalDate = Date()
		let julianDate = JulianDate(date: originalDate)
		let roundTrippedDate = julianDate.asDate

		XCTAssertEqual(originalDate.timeIntervalSince1970, roundTrippedDate.timeIntervalSince1970, accuracy: 0.001)
	}

	func testJulianDateDaysElapsed()
	{
		let epoch = JulianDate(date: Date())
		let tenDaysLater = JulianDate(epoch.value + 10.0)

		XCTAssertEqual(tenDaysLater.daysElapsed(since: epoch), 10.0, accuracy: 0.0001)
	}

	func testCircularOrbitHoldsConstantRadius()
	{
		let elements = CircularOrbitElements(
			orbitRadiusInMeters: 1.0e11,
			orbitPeriodInDays: 400.0,
			startingAngle: 0.3,
			epoch: JulianDate(2_460_000.0))

		for daysElapsed in stride(from: 0.0, through: 500.0, by: 37.0)
		{
			let date = JulianDate(elements.epoch.value + daysElapsed)
			let position = elements.position(atDate: date)
			let radius = (position.x * position.x + position.y * position.y).squareRoot()

			XCTAssertEqual(radius, elements.orbitRadiusInMeters, accuracy: 1.0)
		}
	}

	func testCircularOrbitReturnsToStartAfterOnePeriod()
	{
		let elements = CircularOrbitElements(
			orbitRadiusInMeters: 2.0e11,
			orbitPeriodInDays: 200.0,
			startingAngle: 1.1,
			epoch: JulianDate(2_460_000.0))

		let atEpoch = elements.position(atDate: elements.epoch)
		let afterOnePeriod = elements.position(atDate: JulianDate(elements.epoch.value + elements.orbitPeriodInDays))

		XCTAssertEqual(atEpoch.x, afterOnePeriod.x, accuracy: 0.01)
		XCTAssertEqual(atEpoch.y, afterOnePeriod.y, accuracy: 0.01)
	}

	func testTransitReachesEndpointsAtBoundaryTimes()
	{
		let departure = JulianDate(2_460_000.0)
		let arrival = JulianDate(2_460_030.0)
		let parameters = TransitParameters(
			departurePosition: CartesianPosition(x: 0.0, y: 0.0, z: 0.0),
			arrivalPosition: CartesianPosition(x: 1.0e11, y: 0.0, z: 0.0),
			departure: departure,
			arrival: arrival)

		XCTAssertEqual(parameters.position(atDate: departure), parameters.departurePosition)
		XCTAssertEqual(parameters.position(atDate: arrival), parameters.arrivalPosition)
	}

	func testTransitReachesMidpointAtHalfwayTime()
	{
		let departure = JulianDate(2_460_000.0)
		let arrival = JulianDate(2_460_030.0)
		let parameters = TransitParameters(
			departurePosition: CartesianPosition(x: 0.0, y: 0.0, z: 0.0),
			arrivalPosition: CartesianPosition(x: 1.0e11, y: 0.0, z: 0.0),
			departure: departure,
			arrival: arrival)

		let midDate = JulianDate((departure.value + arrival.value) / 2.0)
		let midPosition = parameters.position(atDate: midDate)

		XCTAssertEqual(midPosition.x, 0.5e11, accuracy: 1.0)
	}

	//	This one actually calls SwiftAA, so it needs network access to resolve the
	//	dependency the first time, and confirms the whole fixedBody path is wired up.
	//	Real Earth orbit is elliptical (roughly 0.983-1.017 AU), hence the loose tolerance.
	func testEarthFixedBodyIsRoughlyOneAstronomicalUnitFromTheSun()
	{
		let position = OrbitalElements.position(ofKind: .fixedBody(.earth), atDate: Date())
		let radiusInMeters = (position.x * position.x + position.y * position.y + position.z * position.z).squareRoot()
		let oneAstronomicalUnitInMeters = SolarSystemData.meanOrbitRadiusInMeters[.earth]!

		let percentDifference = abs(radiusInMeters - oneAstronomicalUnitInMeters) / oneAstronomicalUnitInMeters
		XCTAssertLessThan(percentDifference, 0.02)
	}
}
