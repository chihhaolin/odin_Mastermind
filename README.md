# Mastermind

A Mastermind game built in Ruby — playable as a CLI app or in the browser.

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

## CLI

```bash
ruby main.rb
```

## Web

```bash
bundle exec rackup config.ru -p 4567  # 標準 Rack 啟動方式
bundle exec ruby web/app.rb           # 直接用 Ruby 啟動
# then open http://localhost:4567
```

## Test

```bash
bundle exec rspec                          # all tests
bundle exec rspec spec/web/                # web tests only
bundle exec rspec --format documentation   # verbose output
```
