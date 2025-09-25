/// Configurable CSP solver that can switch between different heuristics
/// This allows us to benchmark MRV-only vs MRV+Degree tie-breaking

import 'dart:async';
import 'dart:math';
import 'types.dart';

/// Heuristic options for variable selection
enum VariableSelectionHeuristic {
  mrvOnly,           // Original MRV heuristic
  mrvWithDegree,     // MRV with degree tie-breaking
}

/// Enhanced CSP problem that includes heuristic configuration
class ConfigurableCspProblem extends CspProblem {
  VariableSelectionHeuristic heuristic;
  
  ConfigurableCspProblem({
    required Map<String, List<dynamic>> variables,
    List<BinaryConstraint> constraints = const <BinaryConstraint>[],
    List<NaryConstraint> naryConstraints = const <NaryConstraint>[],
    int timeStep = 1,
    CspCallback? cb,
    this.heuristic = VariableSelectionHeuristic.mrvWithDegree,
  }) : super(
    variables: variables,
    constraints: constraints,
    naryConstraints: naryConstraints,
    timeStep: timeStep,
    cb: cb,
  );
}

/// Statistics tracking for benchmarking
class SolverStats {
  int steps = 0;
  int backtracks = 0;
  int constraintChecks = 0;
  Duration solvingTime = Duration.zero;
  bool solved = false;
  
  void reset() {
    steps = 0;
    backtracks = 0;
    constraintChecks = 0;
    solvingTime = Duration.zero;
    solved = false;
  }
  
  @override
  String toString() {
    return 'SolverStats(steps: $steps, backtracks: $backtracks, '
           'constraintChecks: $constraintChecks, time: ${solvingTime.inMilliseconds}ms, '
           'solved: $solved)';
  }
}

/// Enhanced CSP solver with configurable heuristics and statistics tracking
class ConfigurableCSP {
  static const String _failure = 'FAILURE';
  static final SolverStats _stats = SolverStats();
  
  /// Get the current solver statistics
  static SolverStats get stats => _stats;
  
  /// Solve with configurable heuristics and statistics tracking
  static Future<dynamic> solve(ConfigurableCspProblem csp) async {
    _stats.reset();
    final stopwatch = Stopwatch()..start();
    
    _validateProblem(csp);
    csp.naryIndex = _buildNaryIndex(csp.naryConstraints);
    
    final result = await _backtrack({}, _cloneVars(csp.variables), csp);
    
    stopwatch.stop();
    _stats.solvingTime = stopwatch.elapsed;
    _stats.solved = result != _failure;
    
    if (result == _failure) {
      return _failure;
    }
    
    if (result is Map<String, List<dynamic>>) {
      final unwrappedResult = <String, dynamic>{};
      result.forEach((key, value) {
        unwrappedResult[key] = (value.isNotEmpty) ? value[0] : null;
      });
      return unwrappedResult;
    }
    return result;
  }
  
  static Future<dynamic> _backtrack(
      Map<String, List<dynamic>> assigned,
      Map<String, List<dynamic>> unassigned,
      ConfigurableCspProblem csp) async {
    if (_finished(unassigned)) {
      return assigned;
    }
    
    // Use configurable variable selection heuristic
    final nextKey = _selectUnassignedVariable(unassigned, csp);
    if (nextKey == null) {
      return _failure;
    }
    
    final values = _orderValues(nextKey, assigned, unassigned, csp);
    final savedDomain = unassigned[nextKey];
    unassigned.remove(nextKey);
    
    for (final value in values) {
      _stats.steps++;
      final currentAssignment = _cloneVars(assigned);
      currentAssignment[nextKey] = [value];
      
      final consistentVars = _enforceConsistency(currentAssignment, unassigned, csp);
      
      if (consistentVars == _failure) {
        _stats.backtracks++;
        continue;
      }
      
      final consistentMap = consistentVars as Map<String, List<dynamic>>;
      
      final newAssigned = <String, List<dynamic>>{};
      final newUnassigned = <String, List<dynamic>>{};
      consistentMap.forEach((key, value) {
        if (currentAssignment.containsKey(key)) {
          newAssigned[key] = List<dynamic>.from(value);
        } else {
          newUnassigned[key] = List<dynamic>.from(value);
        }
      });
      
      if (_anyEmpty(consistentMap)) {
        _stats.backtracks++;
        continue;
      }
      
      final result = await _backtrack(newAssigned, newUnassigned, csp);
      
      if (result != _failure) {
        return result;
      }
      _stats.backtracks++;
    }
    
    if (savedDomain != null) {
      unassigned[nextKey] = savedDomain;
    }
    return _failure;
  }
  
  /// Variable selection with configurable heuristic
  static String? _selectUnassignedVariable(
      Map<String, List<dynamic>> unassigned, ConfigurableCspProblem csp) {
    if (unassigned.isEmpty) return null;
    
    switch (csp.heuristic) {
      case VariableSelectionHeuristic.mrvOnly:
        return _selectMrvOnly(unassigned);
      case VariableSelectionHeuristic.mrvWithDegree:
        return _selectMrvWithDegree(unassigned, csp);
    }
  }
  
  /// Original MRV-only heuristic
  static String? _selectMrvOnly(Map<String, List<dynamic>> unassigned) {
    String? minKey;
    int minLen = 1 << 30;
    for (final entry in unassigned.entries) {
      final len = entry.value.length;
      if (len < minLen) {
        minKey = entry.key;
        minLen = len;
        if (len == 1) break;
      }
    }
    return minKey;
  }
  
  /// MRV with degree tie-breaking heuristic
  static String? _selectMrvWithDegree(
      Map<String, List<dynamic>> unassigned, ConfigurableCspProblem csp) {
    if (unassigned.isEmpty) return null;
    
    // Find minimum domain size
    int minLen = 1 << 30;
    for (final entry in unassigned.entries) {
      final len = entry.value.length;
      if (len < minLen) {
        minLen = len;
        if (len == 1) return entry.key;
      }
    }
    
    // Find all variables with minimum domain size
    final candidates = <String>[];
    for (final entry in unassigned.entries) {
      if (entry.value.length == minLen) {
        candidates.add(entry.key);
      }
    }
    
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
  
  static int _calculateDegree(String variable, ConfigurableCspProblem csp) {
    int degree = 0;
    
    // Count binary constraints
    for (final constraint in csp.constraints) {
      if (constraint.head == variable || constraint.tail == variable) {
        degree++;
      }
    }
    
    // Count n-ary constraints
    if (csp.naryIndex != null && csp.naryIndex!.containsKey(variable)) {
      degree += csp.naryIndex![variable]!.length;
    }
    
    return degree;
  }
  
  static List<dynamic> _orderValues(
      String nextKey,
      Map<String, List<dynamic>> assigned,
      Map<String, List<dynamic>> unassigned,
      ConfigurableCspProblem csp) {
    final baseValues = List<dynamic>.from(unassigned[nextKey]!);
    if (baseValues.length <= 1) return baseValues;
    
    final scores = <dynamic, num>{};
    
    for (final val in baseValues) {
      final a = _cloneVars(assigned);
      final u = _cloneVars(unassigned);
      a[nextKey] = [val];
      u.remove(nextKey);
      
      final res = _enforceConsistency(a, u, csp);
      
      if (res == _failure || _anyEmpty(res as Map<String, List<dynamic>>)) {
        scores[val] = double.negativeInfinity;
      } else {
        scores[val] = res.values.fold<int>(0, (sum, d) => sum + d.length);
      }
    }
    
    baseValues.sort((a, b) => scores[b]!.compareTo(scores[a]!));
    return baseValues;
  }
  
  // Copy all the consistency and utility methods from the original solver
  static dynamic _enforceConsistency(Map<String, List<dynamic>> assigned,
      Map<String, List<dynamic>> unassigned, ConfigurableCspProblem csp) {
    final variables = _partialAssignment(assigned, unassigned);
    
    if (csp.constraints.isNotEmpty) {
      if (!_runAC3(variables, csp.constraints)) {
        return _failure;
      }
    }
    
    if (csp.naryConstraints.isNotEmpty) {
      if (!_runGAC(variables, csp)) {
        return _failure;
      }
    }
    
    return variables;
  }
  
  static Map<String, List<NaryConstraint>> _buildNaryIndex(
      List<NaryConstraint> naryConstraints) {
    final index = <String, List<NaryConstraint>>{};
    for (final c in naryConstraints) {
      for (final v in c.vars) {
        (index[v] ??= []).add(c);
      }
    }
    return index;
  }
  
  static bool _runAC3(Map<String, List<dynamic>> variables,
      List<BinaryConstraint> constraints) {
    List<BinaryConstraint> queue = List.from(constraints);
    
    while (queue.isNotEmpty) {
      _stats.constraintChecks++;
      final constraint = queue.removeAt(0);
      final head = constraint.head;
      final tail = constraint.tail;
      
      if (!variables.containsKey(head) || !variables.containsKey(tail))
        continue;
      
      bool removed = false;
      final headDomain = variables[head]!;
      final tailDomain = variables[tail]!;
      final newTailDomain = <dynamic>[];
      
      for (final tailVal in tailDomain) {
        final bool hasSupport =
            headDomain.any((headVal) => constraint.predicate(headVal, tailVal));
        
        if (hasSupport) {
          newTailDomain.add(tailVal);
        } else {
          removed = true;
        }
      }
      
      if (removed) {
        if (newTailDomain.isEmpty) return false;
        variables[tail] = newTailDomain;
        queue.addAll(constraints.where((c) => c.head == tail));
      }
    }
    return true;
  }
  
  static bool _runGAC(Map<String, List<dynamic>> variables, ConfigurableCspProblem csp) {
    final queue = List<NaryConstraint>.from(csp.naryConstraints);
    final index = csp.naryIndex!;
    
    while (queue.isNotEmpty) {
      _stats.constraintChecks++;
      final constraint = queue.removeAt(0);
      bool changedAny = false;
      
      for (final varName in constraint.vars) {
        final domain = variables[varName];
        if (domain == null) continue;
        
        final newDomain = domain
            .where((val) => _hasSupport(varName, val, constraint, variables))
            .toList();
        
        if (newDomain.length != domain.length) {
          if (newDomain.isEmpty) return false;
          variables[varName] = newDomain;
          changedAny = true;
        }
      }
      
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
    return true;
  }
  
  static bool _hasSupport(String focusVar, dynamic focusVal, NaryConstraint c,
      Map<String, List<dynamic>> variables) {
    final others = c.vars.where((v) => v != focusVar).toList();
    if (others.any((v) => !variables.containsKey(v) || variables[v]!.isEmpty)) {
      return false;
    }
    
    final order = [focusVar, ...others];
    final domains = [
      [focusVal],
      ...others.map((v) => variables[v]!)
    ];
    
    final assignment = <String, dynamic>{};
    
    bool dfs(int i) {
      if (i == order.length) {
        return c.predicate(assignment);
      }
      
      final varName = order[i];
      for (final val in domains[i]) {
        assignment[varName] = val;
        if (dfs(i + 1)) return true;
      }
      return false;
    }
    
    return dfs(0);
  }
  
  static Map<String, List<dynamic>> _cloneVars(
      Map<String, List<dynamic>> variables) {
    final out = <String, List<dynamic>>{};
    variables.forEach((k, v) => out[k] = List<dynamic>.from(v));
    return out;
  }
  
  static bool _finished(Map<String, List<dynamic>> unassigned) =>
      unassigned.isEmpty;
  
  static bool _anyEmpty(Map<String, List<dynamic>> vars) =>
      vars.values.any((v) => v.isEmpty);
  
  static Map<String, List<dynamic>> _partialAssignment(
          Map<String, List<dynamic>> assigned,
          Map<String, List<dynamic>> unassigned) =>
      {...unassigned, ...assigned};
  
  static void _validateProblem(ConfigurableCspProblem csp) {
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