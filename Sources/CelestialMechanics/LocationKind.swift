//
//  LocationKind.swift
//  CelestialMechanics
//

import Foundation

/**
	The kinds of location this package knows how to compute an absolute, heliocentric
	position for.

	Deliberately not included here: an "anchored" case (a location fixed relative to
	another location, such as a landed ship, or a ship docked at a station). It has no
	independent position of its own to compute -- resolving it means walking to `at` and
	adding an offset, which needs the `Location` graph itself. That's app/model-level
	knowledge this Foundation-only package doesn't have, so your `Location` type's own
	`kind`/switch will have one more case than this enum does, and only forward the three
	below into `OrbitalElements.position(ofKind:atDate:)`.
*/

public enum LocationKind : Codable
{
	case fixedBody(PlanetIdentifier)
	case circularOrbit(CircularOrbitElements)
	case transit(TransitParameters)
}
