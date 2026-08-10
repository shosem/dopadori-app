require "rails_helper"

# テストが開発DBに対して走っていないことを、毎回の rspec で確かめる。
#
# 一度実際に起きている: コンテナが RAILS_ENV=development を設定していたため
# rails_helper の `ENV['RAILS_ENV'] ||= 'test'` が効かず、全 spec が開発DBに
# 対して走っていた。database.yml の test セクションを正しく書いても、
# そもそも test 環境で走っていなければ意味がない。
#
# 「文書に分離済みと書いてあること」ではなく「実際にどこへ繋がっているか」を
# 検証対象にするため、手で打つ確認コマンドではなくテストとして残す。
RSpec.describe "テスト実行環境" do
  it "test 環境で走っている" do
    expect(Rails.env).to eq("test")
  end

  it "開発DBとは別のデータベースに繋がっている" do
    development_db = ActiveRecord::Base.configurations
      .configs_for(env_name: "development", name: "primary")
      .database

    expect(ActiveRecord::Base.connection_db_config.database).not_to eq(development_db)
  end
end
