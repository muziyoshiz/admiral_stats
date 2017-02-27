require 'test_helper'

class ApiImportControllerTest < ActionDispatch::IntegrationTest
  # Time.parse("2017-02-27 16:00:00 +09:00").to_i
  # => 1488178800
  TOKEN = JWT.encode({ id: 1, iat: 1488178800 }, Rails.application.secrets.secret_key_base, 'HS256')

  test 'Authorizationヘッダを指定しない場合' do
    post api_import_url('Personal_basicInfo', '20170227_160000')

    # http://api.rubyonrails.org/classes/ActionDispatch/Assertions/ResponseAssertions.html#method-i-assert_response
    assert_response 401

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

    post api_import_url('Personal_basicInfo', '20170227_160000'), headers: { 'Authorization' => "bearer #{another_token}" }

    assert_response 401

    assert_equal JSON.generate(
        {
            errors: [
                { message: 'Invalid token' }
            ]
        }), @response.body
  end

  test '未サポートのファイル種別を指定した場合' do
    post api_import_url('unknown_file_type', 'test2'), headers: { 'Authorization' => "bearer #{TOKEN}" }

    assert_response 200

    assert_equal JSON.generate(
        {
            errors: [
                { message: 'Unsupported file type: unknown_file_type' }
            ]
        }), @response.body
  end

  test '不正な形式のタイムスタンプを指定した場合' do
    post api_import_url('Personal_basicInfo', '202X0101_000000'), headers: { 'Authorization' => "bearer #{TOKEN}" }

    assert_response 200

    assert_equal JSON.generate(
        {
            errors: [
                { message: 'Invalid timestamp: 202X0101_000000' }
            ]
        }), @response.body
  end

  test '有効期限切れの（admiral_tokens テーブルから削除されている）トークンを指定した場合' do
    # Time.parse("2016-02-27 16:00:00 +09:00").to_i
    # => 1456556400
    expired_token = JWT.encode({ id: 1, iat: 1456556400 }, Rails.application.secrets.secret_key_base, 'HS256')

    post api_import_url('Personal_basicInfo', '20170227_160000'), headers: { 'Authorization' => "bearer #{expired_token}" }

    assert_response 401

    assert_equal JSON.generate(
        {
            errors: [
                { message: 'Expired token' }
            ]
        }), @response.body
  end

  test '基本情報のインポート' do
    # Personal_basicInfo
    json = <<-JSON
{"fuel":6750,"ammo":6183,"steel":7126,"bauxite":6513,"bucket":46,"level":32,"roomItemCoin":82,"resultPoint":"3571","rank":"圏外","titleId":7,"materialMax":7200,"strategyPoint":915}
    JSON

    # 登録前にはレコードが無いことを確認
    exported_at = Time.parse("2017-02-27 16:00:00 +09:00")
    assert_equal false, AdmiralStatus.where(admiral_id: 1, exported_at: exported_at).exists?

    post api_import_url('Personal_basicInfo', '20170227_160000'),
         params: json, headers: { 'Authorization' => "bearer #{TOKEN}", 'Content-Type' => 'application/json' }

    assert_response 200

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
    assert_equal "3571", r.result_point
    assert_equal "圏外", r.rank
    assert_equal 7,      r.title_id
    assert_equal 915,    r.strategy_point
  end

  test '艦娘図鑑のインポート' do
    # TcBook_info
    json = <<-JSON

    JSON

  end

  test '艦娘一覧のインポート' do
    # CharacterList_info
    json = <<-JSON

    JSON
  end

  test 'イベント進捗情報のインポート' do
    # Event_info
    json = <<-JSON

    JSON
  end
end
