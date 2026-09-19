//
//  CircularOrbitElements.swift
//  CelestialMechanics
//

import Foundation

/**
	A circular, coplanar orbit fully described by data -- no code change needed to add
	one. This is how the server introduces a new place (a station, a fictional
	settlement) without an app update: it just sends down these four numbers.

	See solar-system-view-architecture.md for the model this implements:
		mean motion:     n = 2π / T
		angle at time t: θ(t) = θ0 + n·(t − t0)
		position:        x = r·cos(θ), y = r·sin(θ), z = 0
*/

public struct CircularOrbitElements : Codable, Equatable, Sendable
{
	public var	orbitRadiusInMeters	:	Double
	public var	orbitPeriodInDays	:	Double
	public var	startingAngle		:	Double			//	θ0, in radians, at `epoch`
	public var	epoch				:	JulianDate

	public init(orbitRadiusInMeters inOrbitRadiusInMeters: Double,
			orbitPeriodInDays inOrbitPeriodInDays: Double,
			startingAngle inStartingAngle: Double,
			epoch inEpoch: JulianDate)
	{
		self.orbitRadiusInMeters = inOrbitRadiusInMeters
		self.orbitPeriodInDays = inOrbitPeriodInDays
		self.startingAngle = inStartingAngle
		self.epoch = inEpoch
	}

	func position(atDate inDate: JulianDate) -> CartesianPosition
	{
		let meanMotion = (2.0 * Double.pi) / self.orbitPeriodInDays
		let elapsedDays = inDate.daysElapsed(since: self.epoch)
		let angle = self.startingAngle + meanMotion * elapsedDays

		return CartesianPosition(
			x: self.orbitRadiusInMeters * cos(angle),
			y: self.orbitRadiusInMeters * sin(angle),
			z: 0.0)
	}
}
