/// lib/src/builtin_constraints.dart

/// Built-in constraint factory functions for common CSP constraint types.
/// These are much faster than generic lambda functions and provide better
/// error messages and debugging support.

import 'types.dart';

/// Creates a constraint ensuring all variables have different values
///
/// This is one of the most common constraints in CSP problems.
/// Examples: Sudoku rows/columns, N-Queens, graph coloring
///
/// Usage:
/// ```dart
/// final p = Problem();
/// p.addVariables(['A', 'B', 'C'], [1, 2, 3]);
/// p.addConstraint(['A', 'B', 'C'], allDifferent());
/// ```
NaryPredicate allDifferent() {
  return (Map<String, dynamic> assignment) {
    final values = assignment.values.toSet();
    return values.length == assignment.length; // All values must be unique
  };
}

/// Creates a binary all-different constraint for exactly 2 variables
/// More efficient than the n-ary version for 2 variables
BinaryPredicate allDifferentBinary() {
  return (dynamic a, dynamic b) => a != b;
}

/// Creates a constraint ensuring all variables have the same value
///
/// Examples: Ensuring consistent settings across components
///
/// Usage:
/// ```dart
/// p.addConstraint(['X', 'Y', 'Z'], allEqual());
/// ```
NaryPredicate allEqual() {
  return (Map<String, dynamic> assignment) {
    if (assignment.isEmpty) return true;

    final firstValue = assignment.values.first;
    return assignment.values.every((value) => value == firstValue);
  };
}

/// Binary version for exactly 2 variables
BinaryPredicate allEqualBinary() {
  return (dynamic a, dynamic b) => a == b;
}

/// Creates a constraint ensuring variables sum to an exact value
///
/// Examples: Magic squares, resource allocation with exact budget
///
/// Usage:
/// ```dart
/// p.addConstraint(['A', 'B', 'C'], exactSum(15));
/// p.addConstraint(['X', 'Y'], exactSum(10, multipliers: [2, 3])); // 2*X + 3*Y = 10
/// ```
NaryPredicate exactSum(num targetSum, {List<num>? multipliers}) {
  return (Map<String, dynamic> assignment) {
    if (assignment.isEmpty) return targetSum == 0;

    num sum = 0;
    int index = 0;

    for (final value in assignment.values) {
      final multiplier = multipliers?[index] ?? 1;
      sum += value * multiplier;
      index++;
    }

    return sum == targetSum;
  };
}

/// Creates a constraint ensuring variables sum to at least a minimum value
NaryPredicate minSum(num minimumSum, {List<num>? multipliers}) {
  return (Map<String, dynamic> assignment) {
    if (assignment.isEmpty) return minimumSum <= 0;

    num sum = 0;
    int index = 0;

    for (final value in assignment.values) {
      final multiplier = multipliers?[index] ?? 1;
      sum += value * multiplier;
      index++;
    }

    return sum >= minimumSum;
  };
}

/// Creates a constraint ensuring variables sum to at most a maximum value
NaryPredicate maxSum(num maximumSum, {List<num>? multipliers}) {
  return (Map<String, dynamic> assignment) {
    if (assignment.isEmpty) return true;

    num sum = 0;
    int index = 0;

    for (final value in assignment.values) {
      final multiplier = multipliers?[index] ?? 1;
      sum += value * multiplier;
      index++;
    }

    return sum <= maximumSum;
  };
}

/// Creates a constraint ensuring variables sum within a range
NaryPredicate sumInRange(num minSum, num maxSum, {List<num>? multipliers}) {
  return (Map<String, dynamic> assignment) {
    if (assignment.isEmpty) return minSum <= 0 && maxSum >= 0;

    num sum = 0;
    int index = 0;

    for (final value in assignment.values) {
      final multiplier = multipliers?[index] ?? 1;
      sum += value * multiplier;
      index++;
    }

    return sum >= minSum && sum <= maxSum;
  };
}

// Binary versions of sum constraints for 2-variable optimization
BinaryPredicate exactSumBinary(num targetSum, {List<num>? multipliers}) {
  final m1 = multipliers?[0] ?? 1;
  final m2 = multipliers?[1] ?? 1;
  return (dynamic a, dynamic b) => (a * m1 + b * m2) == targetSum;
}

BinaryPredicate minSumBinary(num minimumSum, {List<num>? multipliers}) {
  final m1 = multipliers?[0] ?? 1;
  final m2 = multipliers?[1] ?? 1;
  return (dynamic a, dynamic b) => (a * m1 + b * m2) >= minimumSum;
}

BinaryPredicate maxSumBinary(num maximumSum, {List<num>? multipliers}) {
  final m1 = multipliers?[0] ?? 1;
  final m2 = multipliers?[1] ?? 1;
  return (dynamic a, dynamic b) => (a * m1 + b * m2) <= maximumSum;
}

BinaryPredicate sumInRangeBinary(num minSum, num maxSum,
    {List<num>? multipliers}) {
  final m1 = multipliers?[0] ?? 1;
  final m2 = multipliers?[1] ?? 1;
  return (dynamic a, dynamic b) {
    final sum = a * m1 + b * m2;
    return sum >= minSum && sum <= maxSum;
  };
}

BinaryPredicate exactProductBinary(num targetProduct) {
  return (dynamic a, dynamic b) => (a * b) == targetProduct;
}

BinaryPredicate minProductBinary(num minimumProduct) {
  return (dynamic a, dynamic b) => (a * b) >= minimumProduct;
}

BinaryPredicate maxProductBinary(num maximumProduct) {
  return (dynamic a, dynamic b) => (a * b) <= maximumProduct;
}

/// Creates a constraint ensuring variables multiply to an exact value
NaryPredicate exactProduct(num targetProduct) {
  return (Map<String, dynamic> assignment) {
    if (assignment.isEmpty) return targetProduct == 1;

    num product = 1;
    for (final value in assignment.values) {
      product *= value;
    }

    return product == targetProduct;
  };
}

/// Creates a constraint ensuring variables multiply to at least a minimum
NaryPredicate minProduct(num minimumProduct) {
  return (Map<String, dynamic> assignment) {
    if (assignment.isEmpty) return minimumProduct <= 1;

    num product = 1;
    for (final value in assignment.values) {
      product *= value;
    }

    return product >= minimumProduct;
  };
}

/// Creates a constraint ensuring variables multiply to at most a maximum
NaryPredicate maxProduct(num maximumProduct) {
  return (Map<String, dynamic> assignment) {
    if (assignment.isEmpty) return true;

    num product = 1;
    for (final value in assignment.values) {
      product *= value;
    }

    return product <= maximumProduct;
  };
}

/// Creates a constraint ensuring all variables take values from allowed set
NaryPredicate inSet(Set<dynamic> allowedValues) {
  return (Map<String, dynamic> assignment) {
    return assignment.values.every((value) => allowedValues.contains(value));
  };
}

/// Creates a constraint ensuring no variables take values from forbidden set
NaryPredicate notInSet(Set<dynamic> forbiddenValues) {
  return (Map<String, dynamic> assignment) {
    return assignment.values.every((value) => !forbiddenValues.contains(value));
  };
}

// Binary versions of set membership constraints for 2-variable optimization
BinaryPredicate inSetBinary(Set<dynamic> allowedValues) {
  return (dynamic a, dynamic b) =>
      allowedValues.contains(a) && allowedValues.contains(b);
}

BinaryPredicate notInSetBinary(Set<dynamic> forbiddenValues) {
  return (dynamic a, dynamic b) =>
      !forbiddenValues.contains(a) && !forbiddenValues.contains(b);
}

/// Creates a constraint ensuring at least N variables have values in the set
NaryPredicate someInSet(Set<dynamic> values, int minimumCount) {
  return (Map<String, dynamic> assignment) {
    final count =
        assignment.values.where((value) => values.contains(value)).length;
    return count >= minimumCount;
  };
}

/// Creates a constraint ensuring at least N variables have values NOT in the set
NaryPredicate someNotInSet(Set<dynamic> values, int minimumCount) {
  return (Map<String, dynamic> assignment) {
    final count =
        assignment.values.where((value) => !values.contains(value)).length;
    return count >= minimumCount;
  };
}

/// Creates a constraint ensuring variables are in ascending order
NaryPredicate ascendingInOrder(List<String> variableOrder) {
  return (Map<String, dynamic> assignment) {
    for (int i = 1; i < variableOrder.length; i++) {
      final current = assignment[variableOrder[i]];
      final previous = assignment[variableOrder[i - 1]];
      if (current == null || previous == null) return true;
      if (current < previous) {
        return false;
      }
    }
    return true;
  };
}

/// Creates a constraint ensuring variables are in strictly ascending order
NaryPredicate strictlyAscendingInOrder(List<String> variableOrder) {
  return (Map<String, dynamic> assignment) {
    for (int i = 1; i < variableOrder.length; i++) {
      final current = assignment[variableOrder[i]];
      final previous = assignment[variableOrder[i - 1]];
      if (current == null || previous == null) return true;
      if (current <= previous) {
        return false;
      }
    }
    return true;
  };
}

/// Creates a constraint ensuring variables are in descending order
NaryPredicate descendingInOrder(List<String> variableOrder) {
  return (Map<String, dynamic> assignment) {
    for (int i = 1; i < variableOrder.length; i++) {
      final current = assignment[variableOrder[i]];
      final previous = assignment[variableOrder[i - 1]];
      if (current == null || previous == null) return true;
      if (current > previous) {
        return false;
      }
    }
    return true;
  };
}

// Binary versions of ordering constraints for 2-variable optimization
BinaryPredicate ascendingBinary() {
  return (dynamic a, dynamic b) => a <= b;
}

BinaryPredicate strictlyAscendingBinary() {
  return (dynamic a, dynamic b) => a < b;
}

BinaryPredicate descendingBinary() {
  return (dynamic a, dynamic b) => a >= b;
}
