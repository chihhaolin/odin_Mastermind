# Mastermind — Project Spec

## Overview
Build a command-line Mastermind game in Ruby.
The player has **12 turns** to guess a secret color code.
After each guess, feedback is provided on how close the guess was.

---

## Feedback Rules
- **Exact match**: correct color in the correct position
- **Color match**: correct color but in the wrong position
- **No match**: color not in the secret code at all

---

## Phase 1 — Human Guesses, Computer Sets Code

- [ ] The computer randomly generates a secret color code
- [ ] The human player inputs a guess each turn
- [ ] The game provides feedback after each guess:
  - Number of exact matches
  - Number of color-only matches
- [ ] The game ends when:
  - The player guesses the code correctly, **or**
  - The player exhausts all 12 turns

---

## Phase 2 — Role Selection

- [ ] At the start of the game, the player chooses a role:
  - **Guesser**: human guesses, computer sets the code (same as Phase 1)
  - **Code Maker**: human sets the secret code, computer guesses

---

## Phase 3 — Computer as Guesser (AI Strategy)

- [ ] The computer attempts to guess the human's secret code within 12 turns
- [ ] Minimum strategy — random with memory:
  - [ ] The computer guesses randomly on the first turn
  - [ ] Exact matches from previous guesses are kept in the same position
  - [ ] Colors that were correct but misplaced must still appear in subsequent guesses
- [ ] *(Optional)* Implement a more advanced solving algorithm (e.g., Knuth's 5-guess algorithm)

---

## Constraints
- The secret code consists of **4 positions**
- Colors can be repeated
- The game is played entirely in the **command line**