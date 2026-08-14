class AddGaveInToUrges < ActiveRecord::Migration[8.1]
  # 「我慢できなかった」を resolved の4つ目の状態にせず、独立した軸として持つ。
  # enum だと状態が排他になり、calmed の記録を我慢できなかったに変えた瞬間に
  # 「落ち着いた」という事実が消える。両方とも実際に起きたことなので消してはいけない。
  #
  # default: false は「まだ何も言っていない」であって「我慢できた」ではない。
  # true を既定にすると、全レコードがアプリの知らない成功を主張し、一覧が勝ち星の列になる。
  def change
    add_column :urges, :gave_in, :boolean, default: false, null: false
  end
end
