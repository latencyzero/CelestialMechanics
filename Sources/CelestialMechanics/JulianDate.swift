//
//  JulianDate.swift
//  CelestialMechanics
//

import Foundation

/**
	A lightweight Julian Date wrapper, independent of SwiftAA's own `JulianDay`.
	Exists so callers of this package -- including the Vapor server -- don't need a
	SwiftAA dependency just to talk about "a point in time" the way this package does.
	Conversion to SwiftAA's `JulianDay` happens only inside `OrbitalElements`, right at
	the boundary where a fixed-body position actually needs SwiftAA.
*/

public struct JulianDate : Codable, Equatable, Sendable
{
	private static let secondsPerDay			:	Double	=	86_400.0
	private static let unixEpochAsJulianDate	:	Double	=	2_440_587.5

	public var	value	:	Double

	public init(_ inValue: Double)
	{
		self.value = inValue
	}

	public init(date inDate: Date)
	{
		self.value = Self.unixEpochAsJulianDate + inDate.timeIntervalSince1970 / Self.secondsPerDay
	}

	public var asDate : Date
	{
		return Date(timeIntervalSince1970: (self.value - Self.unixEpochAsJulianDate) * Self.secondsPerDay)
	}

	/**
		Days elapsed since an earlier `JulianDate`. Negative if `inEarlier` is actually later.
	*/

	public func daysElapsed(since inEarlier: JulianDate) -> Double
	{
		return self.value - inEarlier.value
	}
}
