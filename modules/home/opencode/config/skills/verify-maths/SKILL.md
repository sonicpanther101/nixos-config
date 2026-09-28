---
name: verify-maths
description: Use when a task involves calculations, algebra, calculus, physics, units, statistics or checking a derivation. Verifies results with sympy/numpy before answering and shows the check.
---

# Verify maths before asserting it

1. Restate the problem symbolically. List units and assumptions.
2. Solve or derive it on paper first.
3. Verify with Python via bash. Prefer `sympy` for symbolic work (simplify the difference of two forms
   and confirm it is 0), `numpy`/`mpmath` for numeric spot checks at 2-3 random points, and `pint` or
   explicit factors for units.
4. Report the result, then a short "Check" section: the code you ran and what it returned.
5. If symbolic and numeric disagree, say so and resolve it before presenting an answer.
6. For plots or diagrams, save a PNG and reference the path.
