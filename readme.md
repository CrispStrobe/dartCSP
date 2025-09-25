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

### Built-in Constraint Library
- **20+ Pre-built Constraints**: Common constraint patterns like `allDifferent()`, `exactSum()`, `ascending()`, etc.
- **Optimized Performance**: Built-in constraints are faster than equivalent lambda functions
- **Extension Methods**: Fluent API methods like `addAllDifferent()` for cleaner code

### Developer Features
- **Fluent Builder API**: An intuitive Problem class to easily define your CSP
- **Comprehensive Demo**: Complete examples showing all constraint types and problem-solving techniques
- **Visualization Hooks**: Step-by-step callback system for demos and debugging
- **Type Safety**: Full Dart type system integration
- **Async Support**: Non-blocking solving with `Future`-based API

## Quick Start

### 1. Installation

Add `dart_csp.dart` to your project (e.g., in your `lib` directory) and import it:

```dart
import 'dart_csp.dart';
```

### 2. Your First Problem - Map Coloring

```dart
Future<void> main() async {
  final p = Problem();
  
  // Variables: Australian states, Domain: Colors
  p.addVariables(['WA', 'NT', 'SA', 'Q', 'NSW', 'V'], ['red', 'green', 'blue']);
  
  // Constraints: Adjacent states must have different colors
  p.addAllDifferent(['SA', 'WA']); // Using built-in constraint
  p.addAllDifferent(['SA', 'NT']);
  p.addAllDifferent(['SA', 'Q']);
  // ... more constraints
  
  final solution = await p.getSolution();
  print(solution); // {WA: red, NT: blue, SA: green, ...}
}
```

### 3. Run the Comprehensive Demo

The library includes a complete demo showcasing all features:

```bash
dart run demo.dart
```

This runs 11 different constraint satisfaction problems demonstrating:
- USA Map Coloring
- N-Queens Problem  
- Sudoku Solving
- Magic Square Generation
- Resource Allocation
- Class Scheduling
- And more!

## How to Use dart_csp

### Method 1: The Problem Builder (Recommended)

The Problem class provides a clean, step-by-step builder pattern with built-in constraints.

```dart
final p = Problem();

// 1. Add variables and domains
p.addVariables(['A', 'B', 'C'], [1, 2, 3, 4, 5]);

// 2. Use built-in constraints (recommended)
p.addAllDifferent(['A', 'B', 'C']);      // All different values
p.addExactSum(['A', 'B'], 7);            // A + B = 7
p.addAscending(['A', 'B', 'C']);         // A ≤ B ≤ C

// 3. Or define custom constraints
p.addConstraint(['A', 'B'], (a, b) => a * b <= 10);

// 4. Solve
final solution = await p.getSolution();
```

### Method 2: Manual CspProblem Construction

Direct access to underlying data structures for programmatic generation.

```dart
var variables = <String, List<dynamic>>{
  'A': [1, 2, 3],
  'B': [1, 2, 3, 4],
  'C': [3, 4, 5],
};

var binaryConstraints = <BinaryConstraint>[
  BinaryConstraint('A', 'B', (a, b) => a < b),
  BinaryConstraint('B', 'A', (b, a) => b > a),
];

final problem = CspProblem(
  variables: variables,
  constraints: binaryConstraints,
);

final solution = await CSP.solve(problem);
```

## Built-in Constraint Library

The library provides optimized, reusable constraint functions for common patterns:

### Equality/Inequality Constraints

```dart
// All variables must have different values
p.addAllDifferent(['A', 'B', 'C', 'D']);

// All variables must have the same value  
p.addAllEqual(['X', 'Y', 'Z']);
```

### Arithmetic Constraints

```dart
// Sum constraints
p.addExactSum(['A', 'B', 'C'], 15);           // A + B + C = 15
p.addSumRange(['A', 'B'], 5, 10);             // 5 ≤ A + B ≤ 10

// Weighted sums
p.addExactSum(['A', 'B'], 20, multipliers: [3, 4]); // 3*A + 4*B = 20

// Product constraints  
p.addExactProduct(['X', 'Y'], 12);            // X * Y = 12
p.addConstraint(['A', 'B', 'C'], minProduct(8));     // A * B * C ≥ 8
```

### Set Membership Constraints

```dart
// Variables must be from allowed set
p.addInSet(['A', 'B'], {2, 3, 5, 7});        // Only prime numbers

// Variables cannot be from forbidden set
p.addNotInSet(['X', 'Y'], {2, 4, 6});        // No even numbers

// At least N variables must be from set
p.addConstraint(['A', 'B', 'C'], someInSet({1, 3, 5}, 2)); // ≥2 odd numbers
```

### Ordering Constraints

```dart
// Ordering (preserves variable sequence)
p.addAscending(['A', 'B', 'C']);             // A ≤ B ≤ C
p.addStrictlyAscending(['X', 'Y', 'Z']);     // X < Y < Z  
p.addDescending(['P', 'Q', 'R']);            // P ≥ Q ≥ R
```

### Using Factory Functions Directly

You can also use the constraint factory functions directly:

```dart
// Using factory functions with addConstraint()
p.addConstraint(['A', 'B', 'C'], allDifferent());
p.addConstraint(['X', 'Y'], exactSumBinary(10)); // For 2 variables, more efficient

// Custom combinations
p.addConstraint(['A', 'B', 'C'], (assignment) {
  // Custom logic combining multiple constraint types
  return allDifferent()(assignment) && exactSum(12)(assignment);
});
```

## Real-World Examples

### Sudoku Solver

```dart
Future<void> solveSudoku(List<List<int>> puzzle) async {
  final p = Problem();
  
  // Add variables for each cell
  for (int r = 0; r < 9; r++) {
    for (int c = 0; c < 9; c++) {
      final key = '$r-$c';
      if (puzzle[r][c] != 0) {
        p.addVariable(key, [puzzle[r][c]]);  // Clue
      } else {
        p.addVariable(key, [1, 2, 3, 4, 5, 6, 7, 8, 9]);  // Empty cell
      }
    }
  }
  
  // Row constraints (all different)
  for (int r = 0; r < 9; r++) {
    final row = List.generate(9, (c) => '$r-$c');
    p.addAllDifferent(row);
  }
  
  // Column constraints
  for (int c = 0; c < 9; c++) {
    final col = List.generate(9, (r) => '$r-$c');
    p.addAllDifferent(col);
  }
  
  // 3x3 block constraints
  for (int br in [0, 3, 6]) {
    for (int bc in [0, 3, 6]) {
      final block = <String>[];
      for (int r = br; r < br + 3; r++) {
        for (int c = bc; c < bc + 3; c++) {
          block.add('$r-$c');
        }
      }
      p.addAllDifferent(block);
    }
  }
  
  final solution = await p.getSolution();
  // Print solved puzzle...
}
```

### Magic Square Generator

```dart
Future<void> generateMagicSquare() async {
  final p = Problem();
  
  // 3x3 grid with numbers 1-9
  final positions = ['00', '01', '02', '10', '11', '12', '20', '21', '22'];
  p.addVariables(positions, [1, 2, 3, 4, 5, 6, 7, 8, 9]);
  
  // Each number appears exactly once
  p.addAllDifferent(positions);
  
  // All rows sum to 15
  p.addExactSum(['00', '01', '02'], 15);
  p.addExactSum(['10', '11', '12'], 15);  
  p.addExactSum(['20', '21', '22'], 15);
  
  // All columns sum to 15
  p.addExactSum(['00', '10', '20'], 15);
  p.addExactSum(['01', '11', '21'], 15);
  p.addExactSum(['02', '12', '22'], 15);
  
  // Diagonals sum to 15
  p.addExactSum(['00', '11', '22'], 15);
  p.addExactSum(['02', '11', '20'], 15);
  
  final solution = await p.getSolution();
  // Display magic square...
}
```

### Resource Allocation

```dart
Future<void> allocateResources() async {
  final p = Problem();
  
  // Teams get 3-10 resources each  
  p.addVariables(['TeamA', 'TeamB', 'TeamC'], [3, 4, 5, 6, 7, 8, 9, 10]);
  
  // Total budget constraint
  p.addExactSum(['TeamA', 'TeamB', 'TeamC'], 20);
  
  // Priority: TeamA gets at least as much as TeamB
  p.addConstraint(['TeamA', 'TeamB'], (a, b) => a >= b);
  
  final solution = await p.getSolution();
  print('Team A: ${solution['TeamA']} resources');
  print('Team B: ${solution['TeamB']} resources'); 
  print('Team C: ${solution['TeamC']} resources');
}
```

## Advanced Usage

### Visualization and Debugging

Monitor the solver's progress with callback functions:

```dart
void visualizer(
  Map<String, List<dynamic>> assigned,
  Map<String, List<dynamic>> unassigned,
) {
  print("\n--- Solver Step ---");
  print("Assigned: $assigned");
  print("Unassigned Domains: $unassigned");
}

final p = Problem();
// ... define problem ...
p.setOptions(
  timeStep: 100, // 100ms pause between steps
  callback: visualizer,
);

final solution = await p.getSolution();
```

### Performance Optimization

1. **Use Built-in Constraints**: `addAllDifferent()` is faster than custom lambdas
2. **Restrict Domains Early**: Smaller initial domains = faster solving
3. **Strategic Constraint Ordering**: Add most constraining constraints first
4. **Consider Clues**: For puzzles, pre-fill strategic positions to reduce search space

```dart
// Performance example: Magic square with clue
final p = Problem();

// Add strategic clue to dramatically reduce search space
p.addVariable('11', [5]); // Center is always 5

// Remaining variables exclude the clue value  
final positions = ['00', '01', '02', '10', '12', '20', '21', '22'];
p.addVariables(positions, [1, 2, 3, 4, 6, 7, 8, 9]); // No 5

// ... add constraints ...
```

## API Reference

### Problem Class (Builder) - Core Methods

| Method | Parameters | Description |
|--------|------------|-------------|
| `addVariable()` | `String name`, `List<dynamic> domain` | Adds a single variable with its domain |
| `addVariables()` | `List<String> names`, `List<dynamic> domain` | Adds multiple variables sharing the same domain |
| `addConstraint()` | `List<String> vars`, `Function predicate` | Adds custom binary or n-ary constraint |
| `setOptions()` | `int? timeStep`, `CspCallback? callback` | Sets visualization parameters |
| `getSolution()` | (none) | Builds and solves the problem |

### Problem Class - Built-in Constraint Extensions

| Method | Parameters | Description |
|--------|------------|-------------|
| `addAllDifferent()` | `List<String> variables` | All variables have different values |
| `addAllEqual()` | `List<String> variables` | All variables have the same value |
| `addExactSum()` | `List<String> vars`, `num sum`, `List<num>? multipliers` | Variables sum to exact value |
| `addSumRange()` | `List<String> vars`, `num min`, `num max`, `List<num>? multipliers` | Sum within range |
| `addExactProduct()` | `List<String> vars`, `num product` | Variables multiply to exact value |
| `addInSet()` | `List<String> vars`, `Set<dynamic> allowed` | Variables must be from allowed set |
| `addNotInSet()` | `List<String> vars`, `Set<dynamic> forbidden` | Variables cannot be from forbidden set |
| `addAscending()` | `List<String> variables` | Variables in non-decreasing order |
| `addStrictlyAscending()` | `List<String> variables` | Variables in strictly increasing order |
| `addDescending()` | `List<String> variables` | Variables in non-increasing order |

### Built-in Constraint Factory Functions

#### Equality Constraints
- `allDifferent()` → `NaryPredicate`
- `allDifferentBinary()` → `BinaryPredicate`  
- `allEqual()` → `NaryPredicate`
- `allEqualBinary()` → `BinaryPredicate`

#### Arithmetic Constraints
- `exactSum(num target, {List<num>? multipliers})` → `NaryPredicate`
- `minSum(num minimum, {List<num>? multipliers})` → `NaryPredicate`
- `maxSum(num maximum, {List<num>? multipliers})` → `NaryPredicate`
- `sumInRange(num min, num max, {List<num>? multipliers})` → `NaryPredicate`
- `exactProduct(num target)` → `NaryPredicate`
- `minProduct(num minimum)` → `NaryPredicate`
- `maxProduct(num maximum)` → `NaryPredicate`

#### Set Membership Constraints  
- `inSet(Set<dynamic> allowed)` → `NaryPredicate`
- `notInSet(Set<dynamic> forbidden)` → `NaryPredicate`
- `someInSet(Set<dynamic> values, int minimum)` → `NaryPredicate`
- `someNotInSet(Set<dynamic> values, int minimum)` → `NaryPredicate`

#### Ordering Constraints
- `ascendingInOrder(List<String> order)` → `NaryPredicate`
- `strictlyAscendingInOrder(List<String> order)` → `NaryPredicate`
- `descendingInOrder(List<String> order)` → `NaryPredicate`

*Note: Binary versions (suffix `Binary`) are available for 2-variable optimizations.*

### CspProblem Class (Manual Construction)

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

### Type Definitions

```dart
typedef BinaryPredicate = bool Function(dynamic headVal, dynamic tailVal);
typedef NaryPredicate = bool Function(Map<String, dynamic> assignment);
typedef CspCallback = void Function(
  Map<String, List<dynamic>> assigned, 
  Map<String, List<dynamic>> unassigned
);
```

## Running the Demo

The comprehensive demo (`demo.dart`) showcases all library features with 11 different problems:

```bash
dart run demo.dart
```

### Demo Contents

1. **USA Map Coloring** - Compares old vs new constraint methods
2. **8-Queens Problem** - Classic backtracking demonstration  
3. **Sudoku Solver** - Using built-in `allDifferent` constraints
4. **All Different & Equal Constraints** - Basic constraint examples
5. **Sum Constraints** - Arithmetic constraint varieties
6. **Product Constraints** - Multiplication-based rules
7. **Set Membership** - Value inclusion/exclusion constraints
8. **Ordering Constraints** - Sequential arrangement rules
9. **Magic Square** - Complex multi-constraint problem with random clues
10. **Resource Allocation** - Real-world optimization scenario
11. **Class Scheduling** - Timetabling with multiple constraint types

Each demo includes:
- Problem setup explanation
- Constraint definition examples  
- Solution verification
- Performance timing

## Performance Tips

1. **Use Built-in Constraints**: Pre-optimized functions are faster than equivalent lambdas
2. **Strategic Domain Reduction**: Limit initial domains as much as possible
3. **Constraint Ordering**: Add most restrictive constraints first
4. **Choose Appropriate Constraint Types**: Use binary constraints for 2-variable rules
5. **Consider Problem Structure**: Add strategic "clues" to reduce search space

### Performance Comparison

```dart
// Slower: Custom lambda
p.addConstraint(['A', 'B', 'C'], (assignment) {
  final values = assignment.values.toSet();
  return values.length == assignment.length;
});

// Faster: Built-in constraint
p.addAllDifferent(['A', 'B', 'C']);

// Even faster: Binary constraint for 2 variables
p.addConstraint(['A', 'B'], allDifferentBinary());
```

## Contributing

Contributions are welcome! This library builds upon the excellent foundation of [csp.js](https://github.com/PrajitR/jusCSP) by Prajit Ramachandran.

### Development Setup

1. Clone the repository
2. Run the demo: `dart run demo.dart`
3. Run tests: `dart test` (if test suite exists)
4. Add new constraint types to the built-in library
5. Update documentation and examples

## License

MIT License - see LICENSE file for details.

---

*Built with ❤️ for the Dart & Flutter community*