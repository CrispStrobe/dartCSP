/// A generic, reusable library for solving Constraint Satisfaction Problems (CSPs).
///
/// A CSP is a mathematical problem defined by a set of variables, a domain of
/// possible values for each variable, and a set of constraints that restrict
/// the values the variables can take.
///
/// This solver finds a solution by using a backtracking search algorithm enhanced
/// with forward checking (consistency enforcement) and heuristics to prune the
/// search space efficiently. It supports both binary (between two variables)
/// and n-ary (among multiple variables) constraints.
///
/// To define a problem, use the user-friendly [Problem] builder class.
///
/// Core algorithms implemented:
/// - Backtracking: A form of depth-first search for exploring possible assignments.
/// - AC-3: Enforces arc consistency for binary constraints.
/// - GAC (Generalized Arc Consistency): Enforces consistency for n-ary constraints.
/// - MRV (Minimum Remaining Values): A heuristic for variable selection.
/// - LCV (Least Constraining Value): A heuristic for value ordering.
///
/// ### Usage Examples
///
/// Basic usage with lambda constraints:
/// ```dart
/// import 'package:dart_csp/dart_csp.dart';
///
/// final p = Problem();
/// const colors = ['red', 'green', 'blue'];
///
/// // 1. Add variables and their domains
/// p.addVariables(['WA', 'NT', 'SA', 'Q', 'NSW', 'V', 'T'], colors);
///
/// // 2. Add constraints
/// p.addConstraint(['SA', 'WA'], (sa, wa) => sa != wa);
/// p.addConstraint(['SA', 'NT'], (sa, nt) => sa != nt);
/// p.addConstraint(['SA', 'Q'], (sa, q) => sa != q);
/// p.addConstraint(['SA', 'NSW'], (sa, nsw) => sa != nsw);
/// p.addConstraint(['SA', 'V'], (sa, v) => sa != v);
/// p.addConstraint(['WA', 'NT'], (wa, nt) => wa != nt);
/// p.addConstraint(['NT', 'Q'], (nt, q) => nt != q);
/// p.addConstraint(['Q', 'NSW'], (q, nsw) => q != nsw);
/// p.addConstraint(['NSW', 'V'], (nsw, v) => nsw != v);
///
/// // 3. Get the solution
/// final solution = await p.getSolution();
/// if (solution is Map) {
///   print("Solution found: $solution");
/// } else {
///   print("No solution found!");
/// }
/// ```
///
/// Using built-in constraint helpers:
/// ```dart
/// final p = Problem();
/// p.addVariables(['A', 'B', 'C'], [1, 2, 3, 4, 5]);
///
/// // Built-in constraints are more efficient
/// p.addAllDifferent(['A', 'B', 'C']);
/// p.addExactSum(['A', 'B'], 7);
///
/// final solution = await p.getSolution();
/// ```
///
/// Using string constraints (most convenient):
/// ```dart
/// final p = Problem();
/// p.addVariables(['A', 'B', 'C'], [1, 2, 3, 4, 5]);
///
/// // String constraints are parsed automatically
/// p.addStringConstraints([
///   "A != B",
///   "B != C", 
///   "A + B + C <= 10",
///   "A + B == C"
/// ]);
///
/// final solution = await p.getSolution();
/// ```

library dart_csp;

import 'src/problem.dart';
import 'src/types.dart';

// Core types and definitions
export 'src/types.dart';

// Main problem builder
export 'src/problem.dart';

// CSP solver
export 'src/solver.dart';

// Built-in constraint factories
export 'src/builtin_constraints.dart';

// String constraint parsing
export 'src/constraint_parser.dart';

/// Convenience function to create a new Problem instance
Problem createProblem() => Problem();

/// Convenience function to solve a problem with variables and constraints
/// 
/// Example:
/// ```dart
/// final solution = await solveProblem(
///   variables: {'A': [1, 2, 3], 'B': [1, 2, 3]},
///   constraints: ['A != B']
/// );
/// ```
Future<dynamic> solveProblem({
  required Map<String, List<dynamic>> variables,
  required List<String> constraints,
  int? timeStep,
  CspCallback? callback,
}) async {
  final problem = Problem();
  
  // Add variables
  for (final entry in variables.entries) {
    problem.addVariable(entry.key, entry.value);
  }
  
  // Add string constraints
  problem.addStringConstraints(constraints);
  
  // Set options if provided
  if (timeStep != null || callback != null) {
    problem.setOptions(timeStep: timeStep, callback: callback);
  }
  
  return await problem.getSolution();
}

/// Quick helper for common all-different problems
/// 
/// Example:
/// ```dart
/// final solution = await solveAllDifferent(
///   variables: ['A', 'B', 'C'],
///   domain: [1, 2, 3]
/// );
/// ```
Future<dynamic> solveAllDifferent({
  required List<String> variables,
  required List<dynamic> domain,
}) async {
  final problem = Problem();
  problem.addVariables(variables, domain);
  problem.addAllDifferent(variables);
  return await problem.getSolution();
}

/// Quick helper for sum constraint problems
/// 
/// Example:
/// ```dart
/// final solution = await solveSumProblem(
///   variables: ['A', 'B', 'C'],
///   domain: [1, 2, 3, 4, 5],
///   targetSum: 10
/// );
/// ```
Future<dynamic> solveSumProblem({
  required List<String> variables,
  required List<dynamic> domain,
  required num targetSum,
  List<num>? multipliers,
}) async {
  final problem = Problem();
  problem.addVariables(variables, domain);
  problem.addExactSum(variables, targetSum, multipliers: multipliers);
  return await problem.getSolution();
}