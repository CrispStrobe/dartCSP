/// Complete test runner for CSP heuristic comparison
/// Usage: dart run test_runner.dart [option]
/// Options: simple, full, custom, explain

import 'dart:io';
import 'package:dart_csp/dart_csp.dart';

/// Test runner with various demonstration modes
class CSPTestRunner {
  
  /// Quick demonstration of the concept
  static Future<void> simpleDemo() async {
    print('=== SIMPLE DEMONSTRATION ===\n');
    print('Testing star graph: 1 central node + 8 peripheral nodes, 3 colors\n');
    
    // Create star graph
    final variables = <String, List<dynamic>>{
      'CENTER': [0, 1, 2],
      'P1': [0, 1, 2], 'P2': [0, 1, 2], 'P3': [0, 1, 2], 'P4': [0, 1, 2],
      'P5': [0, 1, 2], 'P6': [0, 1, 2], 'P7': [0, 1, 2], 'P8': [0, 1, 2],
    };
    
    final constraints = <BinaryConstraint>[];
    for (int i = 1; i <= 8; i++) {
      constraints.add(BinaryConstraint('CENTER', 'P$i', (a, b) => a != b));
      constraints.add(BinaryConstraint('P$i', 'CENTER', (a, b) => a != b));
    }
    
    print('Problem structure:');
    print('• CENTER has degree 8 (connected to all peripherals)');
    print('• P1-P8 each have degree 1 (connected only to CENTER)');
    print('• When domains shrink equally, which variable should we pick?\n');
    
    // Test MRV-only
    print('Testing MRV-only heuristic...');
    final mrvProblem = ConfigurableCspProblem(
      variables: _cloneVariables(variables),
      constraints: constraints,
      heuristic: VariableSelectionHeuristic.mrvOnly,
    );
    
    await ConfigurableCSP.solve(mrvProblem);
    final mrvStats = ConfigurableCSP.stats;
    print('Result: ${mrvStats.solved ? "SOLVED" : "FAILED"} in ${mrvStats.steps} steps, ${mrvStats.backtracks} backtracks\n');
    
    // Test MRV+Degree
    print('Testing MRV+Degree heuristic...');
    final degreeProblem = ConfigurableCspProblem(
      variables: _cloneVariables(variables),
      constraints: constraints,
      heuristic: VariableSelectionHeuristic.mrvWithDegree,
    );
    
    await ConfigurableCSP.solve(degreeProblem);
    final degreeStats = ConfigurableCSP.stats;
    print('Result: ${degreeStats.solved ? "SOLVED" : "FAILED"} in ${degreeStats.steps} steps, ${degreeStats.backtracks} backtracks\n');
    
    // Analysis
    if (mrvStats.solved && degreeStats.solved) {
      final improvement = (mrvStats.steps - degreeStats.steps) / mrvStats.steps * 100;
      print('ANALYSIS:');
      print('• Step reduction: ${mrvStats.steps - degreeStats.steps} steps (${improvement.toStringAsFixed(1)}% improvement)');
      print('• Backtrack reduction: ${mrvStats.backtracks - degreeStats.backtracks}');
      
      if (improvement > 15) {
        print('• Result: SIGNIFICANT IMPROVEMENT - Degree tie-breaking helps substantially!\n');
      } else if (improvement > 5) {
        print('• Result: MODERATE IMPROVEMENT - Degree tie-breaking provides benefits\n');
      } else {
        print('• Result: MINIMAL IMPROVEMENT - Problem may be too simple\n');
      }
      
      print('WHY IT HELPS:');
      print('• MRV ties are broken by choosing the most connected variable (CENTER)');
      print('• Assigning CENTER first immediately constrains all 8 peripherals');
      print('• This leads to faster constraint propagation and fewer search branches');
    }
  }
  
  /// Comprehensive benchmark suite
  static Future<void> fullBenchmark() async {
    print('=== COMPREHENSIVE BENCHMARK SUITE ===\n');
    print('Testing multiple problem types where degree tie-breaking should help...\n');
    
    final results = <String, Map<String, int>>{};
    
    // Test 1: Star graphs of different sizes
    print('1. STAR GRAPH PROBLEMS');
    print('-' * 40);
    for (final size in [6, 8, 10, 12]) {
      final name = 'Star-$size-nodes';
      print('Testing $name...');
      
      final result = await _testStarGraph(size, 3);
      results[name] = result;
      
      final improvement = result['mrvSteps']! > 0 ? 
          (result['mrvSteps']! - result['degreeSteps']!) / result['mrvSteps']! * 100 : 0;
      print('  MRV: ${result['mrvSteps']} steps, MRV+Degree: ${result['degreeSteps']} steps (${improvement.toStringAsFixed(1)}% improvement)');
    }
    print();
    
    // Test 2: Bottleneck graphs
    print('2. BOTTLENECK GRAPH PROBLEMS');
    print('-' * 40);
    for (final size in [3, 4, 5]) {
      final name = 'Bottleneck-${size}x$size';
      print('Testing $name...');
      
      final result = await _testBottleneckGraph(size, 3);
      results[name] = result;
      
      final improvement = result['mrvSteps']! > 0 ? 
          (result['mrvSteps']! - result['degreeSteps']!) / result['mrvSteps']! * 100 : 0;
      print('  MRV: ${result['mrvSteps']} steps, MRV+Degree: ${result['degreeSteps']} steps (${improvement.toStringAsFixed(1)}% improvement)');
    }
    print();
    
    // Test 3: Grid coloring
    print('3. GRID COLORING PROBLEMS');
    print('-' * 40);
    for (final size in [3, 4, 5]) {
      final name = 'Grid-${size}x$size';
      print('Testing $name...');
      
      final result = await _testGridColoring(size, 3);
      results[name] = result;
      
      final improvement = result['mrvSteps']! > 0 ? 
          (result['mrvSteps']! - result['degreeSteps']!) / result['mrvSteps']! * 100 : 0;
      print('  MRV: ${result['mrvSteps']} steps, MRV+Degree: ${result['degreeSteps']} steps (${improvement.toStringAsFixed(1)}% improvement)');
    }
    print();
    
    // Summary
    print('SUMMARY ANALYSIS');
    print('=' * 50);
    
    var totalMrvSteps = 0;
    var totalDegreeSteps = 0;
    var significantImprovements = 0;
    
    for (final entry in results.entries) {
      totalMrvSteps += entry.value['mrvSteps']!;
      totalDegreeSteps += entry.value['degreeSteps']!;
      
      final improvement = entry.value['mrvSteps']! > 0 ? 
          (entry.value['mrvSteps']! - entry.value['degreeSteps']!) / entry.value['mrvSteps']! * 100 : 0;
      
      if (improvement > 20) significantImprovements++;
    }
    
    final overallImprovement = (totalMrvSteps - totalDegreeSteps) / totalMrvSteps * 100;
    
    print('Overall Results:');
    print('• Total MRV steps: $totalMrvSteps');
    print('• Total MRV+Degree steps: $totalDegreeSteps');
    print('• Overall improvement: ${overallImprovement.toStringAsFixed(1)}%');
    print('• Problems with >20% improvement: $significantImprovements/${results.length}');
    print();
    
    print('Best improvements:');
    final sortedResults = results.entries.toList()
      ..sort((a, b) {
        final improvementA = a.value['mrvSteps']! > 0 ? 
            (a.value['mrvSteps']! - a.value['degreeSteps']!) / a.value['mrvSteps']! * 100 : 0;
        final improvementB = b.value['mrvSteps']! > 0 ? 
            (b.value['mrvSteps']! - b.value['degreeSteps']!) / b.value['mrvSteps']! * 100 : 0;
        return improvementB.compareTo(improvementA);
      });
    
    for (final entry in sortedResults.take(3)) {
      final improvement = entry.value['mrvSteps']! > 0 ? 
          (entry.value['mrvSteps']! - entry.value['degreeSteps']!) / entry.value['mrvSteps']! * 100 : 0;
      print('  ${entry.key}: ${improvement.toStringAsFixed(1)}% improvement');
    }
  }
  
  /// Interactive custom problem testing
  static Future<void> customTesting() async {
    print('=== CUSTOM PROBLEM TESTING ===\n');
    print('Choose a problem type to test:');
    print('1. Star graph (specify size and colors)');
    print('2. Grid coloring (specify dimensions and colors)');
    print('3. N-Queens (specify board size)');
    print('4. Custom constraint problem');
    
    stdout.write('\nEnter choice (1-4): ');
    final choice = stdin.readLineSync() ?? '1';
    
    switch (choice) {
      case '1':
        stdout.write('Number of peripheral nodes (6-20): ');
        final size = int.tryParse(stdin.readLineSync() ?? '8') ?? 8;
        stdout.write('Number of colors (3-5): ');
        final colors = int.tryParse(stdin.readLineSync() ?? '3') ?? 3;
        
        print('\nTesting star graph with $size peripherals and $colors colors...\n');
        await _testAndCompareStarGraph(size, colors);
        break;
        
      case '2':
        stdout.write('Grid size (3-6): ');
        final size = int.tryParse(stdin.readLineSync() ?? '4') ?? 4;
        stdout.write('Number of colors (3-5): ');
        final colors = int.tryParse(stdin.readLineSync() ?? '3') ?? 3;
        
        print('\nTesting ${size}x$size grid with $colors colors...\n');
        await _testAndCompareGridColoring(size, colors);
        break;
        
      case '3':
        stdout.write('Board size (4-12): ');
        final size = int.tryParse(stdin.readLineSync() ?? '8') ?? 8;
        
        print('\nTesting $size-Queens problem...\n');
        await _testAndCompareNQueens(size);
        break;
        
      default:
        print('Invalid choice, running star graph example...\n');
        await _testAndCompareStarGraph(8, 3);
    }
  }
  
  /// Explain the concepts and theory
  static void explainConcepts() {
    print('=== THEORETICAL BACKGROUND ===\n');
    
    print('CSP VARIABLE ORDERING HEURISTICS');
    print('-' * 50);
    print('The order in which we assign variables in backtracking search');
    print('dramatically affects performance. Good heuristics can reduce');
    print('search time from exponential to polynomial in many cases.\n');
    
    print('MRV (Minimum Remaining Values):');
    print('• Select the variable with the smallest domain');
    print('• "Fail-fast" principle: detect inconsistencies early');
    print('• Prunes search tree by failing on dead-end paths quickly');
    print('• Problem: What if multiple variables have the same domain size?\n');
    
    print('DEGREE TIE-BREAKING:');
    print('• Among variables with equal domain sizes, pick the most connected');
    print('• "Most constraining variable" principle');
    print('• High-degree variables constrain many neighbors when assigned');
    print('• Leads to more constraint propagation and faster domain reduction\n');
    
    print('WHEN DEGREE TIE-BREAKING HELPS MOST:');
    print('1. Star topologies: Central hub vs peripheral nodes');
    print('   - Hub has high degree, peripherals have degree 1');
    print('   - Assigning hub first constrains all peripherals at once');
    print();
    print('2. Bottleneck graphs: Bridge nodes connecting clusters');
    print('   - Bridge nodes have higher degree than cluster nodes');
    print('   - Critical for maintaining connectivity between regions');
    print();
    print('3. Grid problems: Corner/edge/center positions');
    print('   - Corner: 2 neighbors, Edge: 3 neighbors, Center: 4 neighbors');
    print('   - Center positions are more constraining');
    print();
    print('4. Hub-and-spoke networks: Communication/transportation systems');
    print('   - Central stations/routers have many connections');
    print('   - Peripheral endpoints have few connections\n');
    
    print('WHEN IT HELPS LESS:');
    print('• Regular graphs where all nodes have similar degrees');
    print('• Sparse constraint graphs with few connections');
    print('• Problems where MRV rarely produces ties');
    print('• Very easy problems that solve quickly anyway\n');
    
    print('IMPLEMENTATION NOTES:');
    print('• Degree calculation: O(1) with pre-built constraint index');
    print('• MRV+Degree overhead is minimal');
    print('• Best results on problems with high constraint density');
    print('• Combines well with other CSP techniques (AC-3, GAC, LCV)');
  }
  
  // Helper methods for testing different problem types
  
  static Future<Map<String, int>> _testStarGraph(int peripherals, int colors) async {
    final variables = <String, List<dynamic>>{};
    final constraints = <BinaryConstraint>[];
    
    final colorList = List.generate(colors, (i) => i);
    variables['CENTER'] = List.from(colorList);
    
    for (int i = 0; i < peripherals; i++) {
      variables['P$i'] = List.from(colorList);
      constraints.add(BinaryConstraint('CENTER', 'P$i', (a, b) => a != b));
      constraints.add(BinaryConstraint('P$i', 'CENTER', (a, b) => a != b));
    }
    
    // Test MRV-only
    final mrvProblem = ConfigurableCspProblem(
      variables: _cloneVariables(variables),
      constraints: constraints,
      heuristic: VariableSelectionHeuristic.mrvOnly,
    );
    await ConfigurableCSP.solve(mrvProblem);
    final mrvSteps = ConfigurableCSP.stats.steps;
    
    // Test MRV+Degree
    final degreeProblem = ConfigurableCspProblem(
      variables: _cloneVariables(variables),
      constraints: constraints,
      heuristic: VariableSelectionHeuristic.mrvWithDegree,
    );
    await ConfigurableCSP.solve(degreeProblem);
    final degreeSteps = ConfigurableCSP.stats.steps;
    
    return {'mrvSteps': mrvSteps, 'degreeSteps': degreeSteps};
  }
  
  static Future<Map<String, int>> _testBottleneckGraph(int clusterSize, int colors) async {
    final variables = <String, List<dynamic>>{};
    final constraints = <BinaryConstraint>[];
    
    final colorList = List.generate(colors, (i) => i);
    
    // Create clusters and bridge
    for (int i = 0; i < clusterSize; i++) {
      variables['A$i'] = List.from(colorList);
      variables['B$i'] = List.from(colorList);
    }
    variables['BRIDGE'] = List.from(colorList);
    
    // Cluster constraints
    for (int i = 0; i < clusterSize; i++) {
      for (int j = i + 1; j < clusterSize; j++) {
        _addBidirectionalConstraint(constraints, 'A$i', 'A$j', (a, b) => a != b);
        _addBidirectionalConstraint(constraints, 'B$i', 'B$j', (a, b) => a != b);
      }
    }
    
    // Bridge constraints (high degree node)
    for (int i = 0; i < clusterSize; i++) {
      _addBidirectionalConstraint(constraints, 'BRIDGE', 'A$i', (a, b) => a != b);
      _addBidirectionalConstraint(constraints, 'BRIDGE', 'B$i', (a, b) => a != b);
    }
    
    return await _runComparison(variables, constraints);
  }
  
  static Future<Map<String, int>> _testGridColoring(int gridSize, int colors) async {
    final variables = <String, List<dynamic>>{};
    final constraints = <BinaryConstraint>[];
    
    final colorList = List.generate(colors, (i) => i);
    
    // Create grid
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        variables['C${r}_$c'] = List.from(colorList);
      }
    }
    
    // Add adjacency constraints
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        final current = 'C${r}_$c';
        
        if (c + 1 < gridSize) {
          _addBidirectionalConstraint(constraints, current, 'C${r}_${c + 1}', (a, b) => a != b);
        }
        if (r + 1 < gridSize) {
          _addBidirectionalConstraint(constraints, current, 'C${r + 1}_$c', (a, b) => a != b);
        }
      }
    }
    
    return await _runComparison(variables, constraints);
  }
  
  static Future<Map<String, int>> _runComparison(
      Map<String, List<dynamic>> variables, 
      List<BinaryConstraint> constraints) async {
    
    // Test MRV-only
    final mrvProblem = ConfigurableCspProblem(
      variables: _cloneVariables(variables),
      constraints: constraints,
      heuristic: VariableSelectionHeuristic.mrvOnly,
    );
    await ConfigurableCSP.solve(mrvProblem);
    final mrvSteps = ConfigurableCSP.stats.steps;
    
    // Test MRV+Degree
    final degreeProblem = ConfigurableCspProblem(
      variables: _cloneVariables(variables),
      constraints: constraints,
      heuristic: VariableSelectionHeuristic.mrvWithDegree,
    );
    await ConfigurableCSP.solve(degreeProblem);
    final degreeSteps = ConfigurableCSP.stats.steps;
    
    return {'mrvSteps': mrvSteps, 'degreeSteps': degreeSteps};
  }
  
  static Future<void> _testAndCompareStarGraph(int peripherals, int colors) async {
    final result = await _testStarGraph(peripherals, colors);
    _printComparison('Star Graph ($peripherals nodes, $colors colors)', result);
  }
  
  static Future<void> _testAndCompareGridColoring(int size, int colors) async {
    final result = await _testGridColoring(size, colors);
    _printComparison('Grid Coloring (${size}x$size, $colors colors)', result);
  }
  
  static Future<void> _testAndCompareNQueens(int size) async {
    // Simplified N-Queens implementation for demonstration
    print('N-Queens testing would require additional implementation...');
    print('(N-Queens uses n-ary constraints which need different handling)');
  }
  
  static void _printComparison(String problemName, Map<String, int> result) {
    final improvement = result['mrvSteps']! > 0 ? 
        (result['mrvSteps']! - result['degreeSteps']!) / result['mrvSteps']! * 100 : 0;
    
    print('Results for $problemName:');
    print('  MRV-only: ${result['mrvSteps']} steps');
    print('  MRV+Degree: ${result['degreeSteps']} steps');
    print('  Improvement: ${improvement.toStringAsFixed(1)}%');
    
    if (improvement > 20) {
      print('  Status: EXCELLENT improvement');
    } else if (improvement > 10) {
      print('  Status: GOOD improvement');
    } else if (improvement > 0) {
      print('  Status: MODEST improvement');
    } else {
      print('  Status: MINIMAL/NO improvement');
    }
  }
  
  static Map<String, List<dynamic>> _cloneVariables(Map<String, List<dynamic>> variables) {
    final cloned = <String, List<dynamic>>{};
    variables.forEach((key, value) {
      cloned[key] = List.from(value);
    });
    return cloned;
  }
  
  static void _addBidirectionalConstraint(
      List<BinaryConstraint> constraints, 
      String var1, 
      String var2, 
      bool Function(dynamic, dynamic) predicate) {
    constraints.add(BinaryConstraint(var1, var2, predicate));
    constraints.add(BinaryConstraint(var2, var1, (a, b) => predicate(b, a)));
  }
}

/// Main entry point
Future<void> main(List<String> args) async {
  final mode = args.isNotEmpty ? args[0].toLowerCase() : 'simple';
  
  print('CSP Heuristic Comparison Tool');
  print('Comparing MRV-only vs MRV+Degree tie-breaking\n');
  
  switch (mode) {
    case 'simple':
    case 'demo':
      await CSPTestRunner.simpleDemo();
      break;
      
    case 'full':
    case 'benchmark':
      await CSPTestRunner.fullBenchmark();
      break;
      
    case 'custom':
    case 'interactive':
      await CSPTestRunner.customTesting();
      break;
      
    case 'explain':
    case 'theory':
      CSPTestRunner.explainConcepts();
      break;
      
    default:
      print('Usage: dart run test_runner.dart [mode]');
      print('Modes:');
      print('  simple    - Quick demonstration (default)');
      print('  full      - Comprehensive benchmark suite');
      print('  custom    - Interactive custom problem testing');
      print('  explain   - Theoretical background explanation');
      print('\nRunning simple demo...\n');
      await CSPTestRunner.simpleDemo();
  }
}