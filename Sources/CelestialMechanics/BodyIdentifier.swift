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
		Earth’s Moon. Positioned relative to Earth (SwiftAA), but absolute as far as
		`Placement` goes: its parent, if any, is only informational.
	*/

	case moon

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
		Every body this build can position: the planets and the moons. (There’s no
		`CaseIterable`, since `.unknown` has no single value.)
	*/

	public static
	let
	known: [BodyIdentifier] = BodyIdentifier.planets + [.moon]

	/**
		Whether this is one of the eight planets.
	*/

	public var
	isPlanet: Bool
	{
		return Self.planets.contains(self)
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
		switch inRawValue
		{
			case "mercury":		self = .mercury
			case "venus":		self = .venus
			case "earth":		self = .earth
			case "mars":		self = .mars
			case "jupiter":		self = .jupiter
			case "saturn":		self = .saturn
			case "uranus":		self = .uranus
			case "neptune":		self = .neptune
			case "moon":		self = .moon
			default:			self = .unknown(inRawValue)
		}
	}

	public var
	rawValue: String
	{
		switch self
		{
			case .mercury:					return "mercury"
			case .venus:					return "venus"
			case .earth:					return "earth"
			case .mars:						return "mars"
			case .jupiter:					return "jupiter"
			case .saturn:					return "saturn"
			case .uranus:					return "uranus"
			case .neptune:					return "neptune"
			case .moon:						return "moon"
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
