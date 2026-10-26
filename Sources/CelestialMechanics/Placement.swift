//
//  Placement.swift
//  CelestialMechanics
//

import Foundation

/**
	How a location's position is defined relative to its parent (the location it's
	"at", if any). Replaces the old `LocationKind`; see `Docs/location-placement.md`.

	Only `.ephemeris` and `.transit` are absolute (heliocentric) and ignore the parent.
	The others are measured from the parent's position, which is the Sun's (the
	origin) when there isn't one.
*/

public enum Placement : Codable, Equatable, Sendable
{
	/**
		A real body (a planet or the Moon), positioned by SwiftAA. The parent is
		ignored. A body this build doesn’t know (`BodyIdentifier.unknown`) sits at
		its parent’s position, like `.attached` with no offset.
	*/

	case ephemeris(BodyIdentifier)

	/**
		A circular, coplanar orbit around the parent (the Sun if none): stations,
		fictional bodies.
	*/

	case orbit(CircularOrbitElements)

	/**
		An elliptical, inclined two-body orbit around the parent (the Sun if none):
		asteroids and other small bodies, from JPL's Small-Body Database.
	*/

	case keplerian(KeplerianOrbitElements)

	/**
		Fixed on the parent's surface and rotating with it: cities, bases. The parent
		must be an `.ephemeris` body, which supplies the radius and orientation. (A
		parent this build doesn’t know has none, so the location is at its center.)
	*/

	case surface(SurfaceCoordinates)

	/**
		A rigid offset (meters, heliocentric ecliptic axes) from the parent, often
		zero: a ship docked at a station.
	*/

	case attached(CartesianPosition)

	/**
		A ship in flight. Absolute, like `.ephemeris`.
	*/

	case transit(TransitParameters)

	/**
		Whether the position is heliocentric and so independent of the parent.
	*/

	public var
	isAbsolute: Bool
	{
		switch self
		{
			case .ephemeris, .transit:
				return true

			case .orbit, .keplerian, .surface, .attached:
				return false
		}
	}
}

/**
	A point on or above a body's surface. Latitude is planetocentric, longitude is
	east-positive from the body's IAU prime meridian (both in degrees, so they're
	readable in admin tools), and altitude is meters above the mean radius.
*/

public struct SurfaceCoordinates : Codable, Equatable, Sendable
{
	public var	latitude		:	Double			//	degrees, -90…90
	public var	longitude		:	Double			//	degrees, -180…180, east-positive
	public var	altitude		:	Double			//	meters above mean radius

	public init(latitude inLatitude: Double, longitude inLongitude: Double, altitude inAltitude: Double = 0.0)
	{
		self.latitude = inLatitude
		self.longitude = inLongitude
		self.altitude = inAltitude
	}

	/**
		Whether the coordinates are finite and in range.
	*/

	public var
	isValid: Bool
	{
		return self.latitude.isFinite && abs(self.latitude) <= 90.0
			&& self.longitude.isFinite && abs(self.longitude) <= 180.0
			&& self.altitude.isFinite
	}

	/**
		Offset from the center of a body of `inRadius` meters with `inOrientation`, in
		the heliocentric ecliptic frame.
	*/

	func
	offset(radius inRadius: Double, orientation inOrientation: BodyOrientation) -> CartesianPosition
	{
		let lat = self.latitude * .pi / 180.0
		let lon = self.longitude * .pi / 180.0

		let m = inOrientation.primeMeridian
		let e = inOrientation.east
		let n = inOrientation.northPole

		let a = cos(lat) * cos(lon)
		let b = cos(lat) * sin(lon)
		let c = sin(lat)
		let r = inRadius + self.altitude

		return CartesianPosition(x: r * (a * m.x + b * e.x + c * n.x),
									y: r * (a * m.y + b * e.y + c * n.y),
									z: r * (a * m.z + b * e.z + c * n.z))
	}
}

/**
	How a location keeps time. A plain UTC offset can't do this: Earth zones have
	daylight saving rules, and other places don't have a 24-hour day at all (Mars's
	sol is 24h 39m 35s, a station can pick any day length). So the rule is relative
	to a *day*, whatever length that is, and a "local hour" is 1/24 of it.
*/

public enum LocalTimeRule : Codable, Equatable, Sendable
{
	/**
		An IANA time zone identifier, e.g. `America/Los_Angeles`. Earth only; carries
		its own daylight saving rules.
	*/

	case iana(String)

	/**
		Mean local solar time at the location's own longitude on its body (noon when
		the mean Sun crosses its meridian). The default for a surface location with no
		civil zone, anywhere.
	*/

	case localMeanSolar

	/**
		A body-wide zone: mean solar time at the body's prime meridian, shifted by
		`offsetInHours` local hours (1/24 of that body's solar day). The analog of
		“UTC+n” for Mars or the Moon.
	*/

	case bodyZone(offsetInHours: Double)

	/**
		A clock with its own day, for stations and ships: a day of `dayLengthInSeconds`
		(SI) that starts at midnight at `midnightEpoch`.
	*/

	case cycle(dayLengthInSeconds: Double, midnightEpoch: JulianDate)

	/**
		Whether the rule's values are sane. IANA identifiers are checked with
		`TimeZone`, which can only vouch for what the platform's tz database knows.
	*/

	public var
	isValid: Bool
	{
		switch self
		{
			case .iana(let inID):
				return TimeZone(identifier: inID) != nil

			case .localMeanSolar:
				return true

			case .bodyZone(let inOffset):
				return inOffset.isFinite && abs(inOffset) <= 24.0

			case .cycle(let inLength, let inEpoch):
				return inLength.isFinite && inLength > 0.0 && inEpoch.value.isFinite
		}
	}
}
