//
//  OrbitalElements.swift
//  CelestialMechanics
//

import Foundation
import SwiftAA

/**
	The one seam between "how do I compute a position" and everything that calls it.
	Growing this later (real Keplerian elements for `.circularOrbit`, an intercept
	trajectory for `.transit`, higher-fidelity VSOP2013 precision) is a change behind
	this function, not a rewrite of the callers.
*/

public enum OrbitalElements
{
	/**
		The heliocentric position of `inPlacement` at `inDate`. `inParentPosition` is
		the heliocentric position of the location it's "at" (the origin if none), and
		`inParentPlacement` that location's placement, needed to place a surface
		location on its body.
	*/

	public static func position(of inPlacement: Placement,
									parentPosition inParentPosition: CartesianPosition = CartesianPosition(),
									parentPlacement inParentPlacement: Placement? = nil,
									atDate inDate: Date)
		-> CartesianPosition
	{
		let julianDate = JulianDate(date: inDate)

		switch inPlacement
		{
		case .ephemeris(let inBody):
			//	A body this build doesn't know can only sit where its parent is…

			return Self.heliocentricPosition(ofBody: inBody, atDate: inDate) ?? inParentPosition

		case .orbit(let inElements):
			return inParentPosition + inElements.position(atDate: julianDate)

		case .surface(let inCoordinates):
			//	Only a real body has a radius and orientation. Anything else is
			//	treated as being at the parent's center…

			guard
				case .ephemeris(let inBody)? = inParentPlacement,
				let orientation = BodyRotation.orientation(of: inBody, atDate: inDate)
			else
			{
				return inParentPosition
			}

			let offset = inCoordinates.offset(radius: SolarSystemData.meanRadiusInMeters[inBody] ?? 0.0, orientation: orientation)
			return inParentPosition + offset

		case .attached(let inOffset):
			return inParentPosition + inOffset

		case .transit(let inParameters):
			return inParameters.position(atDate: julianDate)
		}
	}

	//	MARK: - Fixed bodies (SwiftAA-backed)

	/**
		The heliocentric position of a real body, or nil if this build doesn't know it.
	*/

	private static func heliocentricPosition(ofBody inBody: BodyIdentifier, atDate inDate: Date) -> CartesianPosition?
	{
		let julianDay = JulianDay(inDate)

		if inBody == .moon
		{
			//	SwiftAA gives the Moon's geocentric ecliptic coordinates in the same
			//	frame (ecliptic and equinox of date) as the planets' heliocentric
			//	ones, so it's Earth's position plus the Moon's offset from it…

			let moon = Moon(julianDay: julianDay)
			let longitude = moon.apparentEclipticCoordinates.celestialLongitude.inRadians.value
			let latitude = moon.apparentEclipticCoordinates.celestialLatitude.inRadians.value
			let radiusInMeters = moon.radiusVector.inMeters.value

			guard
				let earth = Self.heliocentricPosition(ofPlanet: .earth, julianDay: julianDay)
			else
			{
				return nil
			}

			return earth + CartesianPosition(x: radiusInMeters * cos(latitude) * cos(longitude),
												y: radiusInMeters * cos(latitude) * sin(longitude),
												z: radiusInMeters * sin(latitude))
		}

		return Self.heliocentricPosition(ofPlanet: inBody, julianDay: julianDay)
	}

	private static func heliocentricPosition(ofPlanet inPlanet: BodyIdentifier, julianDay inJulianDay: JulianDay) -> CartesianPosition?
	{
		guard
			let body = Self.makeBody(for: inPlanet, julianDay: inJulianDay)
		else
		{
			return nil
		}

		let longitude = body.heliocentricEclipticCoordinates.celestialLongitude.inRadians.value
		let latitude = body.heliocentricEclipticCoordinates.celestialLatitude.inRadians.value
		let radiusInMeters = body.radiusVector.inMeters.value

		return CartesianPosition(
			x: radiusInMeters * cos(latitude) * cos(longitude),
			y: radiusInMeters * cos(latitude) * sin(longitude),
			z: radiusInMeters * sin(latitude))
	}

	//	This switch is the one place in the package that has to know Mercury and Venus
	//	are different concrete types -- Swift needs a named type to construct, and no
	//	amount of protocol conformance removes that. Everything downstream of this
	//	function (the caller, `HeliocentricPositionProviding`) doesn't need to know it.
	//	Anything but a planet gives nil.
	private static func makeBody(for inPlanet: BodyIdentifier, julianDay inJulianDay: JulianDay) -> (any HeliocentricPositionProviding)?
	{
		switch inPlanet
		{
		case .mercury:
			return Mercury(julianDay: inJulianDay)
		case .venus:
			return Venus(julianDay: inJulianDay)
		case .earth:
			return Earth(julianDay: inJulianDay)
		case .mars:
			return Mars(julianDay: inJulianDay)
		case .jupiter:
			return Jupiter(julianDay: inJulianDay)
		case .saturn:
			return Saturn(julianDay: inJulianDay)
		case .uranus:
			return Uranus(julianDay: inJulianDay)
		case .neptune:
			return Neptune(julianDay: inJulianDay)
		case .moon, .unknown:
			return nil
		}
	}
}
