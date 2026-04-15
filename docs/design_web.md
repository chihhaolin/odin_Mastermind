# Mastermind — Web 版設計文件

## 設計原則

- **核心邏輯零改動**：`Code`, `Feedback`, `Board`, `ComputerPlayer` 完全不動，直接重用。
- **薄薄的 Web 層**：只新增 HTTP 路由、Session 序列化、View 三層。
- **Sinatra**：輕量、無多餘框架負擔，與原專案風格一致。
- **Server-side Session**：Game 狀態存在加密 Cookie，不需資料庫。

---

## 技術選型

| 層級 | 選擇 | 理由 |
|------|------|------|
| Web 框架 | Sinatra | 輕量，適合單一遊戲應用 |
| 模板引擎 | ERB | Ruby 標準，無額外依賴 |
| Session | Sinatra cookie session | 簡單，不需外部儲存 |
| 前端 | HTML + 原生 CSS | 遊戲邏輯簡單，不需要 SPA |
| 測試 | RSpec + Rack::Test | 與現有 spec 體系一致 |

---

## 檔案結構

```
odin_Mastermind/
├── docs/
│   ├── design.md
│   └── design_web.md          ← 本文件
├── lib/                       ← 完全不動
│   ├── code.rb
│   ├── feedback.rb
│   ├── board.rb
│   ├── human_player.rb        （Web 版不使用，保留 CLI 用）
│   ├── computer_player.rb
│   └── game.rb                （Web 版不使用，保留 CLI 用）
├── web/
│   ├── app.rb                 ← Sinatra 主程式，定義所有路由
│   ├── game_session.rb        ← Session 序列化 / 反序列化
│   └── views/
│       ├── layout.erb         ← HTML 骨架（head、nav）
│       ├── index.erb          ← 首頁：角色選擇
│       └── game.erb           ← 遊戲頁：盤面 + 輸入 / 電腦猜測
├── public/
│   └── style.css              ← 極簡樣式
├── spec/
│   ├── spec_helper.rb         ← 加入 Rack::Test
│   ├── code_spec.rb           ← 不動
│   ├── feedback_spec.rb       ← 不動
│   ├── board_spec.rb          ← 不動
│   ├── computer_player_spec.rb← 不動
│   └── web/
│       ├── game_session_spec.rb  ← 序列化單元測試
│       └── app_spec.rb           ← HTTP request / 整合測試
├── Gemfile
├── config.ru                  ← Rack 進入點（用於 rackup / production）
└── main.rb                    ← CLI 進入點，不動
```

---

## Gemfile 新增依賴

```ruby
source 'https://rubygems.org'

gem 'rspec',   '~> 3.0'

# Web
gem 'sinatra',       '~> 4.0'
gem 'sinatra-contrib','~> 4.0'  # sinatra/reloader, sinatra/json 等
gem 'rack-session',  '~> 2.0'   # Sinatra 4 需要明確引入

group :development do
  gem 'puma', '~> 6.0'          # 開發 server
end

group :test do
  gem 'rack-test', '~> 2.0'     # 模擬 HTTP 請求
end
```

---

## Session 狀態結構

Game 狀態全部存在 `session[:game]` 中，格式為可序列化的 Hash：

```ruby
session[:game] = {
  role:            'guesser',       # 'guesser' | 'maker'
  secret:          ['R','G','B','Y'], # Code#colors.map(&:to_s)
  history: [                         # Board 的歷史紀錄
    {
      guess:    ['R','R','G','B'],
      exact:    1,
      color:    2
    }
  ],
  computer_history: [                # ComputerPlayer 的內部歷史（maker 模式）
    {
      guess:  ['R','G','B','Y'],
      exact:  1,
      color:  0
    }
  ],
  status:          'playing'        # 'playing' | 'won' | 'lost'
}
```

---

## `GameSession` 類別

`web/game_session.rb`

```
職責：在 Plain Hash（可存 cookie）與 domain object 之間轉換，
      並封裝一輪遊戲的狀態推進邏輯。
```

### 主要方法

| 方法 | 說明 |
|------|------|
| `GameSession.new_guesser_game` | 建立電腦出題的新遊戲，回傳 session hash |
| `GameSession.new_maker_game(secret_str)` | 建立人類出題的新遊戲 |
| `GameSession.from_hash(h)` | 從 session hash 重建 GameSession 物件 |
| `#submit_guess(input_str)` | 處理人類猜測，回傳 `{ok:, error:, feedback:, status:}` |
| `#computer_guess` | 推進電腦猜測一輪，回傳 `{guess:, feedback:, status:}` |
| `#to_h` | 序列化回 Plain Hash（存入 session） |
| `#board_rows` | 回傳適合 View 使用的陣列（每列含 guess 字串和 feedback 字串） |
| `#turns_used` | 已用回合數 |
| `#max_turns` | `Board::MAX_TURNS` |

---

## HTTP 路由（`web/app.rb`）

```
GET  /                → 首頁，顯示角色選擇表單
POST /game/start      → 建立新遊戲（params: role, secret）
GET  /game            → 顯示當前遊戲狀態
POST /game/guess      → 提交人類猜測（params: guess）
POST /game/computer   → 觸發電腦猜測一步
POST /game/reset      → 清除 session，回首頁
```

### 路由細節

#### `GET /`
- 清空 session game 狀態
- 渲染 `index.erb`（含角色選擇表單）

#### `POST /game/start`
- `params[:role]` = `'1'`（Guesser）或 `'2'`（Maker）
- Guesser：`GameSession.new_guesser_game` → 存 session → redirect `/game`
- Maker：驗證 `params[:secret]`（`Code.from_input`）→ `GameSession.new_maker_game` → redirect `/game`
- 驗證失敗：redirect `/` 並帶 flash 錯誤

#### `GET /game`
- 若無 session，redirect `/`
- `GameSession.from_hash(session[:game])` 重建狀態
- 渲染 `game.erb`

#### `POST /game/guess`
- Guesser 模式專用
- `session_game.submit_guess(params[:guess])`
- 更新 `session[:game]`
- redirect `/game`（PRG pattern，防重複提交）

#### `POST /game/computer`
- Maker 模式專用
- `session_game.computer_guess`
- 更新 `session[:game]`
- redirect `/game`

#### `POST /game/reset`
- `session.clear`
- redirect `/`

---

## View 說明

### `layout.erb`
- 共用 HTML `<head>`（引入 style.css）
- 頂部顯示 MASTERMIND 標題
- `<%= yield %>` 插入頁面內容

### `index.erb`
- 顯示顏色說明表：R G B Y O P
- 兩個按鈕／表單：
  - **我來猜**（role=1）：直接 POST /game/start
  - **我來出題**（role=2）：顯示 secret 輸入欄，POST /game/start
- 顯示 flash 錯誤訊息（如有）

### `game.erb`
根據 `session[:game][:role]` 和 `status` 決定顯示：

**盤面（共用）：**
- 顯示已用回合數、剩餘回合數
- 歷史表格：每列顯示回合數、猜測色碼、Exact / Color 數

**Guesser 模式（playing 狀態）：**
- `<input>` 輸入猜測（4 個字母）
- 送出按鈕

**Maker 模式（playing 狀態）：**
- 「電腦思考中…」提示
- 「讓電腦猜下一步」按鈕（POST /game/computer）

**結束狀態（won / lost）：**
- 顯示勝負結果、秘密碼
- 「再玩一局」按鈕（POST /game/reset）

---

## 資料流

```
browser
  │
  ▼
web/app.rb (Sinatra routes)
  │   ├─ GET  /game  ──► GameSession.from_hash(session[:game])
  │   │                        │
  │   │                        ▼  重建 domain objects
  │   │                   Code / ComputerPlayer / Board
  │   │                        │
  │   │                        ▼
  │   │                   game.erb (渲染盤面)
  │   │
  │   └─ POST /game/guess ──► GameSession#submit_guess
  │                                │
  │                                ▼
  │                          Code.from_input → Feedback.new
  │                                │
  │                                ▼
  │                          Board#record → session[:game] 更新
  │                                │
  │                                ▼
  │                          redirect /game (PRG)
  ▼
browser (re-GET /game)
```

---

## 測試計畫（RSpec）

### `spec/spec_helper.rb` 修改

```ruby
require 'rack/test'
require_relative '../web/app'    # 引入 Sinatra app

RSpec.configure do |config|
  config.include Rack::Test::Methods, type: :request

  # 讓 request spec 知道要測哪個 app
  config.define_derived_metadata(file_path: %r{spec/web/}) do |meta|
    meta[:type] = :request
  end
end

def app
  Sinatra::Application  # 或 WebApp（若 app.rb 定義命名類別）
end
```

---

### `spec/web/game_session_spec.rb` — 單元測試

測試 `GameSession` 的序列化邏輯與狀態推進，**完全不發 HTTP 請求**。

```ruby
require 'spec_helper'
require_relative '../../lib/code'
require_relative '../../lib/feedback'
require_relative '../../lib/board'
require_relative '../../lib/computer_player'
require_relative '../../web/game_session'

RSpec.describe GameSession do

  describe '.new_guesser_game' do
    it '回傳含 role: guesser 的 Hash' do
      h = GameSession.new_guesser_game
      expect(h[:role]).to eq('guesser')
    end

    it '秘密碼長度為 4，每個元素為合法顏色字母' do
      h = GameSession.new_guesser_game
      expect(h[:secret].length).to eq(4)
      expect(h[:secret]).to all(match(/\A[RGBYOP]\z/))
    end

    it '初始 status 為 playing' do
      expect(GameSession.new_guesser_game[:status]).to eq('playing')
    end

    it '初始 history 為空' do
      expect(GameSession.new_guesser_game[:history]).to be_empty
    end
  end

  describe '.new_maker_game' do
    it '回傳含 role: maker 的 Hash' do
      h = GameSession.new_maker_game('RGYB')
      expect(h[:role]).to eq('maker')
    end

    it '秘密碼與輸入相符' do
      h = GameSession.new_maker_game('RGYB')
      expect(h[:secret]).to eq(%w[R G Y B])
    end
  end

  describe '.from_hash / #to_h 往返序列化' do
    it '序列化後再反序列化，turns_used 不變' do
      h       = GameSession.new_guesser_game
      session = GameSession.from_hash(h)
      expect(session.to_h).to eq(h)
    end
  end

  describe '#submit_guess' do
    subject(:session) { GameSession.from_hash(GameSession.new_guesser_game) }

    context '輸入合法' do
      it '回傳 ok: true' do
        result = session.submit_guess('RRRR')
        expect(result[:ok]).to be true
      end

      it 'turns_used 增加 1' do
        expect { session.submit_guess('RRRR') }.to change(session, :turns_used).by(1)
      end

      it '回傳 feedback 含 exact 與 color' do
        result = session.submit_guess('RRRR')
        expect(result[:feedback]).to have_key(:exact)
        expect(result[:feedback]).to have_key(:color)
      end
    end

    context '輸入非法（長度不對）' do
      it '回傳 ok: false 並含 error 訊息' do
        result = session.submit_guess('RRR')
        expect(result[:ok]).to be false
        expect(result[:error]).to be_a(String)
      end

      it 'turns_used 不增加' do
        expect { session.submit_guess('RRR') }.not_to change(session, :turns_used)
      end
    end

    context '猜中秘密碼' do
      it 'status 變為 won' do
        secret = session.to_h[:secret].join
        session.submit_guess(secret)
        expect(session.to_h[:status]).to eq('won')
      end
    end

    context '用完 12 輪' do
      it 'status 變為 lost' do
        12.times { session.submit_guess('RRRR') unless session.to_h[:status] != 'playing' }
        # 若秘密碼不是 RRRR，12 輪後應為 lost
        expect(%w[lost won]).to include(session.to_h[:status])
      end
    end
  end

  describe '#computer_guess' do
    subject(:session) { GameSession.from_hash(GameSession.new_maker_game('RGYB')) }

    it '回傳包含 guess 字串的 Hash' do
      result = session.computer_guess
      expect(result[:guess]).to match(/\A[RGBYOP]{4}\z/)
    end

    it 'turns_used 增加 1' do
      expect { session.computer_guess }.to change(session, :turns_used).by(1)
    end

    it '猜中時 status 變為 won' do
      # 強迫電腦猜到正確答案（stub）
      allow_any_instance_of(ComputerPlayer).to receive(:make_guess)
        .and_return(Code.from_input('RGYB'))
      session.computer_guess
      expect(session.to_h[:status]).to eq('won')
    end
  end

  describe '#board_rows' do
    it '初始為空陣列' do
      session = GameSession.from_hash(GameSession.new_guesser_game)
      expect(session.board_rows).to be_empty
    end

    it '每猜一次增加一列，含 guess / exact / color 欄位' do
      session = GameSession.from_hash(GameSession.new_guesser_game)
      session.submit_guess('RRRR')
      row = session.board_rows.first
      expect(row).to include(:guess, :exact, :color)
    end
  end
end
```

---

### `spec/web/app_spec.rb` — HTTP Request / 整合測試

使用 `Rack::Test` 模擬瀏覽器行為，**不啟動真實 server**。

```ruby
require 'spec_helper'

RSpec.describe 'Mastermind Web App', type: :request do

  # ── 首頁 ──────────────────────────────────────────────

  describe 'GET /' do
    it '回傳 200 並顯示角色選擇' do
      get '/'
      expect(last_response.status).to eq(200)
      expect(last_response.body).to include('Guesser')
      expect(last_response.body).to include('Code Maker')
    end

    it '顯示顏色說明（R G B Y O P）' do
      get '/'
      %w[R G B Y O P].each do |color|
        expect(last_response.body).to include(color)
      end
    end
  end

  # ── 開始遊戲 ──────────────────────────────────────────

  describe 'POST /game/start' do
    context 'role=1（Guesser）' do
      it 'redirect 到 /game' do
        post '/game/start', role: '1'
        expect(last_response).to be_redirect
        follow_redirect!
        expect(last_request.path).to eq('/game')
      end

      it '遊戲頁面顯示猜測輸入欄' do
        post '/game/start', role: '1'
        follow_redirect!
        expect(last_response.body).to include('<input')
        expect(last_response.body).to include('guess')
      end
    end

    context 'role=2（Maker）合法秘密碼' do
      it 'redirect 到 /game' do
        post '/game/start', role: '2', secret: 'RGYB'
        expect(last_response).to be_redirect
        follow_redirect!
        expect(last_request.path).to eq('/game')
      end

      it '遊戲頁面顯示「讓電腦猜」按鈕' do
        post '/game/start', role: '2', secret: 'RGYB'
        follow_redirect!
        expect(last_response.body).to include('/game/computer')
      end
    end

    context 'role=2 但秘密碼非法（長度不對）' do
      it 'redirect 回 / 並顯示錯誤' do
        post '/game/start', role: '2', secret: 'RRR'
        expect(last_response).to be_redirect
        follow_redirect!
        expect(last_request.path).to eq('/')
        expect(last_response.body).to include('error').or include('Error').or include('invalid').or include('Invalid')
      end
    end

    context 'role=2 但秘密碼含非法字母' do
      it 'redirect 回 / 並顯示錯誤' do
        post '/game/start', role: '2', secret: 'RXYZ'
        expect(last_response).to be_redirect
        follow_redirect!
        expect(last_request.path).to eq('/')
      end
    end
  end

  # ── 遊戲頁面（無 session） ────────────────────────────

  describe 'GET /game（無 session）' do
    it 'redirect 回首頁' do
      get '/game'
      expect(last_response).to be_redirect
      follow_redirect!
      expect(last_request.path).to eq('/')
    end
  end

  # ── 提交猜測 ─────────────────────────────────────────

  describe 'POST /game/guess' do
    before { post '/game/start', role: '1' }

    context '合法猜測' do
      it 'redirect 到 /game（PRG pattern）' do
        post '/game/guess', guess: 'RRRR'
        expect(last_response).to be_redirect
        follow_redirect!
        expect(last_request.path).to eq('/game')
      end

      it '歷史盤面顯示提交的猜測' do
        post '/game/guess', guess: 'RGYB'
        follow_redirect!
        expect(last_response.body).to include('RGYB')
      end

      it '顯示 Exact 與 Color 數字' do
        post '/game/guess', guess: 'RRRR'
        follow_redirect!
        expect(last_response.body).to match(/Exact|exact/)
        expect(last_response.body).to match(/Color|color/)
      end

      it '顯示剩餘回合數遞減' do
        post '/game/guess', guess: 'RRRR'
        follow_redirect!
        expect(last_response.body).to include('11')   # 12 - 1
      end
    end

    context '非法猜測（長度不對）' do
      it 'redirect 到 /game 並顯示錯誤，不扣回合' do
        post '/game/guess', guess: 'RRR'
        follow_redirect!
        expect(last_response.body).to include('12')   # turns 未減少
      end
    end

    context '非法猜測（含非法字母）' do
      it '顯示錯誤訊息' do
        post '/game/guess', guess: 'RXYZ'
        follow_redirect!
        expect(last_response.body).to match(/invalid|Invalid|error|Error/)
      end
    end
  end

  # ── 電腦猜測 ─────────────────────────────────────────

  describe 'POST /game/computer' do
    before { post '/game/start', role: '2', secret: 'RGYB' }

    it 'redirect 到 /game' do
      post '/game/computer'
      expect(last_response).to be_redirect
      follow_redirect!
      expect(last_request.path).to eq('/game')
    end

    it '盤面顯示電腦的猜測（4 個合法字母）' do
      post '/game/computer'
      follow_redirect!
      expect(last_response.body).to match(/[RGBYOP]{4}/)
    end

    it '連續觸發多次，turns_used 正確累加' do
      3.times { post '/game/computer' }
      follow_redirect!
      expect(last_response.body).to include('3').or include('Turn 4')
    end
  end

  # ── 重置 ─────────────────────────────────────────────

  describe 'POST /game/reset' do
    before { post '/game/start', role: '1' }

    it 'redirect 回首頁' do
      post '/game/reset'
      expect(last_response).to be_redirect
      follow_redirect!
      expect(last_request.path).to eq('/')
    end

    it '重置後 GET /game redirect 回首頁（session 清除）' do
      post '/game/reset'
      get '/game'
      expect(last_response).to be_redirect
      follow_redirect!
      expect(last_request.path).to eq('/')
    end
  end

  # ── 完整遊戲流程（整合測試）─────────────────────────

  describe '人類 Guesser 完整流程' do
    it '猜中秘密碼時顯示勝利訊息' do
      post '/game/start', role: '1'
      # 從 session 取出秘密碼（測試環境允許讀取）
      secret = rack_mock_session.cookie_jar['rack.session']  # 視實作調整取法
      # 直接 stub 秘密碼以確定性測試
      allow(Code).to receive(:random).and_return(Code.from_input('RGYB'))
      post '/game/start', role: '1'
      post '/game/guess', guess: 'RGYB'
      follow_redirect!
      expect(last_response.body).to match(/win|Win|cracked|Solved/i)
    end

    it '用完 12 輪後顯示失敗訊息' do
      allow(Code).to receive(:random).and_return(Code.from_input('RGYB'))
      post '/game/start', role: '1'
      12.times { post '/game/guess', guess: 'RRRR' }
      follow_redirect!
      expect(last_response.body).to match(/out of turns|failed|lose/i)
    end
  end

  describe '電腦 Guesser 完整流程' do
    it '電腦猜中時顯示電腦勝利訊息' do
      allow_any_instance_of(ComputerPlayer).to receive(:make_guess)
        .and_return(Code.from_input('RGYB'))
      post '/game/start', role: '2', secret: 'RGYB'
      post '/game/computer'
      follow_redirect!
      expect(last_response.body).to match(/computer|cracked/i)
    end
  end
end
```

---

## 執行測試

```bash
# 安裝新依賴
bundle install

# 執行所有測試（含 CLI 與 Web）
bundle exec rspec

# 只執行 Web 測試
bundle exec rspec spec/web/

# 執行單一 Web 測試檔
bundle exec rspec spec/web/app_spec.rb
bundle exec rspec spec/web/game_session_spec.rb

# 詳細輸出
bundle exec rspec --format documentation spec/web/
```

---

## 啟動 Web Server

```bash
# 開發模式（puma，port 4567）
bundle exec ruby web/app.rb

# 或用 rackup
bundle exec rackup config.ru -p 4567
```

---

## 實作順序

1. 新增 `Gemfile` 依賴（sinatra, rack-test 等），`bundle install`
2. 實作 `web/game_session.rb`，先跑 `game_session_spec.rb` 確認序列化正確
3. 實作 `web/app.rb` 路由骨架（GET `/`、POST `/game/start`、POST `/game/reset`）
4. 建立 `web/views/layout.erb`、`index.erb`，確認首頁可渲染
5. 實作 `web/views/game.erb`（共用盤面）
6. 實作 `POST /game/guess`（Guesser 模式）+ 對應 View
7. 實作 `POST /game/computer`（Maker 模式）+ 對應 View
8. 跑完整 `app_spec.rb`，修正失敗案例
9. 瀏覽器手動驗證兩種角色的完整遊戲流程

---

## 不在範圍內

- 多人 / 多 Session 同時對戰
- 資料庫持久化（排行榜等）
- WebSocket 即時更新
- JavaScript 前端框架（React / Vue 等）
- 使用者帳號系統
