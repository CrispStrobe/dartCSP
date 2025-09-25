/// A command-line application that generates and solves "arithmetic square" puzzles.
///
/// An arithmetic square is a grid of numbers where each row and column forms
/// a valid mathematical equation. This program randomly generates the operators
/// and a few initial numbers (clues), then models the puzzle as a
/// Constraint Satisfaction Problem (CSP) and uses a generic CSP solver to find
/// a valid solution for the remaining empty cells.
///
/// Usage: dart gencw.dart [options]
///
/// Options:
///   --size=<N>        Sets the grid size to N x N (default: 3).
///   --range=<min-max> Sets the range of numbers for cells (default: 1-20).
///   --ops=<op1,op2>   Specifies allowed operators (+,-,*,/) (default: all).
///   --clues=<N>       Sets the number of initial clues (default: auto).
///   verbose           Enables detailed logging of the generation process.

import 'dart:io';
import 'dart:math';
import 'dart_csp.dart';

// ------------------- Configuration & Argument Parsing -------------------

/// A data class to hold the configuration settings for puzzle generation.
class PuzzleConfig {
  /// The size of the N x N grid.
  int gridN;
  /// The minimum possible value for a number in a cell.
  int minN;
  /// The maximum possible value for a number in a cell.
  int maxN;
  /// The list of mathematical operators allowed in the puzzle.
  List<String> ops;
  /// The maximum number of attempts to generate a solvable puzzle layout.
  int maxAttempts;
  /// The desired number of pre-filled cells (clues) in the puzzle.
  int numClues;
  /// A flag to enable or disable verbose logging.
  bool verbose;

  PuzzleConfig({
    this.gridN = 3,
    this.minN = 1,
    this.maxN = 20,
    this.ops = const ['+', '−', '×', '÷'],
    this.maxAttempts = 250,
    this.numClues = 0,
    this.verbose = false,
  });
}

/// Parses command-line arguments to create a [PuzzleConfig] object.
///
/// This function provides default values and overrides them with any valid
/// arguments supplied by the user.
PuzzleConfig parseArgs(List<String> args) {
  final config = PuzzleConfig();
  bool cluesManuallySet = false;

  for (final arg in args) {
    if (arg == 'verbose') {
      config.verbose = true;
      continue;
    }
    if (arg.startsWith('--')) {
      final parts = arg.substring(2).split('=');
      if (parts.length != 2) continue;
      final key = parts[0];
      final value = parts[1];

      switch (key) {
        case 'size':
          final size = int.tryParse(value);
          if (size != null && size >= 3) {
            config.gridN = size;
          }
          break;
        case 'range':
          final rangeParts = value.split('-');
          if (rangeParts.length == 2) {
            final min = int.tryParse(rangeParts[0]);
            final max = int.tryParse(rangeParts[1]);
            if (min != null && max != null && min < max) {
              config.minN = min;
              config.maxN = max;
            }
          }
          break;
        case 'ops':
          const opMap = {'-': '−', '*': '×', '/': '÷'};
          const validOps = {'+', '−', '×', '÷'};
          final userOps = value
              .split(',')
              .map((op) => op.trim())
              .map((op) => opMap[op] ?? op)
              .where((op) => validOps.contains(op))
              .toList();
          if (userOps.isNotEmpty) {
            config.ops = userOps;
          }
          break;
        case 'clues':
          final clues = int.tryParse(value);
          if (clues != null && clues >= 0) {
            config.numClues = clues;
            cluesManuallySet = true;
          }
          break;
      }
    }
  }

  // If the grid is larger than 3x3 and clues haven't been set manually,
  // provide a sensible default number of clues.
  if (config.gridN > 3 && !cluesManuallySet) {
    config.numClues = (config.gridN / 2).floor();
  }
  return config;
}

// ------------------- Main Application Logic -------------------

/// The main entry point of the application.
void main(List<String> args) async {
  final config = parseArgs(args);
  final puzzleGenerator = PuzzleGenerator(config);
  await puzzleGenerator.generate();
}

/// The main class responsible for the puzzle generation and solving process.
class PuzzleGenerator {
  final PuzzleConfig config;
  final Random _random = Random();

  PuzzleGenerator(this.config);

  /// Prints a message to the console only if verbose mode is enabled.
  void log(String message) {
    if (config.verbose) {
      print(message);
    }
  }

  // ------------------- Utility Methods -------------------

  /// Generates a random integer within a specified range (inclusive).
  int randInt(int a, int b) => a + _random.nextInt(b - a + 1);

  /// Selects a random element from a list.
  T randChoice<T>(List<T> arr) => arr[_random.nextInt(arr.length)];

  /// Creates a unique string identifier for a cell at a given row and column.
  String id(int r, int c) => 'r${r}c${c}';

  /// Creates a unique string identifier for an operator.
  String opId(int? r, int? c, String type, [int index = 0]) {
    if (type == 'row') return 'op_r${r}_i$index';
    if (type == 'col') return 'op_c${c}_i$index';
    return '';
  }

  /// Evaluates a mathematical expression from left to right.
  ///
  /// For example, `evaluate([10, 5, 3], ['-', '+'])` would compute `10 - 5 + 3 = 8`.
  /// Returns `null` if the operation is invalid (e.g., division by zero).
  int? evaluate(List<dynamic> operands, List<String> ops) {
    // Ensure all operands are valid numbers before proceeding.
    if (operands.any((op) => op == null) || operands.length != ops.length + 1) {
      return null;
    }

    int currentVal = operands[0] as int;
    for (int i = 0; i < ops.length; i++) {
      final op = ops[i];
      final nextVal = operands[i + 1] as int;
      switch (op) {
        case '+':
          currentVal += nextVal;
          break;
        case '−':
          currentVal -= nextVal;
          break;
        case '×':
          currentVal *= nextVal;
          break;
        case '÷':
          // Division is only valid if the divisor is non-zero and the result is an integer.
          if (nextVal == 0 || currentVal % nextVal != 0) return null;
          currentVal ~/= nextVal; // Use integer division.
          break;
        default:
          return null; // Invalid operator.
      }
    }
    return currentVal;
  }

  // ------------------- CSP Modeling and Grid Display -------------------

  /// Models the arithmetic puzzle as a [CspProblem].
  ///
  /// This is the core translation step. It defines:
  /// - **Variables**: Each cell in the grid becomes a CSP variable (e.g., 'r0c0').
  /// - **Domains**: The domain for each variable is the range of allowed numbers.
  ///   If a cell is a clue, its domain is just that single value.
  /// - **Constraints**: Each row and column equation becomes an n-ary constraint
  ///   that involves all cells in that row/column.
  CspProblem buildPuzzleConstraints(
      Map<String, List<List<String>>> ops, Map<String, int> clues) {
    final variables = <String, List<dynamic>>{};
    final naryConstraints = <NaryConstraint>[];

    // Define the variables and their initial domains.
    for (int r = 0; r < config.gridN; r++) {
      for (int c = 0; c < config.gridN; c++) {
        final cellId = id(r, c);
        if (clues.containsKey(cellId)) {
          // If the cell is a clue, its domain contains only that one value.
          variables[cellId] = [clues[cellId]];
        } else {
          // Otherwise, its domain is the full range of allowed numbers.
          variables[cellId] = List<int>.generate(
              config.maxN - config.minN + 1, (i) => i + config.minN);
        }
      }
    }

    // Create an n-ary constraint for each row equation.
    // For a 4x4 grid, a row constraint involves 'r0c0', 'r0c1', 'r0c2', 'r0c3'
    // and checks if `evaluate([val0, val1, val2], [op1, op2]) == val3`.
    for (int r = 0; r < config.gridN; r++) {
      final rowVars = List<String>.generate(config.gridN, (c) => id(r, c));
      naryConstraints.add(NaryConstraint(
        vars: rowVars,
        predicate: (assign) {
          final values = rowVars.map((v) => assign[v]).toList();
          final operands = values.sublist(0, config.gridN - 1);
          final result = values.last;
          if (operands.any((op) => op == null) || result == null) return false;
          return evaluate(operands, ops['rows']![r]) == result;
        },
      ));
    }

    // Create an n-ary constraint for each column equation.
    for (int c = 0; c < config.gridN; c++) {
      final colVars = List<String>.generate(config.gridN, (r) => id(r, c));
      naryConstraints.add(NaryConstraint(
        vars: colVars,
        predicate: (assign) {
          final values = colVars.map((v) => assign[v]).toList();
          final operands = values.sublist(0, config.gridN - 1);
          final result = values.last;
          if (operands.any((op) => op == null) || result == null) return false;
          return evaluate(operands, ops['cols']![c]) == result;
        },
      ));
    }

    return CspProblem(
        variables: variables, naryConstraints: naryConstraints);
  }

  /// Formats a grid solution or puzzle skeleton into a readable ASCII string.
  String asciiGrid(
      Map<String, dynamic> solution, Map<String, String> ops, int n) {
    final buffer = StringBuffer();
    final hLine = '+' + ('-' * (n * 4 + (n - 1) * 3)) + '+\n';
    buffer.write(hLine);
    for (int r = 0; r < n; r++) {
      buffer.write('|');
      for (int c = 0; c < n; c++) {
        final valStr = solution[id(r, c)]?.toString() ?? '?';
        buffer.write(valStr.padLeft(4, ' '));
        if (c < n - 2) {
          buffer.write(' ${ops[opId(r, null, 'row', c)]} ');
        } else if (c == n - 2) {
          buffer.write(' = ');
        }
      }
      buffer.write(' |\n');
      if (r < n - 1) {
        buffer.write('|');
        for (int c = 0; c < n; c++) {
          final op = (r < n - 2) ? ops[opId(null, c, 'col', r)] : '=';
          buffer.write('  $op ');
          if (c < n - 1) buffer.write('   ');
        }
        buffer.write(' |\n');
      }
    }
    buffer.write(hLine);
    return buffer.toString();
  }

  // ------------------- Main Generation Loop -------------------

  /// The main loop that attempts to generate a solvable puzzle.
  ///
  /// This method repeatedly generates random layouts of operators and clues,
  /// models them as a CSP, and attempts to solve them. It stops when a solvable
  /// layout is found or the maximum number of attempts is reached.
  Future<void> generate() async {
    print('\n--- Generating ${config.gridN}x${config.gridN} Puzzle ---');
    print(
        '(Range: ${config.minN}-${config.maxN}, Ops: [${config.ops.join(', ')}])');
    if (config.numClues > 0) {
      print('(Seeding with up to ${config.numClues} random clues)');
    }

    for (int attempt = 1; attempt <= config.maxAttempts; attempt++) {
      print('\n--- Attempt $attempt/${config.maxAttempts} ---');

      // Step 1: Randomly generate operators for each row and column.
      final opLayout = {'rows': <List<String>>[], 'cols': <List<String>>[]};
      final opDetails = <String, String>{};
      for (int r = 0; r < config.gridN; r++) {
        final ops =
            List.generate(config.gridN - 2, (_) => randChoice(config.ops));
        opLayout['rows']!.add(ops);
        ops.asMap().forEach((i, op) => opDetails[opId(r, null, 'row', i)] = op);
      }
      for (int c = 0; c < config.gridN; c++) {
        final ops =
            List.generate(config.gridN - 2, (_) => randChoice(config.ops));
        opLayout['cols']!.add(ops);
        ops.asMap().forEach((i, op) => opDetails[opId(null, c, 'col', i)] = op);
      }

      // Step 2: Determine forbidden clue locations. For an equation `A / B = C`,
      // `B` is a divisor. Placing a clue at `B` can excessively constrain the
      // puzzle, often making it unsolvable. We forbid placing clues there.
      final forbiddenClueCells = <String>{};
      opLayout['rows']!.asMap().forEach((r, rowOps) {
        rowOps.asMap().forEach((i, op) {
          if (op == '÷') forbiddenClueCells.add(id(r, i + 1));
        });
      });
      opLayout['cols']!.asMap().forEach((c, colOps) {
        colOps.asMap().forEach((i, op) {
          if (op == '÷') forbiddenClueCells.add(id(i + 1, c));
        });
      });
      log('Forbidden clue locations: ${forbiddenClueCells.join(', ')}');

      // Step 3: Randomly generate clues in valid locations.
      final clues = <String, int>{};
      final allCells = [
        for (int r = 0; r < config.gridN; r++)
          for (int c = 0; c < config.gridN; c++) id(r, c)
      ];
      final validClueCells = allCells
          .where((cellId) => !forbiddenClueCells.contains(cellId))
          .toList()
        ..shuffle(_random);

      final numCluesToPlace = min(config.numClues, validClueCells.length);
      for (int i = 0; i < numCluesToPlace; i++) {
        clues[validClueCells[i]] = randInt(config.minN, config.maxN);
      }

      // Step 4: Display the generated puzzle skeleton.
      print(asciiGrid(clues, opDetails, config.gridN));

      // Step 5: Model and attempt to solve the puzzle.
      print("Solving...");
      final prob = buildPuzzleConstraints(opLayout, clues);
      final solution = await CSP.solve(prob);

      // Step 6: Report the outcome.
      if (solution != 'FAILURE') {
        print("\n✅ SUCCESS! Found a solution for the layout above:");
        print(asciiGrid(solution, opDetails, config.gridN));
        return; // Exit successfully.
      } else {
        print("❌ Failed to solve. Generating new layout.");
      }
    }
    print(
        '\n--- FAILED to find a solvable layout in ${config.maxAttempts} attempts. ---');
  }
}

