#!/bin/bash
# Main.mをバックグラウンドで実行するスクリプト
# killしてもデータは残る（定期的にチェックポイントを保存）

# プロジェクトのルートディレクトリに移動
cd "$(dirname "$0")/.."

# MATLABのパス
MATLAB_PATH="/Applications/MATLAB_R2025a.app/bin/matlab"

# ログファイル名（タイムスタンプ付き）
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="Experiment/Result/run_${TIMESTAMP}.log"
PID_FILE="Experiment/Result/run_${TIMESTAMP}.pid"

# Resultディレクトリが存在しない場合は作成
mkdir -p Experiment/Result

# シグナルハンドラーを設定（Ctrl+Cで終了時にクリーンアップ）
cleanup() {
    echo ""
    echo "=== 実行を停止します ==="
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p $PID > /dev/null 2>&1; then
            echo "MATLABプロセス ($PID) を停止中..."
            kill $PID 2>/dev/null
            # 強制終了が必要な場合
            sleep 2
            if ps -p $PID > /dev/null 2>&1; then
                echo "強制終了中..."
                kill -9 $PID 2>/dev/null
            fi
        fi
        rm -f "$PID_FILE"
    fi
    echo "チェックポイントファイルは残っています: Experiment/Result/checkpoint_*.mat"
    echo "実行状況を確認: tail -f $LOG_FILE"
    exit 0
}

trap cleanup SIGINT SIGTERM

# MATLABをバックグラウンドで実行
# -nodisplay: ディスプレイなし
# -nosplash: スプラッシュスクリーンなし
# -r: 実行するコマンド
# -logfile: ログファイルに出力
echo "=== MATLAB実行を開始します ==="
echo "ログファイル: $LOG_FILE"
echo "PIDファイル: $PID_FILE"
echo ""

# nohupを使って、ターミナルを閉じても実行を続ける
nohup $MATLAB_PATH -nodisplay -nosplash -r "startup; cd Experiment; Main; exit" -logfile "$LOG_FILE" > /dev/null 2>&1 &

# プロセスIDを保存
PID=$!
echo $PID > "$PID_FILE"

echo "MATLABプロセスID: $PID"
echo "PIDファイルに保存: $PID_FILE"
echo ""
echo "=== 実行状況の確認方法 ==="
echo "  ログをリアルタイムで確認: tail -f $LOG_FILE"
echo "  プロセス状態を確認: ps -p $PID"
echo "  実行を停止: kill $PID または Ctrl+C"
echo ""
echo "=== 注意事項 ==="
echo "  - 実行を停止しても、チェックポイントファイルは残ります"
echo "  - チェックポイントファイル: Experiment/Result/checkpoint_*.mat"
echo "  - 最終結果ファイル: Experiment/Result/experiment_results_*.mat"
echo ""

# プロセスが終了するまで待機
wait $PID
EXIT_CODE=$?

# PIDファイルを削除
rm -f "$PID_FILE"

if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo "=== 実行が正常に完了しました ==="
else
    echo ""
    echo "=== 実行が終了しました (終了コード: $EXIT_CODE) ==="
    echo "チェックポイントファイルを確認してください: Experiment/Result/checkpoint_*.mat"
fi

