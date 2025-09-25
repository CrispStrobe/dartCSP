# dart_csp

[![Language: Dart](https://img.shields.io/badge/language-Dart-blue.svg)](https://dart.dev/)

A powerful, general-purpose library for modeling and solving Constraint Satisfaction Problems (CSPs) in Dart. Built with intelligent backtracking search, consistency-checking algorithms, and smart heuristics to efficiently solve complex logic puzzles.

> **Note**: This project is a port and enhancement of the excellent [csp.js](https://github.com/PrajitR/jusCSP) by Prajit Ramachandran, adapted for Dart's strong typing, async capabilities, and object-oriented structure. This also enables easy use with flutter projects.

## What is a Constraint Satisfaction Problem?

A CSP is a mathematical problem where you need to find values for variables that satisfy a set of constraints. Every CSP consists of three components:

| Component | Description | Example (Sudoku) |
|-----------|-------------|------------------|
| **Variables** | The unknowns you need to solve for | The 81 empty squares |
| **Domains** | Possible values each variable can take | Numbers 1-9 for each square |
| **Constraints** | Rules that restrict variable assignments | No repeats in rows/columns/blocks |

### Classic CSP Examples

- **Sudoku**: Variables are grid squares, domains are numbers 1-9, constraints prevent duplicates in rows/columns/blocks
- **Map Coloring**: Variables are regions, domains are colors, constraints prevent adjacent regions having the same color  
- **N-Queens**: Variables are queen positions, domains are board squares, constraints prevent queens attacking each other

## Features

This solver goes beyond brute-force search with a number of algorithms:

### Core Algorithms
- **Backtracking Search**: Intelligent depth-first search that backtracks when constraints are violated
- **AC-3 Algorithm**: Enforces arc consistency for binary constraints (two-variable rules)
- **Generalized Arc Consistency (GAC)**: Handles n-ary constraints (multi-variable rules)

### Smart Heuristics
- **Minimum Remaining Values (MRV)**: Chooses the most constrained variable to assign next
- **Least Constraining Value (LCV)**: Selects values that preserve the most options for other variables

### Developer Features
- **Visualization Hooks**: Step-by-step callback system for demos and debugging
- **Type Safety**: Full Dart type system integration
- **Async Support**: Non-blocking solving with `Future`-based API

## Quick Start

### 1. Installation

Add `dart_csp.dart` to your project('s `lib` directory) and import it:

```dart
import 'dart_csp.dart';
```

### 2. Define Your Problem

Create variables, domains, and constraints:

```dart
// Variables and their possible values
var variables = <String, List<dynamic>>{
  'A': [1, 2, 3],
  'B': [1, 2, 3, 4],
  'C': [3, 4, 5],
};

// Binary constraints (between two variables)
var binaryConstraints = <BinaryConstraint>[
  BinaryConstraint('A', 'B', (a, b) => a < b),
  BinaryConstraint('B', 'A', (b, a) => b > a), // Often need both directions
];

// N-ary constraints (multiple variables)
var naryConstraints = <NaryConstraint>[
  NaryConstraint(
    vars: ['A', 'B', 'C'],
    predicate: (assignment) => 
        assignment['A']! + assignment['B']! == assignment['C']!,
  ),
];

// Create the problem
final problem = CspProblem(
  variables: variables,
  constraints: binaryConstraints,
  naryConstraints: naryConstraints,
);
```

### 3. Solve the Problem

```dart
Future<void> main() async {
  print("Solving puzzle...");
  
  final solution = await CSP.solve(problem);
  
  if (solution is String) {
    print("No solution found: $solution");
  } else {
    print("Solution found!");
    solution.forEach((variable, value) {
      print("  $variable = $value");
    });
  }
}
```

## Advanced Usage

### Visualization and Debugging

Monitor the solver's progress with callbacks:

```dart
void visualizer(
  Map<String, List<dynamic>> assigned, 
  Map<String, List<dynamic>> unassigned
) {
  print("\n--- Solver Step ---");
  print("Assigned: $assigned");
  print("Unassigned Domains: $unassigned");
}

final visualProblem = CspProblem(
  variables: variables,
  naryConstraints: naryConstraints,
  cb: visualizer,     // Your callback function
  timeStep: 100,      // 100ms pause between steps
);

final solution = await CSP.solve(visualProblem);
```

### Real-World Example: Arithmetic Square Puzzle

Here's how the included arithmetic puzzle generator uses n-ary constraints:

```dart
class PuzzleGenerator {
  CspProblem buildPuzzleConstraints(
    Map<String, List<List<String>>> ops, 
    Map<String, int> clues
  ) {
    final variables = <String, List<dynamic>>{};
    final naryConstraints = <NaryConstraint>[];

    // 1. Define variables and domains
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        final cellId = '$r,$c';
        if (clues.containsKey(cellId)) {
          // Clue cells have fixed values
          variables[cellId] = [clues[cellId]];
        } else {
          // Empty cells can be any number in range
          variables[cellId] = List<int>.generate(
            maxNum - minNum + 1, 
            (i) => i + minNum
          );
        }
      }
    }

    // 2. Create row equation constraints
    for (int r = 0; r < gridSize; r++) {
      final rowVars = List<String>.generate(gridSize, (c) => '$r,$c');
      
      naryConstraints.add(NaryConstraint(
        vars: rowVars,
        predicate: (assignment) {
          final values = rowVars.map((v) => assignment[v]!).toList();
          final operands = values.sublist(0, gridSize - 1);
          final result = values.last;
          return evaluate(operands, ops['rows']![r]) == result;
        },
      ));
    }

    // 3. Create column equation constraints (similar to rows)
    // ... 

    return CspProblem(
      variables: variables, 
      naryConstraints: naryConstraints
    );
  }

  Future<void> solve() async {
    final puzzle = buildPuzzleConstraints(operators, clues);
    final solution = await CSP.solve(puzzle);
    
    if (solution != 'FAILURE') {
      print("✅ Solution found!");
      displaySolution(solution);
    } else {
      print("❌ No solution exists");
    }
  }
}
```

## API Reference

### CspProblem Class

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `variables` | `Map<String, List<dynamic>>` | ✅ | Variable names mapped to their domains |
| `constraints` | `List<BinaryConstraint>` | ❌ | Rules between pairs of variables |
| `naryConstraints` | `List<NaryConstraint>` | ❌ | Rules among groups of variables |
| `cb` | `CspCallback?` | ❌ | Visualization callback function |
| `timeStep` | `int` | ❌ | Delay in ms between visualization steps |

### Constraint Classes

#### BinaryConstraint
```dart
BinaryConstraint(
  String head,                           // First variable
  String tail,                           // Second variable  
  bool Function(dynamic, dynamic) predicate  // Validation function
)
```

#### NaryConstraint  
```dart
NaryConstraint({
  required List<String> vars,                        // All involved variables
  required bool Function(Map<String, dynamic>) predicate  // Validation function
})
```

### Solver Method

```dart
static Future<dynamic> CSP.solve(CspProblem problem)
```

**Returns**: `Future<Map<String, dynamic>>` on success, `Future<String>` ("FAILURE") if no solution exists.

## Performance Tips

1. **Use MRV heuristic**: The solver automatically picks the most constrained variable first
2. **Define bidirectional constraints**: For binary constraints, often define both `(A,B)` and `(B,A)` directions  
3. **Minimize domain sizes**: Smaller domains lead to faster solving
4. **Group related constraints**: Use n-ary constraints for rules involving multiple variables instead of many binary constraints

## Contributing

Contributions are welcome! This library builds upon the excellent foundation of [csp.js](https://github.com/PrajitR/jusCSP) by Prajit Ramachandran.

## License

MIT License - see LICENSE file for details.

---

*Built with ❤️ for the Dart community*