package org.slugfiller.aspect;

#if macro

import haxe.macro.Type;
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;

#end

/**
	Provides aspect based programming for Haxe.

	This allows multiple modules to inject code into a class at pre-defined
	location.

	To use, add join point methods to the class, as so:
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

	The join point function must be static. The parameters specified in the
	[Aspect.joinpoint] parameters are sent as-is to advice methods. Code from
	advice methods is inserted in place of the [Aspect.joinpoint] call. The name
	of the join point is the same as the method name.
**/

@:final
class Aspect
{
#if macro

	static public function advice() : Array<Field>
	{
		var cl : ClassType = Context.getLocalClass().get();
		var fields : Array<Field> = Context.getBuildFields();
		if (cl.meta.has(":org.slugfiller.aspect.Built"))
		{
			return null;
		}
		cl.meta.add(":org.slugfiller.aspect.Built", [], Context.currentPos());
		Context.onGenerate(function(_) {
			cl.meta.remove(":org.slugfiller.aspect.Built");
		});
		for (inter in cl.interfaces)
		{
			if (inter.t.toString() != "org.slugfiller.aspect.Advice" || inter.params.length != 1)
			{
				continue;
			}
			switch (inter.params[0])
			{
				case TInst(t, params):
					if (params.length != 0)
					{
						Context.error("Cannot add aspect to generic class", Context.currentPos());
					}
					var jp : ClassType = t.get();
					for (i in 0...fields.length)
					{
						var field = fields[i];
						switch (field.kind)
						{
							case FFun(f):
								var isstatic = false;
								for (access in field.access)
								{
									switch (access)
									{
										case AStatic:
											isstatic = true;
										case APublic:
										case AInline:
										default:
											Context.error("Advice method must be public static", field.pos);
									}
								}
								if (!isstatic)
								{
									Context.error("Advice method must be public static", field.pos);
								}
								var name = field.name;
								if (f.ret != null)
								{
									switch (f.ret)
									{
										case TPath(p):
											if (p.sub != null || p.name != "Void" || p.pack.length > 0 || p.params.length > 0)
											{
												Context.error("Advice method must return Void", field.pos);
											}
										default:
											Context.error("Advice method must return Void", field.pos);
									}
								}
								else
								{
									f.ret = TPath({sub : null, name : "Void", pack : [], params : []});
									field.kind = FFun(f);
									fields[i] = field;
								}
								var found = false;
								var statics = jp.statics.get();
								for (stat in statics)
								{
									switch (stat.kind)
									{
										case FMethod(k):
											switch (k)
											{
												case MethInline:
												case MethNormal:
												default:
													continue;
											}
										default:
											continue;
									}
									if (stat.name != name)
									{
										continue;
									}
									found = true;
									stat.meta.add(":org.slugfiller.aspect.Advice", [fieldToExpr(cl, field.name, field.pos)], field.pos);
									Context.onGenerate(function(_) {
										var statics = jp.statics.get();
										for (stat in statics)
										{
											if (stat.name != name)
											{
												continue;
											}
											if (stat.meta.has(":org.slugfiller.aspect.Advice"))
											{
												stat.meta.remove(":org.slugfiller.aspect.Advice");
												Context.error("Target method does not declare a join point", field.pos);
											}
										}
										Context.registerModuleDependency(jp.module, cl.module);
									});
									break;
								}
								if (!found)
								{
									Context.error("Matching join point not found for advice", field.pos);
								}
							default:
								Context.error("Advice may not contain non-function members", field.pos);
						}
					}
				default:
					Context.error("Cannot add aspect to a non-class", Context.currentPos());
			}
		}
		return fields;
	}

	static public function fieldToExpr(cl : ClassType, name : String, pos : Position) : Expr
	{
		var parts : Array<String> = cl.module.split(".");
		parts.push(cl.name);
		parts.push(name);
		var ret : Expr = {expr : EConst(CIdent(parts.shift())), pos : pos};
		for (part in parts)
		{
			ret = {expr : EField(ret, part), pos : pos};
		}
		return ret;
	}

#end

	macro static public function joinpoint(args : Array<Expr>) : Expr
	{
		var add : Array<Expr> = [];
		var locals = Context.getLocalVars();
		var vars : Array<Var> = [];
		var params : Array<Expr> = [];
		var varnum = 0;
		for (expr in args)
		{
			varnum++;
			while (locals.exists("_"+varnum))
			{
				varnum++;
			}
			vars.push({name : "_"+varnum, expr : expr, type : null});
			params.push({expr : EConst(CIdent("_"+varnum)), pos : expr.pos});
		}
		add.push({expr : EVars(vars), pos : Context.currentPos()});
		var jp : ClassType = Context.getLocalClass().get();
		var name = Context.getLocalMethod();
		var statics = jp.statics.get();
		for (field in statics)
		{
			if (field.name != name)
			{
				continue;
			}
			for (meta in field.meta.get())
			{
				if (meta.name != ":org.slugfiller.aspect.Advice")
				{
					continue;
				}
				for (expr in meta.params)
				{
					add.push({expr:ECall(expr, params), pos: meta.pos});
				}
			}
			field.meta.remove(":org.slugfiller.aspect.Advice");
			break;
		}

		return {expr : EBlock(add), pos : Context.currentPos()};
	}
}
