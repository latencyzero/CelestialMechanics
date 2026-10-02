//
//  OrbitalElementsTests.swift
//  CelestialMechanicsTests
//

import Foundation
import Testing
@testable import CelestialMechanics

@Suite("Orbital Elements")
struct
OrbitalElementsTests
{
	@Test("JulianDate round-trips through Date")
	func julianDateRoundTrip()
	{
		let originalDate = Date()
		let julianDate = JulianDate(date: originalDate)
		let roundTrippedDate = julianDate.asDate

		#expect(abs(originalDate.timeIntervalSince1970 - roundTrippedDate.timeIntervalSince1970) < 0.001)
	}

	@Test("JulianDate computes days elapsed")
	func julianDateDaysElapsed()
	{
		let epoch = JulianDate(date: Date())
		let tenDaysLater = JulianDate(epoch.value + 10.0)

		#expect(abs(tenDaysLater.daysElapsed(since: epoch) - 10.0) < 0.0001)
	}

	@Test("Circular orbit holds a constant radius", arguments: stride(from: 0.0, through: 500.0, by: 37.0))
	func circularOrbitHoldsConstantRadius(daysElapsed inDaysElapsed: Double)
	{
		let elements = CircularOrbitElements(
			orbitRadiusInMeters: 1.0e11,
			orbitPeriodInDays: 400.0,
			startingAngle: 0.3,
			epoch: JulianDate(2_460_000.0))

		let date = JulianDate(elements.epoch.value + inDaysElapsed)
		let position = elements.position(atDate: date)
		let radius = (position.x * position.x + position.y * position.y).squareRoot()

		#expect(abs(radius - elements.orbitRadiusInMeters) < 1.0)
	}

	@Test("Circular orbit returns to its start after one period")
	func circularOrbitReturnsToStartAfterOnePeriod()
	{
		let elements = CircularOrbitElements(
			orbitRadiusInMeters: 2.0e11,
			orbitPeriodInDays: 200.0,
			startingAngle: 1.1,
			epoch: JulianDate(2_460_000.0))

		let atEpoch = elements.position(atDate: elements.epoch)
		let afterOnePeriod = elements.position(atDate: JulianDate(elements.epoch.value + elements.orbitPeriodInDays))

		#expect(abs(atEpoch.x - afterOnePeriod.x) < 0.01)
		#expect(abs(atEpoch.y - afterOnePeriod.y) < 0.01)
	}

	@Test("Transit reaches its endpoints at the boundary times")
	func transitReachesEndpointsAtBoundaryTimes()
	{
		let departure = JulianDate(2_460_000.0)
		let arrival = JulianDate(2_460_030.0)
		let parameters = TransitParameters(
			departurePosition: CartesianPosition(x: 0.0, y: 0.0, z: 0.0),
			arrivalPosition: CartesianPosition(x: 1.0e11, y: 0.0, z: 0.0),
			departure: departure,
			arrival: arrival)

		#expect(parameters.position(atDate: departure) == parameters.departurePosition)
		#expect(parameters.position(atDate: arrival) == parameters.arrivalPosition)
	}

	@Test("Transit reaches the midpoint at the halfway time")
	func transitReachesMidpointAtHalfwayTime()
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

		#expect(abs(midPosition.x - 0.5e11) < 1.0)
	}

	//	This one actually calls SwiftAA, so it needs network access to resolve the
	//	dependency the first time, and confirms the whole fixedBody path is wired up.
	//	Real Earth orbit is elliptical (roughly 0.983-1.017 AU), hence the loose tolerance.
	@Test("Earth (fixed body) is roughly 1 AU from the Sun")
	func earthFixedBodyIsRoughlyOneAstronomicalUnitFromTheSun()
		throws
	{
		let position = OrbitalElements.position(ofKind: .fixedBody(.earth), atDate: Date())
		let radiusInMeters = position.magnitude
		let oneAstronomicalUnitInMeters = try #require(SolarSystemData.meanOrbitRadiusInMeters[.earth])

		let percentDifference = abs(radiusInMeters - oneAstronomicalUnitInMeters) / oneAstronomicalUnitInMeters
		#expect(percentDifference < 0.02)
	}
}
