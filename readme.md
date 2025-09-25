# dart_csp

[![Language: Dart](https://img.shields.io/badge/language-Dart-blue.svg)](https://dart.dev/)
[![Tests](https://img.shields.io/badge/tests-passing-brightgreen.svg)](#testing)

A powerful, general-purpose library for modeling and solving Constraint Satisfaction Problems (CSPs) in Dart. Built with intelligent backtracking search, consistency-checking algorithms, and smart heuristics to efficiently solve complex logic puzzles.

This library offers **three intuitive ways** to define constraints: **string expressions** for natural syntax, a high-level **Problem builder** for fast development, and a manual **CspProblem class** for direct control over the underlying structure.

> **Note**: This project is originally based on a port and enhancement of the excellent [csp.js](https://github.com/PrajitR/jusCSP) by Prajit Ramachandran, adapted for Dart's strong typing, async capabilities, and object-oriented structure. This also enables easy use with Flutter projects.

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
- **Multiple Solution Finding**: Stream-based API to find all possible solutions efficiently

### Smart Heuristics
- **Minimum Remaining Values (MRV)**: Chooses the most constrained variable to assign next ("fail-first" principle)
- **Least Constraining Value (LCV)**: Selects values that preserve the most options for other variables

### Built-in Constraint Library
- **20+ Pre-built Constraints**: Common constraint patterns like `allDifferent()`, `exactSum()`, `ascending()`, etc.
- **Optimized Performance**: Built-in constraints are faster than equivalent lambda functions
- **Extension Methods**: Fluent API methods like `addAllDifferent()` for cleaner code

### String Constraint Parsing
- **Natural Language Syntax**: Write constraints as strings like `"A + B == 10"` or `"A != B != C"`
- **Advanced Expression Support**: Complex expressions like `"5 <= A + B <= 7"` and `"A * B + C == 15"`
- **Variable Equations**: Support for `"A + B == C"` where one variable equals an expression of others
- **Set Membership**: Constraints like `"A in [1, 3, 5]"` for allowed value sets
- **Comprehensive Parser**: Handles arithmetic, comparisons, ranges, and chained operations

### Developer Features
- **Modular Architecture**: Clean separation of concerns across multiple focused modules
- **Comprehensive Test Suite**: Full test coverage with test cases covering all functionality
- **Multiple APIs**: Choose between string constraints, builder pattern, or manual construction
- **Fluent Builder API**: An intuitive Problem class to easily define your CSP
- **Rich Examples**: Complete demo showcasing all constraint types and problem-solving techniques
- **Debugging Tools**: Problem validation, summary printing, and step-by-step visualization
- **Type Safety**: Full Dart type system integration with proper error handling
- **Async Support**: Non-blocking solving with `Future`-based API

## Quick Start

### 1. Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  dart_csp: ^2.0.0
```

Then run:
```bash
dart pub get
```

### 2. Import and Use

```dart
import 'package:dart_csp/dart_csp.dart';
```

### 3. Your First Problem - Map Coloring

```dart
Future<void> main() async {
  final p = Problem();
  
  // Variables: Australian states, Domain: Colors
  p.addVariables(['WA', 'NT', 'SA', 'Q', 'NSW', 'V'], ['red', 'green', 'blue']);
  
  // Constraints using string expressions (easiest way!)
  p.addStringConstraints([
    'WA != SA',
    'NT != SA', 
    'Q != SA',
    'NSW != SA',
    'V != SA',
    'WA != NT',
    'NT != Q',
    'Q != NSW',
    'NSW != V'
  ]);
  
  // Get first solution
  final solution = await p.getSolution();
  print(solution); // {WA: red, NT: blue, SA: green, ...}
  
  // Or find all solutions
  print('All possible colorings:');
  await for (final solution in p.getSolutions()) {
    print(solution);
  }
}
```

### 4. Run the Comprehensive Demo

The library includes a complete demo showcasing all features:

```bash
dart run example/demo.dart
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

### Method 1: String Constraints (Recommended)

The most intuitive way - write constraints as natural expressions:

```dart
final p = Problem();

// 1. Add variables and domains
p.addVariables(['A', 'B', 'C'], [1, 2, 3, 4, 5]);

// 2. Add constraints using natural string syntax
p.addStringConstraints([
  'A != B != C',           // All different (chained)
  'A + B == 7',            // Exact sum
  'A < B < C',             // Strict ordering
  '5 <= A + B <= 8',       // Range constraint
  'A * B >= 6',            // Minimum product
  'A + B == C'             // Variable equation
]);

// 3. Solve
final solution = await p.getSolution();
```

**Supported String Constraint Syntax:**

| Pattern | Description | Example |
|---------|-------------|---------|
| **Equality/Inequality** | Variable comparisons | `"A == B"`, `"A != B"` |
| **Chained Operations** | Multiple comparisons | `"A != B != C"`, `"A < B < C"` |
| **Arithmetic Equality** | Exact sums/products | `"A + B == 10"`, `"A * B == 12"` |
| **Arithmetic Inequality** | Min/max constraints | `"A + B >= 5"`, `"A * B <= 20"` |
| **Range Constraints** | Bounded values | `"5 <= A + B <= 10"` |
| **Variable Equations** | Inter-variable relations | `"A + B == C"`, `"A * B == D"` |
| **Complex Expressions** | Mixed operations | `"2*A + 3*B == 15"`, `"A*B + C >= 10"` |
| **Set Membership** | Allowed values | `"A in [1, 3, 5]"` |
| **Single Variable** | Constant comparisons | `"A > 5"`, `"B != 3"` |

### Method 2: The Problem Builder

The Problem class provides a clean, step-by-step builder pattern with built-in constraints:

```dart
final p = Problem();

// 1. Add variables and domains
p.addVariables(['A', 'B', 'C'], [1, 2, 3, 4, 5]);

// 2. Use built-in constraints (highly optimized)
p.addAllDifferent(['A', 'B', 'C']);      // All different values
p.addExactSum(['A', 'B'], 7);            // A + B = 7
p.addAscending(['A', 'B', 'C']);         // A ≤ B ≤ C

// 3. Or define custom constraints with lambda functions
p.addConstraint(['A', 'B'], (a, b) => a * b <= 10);

// 4. Solve
final solution = await p.getSolution();
```

### Method 3: Manual CspProblem Construction

Direct access to underlying data structures for programmatic generation:

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

## Convenience Functions

For quick problem solving, use the top-level convenience functions:

```dart
// Quick all-different problem
final solution1 = await solveAllDifferent(
  variables: ['A', 'B', 'C'],
  domain: [1, 2, 3]
);

// Quick sum problem  
final solution2 = await solveSumProblem(
  variables: ['X', 'Y'],
  domain: [1, 2, 3, 4, 5],
  targetSum: 7
);

// General string constraint problem
final solution3 = await solveProblem(
  variables: {'A': [1, 2, 3, 4], 'B': [1, 2, 3, 4]},
  constraints: ['A != B', 'A + B >= 5']
);
```

## Real-World Examples

### Sudoku Solver with String Constraints

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
  
  // Add all-different constraints using built-in methods
  // Rows
  for (int r = 0; r < 9; r++) {
    final row = List.generate(9, (c) => '$r-$c');
    p.addAllDifferent(row);
  }
  
  // Columns
  for (int c = 0; c < 9; c++) {
    final col = List.generate(9, (r) => '$r-$c');
    p.addAllDifferent(col);
  }
  
  // 3x3 blocks
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

### Magic Square with String Constraints

```dart
Future<void> generateMagicSquare() async {
  final p = Problem();
  
  // 3x3 grid with numbers 1-9
  final positions = ['A1', 'A2', 'A3', 'B1', 'B2', 'B3', 'C1', 'C2', 'C3'];
  p.addVariables(positions, [1, 2, 3, 4, 5, 6, 7, 8, 9]);
  
  // Each number appears exactly once
  p.addAllDifferent(positions);
  
  // All rows, columns, and diagonals sum to 15 using string constraints
  p.addStringConstraints([
    // Rows
    'A1 + A2 + A3 == 15',
    'B1 + B2 + B3 == 15', 
    'C1 + C2 + C3 == 15',
    // Columns
    'A1 + B1 + C1 == 15',
    'A2 + B2 + C2 == 15',
    'A3 + B3 + C3 == 15',
    // Diagonals
    'A1 + B2 + C3 == 15',
    'A3 + B2 + C1 == 15'
  ]);
  
  final solution = await p.getSolution();
  // Display magic square...
}
```

### Resource Allocation with Mixed Constraints

```dart
Future<void> allocateResources() async {
  final p = Problem();
  
  // Teams get 3-10 resources each  
  p.addVariables(['TeamA', 'TeamB', 'TeamC'], [3, 4, 5, 6, 7, 8, 9, 10]);
  
  // Use string constraints for clarity
  p.addStringConstraints([
    'TeamA + TeamB + TeamC == 20',  // Total budget
    'TeamA >= TeamB',               // Priority constraint
    'TeamA >= 3',                   // Minimum allocation
    'TeamB >= 3',
    'TeamC >= 3'
  ]);
  
  final solution = await p.getSolution();
  print('Team A: ${solution['TeamA']} resources');
  print('Team B: ${solution['TeamB']} resources'); 
  print('Team C: ${solution['TeamC']} resources');
}
```

## Testing

The library includes a comprehensive test suite covering all functionality:

```bash
# Run all tests
dart test

# Run tests with coverage
dart pub global activate coverage
dart pub global run coverage:test_with_coverage

# Run specific test groups
dart test test/dart_csp_test.dart -n "Basic Problem Creation"
dart test test/dart_csp_test.dart -n "String Constraints"
```

### Test Coverage

The test suite includes test cases covering:

- **Basic Problem Creation**: Variable addition, domain validation, constraint setup
- **Binary Constraints**: Two-variable relationships and consistency
- **N-ary Constraints**: Multi-variable constraints and complex relationships  
- **String Constraints**: All parsing scenarios and edge cases
- **Built-in Constraints**: Every constraint factory function and extension method
- **Complex Problems**: Magic squares, N-Queens, Sudoku, map coloring
- **Convenience Functions**: Top-level utility functions
- **Failure Cases**: Over-constrained and unsolvable problems
- **Problem Utilities**: Validation, debugging, and introspection
- **Edge Cases**: Malformed constraints, missing variables, empty domains

## Advanced Usage

### Debugging and Problem Validation

```dart
final p = Problem();
p.addVariables(['A', 'B', 'C'], [1, 2, 3]);
p.addStringConstraint('A != B');

// Print problem summary
p.printSummary();

// Validate problem for common issues
final issues = p.validate();
if (issues.isEmpty) {
  print('Problem validation: ✓ No issues found');
} else {
  print('Problem validation issues:');
  for (final issue in issues) {
    print('  - $issue');
  }
}
```

### Visualization and Monitoring

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

1. **Use String Constraints**: Often more readable and just as fast as built-ins
2. **Use Built-in Constraints**: `addAllDifferent()` is faster than custom lambdas
3. **Restrict Domains Early**: Smaller initial domains = faster solving
4. **Strategic Constraint Ordering**: Add most constraining constraints first
5. **Consider Clues**: For puzzles, pre-fill strategic positions to reduce search space

```dart
// Performance example: Magic square with strategic clue
final p = Problem();

// Add strategic clue to dramatically reduce search space
p.addVariable('B2', [5]); // Center is always 5 in 3x3 magic square

// Remaining variables exclude the clue value  
final otherPositions = ['A1', 'A2', 'A3', 'B1', 'B3', 'C1', 'C2', 'C3'];
p.addVariables(otherPositions, [1, 2, 3, 4, 6, 7, 8, 9]); // No 5

// ... add constraints using string syntax ...
p.addStringConstraints([
  'A1 + A2 + A3 == 15',
  'B1 + B2 + B3 == 15', // B2 is constrained to [5]
  // ... more constraints
]);
```

## API Reference

### Problem Class (Builder) - Core Methods

| Method | Parameters | Description |
|--------|------------|-------------|
| `addVariable()` | `String name`, `List<dynamic> domain` | Adds a single variable with its domain |
| `addVariables()` | `List<String> names`, `List<dynamic> domain` | Adds multiple variables sharing the same domain |
| `addConstraint()` | `List<String> vars`, `Function predicate` | Adds custom binary or n-ary constraint |
| `addStringConstraint()` | `String constraint` | Adds constraint from string expression |
| `addStringConstraints()` | `List<String> constraints` | Adds multiple string constraints |
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

### Problem Class - Debugging Extensions

| Method | Returns | Description |
|--------|---------|-------------|
| `printSummary()` | `void` | Prints problem overview to console |
| `validate()` | `List<String>` | Returns list of potential issues |
| `copy()` | `Problem` | Creates a deep copy of the problem |
| `clear()` | `void` | Removes all variables and constraints |
| `variableCount` | `int` | Number of variables in problem |
| `constraintCount` | `int` | Number of constraints in problem |

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

### Convenience Functions

| Function | Parameters | Description |
|----------|------------|-------------|
| `solveProblem()` | `Map<String, List<dynamic>> variables`, `List<String> constraints` | Solve with string constraints |
| `solveAllDifferent()` | `List<String> variables`, `List<dynamic> domain` | Quick all-different solver |  
| `solveSumProblem()` | `List<String> variables`, `List<dynamic> domain`, `num targetSum` | Quick sum constraint solver |

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

## Project Structure

The library is organized into focused, modular components:

```
lib/
├── dart_csp.dart                 # Main library export and convenience functions
└── src/
    ├── types.dart                # Core type definitions and interfaces  
    ├── solver.dart               # CSP solver with backtracking, AC-3, GAC
    ├── problem.dart              # Problem builder class and extensions
    ├── builtin_constraints.dart  # Optimized constraint factory functions
    └── constraint_parser.dart    # String constraint parsing engine

example/
├── demo.dart                     # Comprehensive demo of all features
├── usage_examples.dart           # Complete usage examples for all APIs
└── gencw.dart                    # Advanced arithmetic square puzzle generator

test/
└── dart_csp_test.dart           # Comprehensive test suite
```

## Running the Demo

The comprehensive demo (`example/demo.dart`) showcases all library features with 11 different problems:

```bash
dart run example/demo.dart
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

1. **Use String Constraints**: Natural syntax with good performance
2. **Use Built-in Constraints**: Pre-optimized functions are faster than equivalent lambdas
3. **Strategic Domain Reduction**: Limit initial domains as much as possible
4. **Constraint Ordering**: Add most restrictive constraints first
5. **Choose Appropriate Constraint Types**: Use binary constraints for 2-variable rules
6. **Consider Problem Structure**: Add strategic "clues" to reduce search space

### Performance Comparison

```dart
// Readable and fast: String constraints  
p.addStringConstraints(['A != B != C', 'A + B + C == 10']);

// Also fast: Built-in constraints
p.addAllDifferent(['A', 'B', 'C']);
p.addExactSum(['A', 'B', 'C'], 10);

// Slower but flexible: Custom lambda
p.addConstraint(['A', 'B', 'C'], (assignment) {
  final values = assignment.values.toSet();
  return values.length == assignment.length && 
         values.fold<num>(0, (sum, v) => sum + v) == 10;
});

// Fastest for 2 variables: Binary constraint
p.addConstraint(['A', 'B'], allDifferentBinary());
```

## Contributing

Contributions are welcome! This library builds upon the excellent foundation of [csp.js](https://github.com/PrajitR/jusCSP) by Prajit Ramachandran.

### Development Setup

1. Clone the repository
2. Install dependencies: `dart pub get`
3. Run tests: `dart test`
4. Run the demo: `dart run example/demo.dart`
5. Run examples: `dart run example/usage_examples.dart`

## License

MIT License - see LICENSE file for details.

---

*Built with ❤️ for the Dart & Flutter community*