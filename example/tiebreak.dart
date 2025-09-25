/// Better test cases that actually demonstrate degree tie-breaking benefits
/// These create scenarios where MRV ties occur and degree matters

import '../lib/dart_csp.dart';

void main() async {
  print('Testing improved scenarios for degree tie-breaking...');
  print('=' * 60);
  
  await testTighterConstraints();
  await testBottleneckScenario();
  await testMultiStarScenario();
}

/// Test 1: Tighter constraints that force more search
Future<void> testTighterConstraints() async {
  print('\n1. TIGHTER STAR GRAPH (forces more backtracking)');
  print('-' * 50);
  
  // Create a more constrained star: 8 peripherals, only 2 colors
  // This forces more careful assignment and backtracking
  final variables = <String, List<dynamic>>{};
  final constraints = <BinaryConstraint>[];
  
  final colors = [0, 1]; // Only 2 colors makes it much harder
  variables['CENTER'] = List.from(colors);
  
  // Add peripherals
  for (int i = 0; i < 8; i++) {
    variables['P$i'] = List.from(colors);
  }
  
  // Center != each peripheral
  for (int i = 0; i < 8; i++) {
    constraints.add(BinaryConstraint('CENTER', 'P$i', (a, b) => a != b));
    constraints.add(BinaryConstraint('P$i', 'CENTER', (a, b) => a != b));
  }
  
  // Add some peripheral-to-peripheral constraints to create conflicts
  constraints.add(BinaryConstraint('P0', 'P1', (a, b) => a != b));
  constraints.add(BinaryConstraint('P1', 'P0', (a, b) => a != b));
  constraints.add(BinaryConstraint('P2', 'P3', (a, b) => a != b));
  constraints.add(BinaryConstraint('P3', 'P2', (a, b) => a != b));
  
  await compareHeuristics('Tight Star (8 nodes, 2 colors)', variables, constraints);
}

/// Test 2: Bottleneck scenario with bridge nodes
Future<void> testBottleneckScenario() async {
  print('\n2. BOTTLENECK GRAPH (high-degree bridge nodes)');
  print('-' * 50);
  
  final variables = <String, List<dynamic>>{};
  final constraints = <BinaryConstraint>[];
  final colors = [0, 1, 2];
  
  // Two clusters connected by bridges
  for (int i = 0; i < 4; i++) {
    variables['A$i'] = List.from(colors);
    variables['B$i'] = List.from(colors);
  }
  
  // Bridge nodes (will have high degree)
  variables['BRIDGE1'] = List.from(colors);
  variables['BRIDGE2'] = List.from(colors);
  
  // Cluster A internal constraints
  for (int i = 0; i < 4; i++) {
    for (int j = i + 1; j < 4; j++) {
      addBidirectional(constraints, 'A$i', 'A$j', (a, b) => a != b);
    }
  }
  
  // Cluster B internal constraints  
  for (int i = 0; i < 4; i++) {
    for (int j = i + 1; j < 4; j++) {
      addBidirectional(constraints, 'B$i', 'B$j', (a, b) => a != b);
    }
  }
  
  // Bridge connections (creates high-degree nodes)
  for (int i = 0; i < 4; i++) {
    addBidirectional(constraints, 'BRIDGE1', 'A$i', (a, b) => a != b);
    addBidirectional(constraints, 'BRIDGE2', 'B$i', (a, b) => a != b);
  }
  addBidirectional(constraints, 'BRIDGE1', 'BRIDGE2', (a, b) => a != b);
  
  await compareHeuristics('Bottleneck Graph', variables, constraints);
}

/// Test 3: Multiple connected stars
Future<void> testMultiStarScenario() async {
  print('\n3. CONNECTED MULTI-STAR (multiple high-degree nodes)');
  print('-' * 50);
  
  final variables = <String, List<dynamic>>{};
  final constraints = <BinaryConstraint>[];
  final colors = [0, 1, 2];
  
  // Two star centers
  variables['CENTER1'] = List.from(colors);
  variables['CENTER2'] = List.from(colors);
  
  // Peripherals for star 1
  for (int i = 0; i < 5; i++) {
    variables['S1_P$i'] = List.from(colors);
    addBidirectional(constraints, 'CENTER1', 'S1_P$i', (a, b) => a != b);
  }
  
  // Peripherals for star 2
  for (int i = 0; i < 5; i++) {
    variables['S2_P$i'] = List.from(colors);
    addBidirectional(constraints, 'CENTER2', 'S2_P$i', (a, b) => a != b);
  }
  
  // Connect the centers (creates conflict)
  addBidirectional(constraints, 'CENTER1', 'CENTER2', (a, b) => a != b);
  
  // Connect some peripherals across stars (increases difficulty)
  addBidirectional(constraints, 'S1_P0', 'S2_P0', (a, b) => a != b);
  addBidirectional(constraints, 'S1_P1', 'S2_P1', (a, b) => a != b);
  
  await compareHeuristics('Connected Multi-Star', variables, constraints);
}

/// Test 4: Grid with bottlenecks
Future<void> testGridBottleneck() async {
  print('\n4. GRID WITH BOTTLENECK (center positions matter more)');
  print('-' * 50);
  
  final variables = <String, List<dynamic>>{};
  final constraints = <BinaryConstraint>[];
  final colors = [0, 1, 2]; // Tight coloring
  
  // Create 4x4 grid
  for (int r = 0; r < 4; r++) {
    for (int c = 0; c < 4; c++) {
      variables['R${r}C$c'] = List.from(colors);
    }
  }
  
  // Add grid constraints
  for (int r = 0; r < 4; r++) {
    for (int c = 0; c < 4; c++) {
      final current = 'R${r}C$c';
      
      // Right neighbor
      if (c + 1 < 4) {
        addBidirectional(constraints, current, 'R${r}C${c+1}', (a, b) => a != b);
      }
      
      // Bottom neighbor  
      if (r + 1 < 4) {
        addBidirectional(constraints, current, 'R${r+1}C$c', (a, b) => a != b);
      }
    }
  }
  
  await compareHeuristics('4x4 Grid', variables, constraints);
}

Future<void> compareHeuristics(String problemName, 
    Map<String, List<dynamic>> variables, 
    List<BinaryConstraint> constraints) async {
  
  print('Problem: $problemName');
  print('Variables: ${variables.length}, Constraints: ${constraints.length}');
  
  // Calculate degrees for analysis
  final degrees = <String, int>{};
  for (final variable in variables.keys) {
    degrees[variable] = constraints.where((c) => 
        c.head == variable || c.tail == variable).length;
  }
  
  final sortedDegrees = degrees.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  print('Top degrees: ${sortedDegrees.take(3).map((e) => '${e.key}:${e.value}').join(', ')}');
  
  // Test MRV-only
  final mrvProblem = ConfigurableCspProblem(
    variables: cloneVariables(variables),
    constraints: constraints,
    heuristic: VariableSelectionHeuristic.mrvOnly,
  );
  
  await ConfigurableCSP.solve(mrvProblem);
  final mrvStats = ConfigurableCSP.stats;
  
  // Test MRV+Degree
  final degreeProblem = ConfigurableCspProblem(
    variables: cloneVariables(variables),
    constraints: constraints,
    heuristic: VariableSelectionHeuristic.mrvWithDegree,
  );
  
  await ConfigurableCSP.solve(degreeProblem);
  final degreeStats = ConfigurableCSP.stats;
  
  // Compare results
  print('MRV-only:   ${mrvStats.solved ? "SOLVED" : "FAILED"} - ${mrvStats.steps} steps, ${mrvStats.backtracks} backtracks');
  print('MRV+Degree: ${degreeStats.solved ? "SOLVED" : "FAILED"} - ${degreeStats.steps} steps, ${degreeStats.backtracks} backtracks');
  
  if (mrvStats.solved && degreeStats.solved) {
    final stepImprovement = (mrvStats.steps - degreeStats.steps) / mrvStats.steps * 100;
    final backtrackImprovement = mrvStats.backtracks - degreeStats.backtracks;
    
    print('Step improvement: ${stepImprovement.toStringAsFixed(1)}%');
    print('Backtrack reduction: $backtrackImprovement');
    
    if (stepImprovement > 15) {
      print('Result: SIGNIFICANT IMPROVEMENT');
    } else if (stepImprovement > 5) {
      print('Result: MODERATE IMPROVEMENT');  
    } else {
      print('Result: MINIMAL IMPROVEMENT');
    }
  } else {
    print('Result: SOLVING FAILURE');
  }
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