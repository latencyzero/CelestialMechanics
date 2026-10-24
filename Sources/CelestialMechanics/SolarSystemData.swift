//
//  SolarSystemData.swift
//  CelestialMechanics
//

import Foundation

/**
	Reference orbital data (mean radius, period) for the real planets, adapted from the
	NASA Planetary Fact Sheet, and for the Moon (about Earth, not the Sun, for the orbit
	radius and period).

	No longer used to *compute* a real planet's position -- `OrbitalElements` asks
	SwiftAA for that now. Kept because it's still useful for: seeding a plausible
	`.circularOrbit` for a fictional place (e.g. "put this station at roughly Mars's
	distance"), and for sanity-checking `OrbitalElements` against expected values in
	tests below.
*/

public enum SolarSystemData
{
	public static let meanOrbitRadiusInMeters : [BodyIdentifier : Double] =
	[
		.mercury	:	57_909_050_000.0,
		.venus		:	108_208_000_000.0,
		.earth		:	149_598_023_000.0,
		.mars		:	227_939_200_000.0,
		.jupiter	:	778_570_000_000.0,
		.saturn		:	1_433_530_000_000.0,
		.uranus		:	2_872_460_000_000.0,
		.neptune	:	4_495_060_000_000.0,
		.moon		:	384_400_000.0,								//	About Earth
	]

	public static let orbitPeriodInDays : [BodyIdentifier : Double] =
	[
		.mercury	:	87.9691,
		.venus		:	224.701,
		.earth		:	365.256,
		.mars		:	686.980,
		.jupiter	:	4332.59,
		.saturn		:	10_759.22,
		.uranus		:	30_688.5,
		.neptune	:	60_182.0,
		.moon		:	27.321661,									//	Sidereal, about Earth
	]

	/**
		Mean radii, from the same fact sheet (and the IAU for the gas giants, whose
		“surface” is the 1 bar level).
	*/

	public static let meanRadiusInMeters : [BodyIdentifier : Double] =
	[
		.mercury	:	2_439_700.0,
		.venus		:	6_051_800.0,
		.earth		:	6_371_000.0,
		.mars		:	3_389_500.0,
		.jupiter	:	69_911_000.0,
		.saturn		:	58_232_000.0,
		.uranus		:	25_362_000.0,
		.neptune	:	24_622_000.0,
		.moon		:	1_737_400.0,
	]
}
