# タイトル、説明を切り詰める長さの初期値（meta-tags のデフォルト値と同じもの）
MetaTags.configure do |c|
  c.title_limit        = 70
  c.description_limit  = 160
  c.keywords_limit     = 255
  c.keywords_separator = ', '
end