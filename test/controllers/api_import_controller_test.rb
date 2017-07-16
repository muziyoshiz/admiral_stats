require 'test_helper'

class ApiImportControllerTest < ActionDispatch::IntegrationTest
  # Time.parse("2017-02-27 16:00:00 +09:00").to_i
  # => 1488178800
  TOKEN = JWT.encode({ id: 1, iat: 1488178800 }, Rails.application.secrets.secret_key_base, 'HS256')

  test 'data_types Authorizationヘッダを指定しない場合' do
    get '/api/v1/import/file_types'

    assert_response 401
    assert_equal 'Bearer realm="Admiral Stats"', @response.header['WWW-Authenticate']
    assert_equal JSON.generate(
        {
            errors: [
                { message: 'Unauthorized' }
            ]
        }), @response.body
  end

  test 'data_types' do
    # API call 前にはログが無いことを確認
    assert_equal false, ApiRequestLog.all.exists?

    get '/api/v1/import/file_types', headers: { 'Authorization' => "Bearer #{TOKEN}" }

    assert_response 200
    assert_equal JSON.generate(
        [
            'Personal_basicInfo',
            'TcBook_info',
            'CharacterList_info',
            'Event_info'
        ]), @response.body

    # ログがあることを確認
    logs = ApiRequestLog.all
    assert_equal true, logs.exists?
    assert_equal 1, logs.size
    l = logs[0]

    # ログの内容を確認
    assert_equal 1, l.admiral_id
    assert_equal 'GET', l.request_method
    assert_equal 'http://www.example.com/api/v1/import/file_types', l.request_uri
    assert_nil l.user_agent
    assert_equal 200, l.status_code
    assert_nil l.response
    assert_not_nil l.created_at
  end

  test 'data_types User-Agent ヘッダがある場合' do
    # API call 前にはログが無いことを確認
    assert_equal false, ApiRequestLog.all.exists?

    get '/api/v1/import/file_types', headers: { 'Authorization' => "Bearer #{TOKEN}", 'User-Agent' => 'AdmiralStatsExporter-Ruby/1.6.1' }

    assert_response 200
    assert_equal JSON.generate(
        [
            'Personal_basicInfo',
            'TcBook_info',
            'CharacterList_info',
            'Event_info'
        ]), @response.body

    # ログがあることを確認
    logs = ApiRequestLog.all
    assert_equal true, logs.exists?
    assert_equal 1, logs.size
    l = logs[0]

    # ログの内容を確認
    assert_equal 1, l.admiral_id
    assert_equal 'GET', l.request_method
    assert_equal 'http://www.example.com/api/v1/import/file_types', l.request_uri
    assert_equal 'AdmiralStatsExporter-Ruby/1.6.1', l.user_agent
    assert_equal 200, l.status_code
    assert_nil l.response
    assert_not_nil l.created_at
  end

  test 'data_types Origin ヘッダがある場合' do
    # テスト対象を明確にするために、ログのテストは省略

    get '/api/v1/import/file_types', headers: { 'Authorization' => "Bearer #{TOKEN}", 'Origin' => 'https://kancolle-arcade.net'}

    assert_response 200
    assert_equal JSON.generate(
        [
            'Personal_basicInfo',
            'TcBook_info',
            'CharacterList_info',
            'Event_info'
        ]), @response.body

    assert_equal '*', @response.headers['Access-Control-Allow-Origin']
    assert_equal 'GET, POST, OPTIONS', @response.headers['Access-Control-Allow-Methods']
    assert_nil @response.headers['Access-Control-Allow-Headers']
    assert_equal '3600', @response.headers['Access-Control-Max-Age']
    # credential (cookieなど) を使う場合は true に設定する必要があるが、Admiral Stats では不要
    assert_nil @response.headers['Access-Control-Allow-Credentials']
  end

  test 'data_types Origin および Access-Control-Request-Headers ヘッダがある場合' do
    # テスト対象を明確にするために、ログのテストは省略

    get '/api/v1/import/file_types', headers: {
        'Authorization' => "Bearer #{TOKEN}",
        'Origin' => 'https://kancolle-arcade.net',
        'Access-Control-Request-Method' => 'GET',
        'Access-Control-Request-Headers' => 'Content-Type, Authorization'
    }

    assert_response 200
    assert_equal JSON.generate(
        [
            'Personal_basicInfo',
            'TcBook_info',
            'CharacterList_info',
            'Event_info'
        ]), @response.body

    assert_equal '*', @response.headers['Access-Control-Allow-Origin']
    assert_equal 'GET, POST, OPTIONS', @response.headers['Access-Control-Allow-Methods']
    # GET に対しては、Access-Control-Allow-Headers が返されない
    assert_nil @response.headers['Access-Control-Allow-Headers']
    assert_equal '3600', @response.headers['Access-Control-Max-Age']
    # credential (cookieなど) を使う場合は true に設定する必要があるが、Admiral Stats では不要
    assert_nil @response.headers['Access-Control-Allow-Credentials']
  end

  test 'Authorizationヘッダを指定しない場合' do
    post api_import_url('Personal_basicInfo', '20170227_160000')

    # http://api.rubyonrails.org/classes/ActionDispatch/Assertions/ResponseAssertions.html#method-i-assert_response
    assert_response 401
    assert_equal 'Bearer realm="Admiral Stats"', @response.header['WWW-Authenticate']
    assert_equal JSON.generate(
        {
            errors: [
                { message: 'Unauthorized' }
            ]
        }), @response.body
  end

  test 'Bearer 以外の token を指定した場合' do
    post api_import_url('Personal_basicInfo', '20170227_160000'), headers: { 'Authorization' => "token #{TOKEN}" }

    assert_response 401
    assert_equal 'Bearer realm="Admiral Stats"', @response.header['WWW-Authenticate']
    assert_equal JSON.generate(
        {
            errors: [
                { message: 'Unauthorized' }
            ]
        }), @response.body
  end

  test 'Authorizationヘッダに指定したトークンが、違う鍵で作られたものの場合' do
    # 違う鍵でトークンを生成
    another_token = JWT.encode({ id: 1, iat: 1488178800 }, '824a5efc905a43a054f0ecce827284c899d1f60a24343b9fdc096d088dbec5fa1ef0326986c6d1780ed44eeb7d98f4344ee71926d6932c687755e05f8f862415', 'HS256')

    post api_import_url('Personal_basicInfo', '20170227_160000'), headers: { 'Authorization' => "Bearer #{another_token}" }

    assert_response 401
    assert_equal 'Bearer realm="Admiral Stats", error="invalid_token"', @response.header['WWW-Authenticate']
    assert_equal JSON.generate(
        {
            errors: [
                { message: 'Invalid token' }
            ]
        }), @response.body
  end

  test '有効期限切れの（admiral_tokens テーブルから削除されている）トークンを指定した場合' do
    # Time.parse("2016-02-27 16:00:00 +09:00").to_i
    # => 1456556400
    expired_token = JWT.encode({ id: 1, iat: 1456556400 }, Rails.application.secrets.secret_key_base, 'HS256')

    post api_import_url('Personal_basicInfo', '20170227_160000'), headers: { 'Authorization' => "Bearer #{expired_token}" }

    assert_response 401
    assert_equal 'Bearer realm="Admiral Stats", error="invalid_token"', @response.header['WWW-Authenticate']
    assert_equal JSON.generate(
        {
            errors: [
                { message: 'Expired token' }
            ]
        }), @response.body
  end

  test '未サポートのファイル種別を指定した場合' do
    # API call 前にはログが無いことを確認
    assert_equal false, ApiRequestLog.all.exists?

    post api_import_url('unknown_file_type', 'test2'), headers: { 'Authorization' => "Bearer #{TOKEN}" }

    assert_response 200

    assert_equal JSON.generate(
        {
            data: { message: 'Admiral Stats がインポートできないファイル種別のため、無視されました。（ファイル種別：unknown_file_type）' }
        }), @response.body

    # ログがあることを確認
    logs = ApiRequestLog.all
    assert_equal true, logs.exists?
    assert_equal 1, logs.size
    l = logs[0]

    # ログの内容を確認
    assert_equal 1, l.admiral_id
    assert_equal 'POST', l.request_method
    assert_equal 'http://www.example.com/api/v1/import/unknown_file_type/test2', l.request_uri
    assert_equal 200, l.status_code
    assert_nil l.user_agent
    assert_equal 'Admiral Stats がインポートできないファイル種別のため、無視されました。（ファイル種別：unknown_file_type）', l.response
    assert_not_nil l.created_at
  end

  test '不正な形式のタイムスタンプを指定した場合' do
    # API call 前にはログが無いことを確認
    assert_equal false, ApiRequestLog.all.exists?

    post api_import_url('Personal_basicInfo', '202X0101_000000'), headers: { 'Authorization' => "Bearer #{TOKEN}" }

    assert_response 400

    assert_equal JSON.generate(
        {
            errors: [
                { message: 'タイムスタンプの形式が不正です。（タイムスタンプ：202X0101_000000）' }
            ]
        }), @response.body

    # ログがあることを確認
    logs = ApiRequestLog.all
    assert_equal true, logs.exists?
    assert_equal 1, logs.size
    l = logs[0]

    # ログの内容を確認
    assert_equal 1, l.admiral_id
    assert_equal 'POST', l.request_method
    assert_equal 'http://www.example.com/api/v1/import/Personal_basicInfo/202X0101_000000', l.request_uri
    assert_equal 400, l.status_code
    assert_nil l.user_agent
    assert_equal 'タイムスタンプの形式が不正です。（タイムスタンプ：202X0101_000000）', l.response
    assert_not_nil l.created_at
  end

  test '空のボディをアップロードした場合' do
    # 登録前にはレコードが無いことを確認
    exported_at = Time.parse('2017-02-27 16:00:00 +09:00')
    assert_equal false, AdmiralStatus.where(admiral_id: 1, exported_at: exported_at).exists?
    assert_equal false, ApiRequestLog.where(admiral_id: 1).exists?

    post api_import_url('Personal_basicInfo', '20170227_160000'),
         params: nil, headers: { 'Authorization' => "Bearer #{TOKEN}", 'Content-Type' => 'application/json' }

    assert_response 400

    assert_equal JSON.generate(
        {
            errors: [
                { message: '基本情報のインポートに失敗しました。（原因：A JSON text must at least contain two octets!）' }
            ]
        }), @response.body

    # 登録後にはレコードがあることを確認
    records = AdmiralStatus.where(admiral_id: 1, exported_at: exported_at)
    assert_equal false, records.exists?

    # ログがあることを確認
    logs = ApiRequestLog.where(admiral_id: 1)
    assert_equal true, logs.exists?
    assert_equal 1, logs.size
    l = logs[0]

    # ログの内容を確認
    assert_equal 1, l.admiral_id
    assert_equal 'POST', l.request_method
    assert_equal 'http://www.example.com/api/v1/import/Personal_basicInfo/20170227_160000', l.request_uri
    # ログには 200 レスポンスとして記録される
    # TODO 要修正
    assert_equal 200, l.status_code
    assert_nil l.user_agent
    assert_equal '基本情報のインポートに失敗しました。（原因：A JSON text must at least contain two octets!）', l.response
    assert_not_nil l.created_at
  end

  test '基本情報のインポート' do
    # Personal_basicInfo
    json = <<-JSON
{"fuel":6750,"ammo":6183,"steel":7126,"bauxite":6513,"bucket":46,"level":32,"roomItemCoin":82,"resultPoint":"3571","rank":"圏外","titleId":7,"materialMax":7200,"strategyPoint":915}
    JSON

    # 登録前にはレコードが無いことを確認
    exported_at = Time.parse('2017-02-27 16:00:00 +09:00')
    assert_equal false, AdmiralStatus.where(admiral_id: 1, exported_at: exported_at).exists?
    assert_equal false, ApiRequestLog.where(admiral_id: 1).exists?

    post api_import_url('Personal_basicInfo', '20170227_160000'),
         params: json, headers: { 'Authorization' => "Bearer #{TOKEN}", 'Content-Type' => 'application/json' }

    assert_response 201

    assert_equal JSON.generate(
        {
            data: {
                message: '基本情報のインポートに成功しました。'
            }
        }), @response.body

    # 登録後にはレコードがあることを確認
    records = AdmiralStatus.where(admiral_id: 1, exported_at: exported_at)
    assert_equal true, records.exists?

    assert_equal 1, records.size
    r = records[0]

    # レコードの内容を確認
    assert_equal 1,      r.admiral_id
    assert_equal 6750,   r.fuel
    assert_equal 6183,   r.ammo
    assert_equal 7126,   r.steel
    assert_equal 6513,   r.bauxite
    assert_equal 46,     r.bucket
    assert_equal 32,     r.level
    assert_equal 82,     r.room_item_coin
    assert_equal '3571', r.result_point
    assert_equal '圏外', r.rank
    assert_equal 7,      r.title_id
    assert_equal 915,    r.strategy_point
    assert_equal exported_at, r.exported_at

    # ログがあることを確認
    logs = ApiRequestLog.where(admiral_id: 1)
    assert_equal true, logs.exists?
    assert_equal 1, logs.size
    l = logs[0]

    # ログの内容を確認
    assert_equal 1, l.admiral_id
    assert_equal 'POST', l.request_method
    assert_equal 'http://www.example.com/api/v1/import/Personal_basicInfo/20170227_160000', l.request_uri
    assert_equal 201, l.status_code
    assert_nil l.user_agent
    assert_equal '基本情報のインポートに成功しました。', l.response
    assert_not_nil l.created_at
  end

  test '基本情報のインポート Origin ヘッダがある場合' do
    # テスト対象を明確にするために、ログのテストと、レコードの詳細確認は省略

    # Personal_basicInfo
    json = <<-JSON
{"fuel":6750,"ammo":6183,"steel":7126,"bauxite":6513,"bucket":46,"level":32,"roomItemCoin":82,"resultPoint":"3571","rank":"圏外","titleId":7,"materialMax":7200,"strategyPoint":915}
    JSON

    # 登録前にはレコードが無いことを確認
    exported_at = Time.parse('2017-02-27 16:00:00 +09:00')
    assert_equal false, AdmiralStatus.where(admiral_id: 1, exported_at: exported_at).exists?

    post api_import_url('Personal_basicInfo', '20170227_160000'),
         params: json, headers: {
            'Authorization' => "Bearer #{TOKEN}",
            'Content-Type' => 'application/json',
            'Origin' => 'https://kancolle-arcade.net',
        }

    assert_response 201

    assert_equal JSON.generate(
        {
            data: {
                message: '基本情報のインポートに成功しました。'
            }
        }), @response.body

    # 登録後にはレコードがあることを確認
    records = AdmiralStatus.where(admiral_id: 1, exported_at: exported_at)
    assert_equal true, records.exists?

    assert_equal '*', @response.headers['Access-Control-Allow-Origin']
    assert_equal 'GET, POST, OPTIONS', @response.headers['Access-Control-Allow-Methods']
    assert_nil @response.headers['Access-Control-Allow-Headers']
    assert_equal '3600', @response.headers['Access-Control-Max-Age']
    # credential (cookieなど) を使う場合は true に設定する必要があるが、Admiral Stats では不要
    assert_nil @response.headers['Access-Control-Allow-Credentials']
  end

  test '同じ日時の基本情報をインポート済みの場合' do
    # Personal_basicInfo
    json = <<-JSON
{"fuel":6750,"ammo":6183,"steel":7126,"bauxite":6513,"bucket":46,"level":32,"roomItemCoin":82,"resultPoint":"3571","rank":"圏外","titleId":7,"materialMax":7200,"strategyPoint":915}
    JSON

    # 登録前にはレコードが無いことを確認
    exported_at = Time.parse('2017-02-27 17:00:00 +09:00')
    assert_equal true, AdmiralStatus.where(admiral_id: 1, exported_at: exported_at).exists?
    assert_equal false, ApiRequestLog.where(admiral_id: 1).exists?

    post api_import_url('Personal_basicInfo', '20170227_170000'),
         params: json, headers: { 'Authorization' => "Bearer #{TOKEN}", 'Content-Type' => 'application/json' }

    assert_response 200

    assert_equal JSON.generate(
        {
            data: {
                message: '同じ時刻の基本情報がインポート済みのため、無視されました。'
            }
        }), @response.body

    # ログがあることを確認
    logs = ApiRequestLog.where(admiral_id: 1)
    assert_equal true, logs.exists?
    assert_equal 1, logs.size
    l = logs[0]

    # ログの内容を確認
    assert_equal 1, l.admiral_id
    assert_equal 'POST', l.request_method
    assert_equal 'http://www.example.com/api/v1/import/Personal_basicInfo/20170227_170000', l.request_uri
    assert_equal 200, l.status_code
    assert_nil l.user_agent
    assert_equal '同じ時刻の基本情報がインポート済みのため、無視されました。', l.response
    assert_not_nil l.created_at
  end

  test '基本情報のインポート User-Agent がある場合' do
    # Personal_basicInfo
    json = <<-JSON
{"fuel":6750,"ammo":6183,"steel":7126,"bauxite":6513,"bucket":46,"level":32,"roomItemCoin":82,"resultPoint":"3571","rank":"圏外","titleId":7,"materialMax":7200,"strategyPoint":915}
    JSON

    # 登録前にはレコードが無いことを確認
    exported_at = Time.parse('2017-02-27 16:00:00 +09:00')
    assert_equal false, AdmiralStatus.where(admiral_id: 1, exported_at: exported_at).exists?
    assert_equal false, ApiRequestLog.where(admiral_id: 1).exists?

    post api_import_url('Personal_basicInfo', '20170227_160000'),
         params: json, headers: { 'Authorization' => "Bearer #{TOKEN}", 'Content-Type' => 'application/json', 'User-Agent' => 'AdmiralStatsExporter-Ruby/1.6.1' }

    assert_response 201

    assert_equal JSON.generate(
        {
            data: {
                message: '基本情報のインポートに成功しました。'
            }
        }), @response.body

    # 登録後にはレコードがあることを確認
    records = AdmiralStatus.where(admiral_id: 1, exported_at: exported_at)
    assert_equal true, records.exists?

    assert_equal 1, records.size
    r = records[0]

    # レコードの内容を確認
    assert_equal 1,      r.admiral_id
    assert_equal 6750,   r.fuel
    assert_equal 6183,   r.ammo
    assert_equal 7126,   r.steel
    assert_equal 6513,   r.bauxite
    assert_equal 46,     r.bucket
    assert_equal 32,     r.level
    assert_equal 82,     r.room_item_coin
    assert_equal '3571', r.result_point
    assert_equal '圏外', r.rank
    assert_equal 7,      r.title_id
    assert_equal 915,    r.strategy_point
    assert_equal exported_at, r.exported_at

    # ログがあることを確認
    logs = ApiRequestLog.where(admiral_id: 1)
    assert_equal true, logs.exists?
    assert_equal 1, logs.size
    l = logs[0]

    # ログの内容を確認
    assert_equal 1, l.admiral_id
    assert_equal 'POST', l.request_method
    assert_equal 'http://www.example.com/api/v1/import/Personal_basicInfo/20170227_160000', l.request_uri
    assert_equal 201, l.status_code
    assert_equal 'AdmiralStatsExporter-Ruby/1.6.1', l.user_agent
    assert_equal '基本情報のインポートに成功しました。', l.response
    assert_not_nil l.created_at
  end

  test '艦娘図鑑のインポート' do
    # 艦娘図鑑のインポートは分離レベルを指定しているため、
    # self.use_transactional_tests = true (default)
    # に指定された状態では、MySQL では実行できない。実行すると、以下のエラーが発生する。
    # "cannot set transaction isolation in a nested transaction"
  end

  test '艦娘一覧のインポート' do
    # CharacterList_info
    json = <<-JSON
[
  {"bookNo":85,"lv":97,"shipType":"駆逐艦","shipSortNo":1800,"remodelLv":0,"shipName":"朝潮","statusImg":"i/i_69ex6r4uutp3_n.png","starNum":5,"shipClass":"朝潮型","shipClassIndex":1,"tcImg":"s/tc_85_69ex6r4uutp3.jpg","expPercent":97,"maxHp":16,"realHp":16,"damageStatus":"NORMAL","slotNum":2,"slotEquipName":["","","",""],"slotAmount":[0,0,0,0],"slotDisp":["NONE","NONE","NONE","NONE"],"slotImg":["","","",""]},
  {"bookNo":85,"lv":97,"shipType":"駆逐艦","shipSortNo":1800,"remodelLv":1,"shipName":"朝潮改","statusImg":"i/i_umacfn9qcwp1_n.png","starNum":5,"shipClass":"朝潮型","shipClassIndex":1,"tcImg":"s/tc_85_umacfn9qcwp1.jpg","expPercent":97,"maxHp":31,"realHp":31,"damageStatus":"NORMAL","slotNum":3,"slotEquipName":["10cm高角砲＋高射装置","10cm高角砲＋高射装置","61cm四連装(酸素)魚雷",""],"slotAmount":[0,0,0,0],"slotDisp":["NONE","NONE","NONE","NONE"],"slotImg":["equip_icon_26_rv74l134q7an.png","equip_icon_26_rv74l134q7an.png","equip_icon_5_c4bcdscek33o.png",""]},
  {"bookNo":124,"lv":70,"shipType":"重巡洋艦","shipSortNo":1500,"remodelLv":0,"shipName":"鈴谷","statusImg":"i/i_zrr1yq3annrq_n.png","starNum":5,"shipClass":"最上型","shipClassIndex":3,"tcImg":"s/tc_124_2uejd60gndj3.jpg","expPercent":4,"maxHp":40,"realHp":40,"damageStatus":"NORMAL","slotNum":3,"slotEquipName":["","","",""],"slotAmount":[2,2,2,0],"slotDisp":["NOT_EQUIPPED_AIRCRAFT","NOT_EQUIPPED_AIRCRAFT","NOT_EQUIPPED_AIRCRAFT","NONE"],"slotImg":["","","",""]},
  {"bookNo":129,"lv":70,"shipType":"航空巡洋艦","shipSortNo":1400,"remodelLv":1,"shipName":"鈴谷改","statusImg":"i/i_6cc94esr14nz_n.png","starNum":5,"shipClass":"最上型","shipClassIndex":3,"tcImg":"s/tc_129_7k4atc4mguna.jpg","expPercent":4,"maxHp":50,"realHp":50,"damageStatus":"NORMAL","slotNum":4,"slotEquipName":["20.3cm(3号)連装砲","瑞雲","15.5cm三連装副砲","三式弾"],"slotAmount":[5,6,5,6],"slotDisp":["NOT_EQUIPPED_AIRCRAFT","EQUIPPED_AIRCRAFT","NOT_EQUIPPED_AIRCRAFT","NOT_EQUIPPED_AIRCRAFT"],"slotImg":["equip_icon_2_n8b0sex6xclf.png","equip_icon_10_lpoysb3zk6s4.png","equip_icon_4_mgy58yrghven.png","equip_icon_13_jdkmrexetpvn.png"]}
]
    JSON

    # 登録前にはレコードが無いことを確認
    exported_at = Time.parse('2017-02-27 16:00:00 +09:00')
    assert_equal false, ShipStatus.where(admiral_id: 1, exported_at: exported_at).exists?
    assert_equal false, ApiRequestLog.where(admiral_id: 1).exists?

    post api_import_url('CharacterList_info', '20170227_160000'),
         params: json, headers: { 'Authorization' => "Bearer #{TOKEN}", 'Content-Type' => 'application/json' }

    assert_response 201

    assert_equal JSON.generate(
        {
            data: {
                message: '艦娘一覧のインポートに成功しました。'
            }
        }), @response.body

    # 登録後にはレコードがあることを確認
    records = ShipStatus.where(admiral_id: 1, exported_at: exported_at)
    assert_equal true, records.exists?

    assert_equal 4, records.size

    # 朝潮
    r = records[0]
    assert_equal 1,  r.admiral_id
    assert_equal 85, r.book_no
    assert_equal 0,  r.remodel_level
    assert_equal 97, r.level
    assert_equal 5,  r.star_num
    assert_equal exported_at, r.exported_at

    # 朝潮改
    r = records[1]
    assert_equal 1,  r.admiral_id
    assert_equal 85, r.book_no
    assert_equal 1,  r.remodel_level
    assert_equal 97, r.level
    assert_equal 5,  r.star_num
    assert_equal exported_at, r.exported_at

    # 鈴谷
    r = records[2]
    assert_equal 1,   r.admiral_id
    assert_equal 124, r.book_no
    assert_equal 0,   r.remodel_level
    assert_equal 70,  r.level
    assert_equal 5,   r.star_num
    assert_equal exported_at, r.exported_at

    # 鈴谷改
    r = records[3]
    assert_equal 1,   r.admiral_id
    assert_equal 129, r.book_no
    assert_equal 1,   r.remodel_level
    assert_equal 70,  r.level
    assert_equal 5,   r.star_num
    assert_equal exported_at, r.exported_at

    # ログがあることを確認
    logs = ApiRequestLog.where(admiral_id: 1)
    assert_equal true, logs.exists?
    assert_equal 1, logs.size
    l = logs[0]

    # ログの内容を確認
    assert_equal 1, l.admiral_id
    assert_equal 'POST', l.request_method
    assert_equal 'http://www.example.com/api/v1/import/CharacterList_info/20170227_160000', l.request_uri
    assert_equal 201, l.status_code
    assert_nil l.user_agent
    assert_equal '艦娘一覧のインポートに成功しました。', l.response
    assert_not_nil l.created_at
  end

  test 'イベント進捗情報のインポート' do
    # Event_info
    # HEI E-1 クリア、E-5 未クリア
    # OTU 未クリア
    json = <<-'JSON'
[
  {
    "areaId":1000,"areaSubId":1,"level":"HEI","areaKind":"NORMAL","stageImageName":"area_14yzzpb2ab.png",
    "stageMissionName":"前哨戦","stageMissionInfo":"敵泊地へ強襲作戦が発令された！\n主作戦に先立ち、敵泊地海域付近の\n偵察を実施せよ！",
    "requireGp":300,"limitSec":240,
    "rewardList":[
      {"rewardType":"FIRST","dataId":0,"kind":"ROOM_ITEM_COIN","value":50},
      {"rewardType":"FIRST","dataId":1,"kind":"RESULT_POINT","value":500},
      {"rewardType":"SECOND","dataId":0,"kind":"RESULT_POINT","value":200}
    ],
    "stageDropItemInfo":["SMALLBOX","MEDIUMBOX","SMALLREC","NONE"],"sortieLimit":false,
    "areaClearState":"CLEAR","militaryGaugeStatus":"BREAK",
    "eneMilitaryGaugeVal":1000,"militaryGaugeLeft":0,"bossStatus":"NONE","loopCount":1
  },
  {
    "areaId":1000,"areaSubId":5,"level":"HEI","areaKind":"SWEEP","stageImageName":"area_0555h7ae9d.png",
    "stageMissionName":"？","stageMissionInfo":"？",
    "requireGp":0,"limitSec":0,
    "rewardList":[{"dataId":0,"kind":"NONE","value":0}],
    "stageDropItemInfo":["UNKNOWN","NONE","NONE","NONE"],"sortieLimit":false,
    "areaClearState":"NOTCLEAR","militaryGaugeStatus":"NONE",
    "eneMilitaryGaugeVal":0,"militaryGaugeLeft":0,"bossStatus":"NONE","loopCount":1
  },
  {"areaId":1000,"areaSubId":6,"level":"OTU","areaKind":"NORMAL","stageImageName":"area_237vdef8kn.png","stageMissionName":"？","stageMissionInfo":"？","requireGp":0,"limitSec":0,"rewardList":[{"dataId":0,"kind":"NONE","value":0}],"stageDropItemInfo":["UNKNOWN","NONE","NONE","NONE"],"sortieLimit":false,"areaClearState":"NOOPEN","militaryGaugeStatus":"NORMAL","eneMilitaryGaugeVal":1500,"militaryGaugeLeft":1500,"bossStatus":"NONE","loopCount":1},
  {"areaId":1000,"areaSubId":7,"level":"OTU","areaKind":"NORMAL","stageImageName":"area_y6kdvxsugb.png","stageMissionName":"？","stageMissionInfo":"？","requireGp":0,"limitSec":0,"rewardList":[{"dataId":0,"kind":"NONE","value":0}],"stageDropItemInfo":["UNKNOWN","NONE","NONE","NONE"],"sortieLimit":false,"areaClearState":"NOOPEN","militaryGaugeStatus":"NORMAL","eneMilitaryGaugeVal":1500,"militaryGaugeLeft":1500,"bossStatus":"NONE","loopCount":1},
  {"areaId":1000,"areaSubId":8,"level":"OTU","areaKind":"NORMAL","stageImageName":"area_fgp9wbuh6t.png","stageMissionName":"？","stageMissionInfo":"？","requireGp":0,"limitSec":0,"rewardList":[{"dataId":0,"kind":"NONE","value":0}],"stageDropItemInfo":["UNKNOWN","NONE","NONE","NONE"],"sortieLimit":false,"areaClearState":"NOOPEN","militaryGaugeStatus":"NORMAL","eneMilitaryGaugeVal":1800,"militaryGaugeLeft":1800,"bossStatus":"NONE","loopCount":1},
  {"areaId":1000,"areaSubId":9,"level":"OTU","areaKind":"BOSS","stageImageName":"area_22cohixmiv.png","stageMissionName":"？","stageMissionInfo":"？","requireGp":0,"limitSec":0,"rewardList":[{"dataId":0,"kind":"NONE","value":0}],"stageDropItemInfo":["UNKNOWN","NONE","NONE","NONE"],"sortieLimit":false,"areaClearState":"NOOPEN","militaryGaugeStatus":"NORMAL","eneMilitaryGaugeVal":2500,"militaryGaugeLeft":2500,"bossStatus":"ONI","loopCount":1},
  {"areaId":1000,"areaSubId":10,"level":"OTU","areaKind":"SWEEP","stageImageName":"area_ehj5inlsw0.png","stageMissionName":"？","stageMissionInfo":"？","requireGp":0,"limitSec":0,"rewardList":[{"dataId":0,"kind":"NONE","value":0}],"stageDropItemInfo":["UNKNOWN","NONE","NONE","NONE"],"sortieLimit":false,"areaClearState":"NOOPEN","militaryGaugeStatus":"NONE","eneMilitaryGaugeVal":0,"militaryGaugeLeft":0,"bossStatus":"NONE","loopCount":1}
]
    JSON

    # 登録前にはレコードが無いことを確認
    exported_at = Time.parse('2017-02-27 16:00:00 +09:00')
    assert_equal false, EventProgressStatus.where(admiral_id: 1, exported_at: exported_at).exists?
    assert_equal false, ApiRequestLog.where(admiral_id: 1).exists?

    post api_import_url('Event_info', '20170227_160000'),
         params: json, headers: { 'Authorization' => "Bearer #{TOKEN}", 'Content-Type' => 'application/json' }

    assert_response 201

    assert_equal JSON.generate(
        {
            data: {
                message: 'イベント進捗情報のインポートに成功しました。'
            }
        }), @response.body

    # 登録後にはレコードがあることを確認
    records = EventProgressStatus.where(admiral_id: 1, exported_at: exported_at)
    assert_equal true, records.exists?

    assert_equal 2, records.size

    # レコードの内容を確認
    r = records[0]
    assert_equal 1,     r.admiral_id
    assert_equal 1,     r.event_no
    assert_equal 'HEI', r.level
    assert_equal true,  r.opened
    assert_equal 1,     r.current_loop_counts
    assert_equal 0,     r.cleared_loop_counts
    assert_equal 1,     r.cleared_stage_no
    assert_equal 0,     r.current_military_gauge_left
    assert_equal exported_at, r.exported_at

    r = records[1]
    assert_equal 1,     r.admiral_id
    assert_equal 1,     r.event_no
    assert_equal 'OTU', r.level
    assert_equal false, r.opened
    assert_equal 1,     r.current_loop_counts
    assert_equal 0,     r.cleared_loop_counts
    assert_equal 0,     r.cleared_stage_no
    assert_equal 1500,  r.current_military_gauge_left
    assert_equal exported_at, r.exported_at

    # ログがあることを確認
    logs = ApiRequestLog.where(admiral_id: 1)
    assert_equal true, logs.exists?
    assert_equal 1, logs.size
    l = logs[0]

    # ログの内容を確認
    assert_equal 1, l.admiral_id
    assert_equal 'POST', l.request_method
    assert_equal 'http://www.example.com/api/v1/import/Event_info/20170227_160000', l.request_uri
    assert_equal 201, l.status_code
    assert_nil l.user_agent
    assert_equal 'イベント進捗情報のインポートに成功しました。', l.response
    assert_not_nil l.created_at
  end
end
