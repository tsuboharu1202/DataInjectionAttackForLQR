#!/bin/bash
# 実行中のMain.mを停止するスクリプト

cd "$(dirname "$0")/.."

# PIDファイルを検索
PID_FILES=$(find Experiment/Result -name "run_*.pid" -type f 2>/dev/null)

if [ -z "$PID_FILES" ]; then
    echo "実行中のプロセスが見つかりません（PIDファイルが存在しません）"
    echo ""
    echo "手動でプロセスを確認する場合:"
    echo "  ps aux | grep matlab"
    exit 1
fi

# 最新のPIDファイルを使用
LATEST_PID_FILE=$(ls -t $PID_FILES | head -1)
PID=$(cat "$LATEST_PID_FILE" 2>/dev/null)

if [ -z "$PID" ]; then
    echo "PIDファイルが読み込めません: $LATEST_PID_FILE"
    exit 1
fi

# プロセスが実行中か確認
if ! ps -p $PID > /dev/null 2>&1; then
    echo "プロセス $PID は既に終了しています"
    rm -f "$LATEST_PID_FILE"
    exit 0
fi

echo "=== MATLABプロセスを停止します ==="
echo "プロセスID: $PID"
echo "PIDファイル: $LATEST_PID_FILE"
echo ""

# プロセスを停止
echo "停止シグナルを送信..."
kill $PID 2>/dev/null

# 5秒待機
sleep 5

# まだ実行中の場合は強制終了
if ps -p $PID > /dev/null 2>&1; then
    echo "プロセスがまだ実行中です。強制終了します..."
    kill -9 $PID 2>/dev/null
    sleep 1
fi

# PIDファイルを削除
rm -f "$LATEST_PID_FILE"

if ps -p $PID > /dev/null 2>&1; then
    echo "警告: プロセスの停止に失敗しました"
    exit 1
else
    echo "プロセスを停止しました"
    echo ""
    echo "チェックポイントファイルは残っています:"
    echo "  Experiment/Result/checkpoint_*.mat"
    exit 0
fi







