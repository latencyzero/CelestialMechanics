//
//  SolarSystemData.swift
//  CelestialMechanics
//

import Foundation

/**
	Reference orbital data (mean radius, period) for the real planets, adapted from the
	NASA Planetary Fact Sheet, and for the moons (about their planet, not the Sun, for
	the orbit radius and period; the semi-major axes and sidereal periods from the NASA
	and JPL satellite fact sheets). Pluto is about the Sun. The Sun has radius only.

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
		.pluto		:	5_906_380_000_000.0,
		.moon		:	384_400_000.0,								//	About Earth
		.io			:	421_800_000.0,								//	About Jupiter…
		.europa		:	671_100_000.0,
		.ganymede	:	1_070_400_000.0,
		.callisto	:	1_882_700_000.0,
		.mimas		:	185_540_000.0,								//	About Saturn…
		.enceladus	:	238_040_000.0,
		.tethys		:	294_670_000.0,
		.dione		:	377_420_000.0,
		.rhea		:	527_070_000.0,
		.titan		:	1_221_870_000.0,
		.hyperion	:	1_481_010_000.0,
		.iapetus	:	3_560_840_000.0,
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
		.pluto		:	90_560.0,
		.moon		:	27.321661,									//	Sidereal, about Earth
		.io			:	1.769138,									//	About Jupiter…
		.europa		:	3.551181,
		.ganymede	:	7.154553,
		.callisto	:	16.689018,
		.mimas		:	0.942422,									//	About Saturn…
		.enceladus	:	1.370218,
		.tethys		:	1.887802,
		.dione		:	2.736915,
		.rhea		:	4.517500,
		.titan		:	15.945421,
		.hyperion	:	21.276609,
		.iapetus	:	79.321500,
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
		.sun		:	695_700_000.0,
		.pluto		:	1_188_300.0,
		.moon		:	1_737_400.0,
		.io			:	1_821_600.0,
		.europa		:	1_560_800.0,
		.ganymede	:	2_631_200.0,
		.callisto	:	2_410_300.0,
		.mimas		:	198_200.0,
		.enceladus	:	252_100.0,
		.tethys		:	531_100.0,
		.dione		:	561_400.0,
		.rhea		:	763_500.0,
		.titan		:	2_574_700.0,
		.hyperion	:	135_000.0,									//	Irregular: 180 × 133 × 103 km
		.iapetus	:	734_500.0,
	]
}
