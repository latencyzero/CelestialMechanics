//
//  KeplerianOrbitElements.swift
//  CelestialMechanics
//

import Foundation

/**
	A two-body elliptical orbit around the parent (the Sun if none), described by
	classical orbital elements. Meant for asteroids and other small bodies, and shaped
	to be filled in from JPL's Small-Body Database: `a`, `e`, `i`, `om`, `w`, `ma`,
	`epoch` and `per` map directly onto the fields below.

	Angles are in degrees (like `SurfaceCoordinates`, so they're readable in admin
	tools and match JPL's). The reference frame is the ecliptic and equinox of J2000,
	which is what JPL publishes; `position(atDate:)` precesses it to the ecliptic of
	date so it lines up with the SwiftAA-backed planets.

	Only bound orbits (0 ≤ e < 1) are supported. Comets on hyperbolic orbits are not.
*/

public struct KeplerianOrbitElements : Codable, Equatable, Sendable
{
	public var	semiMajorAxisInMeters		:	Double			//	a
	public var	eccentricity				:	Double			//	e, 0 ≤ e < 1
	public var	inclination					:	Double			//	i, degrees
	public var	longitudeOfAscendingNode	:	Double			//	Ω, degrees
	public var	argumentOfPeriapsis			:	Double			//	ω, degrees
	public var	meanAnomaly					:	Double			//	M0, degrees, at `epoch`
	public var	orbitPeriodInDays			:	Double			//	T
	public var	epoch						:	JulianDate

	/**
		General precession in ecliptic longitude, in radians per Julian day (about
		5028.8 arcseconds per Julian century). Rotating the J2000 ecliptic about its
		pole to the ecliptic of date shifts only the longitude of the ascending node.
	*/

	static let precessionPerDay		:	Double	=	(5_028.796_195 / 3_600.0) * (Double.pi / 180.0) / 36_525.0
	static let j2000				:	Double	=	2_451_545.0

	public init(semiMajorAxisInMeters inSemiMajorAxisInMeters: Double,
			eccentricity inEccentricity: Double,
			inclination inInclination: Double,
			longitudeOfAscendingNode inLongitudeOfAscendingNode: Double,
			argumentOfPeriapsis inArgumentOfPeriapsis: Double,
			meanAnomaly inMeanAnomaly: Double,
			orbitPeriodInDays inOrbitPeriodInDays: Double,
			epoch inEpoch: JulianDate)
	{
		self.semiMajorAxisInMeters = inSemiMajorAxisInMeters
		self.eccentricity = inEccentricity
		self.inclination = inInclination
		self.longitudeOfAscendingNode = inLongitudeOfAscendingNode
		self.argumentOfPeriapsis = inArgumentOfPeriapsis
		self.meanAnomaly = inMeanAnomaly
		self.orbitPeriodInDays = inOrbitPeriodInDays
		self.epoch = inEpoch
	}

	/**
		Whether the elements describe a bound orbit with finite values.
	*/

	public var
	isValid: Bool
	{
		return self.semiMajorAxisInMeters.isFinite && self.semiMajorAxisInMeters > 0.0
			&& self.eccentricity.isFinite && self.eccentricity >= 0.0 && self.eccentricity < 1.0
			&& self.inclination.isFinite
			&& self.longitudeOfAscendingNode.isFinite
			&& self.argumentOfPeriapsis.isFinite
			&& self.meanAnomaly.isFinite
			&& self.orbitPeriodInDays.isFinite && self.orbitPeriodInDays > 0.0
			&& self.epoch.value.isFinite
	}

	/**
		The position relative to the parent, in the heliocentric ecliptic frame of date.
	*/

	func position(atDate inDate: JulianDate) -> CartesianPosition
	{
		let degrees = Double.pi / 180.0
		let e = self.eccentricity

		//	Mean anomaly now, wrapped to -π…π so the solver starts close…

		let meanMotion = (2.0 * Double.pi) / self.orbitPeriodInDays
		let elapsedDays = inDate.daysElapsed(since: self.epoch)
		var m = (self.meanAnomaly * degrees + meanMotion * elapsedDays).remainder(dividingBy: 2.0 * Double.pi)

		if m.isNaN
		{
			m = 0.0
		}

		let eccentricAnomaly = Self.solveKepler(meanAnomaly: m, eccentricity: e)

		//	Position in the orbital plane, x toward periapsis…

		let a = self.semiMajorAxisInMeters
		let xOrbit = a * (cos(eccentricAnomaly) - e)
		let yOrbit = a * sqrt(1.0 - e * e) * sin(eccentricAnomaly)

		//	Rotate by ω, i, Ω (and precession) into the ecliptic…

		let precession = Self.precessionPerDay * (inDate.value - Self.j2000)
		let omega = self.argumentOfPeriapsis * degrees
		let incl = self.inclination * degrees
		let node = self.longitudeOfAscendingNode * degrees + precession

		let cosW = cos(omega)
		let sinW = sin(omega)
		let cosI = cos(incl)
		let sinI = sin(incl)
		let cosN = cos(node)
		let sinN = sin(node)

		let x1 = xOrbit * cosW - yOrbit * sinW
		let y1 = xOrbit * sinW + yOrbit * cosW

		return CartesianPosition(x: x1 * cosN - y1 * cosI * sinN,
									y: x1 * sinN + y1 * cosI * cosN,
									z: y1 * sinI)
	}

	/**
		Solves Kepler's equation, M = E − e·sin E, for E. Newton's method, kept inside
		the bracket M − e … M + e (which always holds the root) by falling back to
		bisection, so it can't diverge at high eccentricity.
	*/

	static func
	solveKepler(meanAnomaly inMeanAnomaly: Double, eccentricity inEccentricity: Double) -> Double
	{
		var low = inMeanAnomaly - inEccentricity
		var high = inMeanAnomaly + inEccentricity
		var anomaly = inMeanAnomaly + inEccentricity * sin(inMeanAnomaly)

		for _ in 0 ..< 60
		{
			let residual = anomaly - inEccentricity * sin(anomaly) - inMeanAnomaly

			//	The residual increases with E, so its sign tells which side the root is on…

			if residual > 0.0
			{
				high = anomaly
			}
			else
			{
				low = anomaly
			}

			var next = anomaly - residual / (1.0 - inEccentricity * cos(anomaly))

			if !(next > low && next < high)
			{
				next = 0.5 * (low + high)
			}

			let delta = abs(next - anomaly)
			anomaly = next

			if delta < 1e-13
			{
				break
			}
		}

		return anomaly
	}
}
