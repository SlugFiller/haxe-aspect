This library allows writing aspect-based code in the Haxe programming language.

# Motivation #

Aspect based programming allows separating code based on features rather than code flow or data flow. When coding a feature, instead of adding code to a large number of core modules, a single module may define multiple code blocks which are automatically called from the various core modules.

This can be likened to applying the observer pattern at compile time.

# Terminology #

**Join point** - A location in the code where additional code can be added.

**Advice** - A block of code intended to be inserted at some join point.

# Installation #

The library is available from haxelib, and can be installed using
```
haxelib install haxe-aspect
```

The library can then be used while compiling code
```
haxe -lib haxe-aspect Main.hx
```

# Usage #

Any class may define a join point by calling `Aspect.joinpoint` from a static method:
```
import org.slugfiller.aspect.Aspect;

class MyClass
{
  static function myJoinPoint(param1 : Int, param2 : Int)
  {
    // Defining a join point
    Aspect.joinpoint(param1, param2, " is printed");
  }

  function myNormalMethod()
  {
    // Calling the join point from a normal function
    myJoinPoint(1, 2);
  }
}
```
The method containing the join point MUST be static.

To add code to be called from the join point from another module, a public class implementing the `Advice` interface must be created, as so:
```
import org.slugfiller.aspect.Advice;

class MyAdvice implements Advice<MyClass>
{
  public static function myJoinPoint(param1 : Int, param2 : Int, param3 : String)
  {
    trace((param1+param2*7)+param3);
  }
}
```

A class implementing `Advice` must:

  * Be public
  * Contain only public static functions, and no other fields or methods
  * Each static method must have the same name as a static method containing a join point in the class for which advice is given
  * The method's parameters must match the values passed to the call to `Aspect.joinpoint`

In the above example, the join point from `MyClass` would be transformed into:
```
  static function myJoinPoint(param1 : Int, param2 : Int)
  {
    // Defining a join point
    MyAdvice.myJoinPoint(param1, param2, " is printed"); // Join point is resolved based on given advice
  }
```

Note that it's possible to provide more than one advice for a given join point. No guarantees are made regarding the order in which advice functions are called.