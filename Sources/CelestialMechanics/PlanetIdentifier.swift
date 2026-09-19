//
//  PlanetIdentifier.swift
//  CelestialMechanics
//

import Foundation

/**
	The closed set of real solar-system bodies this package can ask SwiftAA for a
	position. This list only grows if the solar system does -- it is emphatically not
	how the server introduces new places into the game. See `LocationKind.circularOrbit`
	for that; a `PlanetIdentifier` is only ever wrapped in `LocationKind.fixedBody`.

	Stored as a `String` raw value (not the enum case itself) on the wire and in
	`SwiftData`, so an unrecognized value from an older/newer server round-trips as
	data rather than crashing a client that doesn't yet know about it.
*/

public enum PlanetIdentifier : String, Codable, CaseIterable, Sendable
{
	case mercury
	case venus
	case earth
	case mars
	case jupiter
	case saturn
	case uranus
	case neptune
}
