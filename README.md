# vanaclock_obs
OBSでFF11 ヴァナ時間をリアルタイム表示するためのスクリプト

## 導入方法
1. スクリプトのセットアップ
   - OBSの「ツール」→「スクリプト」を開き、「スクリプト」タグの「ロードしたスクリプト」にvanaclock.lua(本スクリプト)を追加する
2. 表示するテキストソースの作成
   - ソースにテキスト(GDI+)を追加し、名前を付ける
3. ソースとスクリプトの関連付け
   - 「ツール」→「スクリプト」を開き、「スクリプト」タグの「ロードしたスクリプト」で本スクリプトを選択し、「Display Text Source欄」に2.でつけた名前を記入する
4. 実行・レイアウト編集
   - シーンをアクティブにすると動作します。サイズ変更等はテキストが表示されてから実施してください。
  
## 注意事項
- ローカルの時刻から算出しているため、実際のヴァナ時刻(=サーバタイム)とずれることがあります。
 (実時間1分でヴァナ時間25のずれとなります)気になる方はNTP等により時刻を同期の上、ご利用ください。
