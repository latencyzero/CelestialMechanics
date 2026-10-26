//
//  OrbitalElements.swift
//  CelestialMechanics
//

import Foundation
import SwiftAA
import AABridge

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

		case .keplerian(let inElements):
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

		switch inBody
		{
		case .sun:
			return CartesianPosition()

		case .pluto:
			return Self.heliocentricPosition(ofPluto: julianDay)

		case .moon, .io, .europa, .ganymede, .callisto, .mimas, .enceladus, .tethys, .dione, .rhea, .titan, .hyperion, .iapetus:
			//	A moon is its planet’s position plus its offset from it…

			guard
				let planetID = inBody.parent,
				let planet = Self.heliocentricPosition(ofPlanet: planetID, julianDay: julianDay),
				let offset = Self.offset(ofMoon: inBody, atDate: inDate)
			else
			{
				return nil
			}

			return planet + offset

		default:
			return Self.heliocentricPosition(ofPlanet: inBody, julianDay: julianDay)
		}
	}

	/**
		A placement’s offset from its parent (meters, heliocentric ecliptic axes), when
		that can be had without the parent’s position: an orbit (`.orbit`,
		`.keplerian`), or a real moon (`.ephemeris`) whose planet’s position only
		matters as a direction. nil for anything else (a planet, `.surface`, …), where
		the offset is the difference of two positions.

		This is much cheaper than subtracting the parent’s heliocentric position from
		the moon’s, since that takes full-precision planet series and this doesn’t.
		It’s for drawing (a moon’s orbit, its place around its planet), where the
		difference is far below a pixel.
	*/

	public static func offsetFromParent(of inPlacement: Placement, atDate inDate: Date) -> CartesianPosition?
	{
		switch inPlacement
		{
		case .ephemeris(let inBody):
			return Self.offset(ofMoon: inBody, atDate: inDate)

		case .orbit(let inElements):
			return inElements.position(atDate: JulianDate(date: inDate))

		case .keplerian(let inElements):
			return inElements.position(atDate: JulianDate(date: inDate))

		case .surface, .attached, .transit:
			return nil
		}
	}

	/**
		The offset of a real moon from its planet, or nil if `inBody` isn’t one. Earth and
		the outer planets are only used for the direction of Earth from the planet,
		which low-precision series give to within arcseconds.
	*/

	private static func offset(ofMoon inBody: BodyIdentifier, atDate inDate: Date) -> CartesianPosition?
	{
		let julianDay = JulianDay(inDate)

		if inBody == .moon
		{
			//	SwiftAA gives the Moon's geocentric ecliptic coordinates in the same
			//	frame (ecliptic and equinox of date) as the planets' heliocentric
			//	ones…

			let moon = Moon(julianDay: julianDay)
			let longitude = moon.apparentEclipticCoordinates.celestialLongitude.inRadians.value
			let latitude = moon.apparentEclipticCoordinates.celestialLatitude.inRadians.value
			let radiusInMeters = moon.radiusVector.inMeters.value

			return CartesianPosition(x: radiusInMeters * cos(latitude) * cos(longitude),
										y: radiusInMeters * cos(latitude) * sin(longitude),
										z: radiusInMeters * sin(latitude))
		}

		guard
			let planetID = inBody.parent,
			let planet = Self.heliocentricPosition(ofPlanet: planetID, julianDay: julianDay, highPrecision: false),
			let earth = Self.heliocentricPosition(ofPlanet: .earth, julianDay: julianDay, highPrecision: false),
			let pole = Self.poleOfDate(of: planetID, atDate: inDate)
		else
		{
			return nil
		}

		return PlanetaryMoons.offset(of: inBody, planet: planet, earth: earth, pole: pole, julianDay: julianDay)
	}

	/**
		`inPlanet`’s north pole, a unit vector in the ecliptic of date, like the positions.
		`BodyRotation` has it in the ecliptic of J2000, which precession has since turned
		about the ecliptic’s pole.
	*/

	private static func poleOfDate(of inPlanet: BodyIdentifier, atDate inDate: Date) -> CartesianPosition?
	{
		guard
			let pole = BodyRotation.orientation(of: inPlanet, atDate: inDate)?.northPole
		else
		{
			return nil
		}

		let angle = KeplerianOrbitElements.precessionPerDay * (JulianDate(date: inDate).value - KeplerianOrbitElements.j2000)

		return CartesianPosition(x: pole.x * cos(angle) - pole.y * sin(angle),
									y: pole.x * sin(angle) + pole.y * cos(angle),
									z: pole.z)
	}

	/**
		Pluto’s position from Meeus’s series (chapter 37), which AA+ says is good for
		1885–2099. They’re referred to the equinox of J2000, so the longitude is
		advanced by precession to match the planets’ (ecliptic of date).
	*/

	private static func heliocentricPosition(ofPluto inJulianDay: JulianDay) -> CartesianPosition
	{
		let precession = KeplerianOrbitElements.precessionPerDay * (inJulianDay.value - KeplerianOrbitElements.j2000)
		let longitude = KPCAAPluto_EclipticLongitude(inJulianDay.value) * .pi / 180.0 + precession
		let latitude = KPCAAPluto_EclipticLatitude(inJulianDay.value) * .pi / 180.0
		let radiusInMeters = KPCAAPluto_RadiusVector(inJulianDay.value) * Self.metersPerAstronomicalUnit

		return CartesianPosition(x: radiusInMeters * cos(latitude) * cos(longitude),
									y: radiusInMeters * cos(latitude) * sin(longitude),
									z: radiusInMeters * sin(latitude))
	}

	private static let metersPerAstronomicalUnit	:	Double	=	149_597_870_700.0

	private static func heliocentricPosition(ofPlanet inPlanet: BodyIdentifier, julianDay inJulianDay: JulianDay, highPrecision inHighPrecision: Bool = true) -> CartesianPosition?
	{
		guard
			let body = Self.makeBody(for: inPlanet, julianDay: inJulianDay, highPrecision: inHighPrecision)
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
	private static func makeBody(for inPlanet: BodyIdentifier, julianDay inJulianDay: JulianDay, highPrecision inHighPrecision: Bool) -> (any HeliocentricPositionProviding)?
	{
		switch inPlanet
		{
		case .mercury:
			return Mercury(julianDay: inJulianDay, highPrecision: inHighPrecision)
		case .venus:
			return Venus(julianDay: inJulianDay, highPrecision: inHighPrecision)
		case .earth:
			return Earth(julianDay: inJulianDay, highPrecision: inHighPrecision)
		case .mars:
			return Mars(julianDay: inJulianDay, highPrecision: inHighPrecision)
		case .jupiter:
			return Jupiter(julianDay: inJulianDay, highPrecision: inHighPrecision)
		case .saturn:
			return Saturn(julianDay: inJulianDay, highPrecision: inHighPrecision)
		case .uranus:
			return Uranus(julianDay: inJulianDay, highPrecision: inHighPrecision)
		case .neptune:
			return Neptune(julianDay: inJulianDay, highPrecision: inHighPrecision)
		default:
			return nil
		}
	}
}
