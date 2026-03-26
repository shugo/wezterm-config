-- Pull in the wezterm API
local wezterm = require 'wezterm'
local act = wezterm.action

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices.

-- For example, changing the initial geometry for new windows:
config.initial_cols = 120
config.initial_rows = 36

-- or, changing the font size and color scheme.
config.font = wezterm.font_with_fallback {
  {
    family = 'Fira Code',
    -- harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' },
  },
  {
    family = 'Cascadia Code', -- for hankaku symbols
    weight = 'Regular',
  },
  {
    family = 'Noto Sans CJK JP',
  },
}
config.font_size = 12
-- config.color_scheme = 'Tango (base16)'
config.color_scheme = 'Tango (terminal.sexy)'
-- config.color_scheme = 'GitHub Dark (Gosh)'

-- config.enable_wayland = false
config.use_ime = true
config.xcursor_theme = "Yaru"
config.treat_east_asian_ambiguous_width_as_wide = false
local default_window_background_opacity = 0.85
config.window_background_opacity = default_window_background_opacity
config.default_cursor_style = 'BlinkingBlock'
-- config.cursor_blink_ease_in = 'Constant'
-- config.cursor_blink_ease_out = 'Constant'
config.visual_bell = {
  fade_in_duration_ms = 200,
  fade_out_duration_ms = 200,
  target = 'CursorColor',
}

config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.show_new_tab_button_in_tab_bar = false

wezterm.on('format-window-title', function(tab, pane, tabs, panes, config)
  return tab.active_pane.title
end)
wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
  local title = tab.active_pane.title
  local index = tostring(tab.tab_index + 1)
  local padding_width = #(index .. " : ")
  if #title > max_width - padding_width then
    title = wezterm.truncate_right(title, max_width - padding_width)
  end

  return {
    { Text = " " .. index .. ":" .. title .. " " },
  }
end)
wezterm.on('update-right-status', function(window, pane)
  local time = wezterm.strftime('%H:%M')

  window:set_right_status(wezterm.format({
    { Foreground = { Color = '#ffffff' } },
    { Text = ' ' .. time .. ' ' },
  }))
end)

config.colors = {
  cursor_bg = '#c5c8c6',
  cursor_fg = '#1d1f21',
  cursor_border = '#c5c8c6',
  visual_bell = '#ff4444',
  tab_bar = {
    background = '#444444',
    inactive_tab = {
      bg_color = '#444444',
      fg_color = '#c5c8c6',
      intensity = 'Normal',
    },
    active_tab = {
      bg_color = '#c5c8c6',
      fg_color = '#444444',
      intensity = 'Bold',
    },
  },
}


-- For presentation
-- config.font_size = 37
-- config initial_cols = 48
-- config initial_rows = 14
-- config enable_tab_bar = false

-- CopyMode/SearchMode を終了する際に検索パターンもクリアするアクション
local function close_copy_mode()
  return act.Multiple {
    { CopyMode = 'ClearPattern' },
    { CopyMode = 'Close' },
  }
end

-- CopyModeのEmacsキーバインド定義
local copy_mode_emacs_keys = {
  -- === カーソル移動 ===

  -- 文字単位
  { key = 'f', mods = 'CTRL',  action = act.CopyMode 'MoveRight' },
  { key = 'b', mods = 'CTRL',  action = act.CopyMode 'MoveLeft' },
  { key = 'n', mods = 'CTRL',  action = act.CopyMode 'MoveDown' },
  { key = 'p', mods = 'CTRL',  action = act.CopyMode 'MoveUp' },

  -- 行頭・行末
  { key = 'a', mods = 'CTRL',  action = act.CopyMode 'MoveToStartOfLineContent' },
  { key = 'e', mods = 'CTRL',  action = act.CopyMode 'MoveToEndOfLineContent' },

  -- 単語単位 (Meta/Alt)
  { key = 'f', mods = 'META',  action = act.CopyMode 'MoveForwardWord' },
  { key = 'b', mods = 'META',  action = act.CopyMode 'MoveBackwardWord' },

  -- ページ移動
  { key = 'v', mods = 'CTRL',  action = act.CopyMode 'PageDown' },
  { key = 'v', mods = 'META',  action = act.CopyMode 'PageUp' },

  -- バッファの先頭・末尾
  { key = '<', mods = 'META',  action = act.CopyMode 'MoveToScrollbackTop' },
  { key = '>', mods = 'META',  action = act.CopyMode 'MoveToScrollbackBottom' },

  -- 画面の先頭・中央・末尾 (Emacs: M-r に相当)
  { key = 'R', mods = 'META',  action = act.CopyMode 'MoveToViewportTop' },
  { key = 'r', mods = 'META',  action = act.CopyMode 'MoveToViewportMiddle' },

  -- === 選択 (マーク) ===

  -- C-Space または C-@ でマーク開始
  { key = 'Space', mods = 'CTRL', action = act.CopyMode { SetSelectionMode = 'Cell' } },
  { key = 'g',     mods = 'CTRL', action = close_copy_mode() }, -- C-g でキャンセル/終了

  -- 行選択モード (C-x h に近い感覚で行単位選択)
  { key = 'x', mods = 'CTRL', action = act.CopyMode { SetSelectionMode = 'Line' } },

  -- 矩形選択 (C-x r)
  { key = 'r', mods = 'CTRL', action = act.CopyMode { SetSelectionMode = 'Block' } },

  -- === コピー・終了 ===

  -- M-w でコピーしてCopyModeを抜ける (Emacsの kill-ring-save)
  {
    key = 'w',
    mods = 'META',
    action = act.Multiple {
      { CopyMode = 'MoveLeft' },
      { CopyTo = 'ClipboardAndPrimarySelection' },
      { CopyMode = 'ClearPattern' },
      { CopyMode = 'Close' },
    },
  },

  -- Enter でもコピー
  {
    key = 'Return',
    mods = 'NONE',
    action = act.Multiple {
      { CopyTo = 'ClipboardAndPrimarySelection' },
      { CopyMode = 'ClearPattern' },
      { CopyMode = 'Close' },
    },
  },

  -- C-g でキャンセル (選択解除 or CopyMode終了)
  { key = 'g', mods = 'CTRL', action = close_copy_mode() },

  -- q でも終了
  { key = 'q', mods = 'NONE', action = close_copy_mode() },

  -- Escape でも終了
  { key = 'Escape', mods = 'NONE', action = close_copy_mode() },

  -- === 検索 (Isearch風) ===

  -- C-s で前方検索
  {
    key = 's',
    mods = 'CTRL',
    action = act.Search { CaseSensitiveString = '' },
  },

  -- C-r で後方検索
  {
    key = 'r',
    mods = 'CTRL',
    action = act.Search { CaseSensitiveString = '' },
  },
}

-- SearchModeのEmacsキーバインド定義
-- search_modeはテキスト入力が主体なので、制御キーのみ設定する
local search_mode_emacs_keys = {
  -- === 検索ナビゲーション ===

  -- C-s: 次のマッチへ (Emacs isearch-repeat-forward)
  { key = 's', mods = 'CTRL', action = act.CopyMode 'NextMatch' },

  -- C-r: 前のマッチへ (Emacs isearch-repeat-backward)
  { key = 'r', mods = 'CTRL', action = act.CopyMode 'PriorMatch' },

  -- Enter: 前のマッチへ (デフォルト踏襲)
  { key = 'Return', mods = 'NONE', action = act.CopyMode 'PriorMatch' },

  -- ページ単位ジャンプ
  { key = 'v', mods = 'CTRL', action = act.CopyMode 'NextMatchPage' },
  { key = 'v', mods = 'META', action = act.CopyMode 'PriorMatchPage' },

  -- === 入力編集 ===

  -- C-u: パターンをクリア (Emacs kill-whole-line 風)
  { key = 'u', mods = 'CTRL', action = act.CopyMode 'ClearPattern' },

  -- C-w: 単語削除 (Emacs backward-kill-word 風)
  -- WezTermのsearch_modeでは SendKey で代替
  { key = 'w', mods = 'CTRL', action = act.SendKey { key = 'w', mods = 'CTRL' } },

  -- C-h / Backspace: 1文字削除
  { key = 'h',         mods = 'CTRL', action = act.SendKey { key = 'Backspace' } },
  { key = 'Backspace', mods = 'NONE', action = act.SendKey { key = 'Backspace' } },

  -- === 検索タイプの切り替え ===

  -- C-t: マッチタイプをサイクル (CaseSensitive / CaseInSensitive / Regex)
  { key = 't', mods = 'CTRL', action = act.CopyMode 'CycleMatchType' },

  -- === モード遷移 ===

  -- Enter でCopyModeに戻り、選択・コピー操作へ移行
  -- (C-s で検索しながら Enter で結果確認 → CopyModeでマーク & M-w でコピー)
  { key = 'Return', mods = 'NONE', action = act.ActivateCopyMode },

  -- C-g / Escape: SearchModeを閉じる（パターンもクリア）
  { key = 'g',      mods = 'CTRL', action = close_copy_mode() },
  { key = 'Escape', mods = 'NONE', action = close_copy_mode() },
}

-- CopyMode / SearchMode のキーバインドとして設定
config.key_tables = {
  copy_mode  = copy_mode_emacs_keys,
  search_mode = search_mode_emacs_keys,
}

----------------------------------------------------
-- keybinds
----------------------------------------------------
-- config.disable_default_key_bindings = true
-- config.keys = require("keybinds").keys
-- config.key_tables = require("keybinds").key_tables
config.leader = { key = "]", mods = "ALT", timeout_milliseconds = 2000 }
config.keys = {
  { key = "c", mods = "LEADER", action = act({ SpawnTab = "CurrentPaneDomain" }) },
  { key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
  { key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },
  { key = "1", mods = "LEADER", action = act.ActivateTab(0) },
  { key = "2", mods = "LEADER", action = act.ActivateTab(1) },
  { key = "3", mods = "LEADER", action = act.ActivateTab(2) },
  { key = "4", mods = "LEADER", action = act.ActivateTab(3) },
  { key = "5", mods = "LEADER", action = act.ActivateTab(4) },
  { key = "6", mods = "LEADER", action = act.ActivateTab(5) },
  { key = "7", mods = "LEADER", action = act.ActivateTab(6) },
  { key = "8", mods = "LEADER", action = act.ActivateTab(7) },
  { key = "9", mods = "LEADER", action = act.ActivateTab(8) },
  { key = "]", mods = "LEADER|ALT", action = act.ActivateLastTab },
  { key = "[", mods = "LEADER", action = act.ActivateCopyMode },
  { key = "]", mods = "LEADER", action = act.PasteFrom("Clipboard") },
  { key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
  { key = "h", mods = "LEADER|ALT", action = act.SplitPane { direction = "Left" } },
  { key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
  { key = "j", mods = "LEADER|ALT", action = act.SplitPane { direction = "Down" } },
  { key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
  { key = "k", mods = "LEADER|ALT", action = act.SplitPane { direction = "Up" } },
  { key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
  { key = "l", mods = "LEADER|ALT", action = act.SplitPane { direction = "Right" } },
  {
    key = '+',
    mods = 'CTRL|ALT|SHIFT',
    action = wezterm.action_callback(function(window, pane)
      local overrides = window:get_config_overrides() or {}
      -- 現在の値を取得（未設定なら1.0と仮定）
      local current = overrides.window_background_opacity or 1.0
      if current < 1.0 then
        overrides.window_background_opacity = current + 0.05
      end
      window:set_config_overrides(overrides)
    end),
  },
  {
    key = '_',
    mods = 'CTRL|ALT|SHIFT',
    action = wezterm.action_callback(function(window, pane)
      local overrides = window:get_config_overrides() or {}
      local current = overrides.window_background_opacity or 1.0
      if current > 0.0 then
        overrides.window_background_opacity = math.max(0, current - 0.05)
      end
      window:set_config_overrides(overrides)
    end),
  },
  {
    key = ')',
    mods = 'CTRL|ALT|SHIFT',
    action = wezterm.action_callback(function(window, pane)
      local overrides = window:get_config_overrides() or {}
      overrides.window_background_opacity = default_window_background_opacity
      window:set_config_overrides(overrides)
    end),
  },
}

-- Finally, return the configuration to wezterm:
return config
