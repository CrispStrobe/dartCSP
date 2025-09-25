// Core CSP solver with backtracking, AC-3, and GAC algorithms.

import 'dart:async';
import 'dart:math'; // for randomization
import 'types.dart';

/// A static class providing the method to solve Constraint Satisfaction Problems.
class CSP {
  /// A constant string representing failure to find a solution.
  static const String _failure = 'FAILURE';

  /// A counter for the number of steps taken in the search, used for the callback delay.
  static int _stepCounter = 0;

  /// Solves the given CSP using the Min-Conflicts local search algorithm.
  ///
  /// This algorithm is suitable for finding a single solution to large problems
  /// where systematic search like backtracking might be too slow. It is not
  /// guaranteed to find a solution if one exists (it can get stuck in local
  /// optima) and it cannot be used to find all solutions.
  ///
  /// - [csp]: The problem to solve.
  /// - [maxSteps]: The maximum number of iterations before giving up.
  ///
  /// Returns a [Future] that completes with:
  /// - A `Map<String, dynamic>` of variable assignments if a solution is found.
  /// - The string 'FAILURE' if no solution is found within [maxSteps].
  static Future<dynamic> solveWithMinConflicts(CspProblem csp,
      {int maxSteps = 1000}) async {
    final random = Random();

    // 1. Generate an initial complete, random assignment.
    final current = <String, dynamic>{};
    csp.variables.forEach((variable, domain) {
      current[variable] = domain[random.nextInt(domain.length)];
    });

    // Pre-build indexes for efficient conflict checking
    final binaryIndex = _buildBinaryIndex(csp.constraints);
    csp.naryIndex ??= _buildNaryIndex(csp.naryConstraints);

    // 2. Main search loop
    for (int i = 0; i < maxSteps; i++) {
      final conflictedVars =
          _getConflictedVariables(current, csp, binaryIndex, csp.naryIndex!);

      // If no variables are in conflict, we have found a solution.
      if (conflictedVars.isEmpty) {
        return current;
      }

      // 3. Randomly select a conflicted variable.
      final variable = conflictedVars[random.nextInt(conflictedVars.length)];

      // 4. Find the value for the selected variable that minimizes conflicts.
      dynamic minConflictValue;
      int minConflicts = 1 << 30; // Initialize with a large number

      // To break ties randomly, we collect all values with the same min score
      var bestValues = <dynamic>[];

      for (final value in csp.variables[variable]!) {
        final conflicts = _countConflictsForVar(
            variable, value, current, csp, binaryIndex, csp.naryIndex!);

        if (conflicts < minConflicts) {
          minConflicts = conflicts;
          minConflictValue = value;
          bestValues = [value];
        } else if (conflicts == minConflicts) {
          bestValues.add(value);
        }
      }

      // 5. Assign the new value to the variable, picking randomly from the best options.
      if (bestValues.isNotEmpty) {
        current[variable] = bestValues[random.nextInt(bestValues.length)];
      } else {
        current[variable] = minConflictValue;
      }
    }

    // If the loop finishes, no solution was found.
    return _failure;
  }

  /// Builds an index mapping variables to their binary constraints for quick lookup.
  static Map<String, List<BinaryConstraint>> _buildBinaryIndex(
      List<BinaryConstraint> constraints) {
    final index = <String, List<BinaryConstraint>>{};
    for (final c in constraints) {
      (index[c.head] ??= []).add(c);
      (index[c.tail] ??= []).add(c);
    }
    return index;
  }

  /// Gets a list of all variables currently involved in a violated constraint.
  static List<String> _getConflictedVariables(
      Map<String, dynamic> assignment,
      CspProblem csp,
      Map<String, List<BinaryConstraint>> binaryIndex,
      Map<String, List<NaryConstraint>> naryIndex) {
    final conflicted = <String>{};

    // Check all constraints
    for (final c in csp.constraints) {
      if (!c.predicate(assignment[c.head], assignment[c.tail])) {
        conflicted.add(c.head);
        conflicted.add(c.tail);
      }
    }

    for (final c in csp.naryConstraints) {
      final subAssignment = <String, dynamic>{};
      for (final v in c.vars) {
        subAssignment[v] = assignment[v];
      }
      if (!c.predicate(subAssignment)) {
        conflicted.addAll(c.vars);
      }
    }
    return conflicted.toList();
  }

  /// Counts the number of conflicts a specific variable/value pair would cause.
  static int _countConflictsForVar(
      String variable,
      dynamic value,
      Map<String, dynamic> assignment,
      CspProblem csp,
      Map<String, List<BinaryConstraint>> binaryIndex,
      Map<String, List<NaryConstraint>> naryIndex) {
    int conflicts = 0;
    final tempAssignment = Map<String, dynamic>.from(assignment);
    tempAssignment[variable] = value;

    // Check relevant binary constraints
    final relevantBinary =
        (binaryIndex[variable] ?? []).toSet(); // Use Set to avoid duplicates
    for (final c in relevantBinary) {
      if (!c.predicate(tempAssignment[c.head], tempAssignment[c.tail])) {
        conflicts++;
      }
    }

    // Check relevant n-ary constraints
    final relevantNary =
        (naryIndex[variable] ?? []).toSet(); // Use Set to avoid duplicates
    for (final c in relevantNary) {
      final subAssignment = <String, dynamic>{};
      for (final v in c.vars) {
        subAssignment[v] = tempAssignment[v];
      }
      if (!c.predicate(subAssignment)) {
        conflicts++;
      }
    }

    return conflicts;
  }

  /// Solves the given Constraint Satisfaction Problem.
  ///
  /// This is the main public entry point to the solver. It initializes the search,
  /// runs the backtracking algorithm, and formats the result.
  ///
  /// Returns a [Future] that completes with:
  /// - A `Map<String, dynamic>` of variable assignments if a solution is found.
  /// - The string 'FAILURE' if no solution exists.
  static Future<dynamic> solve(CspProblem csp) async {
    _stepCounter = 0;
    _validateProblem(csp);

    // Pre-computation: Build an index that maps each variable to its n-ary
    // constraints. This is a critical optimization for the GAC algorithm, as it
    // avoids searching through all constraints repeatedly.
    csp.naryIndex = _buildNaryIndex(csp.naryConstraints);

    // Start the recursive backtracking search with an empty assignment.
    final result = await _backtrack({}, _cloneVars(csp.variables), csp);

    if (result == _failure) {
      return _failure;
    }

    // On success, the result is a map of variables to their single-value domains
    // (e.g., {'A': [5]}). This step unwraps the lists to return a cleaner result
    // (e.g., {'A': 5}).
    if (result is Map<String, List<dynamic>>) {
      final unwrappedResult = <String, dynamic>{};
      result.forEach((key, value) {
        unwrappedResult[key] = (value.isNotEmpty) ? value[0] : null;
      });
      return unwrappedResult;
    }
    return result;
  }

  /// Solves the given CSP and returns a stream of all solutions.
  ///
  /// This method finds all possible solutions to the constraint satisfaction problem
  /// and yields them as a stream. This is useful for problems where you need to
  /// explore multiple solutions or find the optimal one among all possibilities.
  ///
  /// Returns a [Stream] that emits each solution as a `Map<String, dynamic>`.
  /// If no solutions exist, the stream will be empty.
  static Stream<Map<String, dynamic>> solveAll(CspProblem csp) async* {
    _stepCounter = 0;
    _validateProblem(csp);
    csp.naryIndex = _buildNaryIndex(csp.naryConstraints);

    // Start the recursive backtracking search with an empty assignment.
    final solutionStream = _backtrackAll({}, _cloneVars(csp.variables), csp);

    // Yield each solution from the stream after unwrapping the domain lists.
    await for (final solution in solutionStream) {
      final unwrappedResult = <String, dynamic>{};
      solution.forEach((key, value) {
        unwrappedResult[key] = (value.isNotEmpty) ? value[0] : null;
      });
      yield unwrappedResult;
    }
  }

  /// The core recursive backtracking algorithm.
  ///
  /// Backtracking is a depth-first search (DFS) through the space of possible
  /// variable assignments. At each level, it assigns a value to a variable and
  /// then uses consistency enforcement (forward checking) to prune the domains
  /// of neighboring variables. If a domain becomes empty, it backtracks.
  static Future<dynamic> _backtrack(Map<String, List<dynamic>> assigned,
      Map<String, List<dynamic>> unassigned, CspProblem csp) async {
    // Base case: If there are no unassigned variables, a complete and valid
    // solution has been found.
    if (_finished(unassigned)) {
      return assigned;
    }

    // Enhanced Heuristic: Select which variable to assign next using MRV + Degree tie-breaking.
    final nextKey = _selectUnassignedVariable(unassigned, csp);
    if (nextKey == null) {
      // Should not happen if _finished is false, but acts as a safeguard.
      return _failure;
    }

    // Heuristic 2: Order the values of the chosen variable.
    // The Least Constraining Value (LCV) heuristic is used to decide the order
    // in which to try values. It prefers values that leave the most options
    // for other variables, increasing the chance of finding a solution without
    // backtracking.
    final values = _orderValues(nextKey, assigned, unassigned, csp);

    final savedDomain = unassigned[nextKey];
    unassigned.remove(nextKey);

    // Iterate through the chosen values for the selected variable.
    for (final value in values) {
      _stepCounter++;
      final currentAssignment = _cloneVars(assigned);
      currentAssignment[nextKey] = [value];

      // This is the "forward checking" or "look-ahead" step. After making a
      // tentative assignment, enforce consistency to see its impact on other
      // variables' domains.
      final consistentVars =
          _enforceConsistency(currentAssignment, unassigned, csp);

      // If consistency enforcement leads to a contradiction (e.g., an empty
      // domain for some variable), this path is invalid. Skip to the next value.
      if (consistentVars == _failure) {
        continue;
      }

      final consistentMap = consistentVars as Map<String, List<dynamic>>;

      // Prepare the state for the recursive call.
      final newAssigned = <String, List<dynamic>>{};
      final newUnassigned = <String, List<dynamic>>{};
      consistentMap.forEach((key, value) {
        if (currentAssignment.containsKey(key)) {
          newAssigned[key] = List<dynamic>.from(value);
        } else {
          newUnassigned[key] = List<dynamic>.from(value);
        }
      });

      // Optional callback for visualizing the search step.
      if (csp.cb != null) {
        await Future.delayed(
            Duration(milliseconds: _stepCounter * csp.timeStep),
            () => csp.cb!(newAssigned, newUnassigned));
      }

      // If any domain has become empty as a result of our assignment, this
      // path is invalid. Prune this branch and try the next value.
      if (_anyEmpty(consistentMap)) {
        continue;
      }

      // Recurse: Move to the next level of the search tree.
      final result = await _backtrack(newAssigned, newUnassigned, csp);

      // If the recursive call found a solution, propagate it up.
      if (result != _failure) {
        return result;
      }
    }

    // If all values for the current variable have been tried and none led to a
    // solution, backtrack by restoring the state and returning failure.
    if (savedDomain != null) {
      unassigned[nextKey] = savedDomain;
    }
    return _failure;
  }

  /// The core recursive backtracking algorithm modified to be a generator.
  ///
  /// This version doesn't stop after the first solution. Instead, it yields each
  /// solution it finds and continues searching the rest of the tree. This allows
  /// finding all possible solutions to a constraint satisfaction problem.
  ///
  /// The algorithm follows the same structure as the single-solution version but
  /// uses `yield` to emit solutions and `yield*` to pass through all solutions
  /// from recursive calls.
  static Stream<Map<String, List<dynamic>>> _backtrackAll(
      Map<String, List<dynamic>> assigned,
      Map<String, List<dynamic>> unassigned,
      CspProblem csp) async* {
    // Base case: If there are no unassigned variables, a complete and valid
    // solution has been found.
    if (_finished(unassigned)) {
      yield assigned; // Yield the solution instead of returning it
      return; // Stop this path, but allow the caller to continue
    }

    // Enhanced Heuristic: Select which variable to assign next using MRV + Degree tie-breaking.
    final nextKey = _selectUnassignedVariable(unassigned, csp);
    if (nextKey == null) {
      // Should not happen if _finished is false, but acts as a safeguard.
      return;
    }

    // Heuristic 2: Order the values of the chosen variable.
    final values = _orderValues(nextKey, assigned, unassigned, csp);

    final savedDomain = unassigned[nextKey];
    unassigned.remove(nextKey);

    // Iterate through the chosen values for the selected variable.
    for (final value in values) {
      _stepCounter++;
      final currentAssignment = _cloneVars(assigned);
      currentAssignment[nextKey] = [value];

      // Forward checking: enforce consistency to see the impact on other variables.
      final consistentVars =
          _enforceConsistency(currentAssignment, unassigned, csp);

      // If consistency enforcement leads to a contradiction, skip to the next value.
      if (consistentVars == _failure) {
        continue;
      }

      final consistentMap = consistentVars as Map<String, List<dynamic>>;

      // Prepare the state for the recursive call.
      final newAssigned = <String, List<dynamic>>{};
      final newUnassigned = <String, List<dynamic>>{};
      consistentMap.forEach((key, value) {
        if (currentAssignment.containsKey(key)) {
          newAssigned[key] = List<dynamic>.from(value);
        } else {
          newUnassigned[key] = List<dynamic>.from(value);
        }
      });

      // Optional callback for visualizing the search step (less common for all-solutions)
      if (csp.cb != null) {
        await Future.delayed(
            Duration(milliseconds: _stepCounter * csp.timeStep),
            () => csp.cb!(newAssigned, newUnassigned));
      }

      // If any domain has become empty, this path is invalid.
      if (_anyEmpty(consistentMap)) {
        continue;
      }

      // Recurse and yield all solutions found down this path.
      // The 'yield*' keyword is used to yield all items from the sub-stream.
      yield* _backtrackAll(newAssigned, newUnassigned, csp);
    }

    // Restore state for backtracking
    if (savedDomain != null) {
      unassigned[nextKey] = savedDomain;
    }
  }

  // ---------------- Consistency Algorithms ----------------

  /// Enforces consistency on the variable domains after a tentative assignment.
  ///
  /// This function acts as a dispatcher, running AC-3 for binary constraints
  /// and GAC for n-ary constraints.
  static dynamic _enforceConsistency(Map<String, List<dynamic>> assigned,
      Map<String, List<dynamic>> unassigned, CspProblem csp) {
    // Combine assigned and unassigned variables into a single view for consistency checks.
    final variables = _partialAssignment(assigned, unassigned);

    // Run AC-3 for binary constraints. If it returns false, a contradiction was
    // found, and this assignment path is invalid.
    if (csp.constraints.isNotEmpty) {
      if (!_runAC3(variables, csp.constraints)) {
        return _failure;
      }
    }

    // Run GAC for n-ary constraints. If it returns false, a contradiction was
    // found.
    if (csp.naryConstraints.isNotEmpty) {
      if (!_runGAC(variables, csp)) {
        return _failure;
      }
    }

    return variables;
  }

  /// Builds an index mapping variables to their n-ary constraints.
  ///
  /// This is a pre-computation step to optimize GAC. Instead of searching all
  /// n-ary constraints every time a domain changes, we can quickly look up
  /// only the relevant constraints that involve the changed variable.
  static Map<String, List<NaryConstraint>> _buildNaryIndex(
      List<NaryConstraint> naryConstraints) {
    final index = <String, List<NaryConstraint>>{};
    for (final c in naryConstraints) {
      for (final v in c.vars) {
        // For each variable `v` in a constraint `c`, add `c` to `v`'s list in the index.
        (index[v] ??= []).add(c);
      }
    }
    return index;
  }

  /// Implements the AC-3 algorithm to enforce arc consistency for binary constraints.
  ///
  /// An arc (A, B) is consistent if for every value `x` in A's domain, there is
  /// some allowed value `y` in B's domain. AC-3 works by iterating through all
  /// arcs, removing values that do not have "support" in the neighboring variable.
  /// If a domain changes, it re-adds all arcs pointing to that variable to the
  /// queue to propagate the change.
  static bool _runAC3(Map<String, List<dynamic>> variables,
      List<BinaryConstraint> constraints) {
    // Initialize the queue with all arcs (constraints) in the problem.
    List<BinaryConstraint> queue = List.from(constraints);

    while (queue.isNotEmpty) {
      final constraint = queue.removeAt(0);
      final head = constraint.head;
      final tail = constraint.tail;

      if (!variables.containsKey(head) || !variables.containsKey(tail))
        continue;

      bool removed = false;
      final headDomain = variables[head]!;
      final tailDomain = variables[tail]!;
      final newTailDomain = <dynamic>[];

      // For each value in the tail's domain, check if it has support in the head's domain.
      for (final tailVal in tailDomain) {
        // A value `tailVal` has support if there's at least one value `headVal`
        // in the head's domain such that the predicate(headVal, tailVal) is true.
        final bool hasSupport =
            headDomain.any((headVal) => constraint.predicate(headVal, tailVal));

        if (hasSupport) {
          newTailDomain.add(tailVal);
        } else {
          removed = true;
        }
      }

      // If any values were removed from the tail's domain...
      if (removed) {
        // If the domain becomes empty, we have a contradiction.
        if (newTailDomain.isEmpty) return false;

        // Update the domain.
        variables[tail] = newTailDomain;

        // Propagate the change: re-add all arcs that point to the modified
        // variable `tail` to the queue, so their consistency can be re-checked.
        queue.addAll(constraints.where((c) => c.head == tail));
      }
    }
    return true; // All arcs are consistent.
  }

  /// Implements Generalized Arc Consistency (GAC) for n-ary constraints.
  ///
  /// GAC is an extension of arc consistency for constraints involving more than
  /// two variables. A variable is GAC-consistent with respect to a constraint
  /// if for every value in its domain, there exists a valid assignment for all
  /// other variables in the constraint.
  static bool _runGAC(Map<String, List<dynamic>> variables, CspProblem csp) {
    // Initialize the queue with all n-ary constraints.
    final queue = List<NaryConstraint>.from(csp.naryConstraints);
    final index = csp.naryIndex!; // Use the pre-built index for efficiency.

    while (queue.isNotEmpty) {
      final constraint = queue.removeAt(0);
      bool changedAny = false;

      // For each variable in the current constraint...
      for (final varName in constraint.vars) {
        final domain = variables[varName];
        if (domain == null) continue;

        // Filter its domain, keeping only values that have "support".
        final newDomain = domain
            .where((val) => _hasSupport(varName, val, constraint, variables))
            .toList();

        if (newDomain.length != domain.length) {
          // If the domain is now empty, we have a contradiction.
          if (newDomain.isEmpty) return false;

          variables[varName] = newDomain;
          changedAny = true;
        }
      }

      // If any domain was reduced, we must re-check all other constraints
      // involving the variables from the current constraint.
      if (changedAny) {
        for (final v2 in constraint.vars) {
          final related = index[v2] ?? [];
          for (final rc in related) {
            if (!queue.contains(rc)) {
              queue.add(rc);
            }
          }
        }
      }
    }
    return true; // All constraints are GAC-consistent.
  }

  /// Checks if a value has "support" within an n-ary constraint.
  ///
  /// A value `focusVal` for `focusVar` has support if there exists at least one
  /// combination of values for the other variables in the constraint `C` that
  /// satisfies `C.predicate`. This is itself a mini-CSP, solved here with a
  /// simple recursive DFS.
  static bool _hasSupport(String focusVar, dynamic focusVal, NaryConstraint c,
      Map<String, List<dynamic>> variables) {
    // Gather the other variables involved in the constraint.
    final others = c.vars.where((v) => v != focusVar).toList();
    if (others.any((v) => !variables.containsKey(v) || variables[v]!.isEmpty)) {
      // If any other variable has no domain, support is impossible.
      return false;
    }

    final order = [focusVar, ...others];
    final domains = [
      [focusVal], // The domain for our focus variable is just the single value.
      ...others.map((v) => variables[v]!)
    ];

    final assignment = <String, dynamic>{};

    // Use a simple DFS to search for one satisfying assignment.
    bool dfs(int i) {
      // Base case: a full assignment for the constraint has been built.
      if (i == order.length) {
        // Check if this assignment satisfies the predicate.
        return c.predicate(assignment);
      }

      final varName = order[i];
      // Iterate through the values of the current variable.
      for (final val in domains[i]) {
        assignment[varName] = val;
        // Recurse to the next variable.
        if (dfs(i + 1)) return true; // Found support, so exit early.
      }
      return false; // No value at this level led to a solution.
    }

    return dfs(0);
  }

  // ---------------- Enhanced Heuristics ----------------

  /// Selects the next unassigned variable using MRV with degree tie-breaking.
  ///
  /// MRV (Minimum Remaining Values) chooses the variable with the fewest
  /// remaining legal values in its domain. When there are ties, degree
  /// tie-breaking is used to select the variable with the highest degree
  /// (most constraints).
  ///
  /// This is a "fail-first" strategy combined with "most-constraining-first":
  /// - MRV: if a mistake is to be made, make it on a highly constrained variable
  ///   where the mistake will be discovered sooner, pruning the search tree.
  /// - Degree: among equally constrained variables, choose the one that constrains
  ///   the most other variables, as it's more likely to help narrow the search space.
  static String? _selectUnassignedVariable(
      Map<String, List<dynamic>> unassigned, CspProblem csp) {
    if (unassigned.isEmpty) return null;

    // Find minimum domain size
    int minLen = 1 << 30; // A large number, equivalent to infinity.
    for (final entry in unassigned.entries) {
      final len = entry.value.length;
      if (len < minLen) {
        minLen = len;
        // Optimization: if a domain has only one value, it's the most
        // constrained possible, so we can select it immediately.
        if (len == 1) return entry.key;
      }
    }

    // Find all variables with minimum domain size (MRV candidates)
    final candidates = <String>[];
    for (final entry in unassigned.entries) {
      if (entry.value.length == minLen) {
        candidates.add(entry.key);
      }
    }

    // If only one candidate, return it
    if (candidates.length == 1) return candidates.first;

    // Tie-breaking: select variable with highest degree
    String? maxDegreeVar;
    int maxDegree = -1;

    for (final variable in candidates) {
      final degree = _calculateDegree(variable, csp);
      if (degree > maxDegree) {
        maxDegree = degree;
        maxDegreeVar = variable;
      }
    }

    return maxDegreeVar ?? candidates.first;
  }

  /// Calculates the degree of a variable (number of constraints it participates in).
  ///
  /// The degree includes both binary and n-ary constraints. For binary constraints,
  /// each constraint relationship is counted once per variable involved.
  static int _calculateDegree(String variable, CspProblem csp) {
    int degree = 0;

    // Count binary constraints
    for (final constraint in csp.constraints) {
      if (constraint.head == variable || constraint.tail == variable) {
        degree++;
      }
    }

    // Count n-ary constraints using the pre-built index for efficiency
    if (csp.naryIndex != null && csp.naryIndex!.containsKey(variable)) {
      degree += csp.naryIndex![variable]!.length;
    }

    return degree;
  }

  /// Orders the values of a variable's domain using the LCV heuristic.
  ///
  /// LCV (Least Constraining Value) prefers the value that prunes the fewest
  /// values from the domains of neighboring variables. This is a "succeed-first"
  /// strategy: it tries to keep the search space as open as possible, increasing
  /// the chances of finding a solution on the current path.
  static List<dynamic> _orderValues(
      String nextKey,
      Map<String, List<dynamic>> assigned,
      Map<String, List<dynamic>> unassigned,
      CspProblem csp) {
    final baseValues = List<dynamic>.from(unassigned[nextKey]!);
    if (baseValues.length <= 1) return baseValues;

    final scores = <dynamic, num>{};

    // For each potential value, calculate a "score".
    for (final val in baseValues) {
      // Create temporary copies to test the effect of assigning the value.
      final a = _cloneVars(assigned);
      final u = _cloneVars(unassigned);
      a[nextKey] = [val];
      u.remove(nextKey);

      // Tentatively enforce consistency.
      final res = _enforceConsistency(a, u, csp);

      // A higher score is better. The score is the total number of remaining
      // values across all other variables' domains.
      if (res == _failure || _anyEmpty(res as Map<String, List<dynamic>>)) {
        scores[val] = double.negativeInfinity; // This value leads to failure.
      } else {
        scores[val] = res // scores[val] = (res as Map<String, List<dynamic>>)
            .values
            .fold<int>(0, (sum, d) => sum + d.length);
      }
    }

    // Sort the values in descending order of their scores.
    baseValues.sort((a, b) => scores[b]!.compareTo(scores[a]!));
    return baseValues;
  }

  // ------------------- Utility Methods -------------------

  /// Creates a deep copy of the variable domains map.
  static Map<String, List<dynamic>> _cloneVars(
      Map<String, List<dynamic>> variables) {
    final out = <String, List<dynamic>>{};
    variables.forEach((k, v) => out[k] = List<dynamic>.from(v));
    return out;
  }

  /// Checks if all variables have been assigned.
  static bool _finished(Map<String, List<dynamic>> unassigned) =>
      unassigned.isEmpty;

  /// Checks if any variable has an empty domain.
  static bool _anyEmpty(Map<String, List<dynamic>> vars) =>
      vars.values.any((v) => v.isEmpty);

  /// Combines assigned and unassigned variables into a single map.
  static Map<String, List<dynamic>> _partialAssignment(
          Map<String, List<dynamic>> assigned,
          Map<String, List<dynamic>> unassigned) =>
      {...unassigned, ...assigned};

  /// Validates the structure and integrity of the provided CspProblem.
  static void _validateProblem(CspProblem csp) {
    final varsSet = csp.variables.keys.toSet();

    for (final c in csp.constraints) {
      if (!varsSet.contains(c.head)) {
        throw ArgumentError(
            'Binary constraint references unknown variable "${c.head}"');
      }
      if (!varsSet.contains(c.tail)) {
        throw ArgumentError(
            'Binary constraint references unknown variable "${c.tail}"');
      }
    }

    for (final c in csp.naryConstraints) {
      if (c.vars.isEmpty) {
        throw ArgumentError('N-ary constraint missing vars list');
      }
      for (final v in c.vars) {
        if (!varsSet.contains(v)) {
          throw ArgumentError(
              'N-ary constraint references unknown variable "$v"');
        }
      }
    }
  }
}