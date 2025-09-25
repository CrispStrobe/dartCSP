/// Debug tool to understand when and why heuristic choices actually differ
/// This will help us understand if degree tie-breaking is even being triggered

import '../lib/dart_csp.dart';

void main() async {
  print('DEBUGGING: When Do Heuristics Actually Differ?');
  print('=' * 50);
  
  await debugHeuristicChoices();
  await analyzeConstraintPropagationImpact();
}

/// Modified solver that tracks heuristic decisions
Future<void> debugHeuristicChoices() async {
  print('\n1. TRACKING HEURISTIC DECISIONS');
  print('-' * 35);
  
  // Create a simple problem where we can track what happens
  final variables = <String, List<dynamic>>{
    'A': [0, 1, 2],  // Will connect to everyone (degree 3) 
    'B': [0, 1, 2],  // Will connect to A only (degree 1)
    'C': [0, 1, 2],  // Will connect to A only (degree 1) 
    'D': [0, 1, 2],  // Will connect to A only (degree 1)
  };
  
  final constraints = <BinaryConstraint>[
    BinaryConstraint('A', 'B', (a, b) => a != b),
    BinaryConstraint('B', 'A', (a, b) => a != b),
    BinaryConstraint('A', 'C', (a, b) => a != b),
    BinaryConstraint('C', 'A', (a, b) => a != b),
    BinaryConstraint('A', 'D', (a, b) => a != b),
    BinaryConstraint('D', 'A', (a, b) => a != b),
  ];
  
  print('Problem setup:');
  print('- A connects to B, C, D (degree 3)');
  print('- B, C, D each connect only to A (degree 1 each)');
  print('- 3 colors available');
  print('- Expected: A should be chosen first by degree heuristic');
  print('');
  
  // Test with detailed analysis
  await testWithDomainTracking('MRV-only', variables, constraints, false);
  await testWithDomainTracking('MRV+Degree', variables, constraints, true);
}

Future<void> testWithDomainTracking(String heuristic, 
    Map<String, List<dynamic>> variables,
    List<BinaryConstraint> constraints,
    bool useDegree) async {
  
  print('Testing $heuristic:');
  
  // Calculate degrees for reference
  final degrees = <String, int>{};
  for (final variable in variables.keys) {
    degrees[variable] = constraints.where((c) => 
        c.head == variable || c.tail == variable).length;
  }
  print('Variable degrees: ${degrees.entries.map((e) => '${e.key}:${e.value}').join(', ')}');
  
  final problem = ConfigurableCspProblem(
    variables: cloneVariables(variables),
    constraints: constraints,
    heuristic: useDegree ? VariableSelectionHeuristic.mrvWithDegree : VariableSelectionHeuristic.mrvOnly,
  );
  
  final result = await ConfigurableCSP.solve(problem);
  final stats = ConfigurableCSP.stats;
  
  print('Result: ${stats.solved ? "SOLVED" : "FAILED"}');
  print('Steps: ${stats.steps}, Backtracks: ${stats.backtracks}');
  
  if (result != 'FAILURE') {
    final solution = result as Map<String, dynamic>;
    // Show assignment order by analyzing solution
    print('Final assignment: ${solution.entries.map((e) => '${e.key}=${e.value}').join(', ')}');
  }
  print('');
}

/// Test how constraint propagation affects domain sizes
Future<void> analyzeConstraintPropagationImpact() async {
  print('2. CONSTRAINT PROPAGATION ANALYSIS');
  print('-' * 35);
  
  // Create problem where we can see domain reduction step by step
  final originalVariables = <String, List<dynamic>>{
    'CENTER': [0, 1, 2],
    'P1': [0, 1, 2], 
    'P2': [0, 1, 2],
    'P3': [0, 1, 2],
    'P4': [0, 1, 2],
  };
  
  final constraints = <BinaryConstraint>[];
  for (int i = 1; i <= 4; i++) {
    constraints.add(BinaryConstraint('CENTER', 'P$i', (a, b) => a != b));
    constraints.add(BinaryConstraint('P$i', 'CENTER', (a, b) => a != b));
  }
  
  print('Before any assignments:');
  for (final entry in originalVariables.entries) {
    print('  ${entry.key}: domain size ${entry.value.length}');
  }
  print('');
  
  // Simulate what happens when we assign CENTER = 0
  print('After assigning CENTER = 0 (simulated):');
  print('  CENTER: domain size 1 [0]');
  print('  P1, P2, P3, P4: domain size 2 [1, 2] (0 eliminated by constraint)');
  print('');
  print('At this point:');
  print('- CENTER is assigned (not in unassigned variables)');
  print('- P1, P2, P3, P4 all have domain size 2');  
  print('- MRV tie between P1, P2, P3, P4!');
  print('- Degree heuristic should pick arbitrarily (all have same degree)');
  print('- But any choice works since no conflicts between peripherals');
  print('');
}

/// Test case specifically designed to create meaningful MRV ties
Future<void> testEngineredTies() async {
  print('3. ENGINEERED MRV TIES');
  print('-' * 25);
  
  // Problem: force a situation where domains reduce symmetrically
  final variables = <String, List<dynamic>>{
    'HUB1': [0, 1, 2, 3],  // High degree
    'HUB2': [0, 1, 2, 3],  // High degree  
    'LEAF1': [0, 1, 2, 3], // Low degree
    'LEAF2': [0, 1, 2, 3], // Low degree
    'LEAF3': [0, 1, 2, 3], // Low degree
    'LEAF4': [0, 1, 2, 3], // Low degree
  };
  
  final constraints = <BinaryConstraint>[];
  
  // HUB1 connects to LEAF1, LEAF2 (degree 2)
  addBidirectional(constraints, 'HUB1', 'LEAF1', (a, b) => a != b);
  addBidirectional(constraints, 'HUB1', 'LEAF2', (a, b) => a != b);
  
  // HUB2 connects to LEAF3, LEAF4 (degree 2)
  addBidirectional(constraints, 'HUB2', 'LEAF3', (a, b) => a != b);
  addBidirectional(constraints, 'HUB2', 'LEAF4', (a, b) => a != b);
  
  // Key: Connect HUB1 and HUB2 (creates interdependence)
  addBidirectional(constraints, 'HUB1', 'HUB2', (a, b) => a != b);
  
  // This should create a scenario where HUB1 and HUB2 have degree 3 each
  // and LEAF1,2,3,4 have degree 1 each
  
  print('Problem design:');
  print('- HUB1, HUB2: degree 3 each (should be preferred by degree heuristic)');
  print('- LEAF1, LEAF2, LEAF3, LEAF4: degree 1 each');
  print('- 4 colors, should be solvable but require some search');
  print('');
  
  await testWithDomainTracking('MRV-only', variables, constraints, false);
  await testWithDomainTracking('MRV+Degree', variables, constraints, true);
}

void addBidirectional(List<BinaryConstraint> constraints, String var1, String var2, 
    bool Function(dynamic, dynamic) predicate) {
  constraints.add(BinaryConstraint(var1, var2, predicate));
  constraints.add(BinaryConstraint(var2, var1, (a, b) => predicate(b, a)));
}

Map<String, List<dynamic>> cloneVariables(Map<String, List<dynamic>> variables) {
  final cloned = <String, List<dynamic>>{};
  variables.forEach((key, value) {
    cloned[key] = List.from(value);
  });
  return cloned;
}