//
//  CartesianPosition.swift
//  CelestialMechanics
//

import Foundation

/**
	A cartesian position in meters. Absolute positions are heliocentric (Sun at the
	origin); offsets (e.g. a landed ship's position relative to its planet) use the
	same type, and it is the caller's job to know which is which -- this package only
	produces absolute, heliocentric positions.
*/

public struct CartesianPosition : Codable, Equatable, Sendable
{
	public var	x	:	Double
	public var	y	:	Double
	public var	z	:	Double

	public init(x inX: Double = 0.0, y inY: Double = 0.0, z inZ: Double = 0.0)
	{
		self.x = inX
		self.y = inY
		self.z = inZ
	}

	public static func + (inLeft: CartesianPosition, inRight: CartesianPosition) -> CartesianPosition
	{
		return CartesianPosition(x: inLeft.x + inRight.x, y: inLeft.y + inRight.y, z: inLeft.z + inRight.z)
	}

	public static func - (inLeft: CartesianPosition, inRight: CartesianPosition) -> CartesianPosition
	{
		return CartesianPosition(x: inLeft.x - inRight.x, y: inLeft.y - inRight.y, z: inLeft.z - inRight.z)
	}

	public static func * (inScalar: Double, inPosition: CartesianPosition) -> CartesianPosition
	{
		return CartesianPosition(x: inScalar * inPosition.x, y: inScalar * inPosition.y, z: inScalar * inPosition.z)
	}
}
