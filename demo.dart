// Import the CSP library. Ensure dart_csp.dart is in the same directory.
import 'dart:math';
import 'dart_csp.dart';

/// Main entry point for the demonstrations.
Future<void> main() async {
  await runMapColoringDemo();
  await runNQueensDemo();
  await runSudokuDemo();
}

/// Prints a formatted header to the console.
void printHeader(String title) {
  print('\n' + '─' * 50);
  print('─ Solving: $title');
  print('─' * 50);
}

// ====================================================================
// DEMO 1: USA Map Coloring
// ====================================================================

/// Runs the Map Coloring demo using both the old and new methods.
Future<void> runMapColoringDemo() async {
  printHeader('USA Map Coloring');
  const colors = ['red', 'green', 'blue', 'yellow'];
  final neighbors = getUsaNeighbors();

  // --- 1. The "Old Way" (Manual CspProblem construction) ---
  print('\n[1] Demonstrating the OLD WAY (Manual CspProblem)...');
  await solveMapColoringOldWay(colors, neighbors);

  // --- 2. The "New Way" (Using the Problem builder) ---
  print('\n[2] Demonstrating the NEW WAY (Problem Builder)...');
  await solveMapColoringNewWay(colors, neighbors);
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
  printResult(solution, successMessage: 'Solution found!');
}

Future<void> solveMapColoringNewWay(
    List<String> colors, Map<String, List<String>> neighbors) async {
  final p = Problem();
  final allStates = neighbors.keys.toList();

  // Add variables
  p.addVariables(allStates, colors);

  // Add constraints. The builder automatically handles symmetry.
  // Use a Set to avoid adding the same constraint twice (e.g., WA-ID and ID-WA).
  final addedConstraints = <String>{};
  for (final entry in neighbors.entries) {
    final state1 = entry.key;
    for (final state2 in entry.value) {
      final pair = [state1, state2]..sort();
      if (addedConstraints.add(pair.join('-'))) {
        p.addConstraint([state1, state2], (c1, c2) => c1 != c2);
      }
    }
  }

  final solution = await p.getSolution();
  printResult(solution, successMessage: 'Solution found!');
}


// ====================================================================
// DEMO 2: N-Queens Problem
// ====================================================================

/// Runs the N-Queens demo using both the old and new methods.
Future<void> runNQueensDemo() async {
  printHeader('8-Queens Problem');
  const size = 8;

  // --- 1. The "Old Way" ---
  print('\n[1] Demonstrating the OLD WAY (Manual CspProblem)...');
  await solveNQueensOldWay(size);

  // --- 2. The "New Way" ---
  print('\n[2] Demonstrating the NEW WAY (Problem Builder)...');
  await solveNQueensNewWay(size);
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

  printResult(solution, successMessage: 'Solution found!');
  if (solution is Map) printQueensBoard(size, solution);
}

Future<void> solveNQueensNewWay(int size) async {
  final p = Problem();

  // Add variables and their domains
  for (int i = 0; i < size; i++) {
    final domain = <List<int>>[];
    for (int j = 0; j < size; j++) {
      domain.add([i, j]);
    }
    p.addVariable(i.toString(), domain);
  }

  // Add constraints between every pair of queens (avoiding duplicates).
  for (int i = 0; i < size; i++) {
    for (int j = i + 1; j < size; j++) {
      p.addConstraint([i.toString(), j.toString()], notColliding);
    }
  }

  final solution = await p.getSolution();

  printResult(solution, successMessage: 'Solution found!');
  if (solution is Map) printQueensBoard(size, solution);
}


// ====================================================================
// DEMO 3: Sudoku
// ====================================================================

Future<void> runSudokuDemo() async {
  printHeader('Sudoku');
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

  // --- 1. The "Old Way" ---
  print('\n[1] Demonstrating the OLD WAY (Manual CspProblem)...');
  await solveSudokuOldWay(puzzle);

  // --- 2. The "New Way" ---
  print('\n[2] Demonstrating the NEW WAY (Problem Builder)...');
  await solveSudokuNewWay(puzzle);
}

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

Future<void> solveSudokuOldWay(List<List<int>> puzzle) async {
  final variables = <String, List<dynamic>>{};
  final constraints = <BinaryConstraint>[];
  final domain = List.generate(9, (i) => i + 1);

  // Populate variables
  for (int r = 0; r < 9; r++) {
    for (int c = 0; c < 9; c++) {
      final key = '$r-$c';
      if (puzzle[r][c] != 0) {
        variables[key] = [puzzle[r][c]];
      } else {
        variables[key] = domain;
      }
    }
  }

  // Populate binary "not-equal" constraints for all units (rows, cols, blocks)
  bool neq(dynamic v1, dynamic v2) => v1 != v2;
  for (final unit in getSudokuUnits()) {
    for (int i = 0; i < unit.length; i++) {
      for (int j = i + 1; j < unit.length; j++) {
        constraints.add(BinaryConstraint(unit[i], unit[j], neq));
        constraints.add(BinaryConstraint(unit[j], unit[i], neq));
      }
    }
  }

  final problem = CspProblem(variables: variables, constraints: constraints);
  final solution = await CSP.solve(problem);

  printResult(solution, successMessage: 'Solution found!');
  if (solution is Map) printSudokuBoard(solution);
}

Future<void> solveSudokuNewWay(List<List<int>> puzzle) async {
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

  // Add binary "not-equal" constraints for all units.
  // NOTE: A more efficient approach for Sudoku would be to use a single N-ARY
  // "all-different" constraint for each 9-cell unit. This is just to
  // demonstrate the binary constraint builder.
  for (final unit in getSudokuUnits()) {
    for (int i = 0; i < unit.length; i++) {
      for (int j = i + 1; j < unit.length; j++) {
        p.addConstraint([unit[i], unit[j]], (v1, v2) => v1 != v2);
      }
    }
  }

  final solution = await p.getSolution();
  printResult(solution, successMessage: 'Solution found!');
  if (solution is Map) printSudokuBoard(solution);
}

// ====================================================================
// Data and Print Helpers
// ====================================================================

/// Prints the final result of a CSP.
void printResult(dynamic solution, {String successMessage = ''}) {
  if (solution == 'FAILURE') {
    print('>>> Status: FAILURE');
  } else {
    print('>>> Status: SUCCESS');
    if (successMessage.isNotEmpty) print(successMessage);
    // print(solution); // Uncomment to see the raw solution map
  }
}

/// Prints a solved N-Queens board.
void printQueensBoard(int size, Map solution) {
  final board = List.generate(size, (_) => List.filled(size, '.'));
  for (final pos in solution.values) {
    if (pos is List<int>) {
      board[pos[0]][pos[1]] = 'Q';
    }
  }
  for (final row in board) {
    print(row.join(' '));
  }
}

/// Prints a solved Sudoku board.
void printSudokuBoard(Map solution) {
  const divider = '|-------+-------+-------|';
  print(divider);
  for (int r = 0; r < 9; r++) {
    String rowStr = '| ';
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