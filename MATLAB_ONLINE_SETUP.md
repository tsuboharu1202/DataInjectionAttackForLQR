# MATLAB Online セットアップガイド

このプロジェクトをMATLAB Online（東大ライセンス）で実行するための手順です。

## 前提条件

- MATLAB Online へのアクセス（東大アカウント）
- MOSEK ライセンス（MATLAB Onlineでも利用可能か確認が必要）
- YALMIP ツールボックス（MATLAB Onlineにインストール済みか確認）

## セットアップ手順

### 1. プロジェクトのアップロード

#### 方法A: GitHubからクローン（推奨）

```matlab
% MATLAB Onlineのコマンドウィンドウで実行
cd ~/Documents/MATLAB
!git clone https://github.com/tsuboharu1202/DataInjectionAttackForLQR.git ForLQR
cd ForLQR
```

#### 方法B: ZIPファイルでアップロード

1. ローカルでプロジェクトをZIP圧縮
2. MATLAB Onlineの「ファイル」→「アップロード」でZIPをアップロード
3. 解凍してプロジェクトフォルダに移動

### 2. パスの設定

```matlab
% プロジェクトルートに移動
cd ~/Documents/MATLAB/ForLQR  % またはアップロードしたパス

% startup.mを実行してパスを設定
startup
```

### 3. 必要なツールボックスの確認

```matlab
% YALMIPの確認
try
    yalmip('version')
    fprintf('YALMIP: OK\n');
catch
    error('YALMIPがインストールされていません。Add-On Explorerからインストールしてください。');
end

% MOSEKの確認
try
    mosekopt('version')
    fprintf('MOSEK: OK\n');
catch
    warning('MOSEKが利用できない可能性があります。YALMIPの自動フォールバックに依存します。');
end
```

### 4. 動作確認

```matlab
% 簡単なデモを実行
cd scripts
demo_attack
```

## 実験の実行

### 基本的な実行方法

```matlab
% プロジェクトルートに移動
cd ~/Documents/MATLAB/ForLQR

% startup.mを実行
startup

% 実験を実行
cd Experiment
Main
```

### 長時間実行時の注意点

**重要**: MATLAB Onlineはセッションタイムアウトがある可能性があります。

1. **チェックポイント機能を活用**
   - `Main.m`は自動的にチェックポイントを保存します
   - セッションが切れても、チェックポイントから再開可能

2. **進捗の確認**
   - コマンドウィンドウに進捗が表示されます
   - `Result/experiment_YYYYMMDD_HHMMSS/` フォルダで結果を確認できます

3. **セッションタイムアウト対策**
   ```matlab
   % チェックポイントから再開する場合
   cd Experiment/Result
   % 最新のcheckpoint_*.matを確認
   % Main.mを修正して、チェックポイントから読み込むロジックを追加
   ```

### パラメータの調整

`Experiment/Main.m`の以下の部分を編集：

```matlab
% 本番実験用パラメータ
PARAM_ATTACKER_UPPERLIMIT = [0.0001, 0.0005, 0.001, 0.005, 0.01];
PARAM_SAMPLE_COUNT = [5, 10, 20, 50, 100];
PARAM_SYSTEM_DIM = [3, 2; 4, 3; 6, 4; 8, 5];
NUM_TRIALS = 50;  % 本番は50回
```

## 結果の確認

### 可視化

```matlab
cd Experiment
% 結果ファイルのパスを指定
visualize_results('Result/experiment_YYYYMMDD_HHMMSS.mat')
% または、新しいディレクトリ構造の場合
visualize_results('Result/experiment_YYYYMMDD_HHMMSS')
```

### データのダウンロード

1. MATLAB Onlineの「ファイル」パネルから
2. `Experiment/Result/experiment_YYYYMMDD_HHMMSS/` フォルダを右クリック
3. 「ダウンロード」を選択（ZIP形式でダウンロード可能）

## トラブルシューティング

### MOSEKが使えない場合

`lqr_src/+sdp/solveSDP.m`で自動的にフォールバックされますが、明示的に設定する場合：

```matlab
% cfg.Const.mを編集
SOLVER = "sdpt3"  % または "sedumi", "sdpa"
```

### メモリ不足の場合

`Main.m`で以下を確認：

```matlab
SAVE_TRIAL_DATA_TO_FILE = true;  % ファイルに保存（メモリ効率化）
```

### パスの問題

```matlab
% 現在のパスを確認
path

% startup.mを再実行
startup

% パスが正しく設定されているか確認
which cfg.Const
which datasim.SystemData
```

## 注意事項

1. **MATLAB Driveの容量制限**: 結果データは15-20MB程度ですが、複数の実験を実行する場合は容量に注意
2. **セッションタイムアウト**: 長時間実行時は定期的にチェックポイントが保存されることを確認
3. **MOSEKライセンス**: 東大のライセンスがMATLAB Onlineでも有効か事前に確認してください

## サポート

問題が発生した場合：
1. エラーメッセージを確認
2. `Experiment/Result/` フォルダのチェックポイントファイルを確認
3. GitHubのIssuesに報告

