//
//  PlanetaryMoons.swift
//  CelestialMechanics
//

import Foundation
import SwiftAA
import AABridge

/**
	Positions for Jupiter’s Galilean moons and Saturn’s eight classical ones, from
	SwiftAA (Meeus’s chapters 44 and 46).

	SwiftAA gives each moon’s offset from its planet as seen from Earth, not in the
	heliocentric frame everything else here uses. The coordinates are in units of the
	planet’s equatorial radius, along three axes: Y toward the planet’s north pole as
	it appears on the sky, X toward its west (along its equator, across the sky), and
	Z along the line of sight, away from Earth (negative for a moon nearer Earth than
	its planet). Those axes are built from where Earth and the planet are, and the
	planet’s pole, and the offset is rotated into the ecliptic.

	(SwiftAA’s own `GalileanMoon.rectangularCoordinates()` can’t be used: its fields
	aren’t public.)
*/

enum PlanetaryMoons
{
	/**
		The heliocentric ecliptic offset, in meters, of `inMoon` from its planet, which
		is at `inPlanet` while Earth is at `inEarth`. `inPole` is the planet’s north pole (a
		unit vector, ecliptic of date). nil if it’s not a moon of Jupiter or Saturn.
	*/

	static
	func
	offset(of inMoon: BodyIdentifier, planet inPlanet: CartesianPosition, earth inEarth: CartesianPosition, pole inPole: CartesianPosition, julianDay inJulianDay: JulianDay)
		-> CartesianPosition?
	{
		guard
			let sky = Self.skyCoordinates(of: inMoon, julianDay: inJulianDay)
		else
		{
			return nil
		}

		//	The unit vector u from Earth to the planet, and the two axes across it: north
		//	is the pole’s part across the line of sight, and west completes the set
		//	(west, north, toward Earth) as a right-handed one…

		let line = inPlanet - inEarth
		let distance = line.magnitude

		guard
			distance > 0.0
		else
		{
			return nil
		}

		let u = (1.0 / distance) * line
		let acrossPole = inPole - Self.dot(inPole, u) * u
		let across = acrossPole.magnitude

		guard
			across > 0.0
		else
		{
			return nil
		}

		let north = (1.0 / across) * acrossPole
		let west = Self.cross(u, north)

		return sky.radiusInMeters * (sky.x * west + sky.y * north + sky.z * u)
	}

	private
	static
	func
	dot(_ inA: CartesianPosition, _ inB: CartesianPosition) -> Double
	{
		return inA.x * inB.x + inA.y * inB.y + inA.z * inB.z
	}

	private
	static
	func
	cross(_ inA: CartesianPosition, _ inB: CartesianPosition) -> CartesianPosition
	{
		return CartesianPosition(x: inA.y * inB.z - inA.z * inB.y,
									y: inA.z * inB.x - inA.x * inB.z,
									z: inA.x * inB.y - inA.y * inB.x)
	}

	/**
		SwiftAA’s true (not apparent) coordinates of `inMoon`, in planetary radii, and the
		radius in meters.
	*/

	private
	static
	func
	skyCoordinates(of inMoon: BodyIdentifier, julianDay inJulianDay: JulianDay)
		-> (x: Double, y: Double, z: Double, radiusInMeters: Double)?
	{
		let components: KPCAA3DCoordinateComponents
		let radius: Double

		switch inMoon
		{
		case .io, .europa, .ganymede, .callisto:
			let details = KPCAAGalileanMoons_CalculateDetails(inJulianDay.value, false)

			switch inMoon
			{
				case .io:		components = details.Satellite1.TrueRectangularCoordinateComponents
				case .europa:	components = details.Satellite2.TrueRectangularCoordinateComponents
				case .ganymede:	components = details.Satellite3.TrueRectangularCoordinateComponents
				default:		components = details.Satellite4.TrueRectangularCoordinateComponents
			}

			radius = Self.jupiterEquatorialRadiusInMeters

		case .mimas, .enceladus, .tethys, .dione, .rhea, .titan, .hyperion, .iapetus:
			let details = KPCAASaturnMoonsDetails_Calculate(inJulianDay.value, false)

			switch inMoon
			{
				case .mimas:		components = details.Satellite1.TrueRectangularCoordinateComponents
				case .enceladus:	components = details.Satellite2.TrueRectangularCoordinateComponents
				case .tethys:		components = details.Satellite3.TrueRectangularCoordinateComponents
				case .dione:		components = details.Satellite4.TrueRectangularCoordinateComponents
				case .rhea:			components = details.Satellite5.TrueRectangularCoordinateComponents
				case .titan:		components = details.Satellite6.TrueRectangularCoordinateComponents
				case .hyperion:		components = details.Satellite7.TrueRectangularCoordinateComponents
				default:			components = details.Satellite8.TrueRectangularCoordinateComponents
			}

			radius = Self.saturnEquatorialRadiusInMeters

		default:
			return nil
		}

		return (components.X, components.Y, components.Z, radius)
	}

	//	The IAU equatorial radii (the 1 bar level), the units of SwiftAA’s coordinates…

	private	static	let	jupiterEquatorialRadiusInMeters	:	Double	=	71_492_000.0
	private	static	let	saturnEquatorialRadiusInMeters	:	Double	=	60_268_000.0
}
