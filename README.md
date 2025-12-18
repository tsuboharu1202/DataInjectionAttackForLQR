# Data Injection Attack for Direct Data-Driven Control (LQR)

データ駆動制御に対するデータインジェクション攻撃の実験プロジェクト。

## 概要

このプロジェクトは、直接データ駆動制御（Direct Data-Driven Control）に対する敵対的攻撃を実装・評価するためのMATLABコードです。

- **攻撃手法**: DGSM (Direct Gradient-based Sensitivity Method) with implicit differentiation
- **制御手法**: SDP-based LQR controller design
- **実験**: パラメータ空間での網羅的な評価

## プロジェクト構造

```
ForLQR/
├── +cfg/              # 設定クラス（AttackType, Const）
├── basic_src/         # 基本機能（データ生成、システム定義）
├── lqr_src/           # LQR関連（攻撃、勾配計算、SDP解法）
│   ├── +attack/       # 攻撃手法の実装
│   ├── +grad/         # 勾配計算（direct/implicit）
│   ├── +implicit/     # 暗黙的微分（KKT条件ベース）
│   └── +sdp/          # SDP解法
├── Experiment/        # 実験スクリプト
│   ├── Main.m         # メイン実験スクリプト
│   └── visualize_results.m  # 結果可視化
├── scripts/           # デモ・テストスクリプト
└── startup.m          # パス設定
```

## クイックスタート

### ローカル環境

```matlab
% 1. パスを設定
startup

% 2. デモを実行
cd scripts
demo_attack

% 3. 実験を実行
cd Experiment
Main
```

### MATLAB Online

詳細は [MATLAB_ONLINE_SETUP.md](MATLAB_ONLINE_SETUP.md) を参照してください。

## 主な機能

### 1. データ生成
- 安定化された開ループシステムのシミュレーション
- 前安定化（pre-stabilization）による安全なデータ収集

### 2. 攻撃手法
- **DIRECT_***: 有限差分による勾配計算
- **IMPLICIT_***: KKT条件ベースの暗黙的微分（高速）

### 3. 実験管理
- パラメータ空間での網羅的評価
- チェックポイント機能（長時間実行対応）
- メタデータ保存（再現性の確保）

## 依存関係

- MATLAB R2020b以降
- YALMIP
- MOSEK (推奨) または SDPT3/SeDuMi/SDPA
- Statistics and Machine Learning Toolbox (可視化用、オプション)

## ライセンス

東大ライセンス（MATLAB Online使用時）

## 参考文献

プロジェクト内のPDFファイルを参照してください。
