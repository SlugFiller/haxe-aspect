package org.slugfiller.aspect;

/**
	Defines a class which contains advice methods for an aspect.

	Code from the advice is added at the join point defined for the aspect.

	An advice is defined by implementing the interface, while specifying, as
	the interface parameter, the class which contains the matching join point.

	For example, for a join point class of the form:
	[
	import org.slugfiller.aspect.Aspect;

	class MyClass
	{
		static function myJoinPoint(param1 : Int, param2 : String)
		{
			Aspect.joinpoint(param1, param2);
		}
	}
]
	It is possible to add an advice class of the form:
	[
	import org.slugfiller.aspect.Advice;

	class MyAdvice implements Advice<MyClass>
	{
		static function myJoinPoint(param1 : Int, param2 : String)
		{
			// Do actions
		}
	}
]

	Advice methods must be public and static, and have the same names as the
	matching join point methods. Advice methods may not return a value. They
	must always return [Void].

	An advice class may not have any members or methods besides advice methods.
	An advice class may provide advice for one or more join points. An advice
	class does not need to implement advice for all join points, and may instead
	provide advice only for select join points.

	Note that the advice class itself must also be public and accessible from
	the join point.
**/

@:remove @:autoBuild(org.slugfiller.aspect.Aspect.advice())
extern interface Advice<T> {}
