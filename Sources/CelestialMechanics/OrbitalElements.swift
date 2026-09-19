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
	public static func position(ofKind inKind: LocationKind, atDate inDate: Date) -> CartesianPosition
	{
		let julianDate = JulianDate(date: inDate)

		switch inKind
		{
		case .fixedBody(let inPlanet):
			return Self.heliocentricPosition(ofPlanet: inPlanet, atDate: inDate)

		case .circularOrbit(let inElements):
			return inElements.position(atDate: julianDate)

		case .transit(let inParameters):
			return inParameters.position(atDate: julianDate)
		}
	}

	//	MARK: - Fixed bodies (SwiftAA-backed)

	private static func heliocentricPosition(ofPlanet inPlanet: PlanetIdentifier, atDate inDate: Date) -> CartesianPosition
	{
		let julianDay = JulianDay(inDate)
		let body = Self.makeBody(for: inPlanet, julianDay: julianDay)

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
	private static func makeBody(for inPlanet: PlanetIdentifier, julianDay inJulianDay: JulianDay) -> any HeliocentricPositionProviding
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
		}
	}
}
