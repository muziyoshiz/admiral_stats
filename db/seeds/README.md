# Admiral Stats のマスターデータについて

艦これアーケードの艦娘、装備、イベントに関する全ユーザ共通の情報（以下、マスターデータ）は、すべて CSV ファイル形式で管理されています。

マスターデータが間違っている場合は、GitHub 上や、Twitter の [@admiral_stats](https://www.admiral-stats.com/admiral_stats) までご報告頂ければ修正します。 

## マスターデータのデータ構造

### 艦娘情報

#### [ship_masters.csv](ship_masters.csv)

- Book No.
    - 艦娘図鑑の図鑑 No.
- Ship class
    - 艦型
- Ship class index
    - 艦番号
- Ship type
    - 艦種
- Ship name
    - 艦名
- Variation num
    - その図鑑 No. を持つカードのバリエーション数（通常は3か6）
- Remodel level
    - ノーマルカードの改造レベルを表す数値
    - この値が 1 の場合は、図鑑の 1 枚目のカードが改
    - この値が 2 の場合は、図鑑の 1 枚目のカードが改二
- Implemented at
    - 艦これアーケードで実装された日時
    - 未実装の場合は NULL（CSV ファイル上では空文字列）
- Memo
    - マスターデータ管理のためのメモ（データベースには登録されない）

#### [updated_ship_masters.csv](updated_ship_masters.csv)

- Book No.
    - あとから改が実装される艦娘の図鑑 No.
- Ship class
    - ship_masters.csv と同じ
- Ship class index
    - ship_masters.csv と同じ
- Ship type
    - ship_masters.csv と同じ
- Ship name
    - ship_masters.csv と同じ
- Variation num
    - その図鑑 No. を持つカードのバリエーション数
    - このレコードが必要になるのは、通常は 3（ノーマルのみ）から6（ノーマルおよび改）に増える場合
- Remodel level
    - ship_masters.csv と同じ
- Implemented at
    - 艦これアーケード上で、カードのバリエーション数が変わった日時
- Memo
    - マスターデータ管理のためのメモ（データベースには登録されない）

#### [special_ship_masters.csv](special_ship_masters.csv)

- Book No.
    - 特別デザインのカードが実装された艦娘の図鑑 No.
- Card index
    - 追加されたカードの図鑑内でのインデックス（0〜）
- Remodel level
    - 追加されたカードの改造レベルを表す数値
    - 0 ならノーマル、1 なら改
- Rarity
    - 追加されたカードのレアリティを表す数値
    - 0: ノーマル相当
    - 1: ホロ相当（運が上がる）
    - 2: 中破相当（運が上がり、装甲が下がる）
- Implemented at
    - 特別デザインのカードのドロップ開始日時
- Memo
    - マスターデータ管理のためのメモ（データベースには登録されない）

### 装備情報

#### [equipment_masters.csv](equipment_masters.csv)

- Book No.
    - 装備図鑑の図鑑 No.
- Equipment ID
    - 装備一覧の装備 ID
    - 図鑑 No. と異なる **場合がある** ので、事前にわからない
    - 未知の装備の場合は NULL
- Rarity
    - 装備のレアリティを表す星の数
    - CSV ファイル上にはわかりやすくするため「☆コモン」のように表示しているが、データベースには星の数だけを登録している
- Equipment name
    - 装備名
- Equipment type
    - 装備種別
    - [艦これ Wiki](http://wikiwiki.jp/kancolle/?%C1%F5%C8%F7) にある装備種別（SEGA 公式サイトの表示よりも細かい）を登録している
- Implemented at
    - 艦これアーケードで実装された日時
    - 未実装の場合は NULL（CSV ファイル上では空文字列）
- Memo
    - マスターデータ管理のためのメモ（データベースには登録されない）

### イベント情報

#### [event_masters.csv](event_masters.csv)

- Event No.
    - イベント No. （例：第壱回なら 1）
- Area ID
    - 海域番号
    - JSON ファイルに含まれる内部的なもので、提督情報には表示されない
- Event name
    - 期間限定海域名
- No. of periods
    - 作戦数（通常は1、多段作戦の場合は2以上）
    - 第1回イベントは多段作戦ではない。第2回イベントは前段作戦/後段作戦
- Period1 started at
    - 後段作戦の開始時刻
    - 後段作戦がない場合は NULL（CSV ファイル上では空文字列）
- Started at
    - イベントの開始時刻
- Ended at
    - イベントの終了時刻
- Memo
    - マスターデータ管理のためのメモ（データベースには登録されない）

#### [event_stage_masters.csv](event_stage_masters.csv)

- Event No.
    - イベント No. （例：第壱回なら 1）
- Level
    - 難易度（HEI, OTU, KOU）
- Period
    - 作戦
    - 前段作戦の場合は 0, 後段作戦の場合は 1
    - 前段作戦/後段作戦に分かれていない場合は 0 のみ
- Stage No.
    - ステージ No.
    - E-1 なら 1
    - 後段作戦が E-4 から始まる場合、E-4 なら 1
- Display stage No.
    - 表示用のステージ No.
    - 後段作戦が E-4 から始まる場合、4
    - 掃討戦の場合は 0
- Stage mission name
    - 作戦名
- Ene military gauge val
    - 海域ゲージの最大値
- Memo
    - マスターデータ管理のためのメモ（データベースには登録されない）

## マスターデータの登録手順

1. 新しい艦娘、装備、イベントの情報を入手する
    - 公式サイトのお知らせを見る
    - 公式サイトの提督情報を見る
    - エクスポートした JSON を見る
2. Excel で Shift JIS 形式の CSV ファイル（*_masters.csv）を編集する
3. 開発環境で db/seeds.rb を実行する
    - この処理のなかで、UTF-8 形式の CSV ファイル（*_masters.utf8.csv）が自動生成される
4. 本番環境で db/seeds.rb を実行する
    - 本番環境では、UFT-8 形式の CSV ファイルのみを使う
