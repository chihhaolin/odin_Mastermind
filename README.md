# Mastermind

A command-line Mastermind game built in Ruby.

## How to Play

The secret code consists of **4 colors**. Colors can repeat.

Available colors:

| Abbreviation | Color  |
|:---:|--------|
| R | Red    |
| G | Green  |
| B | Blue   |
| Y | Yellow |
| O | Orange |
| P | Purple |

You have **12 turns** to guess the code. After each guess you receive:
- **Exact** — correct color in the correct position
- **Color** — correct color in the wrong position

## Roles

**Guesser** — you guess, the computer sets the secret code.

**Code Maker** — you set the secret code, the computer guesses using a consistency-based AI strategy.

## Setup

```bash
bundle install
```

## Run

```bash
ruby main.rb
```

## Test

```bash
bundle exec rspec
bundle exec rspec --format documentation  # verbose output
```
