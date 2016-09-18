//
//  IxState.swift
//  swiftz
//
//  Created by Alexander Ronald Altman on 6/11/14.
//  Copyright (c) 2015 TypeLift. All rights reserved.
//

#if !XCODE_BUILD
	import Operadics
#endif

/// IxState is a State Monad that carries extra type-level state (`I`) through 
/// its computation.
public struct IxState<I, O, A> {
	/// Extracts a final value and state given an index.
	let run : (I) -> (A, O)

	/// Lifts an indexed state computation into an `IxState`.
	public init(_ run : @escaping (I) -> (A, O)) {
		self.run = run
	}

	/// Evaluates the receiver's underlying state computation with the given 
	/// index and returns the final value, discarding the final state.
	public func eval(_ s : I) -> A {
		return run(s).0
	}

	/// Evaluates the receiver's underlying state computation with the given 
	/// index and returns the final state, discarding the final value.
	public func exec(_ s : I) -> O {
		return run(s).1
	}

	/// Applies a function to the final value generated by the receiver's 
	/// underlying state computation.
	public func map<B>(_ f : @escaping (A) -> B) -> IxState<I, O, B> {
		return f <^> self
	}

	/// Uses the function to witness a new `IxState` indexed by a different type.
	public func contramap<H>(_ f : @escaping (H) -> I) -> IxState<H, O, A> {
		return f <!> self
	}

	/// Applies a function to the final state value generated by the receivers 
	/// underlying state computation.
	public func imap<P>(_ f : @escaping (O) -> P) -> IxState<I, P, A> {
		return f <^^> self
	}

	/// Runs both stateful computations, applying the resulting function to the 
	/// final value of the receiver.
	public func ap<E, B>(_ f : IxState<E, I, (A) -> B>) -> IxState<E, O, B> {
		return f <*> self
	}

	/// Uses the final value of the receiver to produce another stateful 
	/// computation.
	public func flatMap<E, B>(_ f : @escaping (A) -> IxState<O, E, B>) -> IxState<I, E, B> {
		return self >>- f
	}

}

/// Lifts the given value into an Indexed State Monad that always returns that
/// value regardless of the index.
public func pure<I, A>(_ x : A) -> IxState<I, I, A> {
	return IxState { (x, $0) }
}

public func <^> <I, O, A, B>(_ f : @escaping (A) -> B, a : IxState<I, O, A>) -> IxState<I, O, B> {
	return IxState { s1 in
		let (x, s2) = a.run(s1)
		return (f(x), s2)
	}
}

public func <!> <H, I, O, A>(_ f : @escaping (H) -> I, a : IxState<I, O, A>) -> IxState<H, O, A> {
	return IxState { a.run(f($0)) }
}

public func <^^> <I, O, P, A>(_ f : @escaping (O) -> P, a : IxState<I, O, A>) -> IxState<I, P, A> {
	return IxState { s1 in
		let (x, s2) = a.run(s1)
		return (x, f(s2))
	}
}

public func <*> <I, J, O, A, B>(_ f : IxState<I, J, (A) -> B>, a : IxState<J, O, A>) -> IxState<I, O, B> {
	return IxState { s1 in
		let (g, s2) = f.run(s1)
		let (x, s3) = a.run(s2)
		return (g(x), s3)
	}
}

public func >>- <I, J, O, A, B>(_ a : IxState<I, J, A>, f : @escaping (A) -> IxState<J, O, B>) -> IxState<I, O, B> {
	return IxState { s1 in
		let (x, s2) = a.run(s1)
		return f(x).run(s2)
	}
}

public func join<I, J, O, A>(_ a : IxState<I, J, IxState<J, O, A>>) -> IxState<I, O, A> {
	return IxState { s1 in
		let (b, s2) = a.run(s1)
		return b.run(s2)
	}
}

/// Fetch the current value of the state within the monad.
public func get<I>() -> IxState<I, I, I> {
	return IxState { ($0, $0) }
}

/// Get a specific component of the state, using a projection function supplied.
public func gets<I, A>(_ f : @escaping (I) -> A) -> IxState<I, I, A> {
	return IxState { (f($0), $0) }
}

/// Sets the state value within the monad to the given value.
public func put<I, O>(_ s : O) -> IxState<I, O, ()> {
	return IxState { _ in ((), s) }
}

/// Updates the state value within the monad to the result of applying the given
/// function to the current state value.
public func modify<I, O>(_ f : @escaping (I) -> O) -> IxState<I, O, ()> {
	return IxState { ((), f($0)) }
}
