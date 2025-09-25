/// Problem builder class and extensions for easy CSP construction.

import 'dart:async';
import 'types.dart';
import 'solver.dart';
import 'builtin_constraints.dart';
import 'constraint_parser.dart';

/// A user-friendly wrapper class to build a constraint satisfaction problem.
///
/// This class provides a builder pattern API to add variables and constraints
/// before creating a [CspProblem] object to be solved by the [CSP] solver.
///
/// ### Usage Example
/// ```dart
/// final p = Problem();
/// const colors = ['red', 'green', 'blue'];
///
/// // 1. Add variables and their domains
/// p.addVariables(['WA', 'NT', 'SA', 'Q', 'NSW', 'V', 'T'], colors);
///
/// // 2. Add constraints
/// p.addConstraint(['SA', 'WA'], (sa, wa) => sa != wa);
/// p.addConstraint(['SA', 'NT'], (sa, nt) => sa != nt);
/// // ... more constraints
///
/// // 3. Get the solution
/// final solution = await p.getSolution();
/// if (solution is Map) {
///   print("Solution found: $solution");
/// } else {
///   print("No solution found!");
/// }
///
/// // 4. Or get all solutions
/// await for (final solution in p.getSolutions()) {
///   print("Found solution: $solution");
/// }
/// ```
class Problem {
  final Map<String, List<dynamic>> _variables = {};
  final List<BinaryConstraint> _constraints = [];
  final List<NaryConstraint> _naryConstraints = [];
  int _timeStep = 1;
  CspCallback? _cb;

  /// Adds a single variable and its domain to the problem.
  ///
  /// - [name]: The name of the variable.
  /// - [domain]: A list of possible values for the variable.
  void addVariable(String name, List<dynamic> domain) {
    if (_variables.containsKey(name)) {
      throw ArgumentError("Variable '$name' already exists.");
    }
    if (domain.isEmpty) {
      throw ArgumentError("Domain for '$name' must be a non-empty list.");
    }
    _variables[name] = List.from(domain);
  }

  /// Adds multiple variables that share the same domain.
  ///
  /// - [names]: A list of variable names.
  /// - [domain]: A list of possible values for all variables.
  void addVariables(List<String> names, List<dynamic> domain) {
    for (final name in names) {
      addVariable(name, domain);
    }
  }

  /// Adds a constraint to the problem.
  ///
  /// Automatically routes to binary or n-ary constraint types based on the
  /// number of variables involved.
  ///
  /// - For **2 variables**, the [predicate] must be a [BinaryPredicate], i.e.,
  ///   `bool Function(dynamic, dynamic)`. The constraint will be added for
  ///   both directions (e.g., A->B and B->A) to ensure full consistency checks.
  /// - For **1, 3, or more variables**, the [predicate] must be an [NaryPredicate], i.e.,
  ///   `bool Function(Map<String, dynamic>)`.
  ///
  /// - [variables]: A list of variable names this constraint applies to.
  /// - [predicate]: The function that evaluates the constraint.
  void addConstraint<T extends Function>(List<String> variables, T predicate) {
    if (variables.isEmpty) {
      throw ArgumentError("addConstraint requires a non-empty list of variables.");
    }
    for (final v in variables) {
      if (!_variables.containsKey(v)) {
        throw ArgumentError(
            "addConstraint references variable '$v' which has not been added yet.");
      }
    }

    if (variables.length == 2) {
      if (predicate is! BinaryPredicate) {
        throw ArgumentError(
            'For 2 variables, predicate must be of type bool Function(dynamic, dynamic)');
      }
      final v1 = variables[0];
      final v2 = variables[1];
      // To ensure full arc consistency, we create directed constraints for
      // both directions from a single user-defined predicate.
      _constraints.add(BinaryConstraint(v1, v2, predicate));
      _constraints.add(BinaryConstraint(v2, v1, (val2, val1) => predicate(val1, val2)));
    } else {
      if (predicate is! NaryPredicate) {
        throw ArgumentError(
            'For 1, 3, or more variables, predicate must be of type bool Function(Map<String, dynamic>)');
      }
      _naryConstraints.add(NaryConstraint(vars: variables, predicate: predicate));
    }
  }

  /// Sets the optional time step and callback for visualizing the search.
  ///
  /// - [timeStep]: The delay in milliseconds between solver steps.
  /// - [callback]: The function to call at each step.
  void setOptions({int? timeStep, CspCallback? callback}) {
    if (timeStep != null) _timeStep = timeStep;
    if (callback != null) _cb = callback;
  }

  /// Solves the problem and returns the first solution found.
  ///
  /// Assembles a [CspProblem] object from the added variables and constraints
  /// and passes it to the core [CSP.solve] function.
  ///
  /// Returns a [Future] that completes with:
  /// - A `Map<String, dynamic>` of variable assignments if a solution is found.
  /// - The string 'FAILURE' if no solution exists.
  Future<dynamic> getSolution() {
    final problem = CspProblem(
      variables: _variables,
      constraints: _constraints,
      naryConstraints: _naryConstraints,
      timeStep: _timeStep,
      cb: _cb,
    );
    return CSP.solve(problem);
  }

  /// Solves the problem and returns a stream of all solutions found.
  ///
  /// Assembles a [CspProblem] object from the added variables and constraints
  /// and uses the backtracking generator to find all valid assignments.
  ///
  /// Returns a [Stream] which emits a `Map<String, dynamic>` for each solution.
  /// If no solutions exist, the stream will be empty.
  ///
  /// ### Usage Example
  /// ```dart
  /// final p = Problem();
  /// p.addVariables(['A', 'B'], [1, 2, 3]);
  /// p.addStringConstraint('A < B');
  /// 
  /// print('All solutions where A < B:');
  /// await for (final solution in p.getSolutions()) {
  ///   print(solution);
  /// }
  /// ```
  Stream<Map<String, dynamic>> getSolutions() {
    final problem = CspProblem(
      variables: _variables,
      constraints: _constraints,
      naryConstraints: _naryConstraints,
      // timeStep and cb are less relevant for streaming all solutions
      // as the callback would be called too frequently
    );
    return CSP.solveAll(problem);
  }

  /// Gets all variables and their current domains
  Map<String, List<dynamic>> get variables => Map.unmodifiable(_variables);

  /// Gets the number of variables in the problem
  int get variableCount => _variables.length;

  /// Gets the number of constraints in the problem
  int get constraintCount => _constraints.length + _naryConstraints.length;

  /// Removes all variables and constraints, resetting the problem
  void clear() {
    _variables.clear();
    _constraints.clear();
    _naryConstraints.clear();
  }

  /// Creates a copy of this problem
  Problem copy() {
    final newProblem = Problem();
    newProblem._variables.addAll(_variables.map((k, v) => MapEntry(k, List.from(v))));
    newProblem._constraints.addAll(_constraints);
    newProblem._naryConstraints.addAll(_naryConstraints);
    newProblem._timeStep = _timeStep;
    newProblem._cb = _cb;
    return newProblem;
  }
}

/// Extension methods for Problem class to make using built-in constraints easier
extension BuiltinConstraints on Problem {
  
  /// Add an all-different constraint
  void addAllDifferent(List<String> variables) {
    if (variables.length == 2) {
      addConstraint(variables, allDifferentBinary());
    } else {
      addConstraint(variables, allDifferent());
    }
  }
  
  /// Add an all-equal constraint
  void addAllEqual(List<String> variables) {
    if (variables.length == 2) {
      addConstraint(variables, allEqualBinary());
    } else {
      addConstraint(variables, allEqual());
    }
  }
  
  /// Add an exact sum constraint
  void addExactSum(List<String> variables, num targetSum, {List<num>? multipliers}) {
    if (variables.length == 2) {
      addConstraint(variables, exactSumBinary(targetSum, multipliers: multipliers));
    } else {
      addConstraint(variables, exactSum(targetSum, multipliers: multipliers));
    }
  }
  
  /// Add a sum range constraint
  void addSumRange(List<String> variables, num minSum, num maxSum, {List<num>? multipliers}) {
    if (variables.length == 2) {
      addConstraint(variables, sumInRangeBinary(minSum, maxSum, multipliers: multipliers));
    } else {
      addConstraint(variables, sumInRange(minSum, maxSum, multipliers: multipliers));
    }
  }
  
  /// Add an exact product constraint
  void addExactProduct(List<String> variables, num targetProduct) {
    if (variables.length == 2) {
      addConstraint(variables, exactProductBinary(targetProduct));
    } else {
      addConstraint(variables, exactProduct(targetProduct));
    }
  }
  
  /// Add an in-set constraint (variables must take values from allowed set)
  void addInSet(List<String> variables, Set<dynamic> allowedValues) {
    if (variables.length == 2) {
      addConstraint(variables, inSetBinary(allowedValues));
    } else {
      addConstraint(variables, inSet(allowedValues));
    }
  }
  
  /// Add a not-in-set constraint (variables cannot take values from forbidden set)
  void addNotInSet(List<String> variables, Set<dynamic> forbiddenValues) {
    if (variables.length == 2) {
      addConstraint(variables, notInSetBinary(forbiddenValues));
    } else {
      addConstraint(variables, notInSet(forbiddenValues));
    }
  }
  
  /// Add an ordering constraint (variables in ascending order)
  void addAscending(List<String> variables) {
    if (variables.length == 2) {
      addConstraint(variables, ascendingBinary());
    } else {
      addConstraint(variables, ascendingInOrder(variables));
    }
  }
  
  /// Add a strict ordering constraint (variables in strictly ascending order)
  void addStrictlyAscending(List<String> variables) {
    if (variables.length == 2) {
      addConstraint(variables, strictlyAscendingBinary());
    } else {
      addConstraint(variables, strictlyAscendingInOrder(variables));
    }
  }
  
  /// Add a descending order constraint
  void addDescending(List<String> variables) {
    if (variables.length == 2) {
      addConstraint(variables, descendingBinary());
    } else {
      addConstraint(variables, descendingInOrder(variables));
    }
  }
}

/// Extension to add string constraint parsing to Problem class
extension StringConstraints on Problem {
  
  /// Add a constraint from a string expression
  /// 
  /// Supports expressions like:
  /// - "A != B" (all different)
  /// - "A + B == 10" (exact sum)  
  /// - "A * B >= 5" (minimum product)
  /// - "A + B + C == D" (variable sum)
  /// - "A in [1, 2, 3]" (set membership)
  /// - "A < B < C" (ordering)
  /// 
  /// Example:
  /// ```dart
  /// final p = Problem();
  /// p.addVariables(['A', 'B', 'C'], [1, 2, 3, 4, 5]);
  /// p.addStringConstraint("A + B == C");
  /// p.addStringConstraint("A != B");
  /// ```
  void addStringConstraint(String constraintStr) {
    try {
      final parsed = ConstraintParser.parseConstraint(constraintStr, _variables);
      
      switch (parsed.type) {
        case ConstraintType.binary:
          addConstraint(parsed.variables, parsed.predicate as BinaryPredicate);
          break;
        case ConstraintType.nary:
          addConstraint(parsed.variables, parsed.predicate as NaryPredicate);
          break;
        case ConstraintType.variableSum:
        case ConstraintType.variableProduct:
          final varConstraint = parsed.predicate as VariableConstraint;
          addConstraint(parsed.variables, varConstraint.toPredicate());
          break;
      }
    } catch (e) {
      throw ConstraintParseException('Failed to parse constraint', constraintStr);
    }
  }
  
  /// Add multiple string constraints at once
  void addStringConstraints(List<String> constraints) {
    for (final constraint in constraints) {
      addStringConstraint(constraint);
    }
  }
}

/// Extension for debugging and introspection
extension ProblemDebug on Problem {
  
  /// Print a summary of the problem
  void printSummary() {
    print('CSP Problem Summary:');
    print('  Variables: ${variableCount}');
    print('  Constraints: ${constraintCount}');
    print('  Variables and domains:');
    for (final entry in _variables.entries) {
      print('    ${entry.key}: ${entry.value}');
    }
  }
  
  /// Validate the problem for common issues
  List<String> validate() {
    final issues = <String>[];
    
    // Check for empty domains
    for (final entry in _variables.entries) {
      if (entry.value.isEmpty) {
        issues.add('Variable ${entry.key} has empty domain');
      }
    }
    
    // Check if problem is over-constrained (more constraints than variables)
    if (constraintCount > variableCount * 2) {
      issues.add('Problem may be over-constrained (${constraintCount} constraints for ${variableCount} variables)');
    }
    
    // Check for isolated variables (variables with no constraints)
    final constrainedVariables = <String>{};
    for (final constraint in _constraints) {
      constrainedVariables.add(constraint.head);
      constrainedVariables.add(constraint.tail);
    }
    for (final constraint in _naryConstraints) {
      constrainedVariables.addAll(constraint.vars);
    }
    
    for (final varName in _variables.keys) {
      if (!constrainedVariables.contains(varName)) {
        issues.add('Variable $varName has no constraints (isolated)');
      }
    }
    
    return issues;
  }
}

/// Extension providing utilities for working with multiple solutions
extension MultipleSolutions on Problem {
  
  /// Get all solutions as a List (convenience method for small solution sets)
  /// 
  /// Warning: This will collect all solutions in memory. For problems with
  /// many solutions, prefer using getSolutions() stream directly.
  ///
  /// Example:
  /// ```dart
  /// final solutions = await p.getAllSolutions();
  /// print('Found ${solutions.length} solutions');
  /// for (final solution in solutions) {
  ///   print(solution);
  /// }
  /// ```
  Future<List<Map<String, dynamic>>> getAllSolutions() async {
    final solutions = <Map<String, dynamic>>[];
    await for (final solution in getSolutions()) {
      solutions.add(solution);
    }
    return solutions;
  }
  
  /// Count the total number of solutions without storing them
  /// 
  /// This is memory-efficient for problems with many solutions.
  ///
  /// Example:
  /// ```dart
  /// final count = await p.countSolutions();
  /// print('This problem has $count solutions');
  /// ```
  Future<int> countSolutions() async {
    int count = 0;
    await for (final _ in getSolutions()) {
      count++;
    }
    return count;
  }
  
  /// Check if multiple solutions exist without finding them all
  /// 
  /// This stops after finding the second solution, making it efficient
  /// for determining if a problem has a unique solution.
  ///
  /// Example:
  /// ```dart
  /// final hasMultiple = await p.hasMultipleSolutions();
  /// if (hasMultiple) {
  ///   print('Problem has multiple solutions');
  /// } else {
  ///   print('Problem has at most one solution');
  /// }
  /// ```
  Future<bool> hasMultipleSolutions() async {
    int count = 0;
    await for (final _ in getSolutions()) {
      count++;
      if (count >= 2) return true;
    }
    return false;
  }

  
  
  /// Get the first N solutions
  /// 
  /// This stops the search after finding the specified number of solutions,
  /// making it more efficient than finding all solutions if you only need a few.
  /// This is useful when you want to see a few examples without processing all solutions.
  ///
  /// Example:
  /// ```dart
  /// final firstFive = await p.getFirstNSolutions(5);
  /// print('First 5 solutions:');
  /// for (final solution in firstFive) {
  ///   print(solution);
  /// }
  /// ```
  Future<List<Map<String, dynamic>>> getFirstNSolutions(int n) async {
    final solutions = <Map<String, dynamic>>[];
    if (n <= 0) return solutions; // Handle n=0 edge case
    await for (final solution in getSolutions()) {
      solutions.add(solution);
      if (solutions.length >= n) {
        break;
      }
    }
    return solutions;
  }

}