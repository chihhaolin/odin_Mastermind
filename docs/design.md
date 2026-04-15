# Mastermind — Design Document

## 檔案結構

```
odin_Mastermind/
├── docs/
│   ├── mastermind.md
│   └── design.md
├── Gemfile
├── main.rb                    # 進入點，啟動遊戲
├── lib/
│   ├── code.rb                # 色碼物件
│   ├── feedback.rb            # 回饋計算
│   ├── board.rb               # 遊戲盤面狀態
│   ├── human_player.rb        # 人類玩家（輸入處理）
│   ├── computer_player.rb     # 電腦玩家（出題 + AI 猜測）
│   └── game.rb                # 遊戲流程主控
└── spec/
    ├── spec_helper.rb
    ├── code_spec.rb
    ├── feedback_spec.rb
    ├── board_spec.rb
    └── computer_player_spec.rb
```

---

## 顏色表示

使用 6 種顏色，以單字母縮寫呈現，方便 CLI 輸入：

| 縮寫 | 顏色   |
|------|--------|
| R    | Red    |
| G    | Green  |
| B    | Blue   |
| Y    | Yellow |
| O    | Orange |
| P    | Purple |

顏色在內部以 Symbol 儲存（`:red`, `:green` …），顯示時轉為大寫字母。

---

## 類別設計

| 類別 | 職責 |
|------|------|
| `Code` | 代表 4 位色碼，負責解析與驗證輸入 |
| `Feedback` | 計算 exact / color match，判斷是否獲勝 |
| `Board` | 記錄並顯示歷史猜測與回饋 |
| `HumanPlayer` | 讀取人類輸入 |
| `ComputerPlayer` | 隨機出題 + 記憶式 AI 猜測 |
| `Game` | 主流程：角色選擇、遊戲迴圈、勝負判定 |

---

### `Code`
代表一組 4 位色碼。

- `Code.random` — 產生隨機色碼
- `Code.from_input(string)` — 從字串（如 `"RGYB"`）解析，驗證輸入合法性
- `#to_s` — 顯示用字串
- `#colors` — 回傳 4 元素 Array

### `Feedback`
計算並持有一次猜測的回饋結果。

- `Feedback.new(secret, guess)` — 傳入兩個 `Code`，計算結果
- `#exact` — 完全正確的數量（對色對位）
- `#color` — 色對位錯的數量
- `#win?` — exact == 4
- `#to_s` — 顯示回饋，如 `"◆◆◇○"` 或 `"Exact: 2, Color: 1"`

**計算邏輯：**
1. 先掃一遍，記錄 exact matches，同時把對應位置標為已用。
2. 在剩餘位置中，計算 secret 與 guess 各顏色的剩餘數量，取 min 加總得 color matches。

### `Board`
追蹤遊戲盤面狀態。

- `#record(guess_code, feedback)` — 記錄一輪
- `#turns_used` — 已用回合數
- `#display` — 印出所有歷史猜測與回饋
- 常數 `MAX_TURNS = 12`

### `HumanPlayer`
處理人類的輸入。

- `#get_guess` — 提示並讀取猜測，驗證格式後回傳 `Code`
- `#get_code` — 人類出題時使用

### `ComputerPlayer`
同時負責「出題」與「猜測」兩個角色。

**出題：**
- `#generate_code` — 回傳隨機 `Code`

**猜測（AI 策略）：**

採用「記憶式隨機」（Random with Memory）：

1. 第一輪：完全隨機猜。
2. 後續輪：
   - 保留上一輪 exact match 的位置（不改變）。
   - 確保上一輪 color match 的顏色仍出現在非 exact 位置。
   - 其餘位置隨機填入合法顏色。
3. 重複直到猜中或 12 輪用完。

> 選擇性擴充：可在 `ComputerPlayer` 中加入 Knuth's 5-guess algorithm 作為進階模式。

### `Game`
遊戲主控，負責流程調度。

- `#start` — 詢問角色選擇，進入對應模式
- `#play_human_guesser` — Phase 1/2：人猜電腦碼
- `#play_computer_guesser` — Phase 3：電腦猜人碼
- 內部迴圈：`loop do … break if win? || out_of_turns? end`

---

## 遊戲流程

```
main.rb
  └─ Game#start
       ├─ 詢問角色（Guesser / Code Maker）
       │
       ├─ [Guesser] ComputerPlayer#generate_code → 秘密碼
       │    loop (最多 12 輪):
       │      HumanPlayer#get_guess → guess
       │      Feedback.new(secret, guess)
       │      Board#record + Board#display
       │      break if win? || out_of_turns?
       │    印出勝負結果
       │
       └─ [Code Maker] HumanPlayer#get_code → 秘密碼
            loop (最多 12 輪):
              ComputerPlayer#make_guess → guess
              Feedback.new(secret, guess)
              Board#record + Board#display
              break if win? || out_of_turns?
            印出勝負結果
```

---

## 錯誤處理

- 輸入驗證集中在 `Code.from_input`：長度必須為 4，每個字母必須是合法顏色縮寫。
- 無效輸入時重新提示，不扣回合數。

---

## 實作順序

1. `Code` + `Feedback`（核心邏輯，可先寫測試驗證回饋計算）
2. `Board`（盤面顯示）
3. `HumanPlayer` + `Game#play_human_guesser`（Phase 1 可玩）
4. 加入角色選擇（Phase 2）
5. `ComputerPlayer#make_guess` AI 策略（Phase 3）

---

## 測試計畫（RSpec）

### 目錄結構

```
odin_Mastermind/
└── spec/
    ├── spec_helper.rb
    ├── code_spec.rb
    ├── feedback_spec.rb
    ├── board_spec.rb
    └── computer_player_spec.rb
```

### `code_spec.rb`

```ruby
describe Code do
  describe '.random' do
    it '產生長度為 4 的色碼' do
    it '每個元素都是合法顏色'
  end

  describe '.from_input' do
    it '正確解析合法字串，如 "RGYB"'
    it '大小寫不敏感，"rgyb" 與 "RGYB" 相同'
    it '長度不為 4 時拋出錯誤'
    it '包含非法字母時拋出錯誤'
  end

  describe '#to_s' do
    it '回傳大寫字母字串，如 "RGYB"'
  end
end
```

### `feedback_spec.rb`

```ruby
describe Feedback do
  describe '#exact' do
    it '4 個位置全對時回傳 4'
    it '沒有任何位置對時回傳 0'
    it '部分位置正確時回傳正確數量'
  end

  describe '#color' do
    it '色對位錯時正確計算數量'
    it '重複顏色不重複計算（secret: RRBB, guess: RRRR → color: 0, exact: 1）'
    it 'exact 已計算的位置不再計入 color'
  end

  describe '#win?' do
    it 'exact == 4 時回傳 true'
    it 'exact < 4 時回傳 false'
  end
end
```

### `board_spec.rb`

```ruby
describe Board do
  describe '#record' do
    it '記錄猜測與回饋後 turns_used 增加 1'
  end

  describe '#turns_used' do
    it '初始為 0'
    it '每次 record 後正確遞增'
  end
end
```

### `computer_player_spec.rb`

```ruby
describe ComputerPlayer do
  describe '#generate_code' do
    it '回傳一個 Code 物件'
    it '每次呼叫結果不完全相同（隨機性驗證，多次取樣）'
  end

  describe '#make_guess' do
    it '第一輪回傳合法的 Code 物件'
    it '第二輪保留上一輪 exact match 的位置顏色不變'
    it '回傳的猜測不與已知不可能的組合重複'
  end
end
```

### 執行方式

```bash
# 安裝依賴
bundle install

# 執行所有測試
bundle exec rspec

# 執行單一檔案
bundle exec rspec spec/feedback_spec.rb

# 顯示詳細輸出
bundle exec rspec --format documentation
```

### `Gemfile`

```ruby
source 'https://rubygems.org'

gem 'rspec', '~> 3.0'
```
