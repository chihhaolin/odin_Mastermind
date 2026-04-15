# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
bundle install                              # install dependencies

# CLI
ruby main.rb                               # run the CLI game

# Web
bundle exec rackup config.ru -p 4567       # start web server (localhost:4567)
ruby web/app.rb                            # alternative: run Sinatra directly

# Tests
bundle exec rspec                          # run all tests (CLI + Web)
bundle exec rspec spec/web/                # web tests only
bundle exec rspec spec/feedback_spec.rb    # run a single spec file
bundle exec rspec --format documentation   # verbose test output
```

## Architecture

The game is split into single-responsibility classes that `main.rb` wires together via `require_relative`.

**Core logic (no I/O):**
- `Code` — immutable 4-element array of color symbols (`:R`–`:P`). Entry point for all input validation via `Code.from_input`.
- `Feedback` — computes exact/color match counts from two `Code` objects. Two-pass algorithm: exact matches first, then color matches from remaining positions.
- `Board` — append-only history of `{guess, feedback}` pairs; holds `MAX_TURNS = 12`.

**Players:**
- `HumanPlayer` — wraps `$stdin`; loops on invalid input without consuming a turn.
- `ComputerPlayer` — dual role: `generate_code` (random) and `make_guess` (AI). The AI generates random candidates and accepts the first one *consistent* with all prior feedback — i.e., `Feedback.new(candidate, prev_guess)` must reproduce the same exact/color counts as actually received.

**Orchestration:**
- `Game#start` asks for role selection, then delegates to `play_human_guesser` or `play_computer_guesser`. Each method owns its own loop and win/loss output.

**Data flow:**
```
main.rb → Game → HumanPlayer / ComputerPlayer
                    ↓
                  Code → Feedback → Board#display
```

## Specs

Tests cover `Code`, `Feedback`, `Board`, and `ComputerPlayer`. `HumanPlayer` and `Game` are not unit-tested (CLI I/O). The consistency test for `ComputerPlayer` directly verifies the AI invariant: simulate `Feedback.new(next_guess, prev_guess)` and assert it matches stored feedback counts.
