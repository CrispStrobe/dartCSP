// Import the CSP library. Ensure dart_csp.dart is in the same directory.
import 'dart:math';
import 'dart_csp.dart';

/// Main entry point for the comprehensive demonstrations.
Future<void> main() async {
  print('🚀 DART CSP COMPREHENSIVE DEMO - Testing All Built-in Constraints');
  print('=' * 70);
  
  // Legacy demos (with new constraints)
  await runMapColoringDemo();
  await runNQueensDemo();
  await runSudokuDemo();
  
  // NeConstraint-specific demos
  await runAllDifferentEqualDemo();
  await runSumConstraintsDemo();
  await runProductConstraintsDemo();
  await runSetMembershipDemo();
  await runOrderingConstraintsDemo(); 
  await runMagicSquareDemo(); 
  await runResourceAllocationDemo();
  await runSchedulingDemo();
  
  print('\n' + '=' * 70);
  print('🎉 All demos completed successfully!');
}

/// Prints a formatted header to the console.
void printHeader(String title) {
  print('\n' + '─' * 50);
  print('─ $title');
  print('─' * 50);
}

/// Prints a sub-section header
void printSubHeader(String title) {
  print('\n   ► $title');
  print('   ' + '─' * (title.length + 2));
}

// ====================================================================
// DEMO 1: USA Map Coloring (Enhanced with Built-in Constraints)
// ====================================================================

/// Runs the Map Coloring demo using both the old and new methods.
Future<void> runMapColoringDemo() async {
  printHeader('USA Map Coloring (Enhanced)');
  const colors = ['red', 'green', 'blue', 'yellow'];
  final neighbors = getUsaNeighbors();

  // --- 1. The "Old Way" (Manual CspProblem construction) ---
  printSubHeader('Old Way (Manual CspProblem)');
  await solveMapColoringOldWay(colors, neighbors);

  // --- 2. The "New Way" with Built-in Constraints ---
  printSubHeader('New Way (Built-in allDifferentBinary())');
  await solveMapColoringWithBuiltins(colors, neighbors);
}

Future<void> solveMapColoringOldWay(
    List<String> colors, Map<String, List<String>> neighbors) async {
  final variables = <String, List<dynamic>>{};
  final constraints = <BinaryConstraint>[];
  final allStates = neighbors.keys.toSet();

  // Populate variables
  for (final state in allStates) {
    variables[state] = List.from(colors);
  }

  // Populate binary constraints (must be added in both directions for AC-3)
  for (final entry in neighbors.entries) {
    final state = entry.key;
    for (final neighbor in entry.value) {
      // Define the not-equal predicate
      bool neq(dynamic c1, dynamic c2) => c1 != c2;
      constraints.add(BinaryConstraint(state, neighbor, neq));
    }
  }

  final problem = CspProblem(variables: variables, constraints: constraints);
  final solution = await CSP.solve(problem);
  printResult(solution, successMessage: 'Solution found using manual approach!');
}

Future<void> solveMapColoringWithBuiltins(
    List<String> colors, Map<String, List<String>> neighbors) async {
  final p = Problem();
  final allStates = neighbors.keys.toList();

  // Add variables
  p.addVariables(allStates, colors);

  // Add constraints using built-in allDifferentBinary()
  final addedConstraints = <String>{};
  for (final entry in neighbors.entries) {
    final state1 = entry.key;
    for (final state2 in entry.value) {
      final pair = [state1, state2]..sort();
      if (addedConstraints.add(pair.join('-'))) {
        // Using the built-in constraint factory function
        p.addConstraint([state1, state2], allDifferentBinary());
      }
    }
  }

  final solution = await p.getSolution();
  printResult(solution, successMessage: 'Solution found using built-in constraints!');
}

// ====================================================================
// DEMO 2: N-Queens Problem (Enhanced)
// ====================================================================

/// Runs the N-Queens demo using both the old and new methods.
Future<void> runNQueensDemo() async {
  printHeader('8-Queens Problem (Enhanced)');
  const size = 8;

  printSubHeader('Old Way (Manual constraints)');
  await solveNQueensOldWay(size);

  printSubHeader('New Way (Built-in constraints)');
  await solveNQueensWithBuiltins(size);
}

/// Predicate to check if two queens collide.
/// A position is represented as a `List<int>` of `[row, col]`.
bool notColliding(dynamic p1, dynamic p2) {
  final pos1 = p1 as List<int>;
  final pos2 = p2 as List<int>;
  // Not in the same column
  if (pos1[1] == pos2[1]) return false;
  // Not on the same diagonal
  if ((pos1[0] - pos2[0]).abs() == (pos1[1] - pos2[1]).abs()) return false;
  return true;
}

Future<void> solveNQueensOldWay(int size) async {
  final variables = <String, List<dynamic>>{};
  final constraints = <BinaryConstraint>[];

  // Model: One variable per queen (and per row).
  // Domain of each variable is the list of possible [row, col] coordinates.
  for (int i = 0; i < size; i++) {
    final domain = <List<int>>[];
    for (int j = 0; j < size; j++) {
      domain.add([i, j]);
    }
    variables[i.toString()] = domain;
  }

  // Add constraints between every pair of queens.
  for (int i = 0; i < size; i++) {
    for (int j = 0; j < size; j++) {
      if (i != j) {
        constraints.add(BinaryConstraint(i.toString(), j.toString(), notColliding));
      }
    }
  }

  final problem = CspProblem(variables: variables, constraints: constraints);
  final solution = await CSP.solve(problem);

  printResult(solution, successMessage: 'Solution found with manual approach!');
  if (solution is Map) printQueensBoard(size, solution);
}

Future<void> solveNQueensWithBuiltins(int size) async {
  final p = Problem();

  // Add variables and their domains
  for (int i = 0; i < size; i++) {
    final domain = <List<int>>[];
    for (int j = 0; j < size; j++) {
      domain.add([i, j]);
    }
    p.addVariable(i.toString(), domain);
  }

  // Add constraints between every pair of queens using factory functions
  for (int i = 0; i < size; i++) {
    for (int j = i + 1; j < size; j++) {
      // Using lambda (old way) - just for comparison
      p.addConstraint([i.toString(), j.toString()], notColliding);
    }
  }

  final solution = await p.getSolution();

  printResult(solution, successMessage: 'Solution found with Problem builder!');
  if (solution is Map) printQueensBoard(size, solution);
}

// ====================================================================
// DEMO 3: Sudoku (Enhanced)
// ====================================================================

Future<void> runSudokuDemo() async {
  printHeader('Sudoku (Enhanced)');
  final puzzle = [
    [5, 3, 0, 0, 7, 0, 0, 0, 0],
    [6, 0, 0, 1, 9, 5, 0, 0, 0],
    [0, 9, 8, 0, 0, 0, 0, 6, 0],
    [8, 0, 0, 0, 6, 0, 0, 0, 3],
    [4, 0, 0, 8, 0, 3, 0, 0, 1],
    [7, 0, 0, 0, 2, 0, 0, 0, 6],
    [0, 6, 0, 0, 0, 0, 2, 8, 0],
    [0, 0, 0, 4, 1, 9, 0, 0, 5],
    [0, 0, 0, 0, 8, 0, 0, 7, 9],
  ];

  printSubHeader('Enhanced Way (Using AllDifferent Extension Methods)');
  await solveSudokuWithBuiltins(puzzle);
}

Future<void> solveSudokuWithBuiltins(List<List<int>> puzzle) async {
  final p = Problem();
  final domain = List.generate(9, (i) => i + 1);

  // Add all 81 variables
  for (int r = 0; r < 9; r++) {
    for (int c = 0; c < 9; c++) {
      final key = '$r-$c';
      if (puzzle[r][c] != 0) {
        p.addVariable(key, [puzzle[r][c]]);
      } else {
        p.addVariable(key, domain);
      }
    }
  }

  // Add all-different constraints using the new extension method!
  // This is much cleaner than individual binary constraints
  
  // Rows
  for (int r = 0; r < 9; r++) {
    final row = <String>[];
    for (int c = 0; c < 9; c++) {
      row.add('$r-$c');
    }
    p.addAllDifferent(row);  // Using the new extension method!
  }

  // Columns  
  for (int c = 0; c < 9; c++) {
    final col = <String>[];
    for (int r = 0; r < 9; r++) {
      col.add('$r-$c');
    }
    p.addAllDifferent(col);  // Using the new extension method!
  }

  // 3x3 Blocks
  for (int br in [0, 3, 6]) {
    for (int bc in [0, 3, 6]) {
      final block = <String>[];
      for (int r = br; r < br + 3; r++) {
        for (int c = bc; c < bc + 3; c++) {
          block.add('$r-$c');
        }
      }
      p.addAllDifferent(block);  // Using the new extension method!
    }
  }

  final solution = await p.getSolution();
  printResult(solution, successMessage: 'Sudoku solved with built-in AllDifferent!');
  if (solution is Map) printSudokuBoard(solution);
}

// ====================================================================
// DEMO 4: All Different and All Equal Constraints
// ====================================================================

Future<void> runAllDifferentEqualDemo() async {
  printHeader('All Different & All Equal Constraints Demo');
  
  printSubHeader('All Different Demo');
  await testAllDifferent();
  
  printSubHeader('All Equal Demo');
  await testAllEqual();
}

Future<void> testAllDifferent() async {
  final p = Problem();
  
  // Variables A, B, C must all be different
  p.addVariables(['A', 'B', 'C'], [1, 2, 3, 4]);
  
  // Test both approaches
  print('   Using extension method: addAllDifferent()');
  p.addAllDifferent(['A', 'B', 'C']);
  
  final solution = await p.getSolution();
  printResult(solution, successMessage: 'All variables have different values!');
  
  // Test factory function approach
  final p2 = Problem();
  p2.addVariables(['X', 'Y'], [1, 2, 3]);
  
  print('   Using factory function: allDifferentBinary()');
  p2.addConstraint(['X', 'Y'], allDifferentBinary());
  
  final solution2 = await p2.getSolution();
  printResult(solution2, successMessage: 'X and Y are different!');
}

Future<void> testAllEqual() async {
  final p = Problem();
  
  // Variables must all have the same value
  p.addVariables(['A', 'B', 'C'], [1, 2, 3]);
  
  print('   Using extension method: addAllEqual()');
  p.addAllEqual(['A', 'B', 'C']);
  
  final solution = await p.getSolution();
  printResult(solution, successMessage: 'All variables have the same value!');
}

// ====================================================================
// DEMO 5: Sum Constraints
// ====================================================================

Future<void> runSumConstraintsDemo() async {
  printHeader('Sum Constraints Demo');
  
  printSubHeader('Exact Sum');
  await testExactSum();
  
  printSubHeader('Min/Max Sum');
  await testMinMaxSum();
  
  printSubHeader('Sum Range');
  await testSumRange();
  
  printSubHeader('Weighted Sum');
  await testWeightedSum();
}

Future<void> testExactSum() async {
  final p = Problem();
  
  // Find three numbers that sum to exactly 10
  p.addVariables(['A', 'B', 'C'], [1, 2, 3, 4, 5, 6]);
  
  print('   Finding A + B + C = 10');
  p.addExactSum(['A', 'B', 'C'], 10);
  
  final solution = await p.getSolution();
  printResult(solution, successMessage: 'Found numbers that sum to 10!');
  if (solution is Map) {
    final sum = solution['A'] + solution['B'] + solution['C'];
    print('   Verification: ${solution['A']} + ${solution['B']} + ${solution['C']} = $sum');
  }
}

Future<void> testMinMaxSum() async {
  final p = Problem();
  
  // Variables that sum to at least 8 but at most 12
  p.addVariables(['X', 'Y', 'Z'], [1, 2, 3, 4, 5]);
  
  print('   Finding X + Y + Z >= 8 and <= 12');
  p.addConstraint(['X', 'Y', 'Z'], minSum(8));
  p.addConstraint(['X', 'Y', 'Z'], maxSum(12));
  
  final solution = await p.getSolution();
  printResult(solution, successMessage: 'Found numbers in range!');
  if (solution is Map) {
    final sum = solution['X'] + solution['Y'] + solution['Z'];
    print('   Verification: ${solution['X']} + ${solution['Y']} + ${solution['Z']} = $sum');
  }
}

Future<void> testSumRange() async {
  final p = Problem();
  
  p.addVariables(['A', 'B'], [1, 2, 3, 4, 5, 6]);
  
  print('   Using sumInRange(4, 8)');
  p.addSumRange(['A', 'B'], 4, 8);
  
  final solution = await p.getSolution();
  printResult(solution, successMessage: 'Sum is in range [4, 8]!');
  if (solution is Map) {
    final sum = solution['A'] + solution['B'];
    print('   Verification: ${solution['A']} + ${solution['B']} = $sum');
  }
}

Future<void> testWeightedSum() async {
  final p = Problem();
  
  // Weighted sum: 2*A + 3*B = 11
  p.addVariables(['A', 'B'], [1, 2, 3, 4]);
  
  print('   Finding 2*A + 3*B = 11');
  p.addExactSum(['A', 'B'], 11, multipliers: [2, 3]);
  
  final solution = await p.getSolution();
  printResult(solution, successMessage: 'Found weighted sum solution!');
  if (solution is Map) {
    final weightedSum = 2 * solution['A'] + 3 * solution['B'];
    print('   Verification: 2*${solution['A']} + 3*${solution['B']} = $weightedSum');
  }
}

// ====================================================================
// DEMO 6: Product Constraints
// ====================================================================

Future<void> runProductConstraintsDemo() async {
  printHeader('Product Constraints Demo');
  
  printSubHeader('Exact Product');
  await testExactProduct();
  
  printSubHeader('Min/Max Product');
  await testMinMaxProduct();
}

Future<void> testExactProduct() async {
  final p = Problem();
  
  // Find numbers that multiply to exactly 12
  p.addVariables(['A', 'B'], [1, 2, 3, 4, 6, 12]);
  
  print('   Finding A * B = 12');
  p.addExactProduct(['A', 'B'], 12);
  
  final solution = await p.getSolution();
  printResult(solution, successMessage: 'Found numbers that multiply to 12!');
  if (solution is Map) {
    final product = solution['A'] * solution['B'];
    print('   Verification: ${solution['A']} * ${solution['B']} = $product');
  }
}

Future<void> testMinMaxProduct() async {
  final p = Problem();
  
  // Product between 6 and 20
  p.addVariables(['X', 'Y', 'Z'], [1, 2, 3, 4]);
  
  print('   Finding X * Y * Z >= 6 and <= 20');
  p.addConstraint(['X', 'Y', 'Z'], minProduct(6));
  p.addConstraint(['X', 'Y', 'Z'], maxProduct(20));
  
  final solution = await p.getSolution();
  printResult(solution, successMessage: 'Found product in range!');
  if (solution is Map) {
    final product = solution['X'] * solution['Y'] * solution['Z'];
    print('   Verification: ${solution['X']} * ${solution['Y']} * ${solution['Z']} = $product');
  }
}

// ====================================================================
// DEMO 7: Set Membership Constraints
// ====================================================================

Future<void> runSetMembershipDemo() async {
  printHeader('Set Membership Constraints Demo');
  
  printSubHeader('In Set Constraint');
  await testInSet();
  
  printSubHeader('Not In Set Constraint');
  await testNotInSet();
  
  printSubHeader('Some In Set Constraint');
  await testSomeInSet();
}

Future<void> testInSet() async {
  final p = Problem();
  
  // Variables must be prime numbers
  p.addVariables(['A', 'B'], [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  
  final primes = {2, 3, 5, 7};
  print('   Variables must be prime: $primes');
  p.addInSet(['A', 'B'], primes);
  
  final solution = await p.getSolution();
  printResult(solution, successMessage: 'Found prime numbers!');
}

Future<void> testNotInSet() async {
  final p = Problem();
  
  // Variables cannot be even
  p.addVariables(['X', 'Y'], [1, 2, 3, 4, 5, 6]);
  
  final evens = {2, 4, 6};
  print('   Variables cannot be even: $evens');
  p.addNotInSet(['X', 'Y'], evens);
  
  final solution = await p.getSolution();
  printResult(solution, successMessage: 'Found odd numbers!');
}

Future<void> testSomeInSet() async {
  final p = Problem();
  
  // At least 2 variables must be in the "special" set
  p.addVariables(['A', 'B', 'C'], [1, 2, 3, 4, 5]);
  
  final special = {1, 3, 5};
  print('   At least 2 variables must be from $special');
  p.addConstraint(['A', 'B', 'C'], someInSet(special, 2));
  
  final solution = await p.getSolution();
  printResult(solution, successMessage: 'At least 2 are from special set!');
  if (solution is Map) {
    final inSpecial = solution.values.where((v) => special.contains(v)).length;
    print('   Verification: $inSpecial variables are in special set');
  }
}

// ====================================================================
// DEMO 8: Ordering Constraints 
// ====================================================================

Future<void> runOrderingConstraintsDemo() async {
  printHeader('Ordering Constraints Demo');
  
  printSubHeader('Ascending Order');
  await testAscending();
  
  printSubHeader('Strictly Ascending Order');
  await testStrictlyAscending();
  
  printSubHeader('Descending Order');
  await testDescending();
}

Future<void> testAscending() async {
  final p = Problem();
  
  // Variables in non-decreasing order
  p.addVariables(['A', 'B', 'C'], [1, 2, 3, 4, 5]);
  
  print('   Variables in ascending order (A <= B <= C)');
  p.addAscending(['A', 'B', 'C']); // preserves order
  
  final solution = await p.getSolution();
  printResult(solution, successMessage: 'Variables are in ascending order!');
  if (solution is Map) {
    print('   Verification: ${solution['A']} <= ${solution['B']} <= ${solution['C']}');
  }
}

Future<void> testStrictlyAscending() async {
  final p = Problem();
  
  // Variables in strictly increasing order
  p.addVariables(['X', 'Y', 'Z'], [1, 2, 3, 4, 5]);
  
  print('   Variables in strictly ascending order (X < Y < Z)');
  p.addStrictlyAscending(['X', 'Y', 'Z']); // preserve order
  
  final solution = await p.getSolution();
  printResult(solution, successMessage: 'Variables are in strictly ascending order!');
  if (solution is Map) {
    print('   Verification: ${solution['X']} < ${solution['Y']} < ${solution['Z']}');
  }
}

Future<void> testDescending() async {
  final p = Problem();
  
  // Variables in non-increasing order
  p.addVariables(['P', 'Q'], [1, 2, 3, 4]);
  
  print('   Variables in descending order (P >= Q)');
  p.addDescending(['P', 'Q']); // preserve order
  
  final solution = await p.getSolution();
  printResult(solution, successMessage: 'Variables are in descending order!');
  if (solution is Map) {
    print('   Verification: ${solution['P']} >= ${solution['Q']}');
  }
}

// ====================================================================
// DEMO 9: Magic Square
// ====================================================================


Future<void> runMagicSquareDemo() async {
  printHeader('3x3 Magic Square - One Random Clue');
  
  final p = Problem();
  final random = Random();
  
  print('   Generating one random clue to reduce search space...');
  
  // Generate one random clue
  final positions = ['00', '01', '02', '10', '11', '12', '20', '21', '22'];
  final randomPosition = positions[random.nextInt(positions.length)];
  final randomValue = random.nextInt(9) + 1; // 1-9
  
  print('   Random clue: Position $randomPosition = $randomValue');
  
  // Add the random clue
  p.addVariable(randomPosition, [randomValue]);
  
  // Add remaining variables with domain excluding the clue value
  final remainingDomain = List.generate(9, (i) => i + 1)
    ..remove(randomValue);
    
  for (final pos in positions) {
    if (pos != randomPosition) {
      p.addVariable(pos, remainingDomain);
    }
  }
  
  print('   Setting up magic square constraints...');
  
  // All different (each number 1-9 appears exactly once)
  p.addAllDifferent(positions);
  
  // Sum constraints = 15 for all rows, columns, and diagonals
  
  // Rows
  p.addExactSum(['00', '01', '02'], 15); // Top row
  p.addExactSum(['10', '11', '12'], 15); // Middle row  
  p.addExactSum(['20', '21', '22'], 15); // Bottom row
  
  // Columns
  p.addExactSum(['00', '10', '20'], 15); // Left column
  p.addExactSum(['01', '11', '21'], 15); // Middle column
  p.addExactSum(['02', '12', '22'], 15); // Right column
  
  // Diagonals
  p.addExactSum(['00', '11', '22'], 15); // Main diagonal
  p.addExactSum(['02', '11', '20'], 15); // Anti-diagonal
  
  print('   Solving magic square with random clue...');
  final solution = await p.getSolution();
  printResult(solution, successMessage: '3x3 Magic Square solved with one random clue!');
  
  if (solution is Map) {
    print('\n   Magic Square:');
    for (int r = 0; r < 3; r++) {
      final row = [solution['${r}0'], solution['${r}1'], solution['${r}2']];
      print('   ${row.join('  ')}');
    }
    
    // Verify sums
    print('\n   Verification:');
    // Rows
    for (int r = 0; r < 3; r++) {
      final sum = solution['${r}0'] + solution['${r}1'] + solution['${r}2'];
      print('   Row $r: $sum');
    }
    // Columns
    for (int c = 0; c < 3; c++) {
      final sum = solution['0$c'] + solution['1$c'] + solution['2$c'];
      print('   Col $c: $sum');
    }
    // Diagonals
    final diag1 = solution['00'] + solution['11'] + solution['22'];
    final diag2 = solution['02'] + solution['11'] + solution['20'];
    print('   Main diagonal: $diag1');
    print('   Anti-diagonal: $diag2');
  } else {
    print('   Note: Some random clues may make the puzzle unsolvable.');
    print('         Run again for a different random clue!');
  }
}


// ====================================================================
// DEMO 10: Resource Allocation
// ====================================================================

Future<void> runResourceAllocationDemo() async {
  printHeader('Resource Allocation Problem');
  
  final p = Problem();
  
  // Teams A, B, C get resource allocations (restricted domain for efficiency)
  p.addVariables(['TeamA', 'TeamB', 'TeamC'], [3, 4, 5, 6, 7, 8, 9, 10]);
  
  print('   Setting up resource allocation constraints...');
  
  // Total budget is exactly 20
  p.addExactSum(['TeamA', 'TeamB', 'TeamC'], 20);
  
  // Each team automatically gets at least 3 resources (enforced by domain)
  // Each team automatically gets at most 10 resources (enforced by domain)
  
  // TeamA gets at least as much as TeamB (priority constraint)
  // Create a proper BinaryPredicate function
  bool teamAPriority(dynamic a, dynamic b) => a >= b;
  p.addConstraint(['TeamA', 'TeamB'], teamAPriority);
  
  final solution = await p.getSolution();
  printResult(solution, successMessage: 'Resource allocation found!');
  
  if (solution is Map) {
    print('   Team A: ${solution['TeamA']} resources');
    print('   Team B: ${solution['TeamB']} resources');
    print('   Team C: ${solution['TeamC']} resources');
    print('   Total: ${solution['TeamA'] + solution['TeamB'] + solution['TeamC']} resources');
  }
}

// ====================================================================
// DEMO 11: Class Scheduling
// ====================================================================

Future<void> runSchedulingDemo() async {
  printHeader('Class Scheduling Problem');
  
  final p = Problem();
  
  // Time slots: 1=9AM, 2=10AM, 3=11AM, 4=1PM, 5=2PM
  final timeSlots = [1, 2, 3, 4, 5];
  
  // Classes to schedule
  p.addVariables(['Math', 'English', 'Science', 'History'], timeSlots);
  
  print('   Setting up scheduling constraints...');
  
  // All classes at different times
  p.addAllDifferent(['Math', 'English', 'Science', 'History']);
  
  // Math must be before lunch (slots 1-3)
  p.addInSet(['Math'], {1, 2, 3});
  
  // Science must be after lunch (slots 4-5)
  p.addInSet(['Science'], {4, 5});
  
  // English and History should be consecutive (for language block)
  p.addConstraint(['English', 'History'], (e, h) => (e - h).abs() == 1);
  
  final solution = await p.getSolution();
  printResult(solution, successMessage: 'Class schedule found!');
  
  if (solution is Map) {
    final timeMap = {1: '9AM', 2: '10AM', 3: '11AM', 4: '1PM', 5: '2PM'};
    print('   Schedule:');
    solution.forEach((subject, time) {
      print('   $subject: ${timeMap[time]}');
    });
  }
}

// ====================================================================
// Helper Functions
// ====================================================================

/// Helper to get a list of 9 variable names for a row, column, or block.
List<List<String>> getSudokuUnits() {
  final units = <List<String>>[];
  // Rows and Columns
  for (int i = 0; i < 9; i++) {
    final row = <String>[];
    final col = <String>[];
    for (int j = 0; j < 9; j++) {
      row.add('$i-$j');
      col.add('$j-$i');
    }
    units.add(row);
    units.add(col);
  }
  // 3x3 Blocks
  for (int br in [0, 3, 6]) {
    for (int bc in [0, 3, 6]) {
      final block = <String>[];
      for (int r = br; r < br + 3; r++) {
        for (int c = bc; c < bc + 3; c++) {
          block.add('$r-$c');
        }
      }
      units.add(block);
    }
  }
  return units;
}

/// Prints the final result of a CSP.
void printResult(dynamic solution, {String successMessage = ''}) {
  if (solution == 'FAILURE') {
    print('   >>> Status: FAILURE ❌');
  } else {
    print('   >>> Status: SUCCESS ✅');
    if (successMessage.isNotEmpty) print('   $successMessage');
    if (solution is Map && solution.length <= 6) {
      // Print small solutions directly
      print('   Solution: $solution');
    }
  }
}

/// Prints a solved N-Queens board.
void printQueensBoard(int size, Map solution) {
  print('\n   Queens Board:');
  final board = List.generate(size, (_) => List.filled(size, '.'));
  for (final pos in solution.values) {
    if (pos is List<int>) {
      board[pos[0]][pos[1]] = 'Q';
    }
  }
  for (final row in board) {
    print('   ${row.join(' ')}');
  }
}

/// Prints a solved Sudoku board.
void printSudokuBoard(Map solution) {
  const divider = '   |-------+-------+-------|';
  print('\n   Solved Sudoku:');
  print(divider);
  for (int r = 0; r < 9; r++) {
    String rowStr = '   | ';
    for (int c = 0; c < 9; c++) {
      rowStr += solution['$r-$c'].toString();
      rowStr += (c + 1) % 3 == 0 ? ' | ' : ' ';
    }
    print(rowStr);
    if ((r + 1) % 3 == 0) print(divider);
  }
}

/// Returns map of US states and their neighbors.
Map<String, List<String>> getUsaNeighbors() => {
      'WA': ['ID', 'OR'],
      'DE': ['MD', 'NJ', 'PA'],
      'DC': ['MD', 'VA'],
      'WI': ['IA', 'IL', 'MI', 'MN'],
      'WV': ['KY', 'MD', 'OH', 'PA', 'VA'],
      'FL': ['AL', 'GA'],
      'WY': ['CO', 'ID', 'MT', 'NE', 'SD', 'UT'],
      'NH': ['MA', 'ME', 'VT'],
      'NJ': ['DE', 'NY', 'PA'],
      'NM': ['AZ', 'CO', 'OK', 'TX', 'UT'],
      'TX': ['AR', 'LA', 'NM', 'OK'],
      'LA': ['AR', 'MS', 'TX'],
      'NC': ['GA', 'SC', 'TN', 'VA'],
      'ND': ['MN', 'MT', 'SD'],
      'NE': ['CO', 'IA', 'KS', 'MO', 'SD', 'WY'],
      'TN': ['AL', 'AR', 'GA', 'KY', 'MO', 'MS', 'NC', 'VA'],
      'NY': ['CT', 'MA', 'NJ', 'PA', 'VT'],
      'PA': ['DE', 'MD', 'NJ', 'NY', 'OH', 'WV'],
      'RI': ['CT', 'MA'],
      'NV': ['AZ', 'CA', 'ID', 'OR', 'UT'],
      'VA': ['DC', 'KY', 'MD', 'NC', 'TN', 'WV'],
      'CO': ['AZ', 'KS', 'NE', 'NM', 'OK', 'UT', 'WY'],
      'CA': ['AZ', 'NV', 'OR'],
      'AL': ['FL', 'GA', 'MS', 'TN'],
      'AR': ['LA', 'MO', 'MS', 'OK', 'TN', 'TX'],
      'VT': ['MA', 'NH', 'NY'],
      'IL': ['IA', 'IN', 'KY', 'MO', 'WI'],
      'GA': ['AL', 'FL', 'NC', 'SC', 'TN'],
      'IN': ['IL', 'KY', 'MI', 'OH'],
      'IA': ['MN', 'MO', 'NE', 'SD', 'WI', 'IL'],
      'MA': ['CT', 'NH', 'NY', 'RI', 'VT'],
      'AZ': ['CA', 'CO', 'NM', 'NV', 'UT'],
      'ID': ['MT', 'NV', 'OR', 'UT', 'WA', 'WY'],
      'CT': ['MA', 'NY', 'RI'],
      'ME': ['NH'],
      'MD': ['DC', 'DE', 'PA', 'VA', 'WV'],
      'OK': ['AR', 'CO', 'KS', 'MO', 'NM', 'TX'],
      'OH': ['IN', 'KY', 'MI', 'PA', 'WV'],
      'UT': ['AZ', 'CO', 'ID', 'NM', 'NV', 'WY'],
      'MO': ['AR', 'IA', 'IL', 'KS', 'KY', 'NE', 'OK', 'TN'],
      'MN': ['IA', 'ND', 'SD', 'WI'],
      'MI': ['IN', 'OH', 'WI'],
      'KS': ['CO', 'MO', 'NE', 'OK'],
      'MT': ['ID', 'ND', 'SD', 'WY'],
      'MS': ['AL', 'AR', 'LA', 'TN'],
      'SC': ['GA', 'NC'],
      'KY': ['IL', 'IN', 'MO', 'OH', 'TN', 'VA', 'WV'],
      'OR': ['CA', 'ID', 'NV', 'WA'],
      'SD': ['IA', 'MN', 'MT', 'ND', 'NE', 'WY'],
      'HI': [],
      'AK': []
    };