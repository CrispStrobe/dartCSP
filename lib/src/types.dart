/// Core type definitions for the CSP library.

/// Type definition for a binary constraint predicate.
///
/// It takes the value of a 'head' variable and a 'tail' variable and returns
/// true if the constraint is satisfied between them. This defines a directed
/// arc from head to tail.
typedef BinaryPredicate = bool Function(dynamic headVal, dynamic tailVal);

/// Type definition for an n-ary constraint predicate.
///
/// It takes a map representing a partial assignment of variables to values
/// and returns true if the constraint is satisfied for that combination.
typedef NaryPredicate = bool Function(Map<String, dynamic> assignment);

/// Type definition for the optional callback function during the search.
///
/// This can be used for visualizing the search process, showing the state of
/// assigned and unassigned variable domains at each step of the backtracking.
typedef CspCallback = void Function(
    Map<String, List<dynamic>> assigned, Map<String, List<dynamic>> unassigned);

/// Represents a binary constraint between two variables, forming a directed arc.
///
/// For a constraint like `A > B`, you might have one `BinaryConstraint` for the
/// arc A -> B and another for B -> A to enforce full consistency.
class BinaryConstraint {
  /// The "source" variable in the directed constraint arc.
  final String head;

  /// The "destination" variable in the directed constraint arc.
  final String tail;

  /// The function that evaluates the constraint between a value from the head's
  /// domain and a value from the tail's domain.
  final BinaryPredicate predicate;

  BinaryConstraint(this.head, this.tail, this.predicate);
}

/// Represents an n-ary constraint involving two or more variables.
///
/// This is used for complex constraints that cannot be broken down into simple
/// binary relationships, such as `A + B = C`.
class NaryConstraint {
  /// The list of variable names involved in this constraint.
  final List<String> vars;

  /// The function that evaluates if a complete assignment for the involved
  /// variables satisfies the constraint.
  final NaryPredicate predicate;

  NaryConstraint({required this.vars, required this.predicate});
}

/// Represents the full definition of a Constraint Satisfaction Problem.
///
/// This class encapsulates all the necessary components of a CSP: the variables,
/// their domains, and the constraints that bind them.
class CspProblem {
  /// A map where keys are variable names and values are lists (domains) of
  /// their possible values.
  Map<String, List<dynamic>> variables;

  /// A list of binary constraints restricting pairs of variables.
  List<BinaryConstraint> constraints;

  /// A list of n-ary constraints restricting groups of variables.
  List<NaryConstraint> naryConstraints;

  /// The delay in milliseconds between steps, used if a [cb] callback is provided.
  int timeStep;

  /// An optional callback function invoked at each step of the search for visualization.
  CspCallback? cb;

  /// Internal index mapping each variable to the n-ary constraints it participates in.
  /// This is built by the solver to speed up the GAC algorithm.
  Map<String, List<NaryConstraint>>? naryIndex;

  CspProblem({
    required this.variables,
    this.constraints = const [],
    this.naryConstraints = const [],
    this.timeStep = 1,
    this.cb,
  });
}