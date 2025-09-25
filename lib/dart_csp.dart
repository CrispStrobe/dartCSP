/// A generic, reusable library for solving Constraint Satisfaction Problems (CSPs).
///
/// A CSP is a mathematical problem defined by a set of variables, a domain of
/// possible values for each variable, and a set of constraints that restrict
/// the values the variables can take.
///
/// This solver finds solutions by using a backtracking search algorithm enhanced
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
///
/// Finding all solutions:
/// ```dart
/// final p = Problem();
/// p.addVariables(['A', 'B'], [1, 2, 3]);
/// p.addStringConstraint('A < B');
///
/// print('All solutions where A < B:');
/// await for (final solution in p.getSolutions()) {
///   print(solution);
/// }
/// // Output:
/// // {A: 1, B: 2}
/// // {A: 1, B: 3}
/// // {A: 2, B: 3}
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

/// Convenience function to find all solutions to a problem with string constraints
///
/// Example:
/// ```dart
/// final solutions = <Map<String, dynamic>>[];
/// await for (final solution in solveAllProblems(
///   variables: {'A': [1, 2, 3], 'B': [1, 2, 3]},
///   constraints: ['A < B']
/// )) {
///   solutions.add(solution);
/// }
/// print('Found ${solutions.length} solutions');
/// ```
Stream<Map<String, dynamic>> solveAllProblems({
  required Map<String, List<dynamic>> variables,
  required List<String> constraints,
}) async* {
  final problem = Problem();

  // Add variables
  for (final entry in variables.entries) {
    problem.addVariable(entry.key, entry.value);
  }

  // Add string constraints
  problem.addStringConstraints(constraints);

  // Stream all solutions
  yield* problem.getSolutions();
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

/// Quick helper for finding all solutions to all-different problems
///
/// Example:
/// ```dart
/// final solutions = <Map<String, dynamic>>[];
/// await for (final solution in solveAllDifferentMultiple(
///   variables: ['A', 'B'],
///   domain: [1, 2, 3]
/// )) {
///   solutions.add(solution);
/// }
/// ```
Stream<Map<String, dynamic>> solveAllDifferentMultiple({
  required List<String> variables,
  required List<dynamic> domain,
}) async* {
  final problem = Problem();
  problem.addVariables(variables, domain);
  problem.addAllDifferent(variables);
  yield* problem.getSolutions();
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

/// Quick helper for finding all solutions to sum constraint problems
///
/// Example:
/// ```dart
/// final solutions = <Map<String, dynamic>>[];
/// await for (final solution in solveSumProblemMultiple(
///   variables: ['X', 'Y'],
///   domain: [1, 2, 3, 4, 5],
///   targetSum: 7
/// )) {
///   solutions.add(solution);
/// }
/// ```
Stream<Map<String, dynamic>> solveSumProblemMultiple({
  required List<String> variables,
  required List<dynamic> domain,
  required num targetSum,
  List<num>? multipliers,
}) async* {
  final problem = Problem();
  problem.addVariables(variables, domain);
  problem.addExactSum(variables, targetSum, multipliers: multipliers);
  yield* problem.getSolutions();
}

/// Utility function to count solutions without storing them in memory
///
/// This is memory-efficient for problems with many solutions.
///
/// Example:
/// ```dart
/// final count = await countAllSolutions(
///   variables: {'A': [1, 2, 3, 4], 'B': [1, 2, 3, 4]},
///   constraints: ['A != B']
/// );
/// print('Problem has $count solutions');
/// ```
Future<int> countAllSolutions({
  required Map<String, List<dynamic>> variables,
  required List<String> constraints,
}) async {
  int count = 0;
  await for (final _ in solveAllProblems(
    variables: variables,
    constraints: constraints,
  )) {
    count++;
  }
  return count;
}

/// Utility function to check if a problem has multiple solutions
///
/// This is efficient as it stops after finding the second solution.
///
/// Example:
/// ```dart
/// final hasMultiple = await hasMultipleSolutions(
///   variables: {'A': [1, 2], 'B': [1, 2]},
///   constraints: ['A != B']
/// );
/// ```
Future<bool> hasMultipleSolutions({
  required Map<String, List<dynamic>> variables,
  required List<String> constraints,
}) async {
  int count = 0;
  await for (final _ in solveAllProblems(
    variables: variables,
    constraints: constraints,
  )) {
    count++;
    if (count >= 2) return true;
  }
  return false;
}

/// Utility function to get the first N solutions efficiently
///
/// Example:
/// ```dart
/// final firstThree = await getFirstNSolutions(
///   n: 3,
///   variables: {'A': [1, 2, 3, 4], 'B': [1, 2, 3, 4]},
///   constraints: ['A < B']
/// );
/// ```
Future<List<Map<String, dynamic>>> getFirstNSolutions({
  required int n,
  required Map<String, List<dynamic>> variables,
  required List<String> constraints,
}) async {
  final solutions = <Map<String, dynamic>>[];
  int count = 0;
  await for (final solution in solveAllProblems(
    variables: variables,
    constraints: constraints,
  )) {
    solutions.add(solution);
    count++;
    if (count >= n) break;
  }
  return solutions;
}
