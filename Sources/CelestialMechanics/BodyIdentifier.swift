//
//  BodyIdentifier.swift
//  CelestialMechanics
//

import Foundation

/**
	The real solar-system bodies this package can position (and, for the client,
	draw in a special way). This list only grows if the solar system does -- it is
	emphatically not how the server introduces new places into the game. See
	`Placement.orbit` for that; a `BodyIdentifier` is only ever wrapped in
	`Placement.ephemeris`.

	On the wire and in `SwiftData` it's a plain string (the case name), and decoding
	never fails: a string this build doesn't know becomes `.unknown`, so a client
	that predates a body still decodes the `Location` that names it. It treats the
	`Location` as an ordinary body, positioned from its parent and drawn from the
	server's data (see `isKnown`). It encodes back to the same string.
*/

public enum BodyIdentifier : Hashable, Sendable, RawRepresentable, Codable
{
	case mercury
	case venus
	case earth
	case mars
	case jupiter
	case saturn
	case uranus
	case neptune

	/**
		The Sun, at the origin of the heliocentric frame.
	*/

	case sun

	/**
		The dwarf planet. SwiftAA has its position (Meeus’s series, valid 1885–2099),
		but not its physical elements.
	*/

	case pluto

	/**
		Earth’s Moon. Positioned relative to Earth (SwiftAA), but absolute as far as
		`Placement` goes: its parent, if any, is only informational.
	*/

	case moon

	/**
		Jupiter’s four Galilean moons and Saturn’s eight classical ones, the moons
		SwiftAA can position. Like the Moon they’re absolute as far as `Placement`
		goes, and their `parent` (see below) is only informational.
	*/

	case io
	case europa
	case ganymede
	case callisto

	case mimas
	case enceladus
	case tethys
	case dione
	case rhea
	case titan
	case hyperion
	case iapetus

	/**
		A body this build doesn’t know, with the string the server sent.
	*/

	case unknown(String)

	/**
		The eight planets, in order from the Sun.
	*/

	public static
	let
	planets: [BodyIdentifier] = [.mercury, .venus, .earth, .mars, .jupiter, .saturn, .uranus, .neptune]

	/**
		The moons this build can position, nearest their planet first.
	*/

	public static
	let
	moons: [BodyIdentifier] =
	[
		.moon,
		.io, .europa, .ganymede, .callisto,
		.mimas, .enceladus, .tethys, .dione, .rhea, .titan, .hyperion, .iapetus,
	]

	/**
		Every body this build can position: the Sun, the planets, Pluto and the
		moons. (There’s no `CaseIterable`, since `.unknown` has no single value.)
	*/

	public static
	let
	known: [BodyIdentifier] = [.sun] + BodyIdentifier.planets + [.pluto] + BodyIdentifier.moons

	/**
		Whether this is one of the eight planets.
	*/

	public var
	isPlanet: Bool
	{
		return Self.planets.contains(self)
	}

	/**
		Whether this is one of the moons in `moons`.
	*/

	public var
	isMoon: Bool
	{
		return self.parent != nil
	}

	/**
		The planet a moon goes around, nil for anything else (including `.unknown`).
		Positions don’t depend on it: a moon is `.ephemeris` and so absolute. It’s the
		`Location` a moon should be `at`, for the hierarchy.
	*/

	public var
	parent: BodyIdentifier?
	{
		switch self
		{
			case .moon:
				return .earth

			case .io, .europa, .ganymede, .callisto:
				return .jupiter

			case .mimas, .enceladus, .tethys, .dione, .rhea, .titan, .hyperion, .iapetus:
				return .saturn

			default:
				return nil
		}
	}

	/**
		Whether this build knows the body, and so can compute its position and
		orientation. If not, use the `Location`’s own data.
	*/

	public var
	isKnown: Bool
	{
		if case .unknown = self
		{
			return false
		}

		return true
	}

	//	MARK: - RawRepresentable

	public init(rawValue inRawValue: String)
	{
		//	`known` is every case but `.unknown`, so a string it doesn’t name is one this
		//	build doesn’t know…

		self = Self.known.first { $0.rawValue == inRawValue } ?? .unknown(inRawValue)
	}

	public var
	rawValue: String
	{
		switch self
		{
			case .mercury:				return "mercury"
			case .venus:				return "venus"
			case .earth:				return "earth"
			case .mars:					return "mars"
			case .jupiter:				return "jupiter"
			case .saturn:				return "saturn"
			case .uranus:				return "uranus"
			case .neptune:				return "neptune"
			case .moon:					return "moon"
			case .sun:					return "sun"
			case .pluto:				return "pluto"
			case .io:					return "io"
			case .europa:				return "europa"
			case .ganymede:				return "ganymede"
			case .callisto:				return "callisto"
			case .mimas:				return "mimas"
			case .enceladus:			return "enceladus"
			case .tethys:				return "tethys"
			case .dione:				return "dione"
			case .rhea:					return "rhea"
			case .titan:				return "titan"
			case .hyperion:				return "hyperion"
			case .iapetus:				return "iapetus"
			case .unknown(let inRawValue):	return inRawValue
		}
	}

	//	MARK: - Codable

	public init(from inDecoder: any Decoder)
		throws
	{
		let container = try inDecoder.singleValueContainer()
		self.init(rawValue: try container.decode(String.self))
	}

	public func encode(to inEncoder: any Encoder)
		throws
	{
		var container = inEncoder.singleValueContainer()
		try container.encode(self.rawValue)
	}
}
