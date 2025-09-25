/// Comprehensive benchmark suite for comparing CSP heuristics
/// Tests MRV-only vs MRV+Degree tie-breaking on various problem types

import 'dart:math';
import '../lib/dart_csp.dart';

/// Benchmark result for a single problem instance
class BenchmarkResult {
  final String problemName;
  final String heuristic;
  final SolverStats stats;
  final bool solved;
  final int problemSize;
  
  BenchmarkResult(this.problemName, this.heuristic, this.stats, this.solved, this.problemSize);
  
  double get efficiency => solved ? (1000.0 / (stats.steps + 1)) : 0.0;
  
  @override
  String toString() {
    return '$problemName ($heuristic): ${solved ? "SOLVED" : "FAILED"} - '
           '${stats.steps} steps, ${stats.backtracks} backtracks, '
           '${stats.solvingTime.inMilliseconds}ms';
  }
}

/// Problem generator for various CSP types
class ProblemGenerator {
  static final _random = Random(42); // Fixed seed for reproducibility
  
  /// Generate a star graph coloring problem
  /// One central node connected to many peripherals - great for degree tie-breaking
  static ConfigurableCspProblem starGraphColoring(int numPeripherals, int numColors,
      {VariableSelectionHeuristic heuristic = VariableSelectionHeuristic.mrvWithDegree}) {
    
    final variables = <String, List<dynamic>>{};
    final constraints = <BinaryConstraint>[];
    
    // Create variables: one center + peripherals
    final colors = List.generate(numColors, (i) => i);
    variables['center'] = List.from(colors);
    for (int i = 0; i < numPeripherals; i++) {
      variables['node_$i'] = List.from(colors);
    }
    
    // Add constraints: center != each peripheral
    for (int i = 0; i < numPeripherals; i++) {
      constraints.add(BinaryConstraint(
        'center', 'node_$i', 
        (a, b) => a != b
      ));
      constraints.add(BinaryConstraint(
        'node_$i', 'center', 
        (a, b) => a != b
      ));
    }
    
    return ConfigurableCspProblem(
      variables: variables,
      constraints: constraints,
      heuristic: heuristic,
    );
  }
  
  /// Generate a bottleneck graph coloring problem
  /// Two clusters connected by bridge nodes - bridge nodes have higher degree
  static ConfigurableCspProblem bottleneckGraphColoring(int clusterSize, int numColors,
      {VariableSelectionHeuristic heuristic = VariableSelectionHeuristic.mrvWithDegree}) {
    
    final variables = <String, List<dynamic>>{};
    final constraints = <BinaryConstraint>[];
    
    final colors = List.generate(numColors, (i) => i);
    
    // Cluster A
    for (int i = 0; i < clusterSize; i++) {
      variables['A$i'] = List.from(colors);
    }
    
    // Cluster B  
    for (int i = 0; i < clusterSize; i++) {
      variables['B$i'] = List.from(colors);
    }
    
    // Bridge nodes (high degree)
    variables['bridge1'] = List.from(colors);
    variables['bridge2'] = List.from(colors);
    
    // Add constraints within cluster A
    for (int i = 0; i < clusterSize; i++) {
      for (int j = i + 1; j < clusterSize; j++) {
        _addBidirectionalConstraint(constraints, 'A$i', 'A$j', (a, b) => a != b);
      }
    }
    
    // Add constraints within cluster B
    for (int i = 0; i < clusterSize; i++) {
      for (int j = i + 1; j < clusterSize; j++) {
        _addBidirectionalConstraint(constraints, 'B$i', 'B$j', (a, b) => a != b);
      }
    }
    
    // Connect bridge1 to all of cluster A
    for (int i = 0; i < clusterSize; i++) {
      _addBidirectionalConstraint(constraints, 'bridge1', 'A$i', (a, b) => a != b);
    }
    
    // Connect bridge2 to all of cluster B  
    for (int i = 0; i < clusterSize; i++) {
      _addBidirectionalConstraint(constraints, 'bridge2', 'B$i', (a, b) => a != b);
    }
    
    // Connect the bridges
    _addBidirectionalConstraint(constraints, 'bridge1', 'bridge2', (a, b) => a != b);
    
    return ConfigurableCspProblem(
      variables: variables,
      constraints: constraints,
      heuristic: heuristic,
    );
  }
  
  /// Generate a grid-based map coloring problem
  /// Corner and edge positions have different degrees than center positions
  static ConfigurableCspProblem gridMapColoring(int gridSize, int numColors,
      {VariableSelectionHeuristic heuristic = VariableSelectionHeuristic.mrvWithDegree}) {
    
    final variables = <String, List<dynamic>>{};
    final constraints = <BinaryConstraint>[];
    
    final colors = List.generate(numColors, (i) => i);
    
    // Create grid variables
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        variables['cell_${row}_$col'] = List.from(colors);
      }
    }
    
    // Add adjacency constraints (4-connected grid)
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        final current = 'cell_${row}_$col';
        
        // Right neighbor
        if (col + 1 < gridSize) {
          final right = 'cell_${row}_${col + 1}';
          _addBidirectionalConstraint(constraints, current, right, (a, b) => a != b);
        }
        
        // Bottom neighbor
        if (row + 1 < gridSize) {
          final bottom = 'cell_${row + 1}_$col';
          _addBidirectionalConstraint(constraints, current, bottom, (a, b) => a != b);
        }
      }
    }
    
    return ConfigurableCspProblem(
      variables: variables,
      constraints: constraints,
      heuristic: heuristic,
    );
  }
  
  static void _addBidirectionalConstraint(
      List<BinaryConstraint> constraints, 
      String var1, 
      String var2, 
      BinaryPredicate predicate) {
    constraints.add(BinaryConstraint(var1, var2, predicate));
    constraints.add(BinaryConstraint(var2, var1, (a, b) => predicate(b, a)));
  }
}

/// Main benchmark runner
class BenchmarkRunner {
  final List<BenchmarkResult> results = [];
  
  /// Run a single benchmark comparison
  Future<void> benchmarkProblem(String name, ConfigurableCspProblem Function() problemFactory) async {
    print('');
    print('=== Benchmarking $name ===');
    
    // Test MRV-only heuristic
    final mrvProblem = problemFactory();
    mrvProblem.heuristic = VariableSelectionHeuristic.mrvOnly;
    
    print('Testing MRV-only...');
    final mrvResult = await ConfigurableCSP.solve(mrvProblem);
    final mrvStats = ConfigurableCSP.stats;
    results.add(BenchmarkResult(name, 'MRV-only', 
        SolverStats()..steps = mrvStats.steps..backtracks = mrvStats.backtracks
        ..constraintChecks = mrvStats.constraintChecks..solvingTime = mrvStats.solvingTime
        ..solved = mrvStats.solved,
        mrvStats.solved, mrvProblem.variables.length));
    
    // Test MRV+Degree heuristic
    final degreeProblem = problemFactory();
    degreeProblem.heuristic = VariableSelectionHeuristic.mrvWithDegree;
    
    print('Testing MRV+Degree...');
    final degreeResult = await ConfigurableCSP.solve(degreeProblem);
    final degreeStats = ConfigurableCSP.stats;
    results.add(BenchmarkResult(name, 'MRV+Degree', 
        SolverStats()..steps = degreeStats.steps..backtracks = degreeStats.backtracks
        ..constraintChecks = degreeStats.constraintChecks..solvingTime = degreeStats.solvingTime
        ..solved = degreeStats.solved,
        degreeStats.solved, degreeProblem.variables.length));
    
    // Compare results
    final improvement = mrvStats.solved && degreeStats.solved ? 
        (mrvStats.steps - degreeStats.steps) / mrvStats.steps * 100 : 0;
    
    print('MRV-only:   ${mrvStats.solved ? "SOLVED" : "FAILED"} - ${mrvStats.steps} steps, ${mrvStats.solvingTime.inMilliseconds}ms');
    print('MRV+Degree: ${degreeStats.solved ? "SOLVED" : "FAILED"} - ${degreeStats.steps} steps, ${degreeStats.solvingTime.inMilliseconds}ms');
    
    if (improvement != 0) {
      print('Improvement: ${improvement.toStringAsFixed(1)}% fewer steps');
    }
  }
  
  /// Run complete benchmark suite
  Future<void> runBenchmarks() async {
    print('Starting CSP Heuristic Benchmark Suite');
    print('=' * 50);
    
    // Star graph problems (should strongly favor degree heuristic)
    await benchmarkProblem('Star Graph (8 nodes, 3 colors)', 
        () => ProblemGenerator.starGraphColoring(8, 3));
        
    await benchmarkProblem('Star Graph (15 nodes, 4 colors)', 
        () => ProblemGenerator.starGraphColoring(15, 4));
    
    // Bottleneck problems (bridge nodes have high degree)
    await benchmarkProblem('Bottleneck Graph (4x4 clusters, 3 colors)', 
        () => ProblemGenerator.bottleneckGraphColoring(4, 3));
        
    await benchmarkProblem('Bottleneck Graph (5x5 clusters, 4 colors)', 
        () => ProblemGenerator.bottleneckGraphColoring(5, 4));
    
    // Grid coloring (corner/edge/center positions have different degrees)
    await benchmarkProblem('Grid Coloring (4x4, 3 colors)', 
        () => ProblemGenerator.gridMapColoring(4, 3));
        
    await benchmarkProblem('Grid Coloring (5x5, 4 colors)', 
        () => ProblemGenerator.gridMapColoring(5, 4));
    
    // Print summary
    _printSummary();
  }
  
  void _printSummary() {
    print('');
    print('=' * 70);
    print('BENCHMARK SUMMARY');
    print('=' * 70);
    
    final mrvResults = results.where((r) => r.heuristic == 'MRV-only').toList();
    final degreeResults = results.where((r) => r.heuristic == 'MRV+Degree').toList();
    
    print('Problem Name'.padRight(35) + 'MRV Steps'.padRight(12) + 'Degree Steps'.padRight(12) + 'Improvement');
    print('-' * 70);
    
    for (int i = 0; i < mrvResults.length; i++) {
      final mrv = mrvResults[i];
      final degree = degreeResults[i];
      
      final improvement = (mrv.solved && degree.solved) ? 
          (mrv.stats.steps - degree.stats.steps) / mrv.stats.steps * 100 : 0;
      
      final impStr = improvement > 0 ? '+${improvement.toStringAsFixed(1)}%' :
                     improvement < 0 ? '${improvement.toStringAsFixed(1)}%' : 'N/A';
      
      final line = mrv.problemName.padRight(35) +
                   (mrv.solved ? mrv.stats.steps.toString() : 'FAILED').padRight(12) +
                   (degree.solved ? degree.stats.steps.toString() : 'FAILED').padRight(12) +
                   impStr;
      print(line);
    }
    
    // Overall statistics
    final totalMrvSteps = mrvResults.where((r) => r.solved).fold(0, (sum, r) => sum + r.stats.steps);
    final totalDegreeSteps = degreeResults.where((r) => r.solved).fold(0, (sum, r) => sum + r.stats.steps);
    final overallImprovement = (totalMrvSteps - totalDegreeSteps) / totalMrvSteps * 100;
    
    print('-' * 70);
    final totalLine = 'TOTAL'.padRight(35) + 
          '$totalMrvSteps'.padRight(12) + 
          '$totalDegreeSteps'.padRight(12) + 
          '+${overallImprovement.toStringAsFixed(1)}%';
    print(totalLine);
    
    print('');
    print('Problems where degree tie-breaking helps most:');
    final improvements = <String, double>{};
    for (int i = 0; i < mrvResults.length; i++) {
      final mrv = mrvResults[i];
      final degree = degreeResults[i];
      
      if (mrv.solved && degree.solved) {
        final improvement = (mrv.stats.steps - degree.stats.steps) / mrv.stats.steps * 100;
        improvements[mrv.problemName] = improvement;
      }
    }
    
    final sorted = improvements.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (final entry in sorted.take(3)) {
      print('  ${entry.key}: +${entry.value.toStringAsFixed(1)}% improvement');
    }
  }
}

/// Main function to run benchmarks
Future<void> main() async {
  final runner = BenchmarkRunner();
  await runner.runBenchmarks();
}

/// Utility function for testing individual problems
Future<void> testSingleProblem() async {
  print('Testing single star graph problem...');
  print('');
  
  // Create a star graph that should benefit from degree tie-breaking
  final problem = ProblemGenerator.starGraphColoring(10, 3);
  
  // Test both heuristics
  problem.heuristic = VariableSelectionHeuristic.mrvOnly;
  final mrvResult = await ConfigurableCSP.solve(problem);
  final mrvStats = ConfigurableCSP.stats;
  
  problem.heuristic = VariableSelectionHeuristic.mrvWithDegree;
  final degreeResult = await ConfigurableCSP.solve(problem);
  final degreeStats = ConfigurableCSP.stats;
  
  print('Star Graph (10 nodes, 3 colors):');
  print('MRV-only:   ${mrvStats.solved ? "SOLVED" : "FAILED"} - ${mrvStats.steps} steps');
  print('MRV+Degree: ${degreeStats.solved ? "SOLVED" : "FAILED"} - ${degreeStats.steps} steps');
  
  if (mrvStats.solved && degreeStats.solved) {
    final improvement = (mrvStats.steps - degreeStats.steps) / mrvStats.steps * 100;
    print('Improvement: ${improvement.toStringAsFixed(1)}% fewer steps');
  }
}