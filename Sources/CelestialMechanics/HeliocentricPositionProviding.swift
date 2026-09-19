//
//  HeliocentricPositionProviding.swift
//  CelestialMechanics
//

import SwiftAA

/**
	A minimal protocol capturing the two SwiftAA accessors this package needs for a
	real planet's position.

	SwiftAA's own `Planet` class and `Earth` class each independently implement
	`heliocentricEclipticCoordinates` with the same signature, but it isn't declared as
	a requirement on any protocol they share -- it's present, but commented out, in
	SwiftAA's `CelestialBody` protocol as shipped. `radiusVector` *is* a shared
	requirement (via `PlanetaryBase`), so only `heliocentricEclipticCoordinates` needs
	this treatment.

	Each conformance below is deliberately empty: the concrete type already implements
	a matching member, so conforming costs nothing. It just gives every real planet one
	shared name to call through, so the only place that has to know Mercury and Venus
	are different classes is `OrbitalElements.makeBody(for:julianDay:)`, where a switch
	is unavoidable because Swift needs a concrete type to construct.
*/

public protocol HeliocentricPositionProviding
{
	var	heliocentricEclipticCoordinates	:	EclipticCoordinates	{	get	}
	var	radiusVector						:	AstronomicalUnit		{	get	}
}

extension Mercury	: HeliocentricPositionProviding	{}
extension Venus		: HeliocentricPositionProviding	{}
extension Earth		: HeliocentricPositionProviding	{}
extension Mars		: HeliocentricPositionProviding	{}
extension Jupiter	: HeliocentricPositionProviding	{}
extension Saturn		: HeliocentricPositionProviding	{}
extension Uranus		: HeliocentricPositionProviding	{}
extension Neptune	: HeliocentricPositionProviding	{}
