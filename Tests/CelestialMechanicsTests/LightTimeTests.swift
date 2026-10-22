//
//  LightTimeTests.swift
//  CelestialMechanicsTests
//

import Foundation
import Testing
@testable import CelestialMechanics

@Suite("Light Time")
struct
LightTimeTests
{
	@Test("Distance of c meters is one light-second")
	func oneLightSecond()
	{
		let from = CartesianPosition(x: 0.0, y: 0.0, z: 0.0)
		let to = CartesianPosition(x: 0.0, y: LightTime.speedOfLightInMetersPerSecond, z: 0.0)

		#expect(abs(LightTime.seconds(from: from, to: to) - 1.0) < 1.0e-12)
	}

	//	1 AU is defined as exactly 149,597,870,700 m, which is ~499.004784 light-seconds.
	@Test("One AU is about 499 light-seconds")
	func oneAstronomicalUnit()
	{
		let from = CartesianPosition(x: 1.0e11, y: -2.0e10, z: 3.0e9)
		let offset = CartesianPosition(x: 3.0, y: 4.0, z: 12.0)		//	|offset| = 13
		let to = from + (149_597_870_700.0 / 13.0) * offset

		#expect(abs(LightTime.seconds(from: from, to: to) - 499.004784) < 1.0e-6)
	}

	@Test("Light time is symmetric, and zero for the same position")
	func isSymmetricAndZeroForSamePosition()
	{
		let a = CartesianPosition(x: 1.0e11, y: 2.0e11, z: -5.0e9)
		let b = CartesianPosition(x: -7.0e11, y: 3.0e10, z: 1.0e9)

		#expect(LightTime.seconds(from: a, to: b) == LightTime.seconds(from: b, to: a))
		#expect(LightTime.seconds(from: a, to: a) == 0.0)
	}

	//	Earth–Mars distance ranges from roughly 0.37 AU to 2.68 AU, i.e. about 3 to 22.3 minutes.
	@Test("Earth to Mars is within the known range")
	func earthToMarsIsWithinKnownRange()
	{
		let seconds = LightTime.seconds(fromPlacement: .ephemeris(.earth), toPlacement: .ephemeris(.mars), atDate: Date())

		#expect(seconds > 3.0 * 60.0)
		#expect(seconds < 22.5 * 60.0)
	}
}
