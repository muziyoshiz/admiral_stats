# Vagrant guide

Vagrant を使って、Admiral Stats の開発環境を簡単に作る方法の説明ページです。

## 必要条件

- ホスト OS に Vagrant および VirtualBox がインストール済みであること
- ホスト OS に Ansible 2系がインストール済みであること
    - セットアップに Ansible provisioner を使っているため、Ansible 必須
    - 開発者は macOS で動作確認済みです
    - Windows では恐らく難しいです（Shell provisioner での書き換え歓迎）

## オプション

事前に vagrant-hostupdater をインストールしておくと、セットアップ後に http://admiral-stats.dev:3000/ でアクセスできるようになります。

```
vagrant plugin install vagrant-hostsupdater
```

## 手順

ホスト OS 上で以下のコマンドを実行すると、VM のセットアップが最後まで自動実行されます。

```
git clone https://github.com/muziyoshiz/admiral_stats.git
cd admiral_stats
vagrant up --provider virtualbox
```

このコマンドが行う作業は、次の通りです。

- CentOS 7 の VM 作成
- NTP などの設定
- MySQL のセットアップ（root ユーザにパスワード無しでログイン可能）
- RVM, Ruby, Bundler, Rails のセットアップ
- Admiral Stats のセットアップ

## Admiral Stats の起動

以下のコマンドで、Admiral Stats が起動します。

```
vagrant ssh -c "cd /vagrant && rails s -b 0.0.0.0"
```

セットアップに成功していれば、以下の URL で Admiral Stats を表示できます。

- http://192.168.33.10:3000/
- http://admiral-stats.dev:3000/

### 開発環境でのログイン方法

Admiral Stats は Twitter 経由でのログインしか提供していません。
この機能は本番環境でしか使えないため、開発環境用のログイン手段を用意しています。

開発環境のみ、以下の URL にアクセスすることでログインできます。これは RAILS_ENV=development で動作中のみ有効な機能です。

- http://192.168.33.10:3000/sessions/debug_create/1/test_user_name

別のユーザでログインしたい場合は、1 と test_user_name の部分を変えてください。
