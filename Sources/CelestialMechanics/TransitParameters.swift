//
//  TransitParameters.swift
//  CelestialMechanics
//

import Foundation

/**
	A ship in flight along a brachistochrone ("flip and burn") trajectory between two
	snapshotted points: constant acceleration for the first half of the distance, then
	constant deceleration for the second half, arriving at rest. See
	propulsion-and-travel-time.md for the underlying t = 2·sqrt(d / a) formula.

	Simplification worth naming explicitly: `departurePosition` and `arrivalPosition`
	are captured once, at the moment the trip is planned -- this models a straight-line
	burn between two fixed points in space, not a true intercept trajectory chasing a
	moving destination. Fine for planet-to-planet hops at this game's timescales, but
	worth revisiting if gravity-assist or long-duration transits to a moving target
	become a real feature.
*/

public struct TransitParameters : Codable, Equatable, Sendable
{
	public var	departurePosition	:	CartesianPosition
	public var	arrivalPosition		:	CartesianPosition
	public var	departure			:	JulianDate
	public var	arrival				:	JulianDate

	public init(departurePosition inDeparturePosition: CartesianPosition,
			arrivalPosition inArrivalPosition: CartesianPosition,
			departure inDeparture: JulianDate,
			arrival inArrival: JulianDate)
	{
		self.departurePosition = inDeparturePosition
		self.arrivalPosition = inArrivalPosition
		self.departure = inDeparture
		self.arrival = inArrival
	}

	func position(atDate inDate: JulianDate) -> CartesianPosition
	{
		let totalDuration = self.arrival.daysElapsed(since: self.departure)

		guard totalDuration > 0.0
		else
		{
			return self.arrivalPosition
		}

		let elapsed = inDate.daysElapsed(since: self.departure)
		let fractionOfTime = min(max(elapsed / totalDuration, 0.0), 1.0)

		//	Progress through *distance* isn't linear in time under constant accel/decel --
		//	it's quadratic in each half, matched to give continuous velocity at the midpoint
		//	(peak speed), which is where the "flip" happens.
		let fractionOfDistance : Double

		if fractionOfTime <= 0.5
		{
			fractionOfDistance = 2.0 * fractionOfTime * fractionOfTime
		}
		else
		{
			let remaining = 1.0 - fractionOfTime
			fractionOfDistance = 1.0 - 2.0 * remaining * remaining
		}

		let delta = self.arrivalPosition - self.departurePosition
		return self.departurePosition + fractionOfDistance * delta
	}
}
