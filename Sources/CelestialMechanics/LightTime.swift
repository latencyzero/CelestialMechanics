//
//  LightTime.swift
//  CelestialMechanics
//

import Foundation

/**
	One-way light-time between two points: straight-line distance divided by c.

	Simplification worth naming explicitly: both positions are taken at the same
	instant, so this ignores the fact that the receiver moves while the signal is in
	flight (no light-time iteration / retarded-position correction). At planetary
	speeds over minutes-to-hours of travel, that error is on the order of seconds,
	which is fine for a message-delay estimate.
*/

public enum LightTime
{
	/**
		Speed of light in a vacuum, exact by definition of the meter.
	*/

	public static let speedOfLightInMetersPerSecond : Double = 299_792_458.0

	public static func seconds(from inFrom: CartesianPosition, to inTo: CartesianPosition) -> TimeInterval
	{
		return inFrom.distance(to: inTo) / Self.speedOfLightInMetersPerSecond
	}

	public static func seconds(fromPlacement inFrom: Placement, toPlacement inTo: Placement, atDate inDate: Date) -> TimeInterval
	{
		let fromPosition = OrbitalElements.position(of: inFrom, atDate: inDate)
		let toPosition = OrbitalElements.position(of: inTo, atDate: inDate)
		return Self.seconds(from: fromPosition, to: toPosition)
	}
}
