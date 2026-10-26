//
//  BodyRotation.swift
//  CelestialMechanics
//

import Foundation

/**
	Which way a body's north pole and prime meridian point at a given moment, as
	unit vectors in the same heliocentric ecliptic frame `OrbitalElements` uses
	for positions (x toward the equinox, z toward ecliptic north). They're
	`CartesianPosition`s for convenience, but unitless directions, not meters.

	Together they're the body-fixed frame: `northPole` is its z axis,
	`primeMeridian` (where the equator meets 0° longitude) its x axis, and
	`east` (90° E on the equator) its y axis.
*/

public struct BodyOrientation : Equatable, Sendable
{
	public var	northPole		:	CartesianPosition
	public var	primeMeridian	:	CartesianPosition

	public var
	east: CartesianPosition
	{
		let n = self.northPole
		let m = self.primeMeridian

		return CartesianPosition(x: n.y * m.z - n.z * m.y,
									y: n.z * m.x - n.x * m.z,
									z: n.x * m.y - n.y * m.x)
	}
}

/**
	Body orientation from the IAU Working Group on Cartographic Coordinates and
	Rotational Elements (WGCCRE) models: the north pole's right ascension and
	declination (α₀, δ₀, ICRF/J2000 equatorial), and the prime meridian's angle W,
	measured eastward along the body's equator from where it crosses the ICRF
	equator.

	Values are from the 2015 report (Archinal et al. 2018), except Mars, which
	uses the 2009 report's simpler linear model (the 2015 one needs a dozen
	periodic terms to be any better). Small periodic terms for Mercury and
	Jupiter are left out; they're hundredths of a degree. The Moon's are left
	out too, but they're not small: its libration terms reach about 4° in the pole
	and 3.6° in W, so its near side can be off by that much.

	“North” is the IAU's: the pole on the north side of the solar system's
	invariable plane. Venus and Uranus spin retrograde, so W decreases for them,
	and their rotation is clockwise seen from that pole.

	SwiftAA has nothing general for this: only Meeus's physical ephemerides for
	Mars and Jupiter, which give the central meridian as seen from Earth.
*/

public enum BodyRotation
{
	public static
	func
	orientation(of inBody: BodyIdentifier, atDate inDate: Date) -> BodyOrientation?
	{
		guard
			let elements = Self.elements(for: inBody, atDate: inDate)
		else
		{
			return nil
		}

		return Self.orientation(rightAscension: elements.rightAscension,
								declination: elements.declination,
								primeMeridianAngle: elements.primeMeridianAngle)
	}

	/**
		The IAU elements for `inBody` at `inDate`, in degrees, with W reduced
		to 0–360°, or nil for a body this build has no model for (`.unknown`, and for now the
		Sun, Pluto and the moons other than ours).
	*/

	public static
	func
	elements(for inBody: BodyIdentifier, atDate inDate: Date)
		-> (rightAscension: Double, declination: Double, primeMeridianAngle: Double)?
	{
		//	The models use TDB, which runs about 69 s ahead of UTC. That's
		//	nearly 0.3° of Earth's rotation, so it's worth adding…

		let d = Self.daysSinceJ2000(atDate: inDate)
		let t = d / Self.daysPerJulianCentury

		let alpha: Double
		let delta: Double
		let w: Double

		switch inBody
		{
		case .mercury:
			alpha = 281.0103 - 0.0328 * t
			delta = 61.4155 - 0.0049 * t
			w = 329.5988 + 6.1385108 * d

		case .venus:
			alpha = 272.76
			delta = 67.16
			w = 160.20 - 1.4813688 * d

		case .earth:
			alpha = 0.00 - 0.641 * t
			delta = 90.00 - 0.557 * t
			w = 190.147 + 360.9856235 * d

		case .mars:
			alpha = 317.68143 - 0.1061 * t
			delta = 52.88650 - 0.0609 * t
			w = 176.630 + 350.89198226 * d

		case .jupiter:
			alpha = 268.056595 - 0.006499 * t
			delta = 64.495303 + 0.002413 * t
			w = 284.95 + 870.5360000 * d			//	System III (the magnetic field)

		case .saturn:
			alpha = 40.589 - 0.036 * t
			delta = 83.537 - 0.004 * t
			w = 38.90 + 810.7939024 * d				//	System III

		case .uranus:
			alpha = 257.311
			delta = -15.175
			w = 203.81 - 501.1600928 * d

		case .neptune:
			let n = Self.radians(357.85 + 52.316 * t)
			alpha = 299.36 + 0.70 * sin(n)
			delta = 43.46 - 0.51 * cos(n)
			w = 249.978 + 541.1397757 * d - 0.48 * sin(n)

		case .moon:
			alpha = 269.9949 + 0.0031 * t
			delta = 66.5392 + 0.0130 * t
			w = 38.3213 + 13.17635815 * d			//	No libration terms; see above

		case .sun, .pluto, .io, .europa, .ganymede, .callisto,
				.mimas, .enceladus, .tethys, .dione, .rhea, .titan, .hyperion, .iapetus,
				.unknown:
			//	No model yet (a `Location` carries its own elements)…

			return nil
		}

		var reduced = w.truncatingRemainder(dividingBy: 360.0)
		if reduced < 0.0
		{
			reduced += 360.0
		}

		return (alpha, delta, reduced)
	}

	/**
		The orientation of a body this package has no model for (a moon, a
		station), from its constant IAU elements, all in degrees: the pole's
		`inRightAscension` and `inDeclination` (ICRF/J2000), and the prime meridian
		angle `inW0` at J2000.0, advancing by `inSpinRate` degrees per day
		(negative for retrograde). This is the linear part of the IAU models, so
		it leaves out the periodic terms and the pole's precession that
		``orientation(of:atDate:)`` has for the planets.
	*/

	public static
	func
	orientation(rightAscension inRightAscension: Double, declination inDeclination: Double, w0 inW0: Double, spinRate inSpinRate: Double, atDate inDate: Date)
		-> BodyOrientation
	{
		var w = (inW0 + inSpinRate * Self.daysSinceJ2000(atDate: inDate)).truncatingRemainder(dividingBy: 360.0)
		if w < 0.0
		{
			w += 360.0
		}

		return Self.orientation(rightAscension: inRightAscension, declination: inDeclination, primeMeridianAngle: w)
	}

	/**
		Days since J2000.0 in TDB, the time argument of the IAU models. TDB runs
		about 69 s ahead of UTC, which is nearly 0.3° of Earth's rotation, so it's
		worth adding.
	*/

	private
	static
	func
	daysSinceJ2000(atDate inDate: Date) -> Double
	{
		return JulianDate(date: inDate.addingTimeInterval(Self.terrestrialTimeOffset)).daysElapsed(since: Self.j2000)
	}

	/**
		Turns IAU elements (degrees) into pole and prime meridian directions in
		the heliocentric ecliptic frame.

		In ICRF equatorial coordinates, the body-fixed frame is
		Rz(α₀ + 90°) · Rx(90° − δ₀) · Rz(W). The pole is its z column and the
		prime meridian its x column, which are then rotated from the equator to
		the ecliptic (by −ε about x).
	*/

	static
	func
	orientation(rightAscension inAlpha: Double, declination inDelta: Double, primeMeridianAngle inW: Double)
		-> BodyOrientation
	{
		let alpha = Self.radians(inAlpha)
		let delta = Self.radians(inDelta)
		let w = Self.radians(inW)

		let pole = CartesianPosition(x: cos(delta) * cos(alpha),
										y: cos(delta) * sin(alpha),
										z: sin(delta))

		//	The ascending node of the body's equator on the ICRF equator, and the
		//	direction 90° east of it along the body's equator; the prime meridian
		//	is W along from the node…

		let node = CartesianPosition(x: -sin(alpha), y: cos(alpha), z: 0.0)
		let nodeEast = CartesianPosition(x: -sin(delta) * cos(alpha),
											y: -sin(delta) * sin(alpha),
											z: cos(delta))
		let meridian = cos(w) * node + sin(w) * nodeEast

		return BodyOrientation(northPole: Self.equatorialToEcliptic(pole),
								primeMeridian: Self.equatorialToEcliptic(meridian))
	}

	private
	static
	func
	equatorialToEcliptic(_ inVector: CartesianPosition) -> CartesianPosition
	{
		let cosE = cos(Self.obliquity)
		let sinE = sin(Self.obliquity)

		return CartesianPosition(x: inVector.x,
									y: cosE * inVector.y + sinE * inVector.z,
									z: -sinE * inVector.y + cosE * inVector.z)
	}

	private
	static
	func
	radians(_ inDegrees: Double) -> Double
	{
		return inDegrees * .pi / 180.0
	}

	private	static	let	j2000					:	JulianDate	=	JulianDate(2_451_545.0)
	private	static	let	daysPerJulianCentury	:	Double		=	36_525.0
	private	static	let	terrestrialTimeOffset	:	TimeInterval	=	69.184
	private	static	let	obliquity				:	Double		=	23.4392911 * .pi / 180.0		//	J2000 mean obliquity
}
