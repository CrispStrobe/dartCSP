# dart_csp

[![Language: Dart](https://img.shields.io/badge/language-Dart-blue.svg)](https://dart.dev/)

A powerful, general-purpose library for modeling and solving Constraint Satisfaction Problems (CSPs) in Dart. Built with intelligent backtracking search, consistency-checking algorithms, and smart heuristics to efficiently solve complex logic puzzles.

This library offers **two ways to define your problem**: a high-level **Problem builder** for fast and intuitive development, and a manual **CspProblem class** for direct control over the underlying structure.

> **Note**: This project is a port and enhancement of the excellent [csp.js](https://github.com/PrajitR/jusCSP) by Prajit Ramachandran, adapted for Dart's strong typing, async capabilities, and object-oriented structure. This also enables easy use with Flutter projects.

## What is a Constraint Satisfaction Problem?

A CSP is a mathematical problem where you need to find values for variables that satisfy a set of constraints. Every CSP consists of three components:

| Component | Description | Example (Sudoku) |
|-----------|-------------|------------------|
| **Variables** | The unknowns you need to solve for | The 81 empty squares |
| **Domains** | Possible values each variable can take | Numbers 1-9 for each square |
| **Constraints** | Rules that restrict variable assignments | No repeats in rows/columns/blocks |

### Classic CSP Examples

- **Sudoku**: Variables are grid squares, domains are numbers 1-9, constraints prevent duplicates in rows/columns/blocks
- **Map Coloring**: Variables are regions, domains are colors, constraints prevent adjacent regions from having the same color  
- **N-Queens**: Variables are queen positions, domains are board squares, constraints prevent queens from attacking each other

## Features

This solver goes beyond brute-force search with the following implemented algorithms:

### Core Algorithms
- **Backtracking Search**: Intelligent depth-first search that backtracks when constraints are violated
- **AC-3 Algorithm**: Enforces arc consistency for binary constraints (two-variable rules)
- **Generalized Arc Consistency (GAC)**: Handles n-ary constraints (multi-variable rules)

### Smart Heuristics
- **Minimum Remaining Values (MRV)**: Chooses the most constrained variable to assign next ("fail-first" principle)
- **Least Constraining Value (LCV)**: Selects values that preserve the most options for other variables

### Developer Features
- **Fluent Builder API**: An intuitive Problem class to easily define your CSP
- **Visualization Hooks**: Step-by-step callback system for demos and debugging
- **Type Safety**: Full Dart type system integration
- **Async Support**: Non-blocking solving with `Future`-based API

## How to Use dart_csp

### 1. Installation

Add `dart_csp.dart` to your project (e.g., in your `lib` directory) and import it:

```dart
import 'dart_csp.dart';
```

### 2. Define Your Problem

You have two ways to define a CSP. The builder is recommended for most use cases.

#### Method 1: The Problem Builder (Recommended)

The Problem class provides a clean, step-by-step builder pattern. It simplifies the process and automatically handles details like constraint symmetry.

```dart
// 1. Create a new Problem instance
final p = Problem();

// 2. Add variables and their domains
const colors = ['red', 'green', 'blue'];
p.addVariables(['WA', 'NT', 'SA'], colors);
p.addVariable('Q', ['red', 'green']); // You can also add one at a time

// 3. Add constraints using intuitive predicates
// The builder automatically creates constraints for both directions (SA->WA and WA->SA)
p.addConstraint(['SA', 'WA'], (sa, wa) => sa != wa);
p.addConstraint(['SA', 'NT'], (sa, nt) => sa != nt);

// N-ary constraints are also simple
p.addConstraint(
  ['WA', 'NT', 'SA'],
  (assignment) => assignment['WA'] != 'red' || assignment['NT'] != 'green'
);

// 4. Solve it!
final solution = await p.getSolution();
```

#### Method 2: Manual CspProblem Construction

This method gives you direct access to the underlying data structures. It's useful if you are generating the problem components programmatically.

```dart
// 1. Define variables and domains
var variables = <String, List<dynamic>>{
  'A': [1, 2, 3],
  'B': [1, 2, 3, 4],
  'C': [3, 4, 5],
};

// 2. Define constraints
var binaryConstraints = <BinaryConstraint>[
  // For full consistency, you must add constraints for both directions manually
  BinaryConstraint('A', 'B', (a, b) => a < b),
  BinaryConstraint('B', 'A', (b, a) => b > a),
];

var naryConstraints = <NaryConstraint>[
  NaryConstraint(
    vars: ['A', 'B', 'C'],
    predicate: (assignment) =>
        assignment['A']! + assignment['B']! == assignment['C']!,
  ),
];

// 3. Create the problem object
final problem = CspProblem(
  variables: variables,
  constraints: binaryConstraints,
  naryConstraints: naryConstraints,
);

// 4. Solve it!
final solution = await CSP.solve(problem);
```

### 3. Handle the Solution

The solver returns a Future that resolves to either a solution Map or the string "FAILURE".

```dart
Future<void> main() async {
  final p = Problem();
  // ... define your problem here ...

  print("Solving puzzle...");
  final solution = await p.getSolution(); // Or await CSP.solve(problem);

  if (solution is String) {
    print("No solution found: $solution");
  } else if (solution is Map) {
    print("Solution found! 🎉");
    solution.forEach((variable, value) {
      print("  $variable = $value");
    });
  }
}
```

## Advanced Usage

## Advanced Usage

### Visualization and Debugging

You can monitor the solver's progress with a callback function. This is supported by both the Problem builder and the manual CspProblem.

```dart
// Define a callback function to print the solver's state at each step
void visualizer(
  Map<String, List<dynamic>> assigned,
  Map<String, List<dynamic>> unassigned,
) {
  print("\n--- Solver Step ---");
  print("Assigned: $assigned");
  print("Unassigned Domains: $unassigned");
}

// Using the Problem builder
final p = Problem();
// ... add variables and constraints ...
p.setOptions(
  timeStep: 100, // 100ms pause between steps
  callback: visualizer,
);
final solution = await p.getSolution();

// Or, using the manual method
final visualProblem = CspProblem(
  variables: variables,
  constraints: constraints,
  cb: visualizer,
  timeStep: 100,
);
final solution = await CSP.solve(visualProblem);
```

### Real-World Example: Arithmetic Square Puzzle

Here's a side-by-side comparison of how the included arithmetic puzzle generator can be implemented using both methods.

#### Using the Problem Builder (New Way)

```dart
class PuzzleGenerator {
  Problem buildPuzzleConstraintsNewWay(Map<String, int> clues) {
    final p = Problem();

    // 1. Add variables and their domains
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        final cellId = '$r,$c';
        p.addVariable(
          cellId,
          clues.containsKey(cellId) ? [clues[cellId]!] : fullDomain,
        );
      }
    }

    // 2. Add n-ary constraints for each row and column equation
    for (int r = 0; r < gridSize; r++) {
      final rowVars = List<String>.generate(gridSize, (c) => '$r,$c');
      p.addConstraint(rowVars, (assignment) {
        // ... predicate logic to check if the equation is valid ...
        final values = rowVars.map((v) => assignment[v]!).toList();
        final operands = values.sublist(0, gridSize - 1);
        final result = values.last;
        return evaluate(operands, ops['rows']![r]) == result;
      });
    }
    // ... similar loop for columns ...

    return p;
  }
}
```

#### Using Manual Construction (Old Way)

```dart
class PuzzleGenerator {
  CspProblem buildPuzzleConstraintsOldWay(Map<String, int> clues) {
    final variables = <String, List<dynamic>>{};
    final naryConstraints = <NaryConstraint>[];

    // 1. Define variables and domains
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        final cellId = '$r,$c';
        if (clues.containsKey(cellId)) {
          variables[cellId] = [clues[cellId]];
        } else {
          variables[cellId] = List<int>.generate(
            maxNum - minNum + 1, 
            (i) => i + minNum
          );
        }
      }
    }

    // 2. Create n-ary constraints for each row and column equation
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
    // ... similar loop for columns ...

    return CspProblem(variables: variables, naryConstraints: naryConstraints);
  }
}
```

## API Reference

### Problem Class (Builder)

The recommended way to define a CSP using a fluent builder pattern.

| Method | Parameters | Description |
|--------|------------|-------------|
| `addVariable()` | `String name`, `List<dynamic> domain` | Adds a single variable and its domain |
| `addVariables()` | `List<String> names`, `List<dynamic> domain` | Adds multiple variables that share the same domain |
| `addConstraint()` | `List<String> vars`, `Function predicate` | Adds a binary or n-ary constraint based on the number of variables |
| `setOptions()` | `int? timeStep`, `CspCallback? callback` | Sets optional parameters for visualization |
| `getSolution()` | (none) | Builds and solves the problem, returning a Future |

#### Constraint Types in Problem Builder

The `addConstraint()` method automatically determines the constraint type:

- **For 2 variables**: Expects a `bool Function(dynamic, dynamic)` predicate. The builder automatically creates bidirectional constraints for full consistency.
- **For 1, 3+ variables**: Expects a `bool Function(Map<String, dynamic>)` predicate for n-ary constraints.

```dart
// Binary constraint (automatic bidirectional)
p.addConstraint(['A', 'B'], (a, b) => a != b);

// N-ary constraint  
p.addConstraint(['A', 'B', 'C'], (assignment) => 
    assignment['A']! + assignment['B']! == assignment['C']!);
```

### CspProblem Class (Core Definition)

The underlying data structure for a CSP when using manual construction.

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

1. **Use the MRV Heuristic**: The solver automatically picks the most constrained variable first, which is a highly effective strategy
2. **Handle Bidirectional Constraints**: For binary rules like A != B, consistency must be checked both ways. The Problem builder does this automatically. If building a CspProblem manually, remember to add constraints for both (A,B) and (B,A)
3. **Minimize Domain Sizes**: The smaller the initial domains, the faster the search space can be pruned
4. **Prefer N-ary Constraints**: For rules involving many variables (like Sudoku's "all-different" rule), a single n-ary constraint is often more efficient than dozens of binary constraints

## Contributing

Contributions are welcome! This library builds upon the excellent foundation of [csp.js](https://github.com/PrajitR/jusCSP) by Prajit Ramachandran.

## License

MIT License - see LICENSE file for details.

---

*Built with ❤️ for the Dart & Flutter community*