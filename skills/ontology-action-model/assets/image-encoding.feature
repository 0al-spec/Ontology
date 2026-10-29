# Synthetic acceptance specifications for a future goal-evaluation component.
# Parsing these scenarios is not execution: no step definitions or codec are supplied.
# All byte counts use decimal bytes; scope is the same image and selected transition.
Feature: Evaluate the consequence of an in-place image transformation
  A declared goal can constrain the change as well as the resulting state.
  Completing encoding does not itself establish goal satisfaction.

  Scenario Outline: Evaluate a relative byte reduction
    Given a supplied observation of "image-1" before encoding with <before> bytes
    And a supplied observation of the same image after encoding with <after> bytes
    And a declared goal to reduce byte length by <comparison> 200000 bytes
    When the evaluator compares the observed transition with the declared goal
    Then the reported byte reduction is <reduction>
    And the goal evaluation is "<evaluation>"

    Examples:
      | before | after  | comparison | reduction | evaluation    |
      | 900000 | 700000 | at least   | 200000    | satisfied     |
      | 800000 | 700000 | at least   | 100000    | not_satisfied |
      | 900000 | 700001 | at least   | 199999    | not_satisfied |
      | 900000 | 699999 | at least   | 200001    | satisfied     |
      | 900000 | 699999 | exactly    | 200001    | not_satisfied |
      | 900000 | 700000 | exactly    | 200000    | satisfied     |
      | 900000 | 900000 | at least   | 0         | not_satisfied |
      | 900000 | 900001 | at least   | -1        | not_satisfied |

  Scenario: A relative goal cannot be evaluated without its baseline
    Given the byte length before encoding is unknown
    And a supplied observation of the selected image after encoding with 700000 bytes
    And a declared goal to reduce byte length by at least 200000 bytes
    When the evaluator compares the available observations with the declared goal
    Then the goal evaluation is "unknown"
    And the explanation identifies the missing baseline byte length
    And no numerical byte reduction is reported

  Scenario: A final-size criterion does not require a baseline size
    Given the byte length before encoding is unknown
    And a supplied observation of the selected image after encoding with 700000 bytes
    And a declared goal for final byte length to be at most 700000 bytes
    When the evaluator compares the available observations with the declared goal
    Then the goal evaluation is "satisfied"
    And no numerical byte reduction is reported

  Scenario: Sufficient reduction does not excuse an unwanted dimension change
    Given a supplied observation before encoding of 900000 bytes and dimensions 1200 by 800
    And a supplied observation of the same image after encoding of 700000 bytes and dimensions 600 by 400
    And a declared goal for at least 200000 bytes of reduction while preserving dimensions
    When the evaluator compares the observed transition with the declared goal
    Then the goal evaluation is "not_satisfied"
    And the explanation identifies the changed dimensions

  Scenario: Completed encoding can miss the goal
    Given the encoding operation completed
    And supplied observations of the same image changing from 800000 to 700000 bytes
    And a declared goal to reduce byte length by at least 200000 bytes
    When the evaluator compares the observed transition with the declared goal
    Then the operation outcome remains "completed"
    And the goal evaluation is "not_satisfied"
