% Main.m - データインジェクション攻撃の実験スクリプト
% 先行研究に則った条件で、各パラメータ組み合わせに対して20回試行し、結果を集計

clear; clc; close all;
startup;

% ========================================
% 実験パラメータの設定
% ========================================
% 攻撃手法（固定）
% - DIRECT_*  : finite-difference gradients
% - IMPLICIT_*: implicit-differentiation gradients (faster)
ATTACK_METHOD = cfg.AttackType.IMPLICIT_DGSM_EV;

% 変動パラメータ（先行研究に基づく）
PARAM_ATTACKER_UPPERLIMIT = [0.0001,0.0005, 0.001, 0.005,0.01];  % 攻撃制約
PARAM_SAMPLE_COUNT = [5, 10, 20, 50, 100];  % サンプル数
PARAM_SYSTEM_DIM = [ 3, 2; 4, 3; 6, 4; 8, 5];  % [n, m] の組み合わせ

% 実験設定
NUM_TRIALS = 50;  % 各条件での試行回数
RESULT_DIR = fullfile(fileparts(mfilename('fullpath')), 'Result');

% 結果保存用のディレクトリを作成
if ~exist(RESULT_DIR, 'dir')
    mkdir(RESULT_DIR);
end

% メモリ効率化オプション
SAVE_TRIAL_DATA_TO_FILE = true;  % true: 試行データをファイルに保存, false: メモリに保存（非推奨）

% ========================================
% 実験ループ
% ========================================
% 有効な条件数を計算（T >= n+m を満たすもののみ）
TOTAL_CONDITIONS = 0;
for idx_eps = 1:length(PARAM_ATTACKER_UPPERLIMIT)
    for idx_T = 1:length(PARAM_SAMPLE_COUNT)
        T = PARAM_SAMPLE_COUNT(idx_T);
        for idx_dim = 1:size(PARAM_SYSTEM_DIM, 1)
            n = PARAM_SYSTEM_DIM(idx_dim, 1);
            m = PARAM_SYSTEM_DIM(idx_dim, 2);
            if T >= n + m
                TOTAL_CONDITIONS = TOTAL_CONDITIONS + 1;
            end
        end
    end
end
TOTAL_TRIALS = TOTAL_CONDITIONS * NUM_TRIALS;

fprintf('=== 実験開始 ===\n');
fprintf('攻撃手法: %s\n', string(ATTACK_METHOD));
fprintf('試行回数/条件: %d回\n', NUM_TRIALS);
fprintf('総条件数: %d (T >= n+m を満たすもののみ)\n', TOTAL_CONDITIONS);
fprintf('総試行数: %d\n', TOTAL_TRIALS);
fprintf('パラメータ組み合わせ:\n');
fprintf('  - ATTACKER_UPPERLIMIT: %s\n', mat2str(PARAM_ATTACKER_UPPERLIMIT));
fprintf('  - SAMPLE_COUNT: %s\n', mat2str(PARAM_SAMPLE_COUNT));
fprintf('  - SYSTEM_DIM: [n, m] = %s\n', mat2str(PARAM_SYSTEM_DIM));
fprintf('  - 制約: T >= n+m (データ数の最小要件)\n');
fprintf('\n');

total_conditions = 0;
% メモリ効率化: 事前にcell配列として確保（配列再割り当てを避ける）
all_results = cell(TOTAL_CONDITIONS, 1);
start_time = tic;
timestamp = datestr(now, 'yyyymmdd_HHMMSS');  % チェックポイント用のタイムスタンプ

% 実験用のルートディレクトリを作成
EXPERIMENT_DIR = fullfile(RESULT_DIR, sprintf('experiment_%s', timestamp));
if ~exist(EXPERIMENT_DIR, 'dir')
    mkdir(EXPERIMENT_DIR);
end
fprintf('実験データ保存先: %s\n', EXPERIMENT_DIR);

% 実験全体の情報を保存
experiment_info = struct();
experiment_info.timestamp = timestamp;
experiment_info.execution_datetime = datestr(now);
experiment_info.matlab_version = version;
try
    experiment_info.matlab_release = version('-release');
catch
    experiment_info.matlab_release = 'unknown';
end
experiment_info.attack_method = string(ATTACK_METHOD);
experiment_info.num_trials = NUM_TRIALS;
experiment_info.param_attacker_upperlimit = PARAM_ATTACKER_UPPERLIMIT;
experiment_info.param_sample_count = PARAM_SAMPLE_COUNT;
experiment_info.param_system_dim = PARAM_SYSTEM_DIM;
experiment_info.total_conditions = TOTAL_CONDITIONS;
experiment_info.total_trials = TOTAL_TRIALS;
experiment_info.save_trial_data_to_file = SAVE_TRIAL_DATA_TO_FILE;

experiment_info_file = fullfile(EXPERIMENT_DIR, 'experiment_info.mat');
save(experiment_info_file, 'experiment_info', '-v7.3');
fprintf('実験情報を保存: %s\n', experiment_info_file);
fprintf('\n');

for idx_eps = 1:length(PARAM_ATTACKER_UPPERLIMIT)
    eps_att = PARAM_ATTACKER_UPPERLIMIT(idx_eps);
    
    for idx_T = 1:length(PARAM_SAMPLE_COUNT)
        T = PARAM_SAMPLE_COUNT(idx_T);
        
        for idx_dim = 1:size(PARAM_SYSTEM_DIM, 1)
            n = PARAM_SYSTEM_DIM(idx_dim, 1);
            m = PARAM_SYSTEM_DIM(idx_dim, 2);
            
            % データ数の制約チェック: T >= n+m が必要
            if T < n + m
                fprintf('\n--- スキップ: eps=%.4f, T=%d, n=%d, m=%d (T < n+m) ---\n', ...
                    eps_att, T, n, m);
                continue;  % この条件はスキップ
            end
            
            total_conditions = total_conditions + 1;
            progress_pct = (total_conditions - 1) / TOTAL_CONDITIONS * 100;
            elapsed_time = toc(start_time);
            if total_conditions > 1
                avg_time_per_condition = elapsed_time / (total_conditions - 1);
                estimated_remaining = avg_time_per_condition * (TOTAL_CONDITIONS - total_conditions + 1);
                fprintf('\n--- 条件 %d/%d (進捗: %.1f%%) ---\n', ...
                    total_conditions, TOTAL_CONDITIONS, progress_pct);
                fprintf('  残り時間の目安: %.1f分\n', estimated_remaining / 60);
            else
                fprintf('\n--- 条件 %d/%d (進捗: %.1f%%) ---\n', ...
                    total_conditions, TOTAL_CONDITIONS, progress_pct);
            end
            fprintf('  パラメータ: eps=%.4f, T=%d, n=%d, m=%d\n', eps_att, T, n, m);
            
            % この条件での結果を格納
            condition_results = struct();
            condition_results.eps_att = eps_att;
            condition_results.T = T;
            condition_results.n = n;
            condition_results.m = m;
            condition_results.rho_ori = zeros(NUM_TRIALS, 1);
            condition_results.rho_adv = zeros(NUM_TRIALS, 1);
            condition_results.is_unstable = false(NUM_TRIALS, 1);
            condition_results.rho_change = zeros(NUM_TRIALS, 1);
            
            % システムを1回だけ生成（20回の試行で共有）
            % 意味のあるシステムを生成（可制御・可観測なシステム）
            rng(1000 + total_conditions);  % 条件ごとに異なるシステムを生成
            
            % MATLABのdrssが使える場合は使用、使えない場合は代替方法
            try
                sys = drss(n, n, m);  % 離散時間の可制御・可観測なシステム
                A = sys.A;
                B = sys.B;
            catch
                % drssが使えない場合：可制御なシステムを手動生成
                % Schur安定なAを生成（固有値の絶対値 < 1）
                A = randn(n, n);
                A = A / (1.1 * max(abs(eig(A))));  % 固有値を1未満にスケール
                % 可制御なBを生成
                B = randn(n, m);
                % 可制御性を確認（必要に応じて調整）
                if rank(ctrb(A, B)) < n
                    % 可制御でない場合はBを調整
                    B = B + 0.1 * eye(n, m);
                end
            end
            
            Q = eye(n);  % 重み行列
            R = eye(m) * 0.1;
            
            % システムの特性を記録
            condition_results.A = A;
            condition_results.B = B;
            condition_results.Q = Q;
            condition_results.R = R;
            condition_results.eig_A = eig(A);  % Aの固有値
            condition_results.K_ori = [];  % 後で計算
            
            % 元のシステムの最適ゲインを計算（1回だけ）
            % 仮のデータで計算（後で各試行で再計算）
            V_temp = make_inputU(m, max(10, T));
            [X_temp, Z_temp, U_temp] = datasim.simulate_openloop_stable(A, B, V_temp);
            sd_temp = datasim.SystemData(A, B, Q, R, X_temp, Z_temp, U_temp);
            K_ori_base = sd_temp.opt_K();
            condition_results.K_ori = K_ori_base;
            [~, lambda_ori_base] = eigs((A+B*K_ori_base), 1, 'largestabs');
            condition_results.rho_ori_base = abs(lambda_ori_base);
            condition_results.eig_AplusBK_ori = eig(A+B*K_ori_base);  % A+B*Kの固有値
            
            % 条件ごとのデータ保存ディレクトリを作成
            condition_dir = fullfile(EXPERIMENT_DIR, sprintf('condition_%03d', total_conditions));
            if ~exist(condition_dir, 'dir')
                mkdir(condition_dir);
            end
            
            % 条件ごとのシステムパラメータを保存（重複を避けるため1回だけ）
            system_params = struct();
            system_params.condition_number = total_conditions;
            system_params.eps_att = eps_att;
            system_params.T = T;
            system_params.n = n;
            system_params.m = m;
            system_params.A = A;
            system_params.B = B;
            system_params.Q = Q;
            system_params.R = R;
            system_params.eig_A = eig(A);
            
            system_params_file = fullfile(condition_dir, 'system_params.mat');
            save(system_params_file, 'system_params', '-v7.3');
            
            % データ保存用の構造体（ファイル保存の場合は統計情報のみ）
            if SAVE_TRIAL_DATA_TO_FILE
                condition_results.trial_data = [];  % メモリには保存しない
                condition_results.data_dir = condition_dir;  % データ保存先を記録
            else
                % 旧方式: メモリに保存（非推奨、メモリ消費大）
                condition_results.trial_data = struct();
                condition_results.trial_data.U = cell(NUM_TRIALS, 1);
                condition_results.trial_data.X = cell(NUM_TRIALS, 1);
                condition_results.trial_data.Z = cell(NUM_TRIALS, 1);
                condition_results.trial_data.X_adv = cell(NUM_TRIALS, 1);
                condition_results.trial_data.Z_adv = cell(NUM_TRIALS, 1);
                condition_results.trial_data.U_adv = cell(NUM_TRIALS, 1);
            end
            
            % 20回試行（システムは固定、U, X, Zだけを変える）
            for trial = 1:NUM_TRIALS
                try
                    % 乱数シードを設定（U, X, Zが変わる）
                    rng(trial);
                    
                    % データ生成（システムは固定）
                    V = make_inputU(m, T);
                    [X, Z, U] = datasim.simulate_openloop_stable(A, B, V);
                    sd = datasim.SystemData(A, B, Q, R, X, Z, U);
                    
                    % データを保存（ファイルまたはメモリ）
                    if SAVE_TRIAL_DATA_TO_FILE
                        % ファイルに保存（メモリ効率化）
                        trial_file = fullfile(condition_dir, sprintf('trial_%03d.mat', trial));
                        
                        % 試行情報を準備（最初の保存時）
                        trial_info = struct();
                        trial_info.trial_number = trial;
                        trial_info.condition_number = total_conditions;
                        trial_info.rng_seed = trial;  % 再現性のため
                        trial_info.trial_timestamp = datestr(now);
                        trial_info.eps_att = eps_att;
                        trial_info.T = T;
                        trial_info.n = n;
                        trial_info.m = m;
                        
                        save(trial_file, 'X', 'Z', 'U', 'trial_info', '-v7.3');
                    else
                        % メモリに保存（旧方式）
                        condition_results.trial_data.U{trial} = U;
                        condition_results.trial_data.X{trial} = X;
                        condition_results.trial_data.Z{trial} = Z;
                    end
                    
                    % 元のシステムの評価
                    K_ori = sd.opt_K();
                    [~,lambda_ori] = eigs((A+B*K_ori), 1, 'largestabs');
                    rho_ori = abs(lambda_ori);
                    
                    % 攻撃実行（eps_attを指定）
                    [X_sdp_adv, Z_sdp_adv, U_sdp_adv] = attack.execute_attack(sd, ATTACK_METHOD, eps_att);
                    
                    % 攻撃後のシステムの評価
                    sd_adv = datasim.SystemData(A,B,sd.Q,sd.R,X_sdp_adv,Z_sdp_adv,U_sdp_adv);
                    K_adv = sd_adv.opt_K();
                    [~,lambda_adv] = eigs((A+B*K_adv), 1, 'largestabs');
                    rho_adv = abs(lambda_adv);
                    
                    % 攻撃データを保存（ファイルまたはメモリ）
                    if SAVE_TRIAL_DATA_TO_FILE
                        % ファイルに追加保存（既存のtrial_XXX.matに追加）
                        trial_file = fullfile(condition_dir, sprintf('trial_%03d.mat', trial));
                        X_adv = X_sdp_adv;  % 変数名を統一
                        Z_adv = Z_sdp_adv;
                        U_adv = U_sdp_adv;
                        
                        % 試行情報を更新（結果を追加）
                        trial_info.rho_ori = rho_ori;
                        trial_info.rho_adv = rho_adv;
                        trial_info.is_unstable = (rho_adv >= 1.0);
                        trial_info.rho_change = rho_adv - rho_ori;
                        
                        save(trial_file, 'X_adv', 'Z_adv', 'U_adv', 'trial_info', '-append', '-v7.3');
                        clear X_adv Z_adv U_adv trial_info;  % メモリをクリア
                    else
                        % メモリに保存（旧方式）
                        condition_results.trial_data.X_adv{trial} = X_sdp_adv;
                        condition_results.trial_data.Z_adv{trial} = Z_sdp_adv;
                        condition_results.trial_data.U_adv{trial} = U_sdp_adv;
                    end
                    
                    % 結果を記録
                    condition_results.rho_ori(trial) = rho_ori;
                    condition_results.rho_adv(trial) = rho_adv;
                    condition_results.is_unstable(trial) = (rho_adv >= 1.0);
                    condition_results.rho_change(trial) = rho_adv - rho_ori;
                    
                    % 進捗表示（試行レベル）
                    trial_progress = (trial / NUM_TRIALS) * 100;
                    condition_progress = ((total_conditions - 1) + trial / NUM_TRIALS) / TOTAL_CONDITIONS * 100;
                    if mod(trial, 5) == 0 || trial == NUM_TRIALS
                        fprintf('  試行 %d/%d完了 (条件内: %.1f%%, 全体: %.1f%%)\n', ...
                            trial, NUM_TRIALS, trial_progress, condition_progress);
                    end
                    
                    % メモリ効率化: 試行ごとに不要な変数をクリア
                    clear V X Z U sd X_sdp_adv Z_sdp_adv U_sdp_adv sd_adv K_ori K_adv lambda_ori lambda_adv;
                    
                    % SDPソルバーのメモリクリア（YALMIPの内部キャッシュをクリア）
                    try
                        yalmip('clear');
                    catch
                        % yalmip('clear')が使えない場合は無視
                    end
                    
                catch ME
                    if isa(ME, 'MException')
                        fprintf('  試行 %dでエラー: %s\n', trial, ME.message);
                    else
                        fprintf('  試行 %dでエラーが発生しました\n', trial);
                    end
                    % エラー時はNaNを記録
                    condition_results.rho_ori(trial) = NaN;
                    condition_results.rho_adv(trial) = NaN;
                    condition_results.is_unstable(trial) = false;
                    condition_results.rho_change(trial) = NaN;
                end
            end
            
            % 統計情報を計算
            condition_results.mean_rho_ori = mean(condition_results.rho_ori, 'omitnan');
            condition_results.mean_rho_adv = mean(condition_results.rho_adv, 'omitnan');
            condition_results.mean_rho_change = mean(condition_results.rho_change, 'omitnan');
            condition_results.unstable_rate = sum(condition_results.is_unstable) / NUM_TRIALS;
            condition_results.std_rho_change = std(condition_results.rho_change, 'omitnan');
            
            % 条件ごとの統計情報をファイルに保存（メモリ効率化）
            summary_file = fullfile(condition_dir, 'summary.mat');
            save(summary_file, 'condition_results', '-v7.3');
            
            % 結果を保存（cell配列に直接代入: 再割り当てを避ける）
            all_results{total_conditions} = condition_results;
            
            % 条件完了時の進捗表示
            condition_progress = total_conditions / TOTAL_CONDITIONS * 100;
            elapsed_time = toc(start_time);
            fprintf('  結果: 不安定化率=%.1f%%, 平均固有値変化=%.4f\n', ...
                condition_results.unstable_rate*100, condition_results.mean_rho_change);
            fprintf('  全体進捗: %.1f%% (経過時間: %.1f分)\n', ...
                condition_progress, elapsed_time / 60);
            
            % ========================================
            % 途中結果を定期的に保存（各条件完了時）
            % ========================================
            checkpoint_filename = fullfile(RESULT_DIR, sprintf('checkpoint_%s.mat', timestamp));
            try
                % cell配列を構造体配列に変換して保存（互換性のため）
                all_results_array = [all_results{1:total_conditions}];
                save(checkpoint_filename, 'all_results_array', 'PARAM_ATTACKER_UPPERLIMIT', ...
                    'PARAM_SAMPLE_COUNT', 'PARAM_SYSTEM_DIM', 'NUM_TRIALS', 'ATTACK_METHOD', ...
                    'total_conditions', 'TOTAL_CONDITIONS', 'start_time', 'SAVE_TRIAL_DATA_TO_FILE', ...
                    'EXPERIMENT_DIR', '-v7.3');
                clear all_results_array;  % メモリをクリア
                fprintf('  チェックポイントを保存: %s\n', checkpoint_filename);
            catch ME
                if isa(ME, 'MException')
                    warning(ME.identifier, 'チェックポイントの保存に失敗: %s', ME.message);
                else
                    warning('チェックポイントの保存に失敗しました');
                end
            end
        end
    end
end

% ========================================
% 結果の保存と表示
% ========================================
% timestampは既に定義済み（チェックポイント用）
result_filename = fullfile(RESULT_DIR, sprintf('experiment_results_%s.mat', timestamp));

% 最終結果を保存（-v7.3で大きなデータにも対応）
try
    % cell配列を構造体配列に変換して保存（互換性のため）
    all_results_array = [all_results{1:total_conditions}];
    % 可視化スクリプトとの互換性のため all_results として保存
    all_results = all_results_array;
    save(result_filename, 'all_results', 'PARAM_ATTACKER_UPPERLIMIT', 'PARAM_SAMPLE_COUNT', ...
        'PARAM_SYSTEM_DIM', 'NUM_TRIALS', 'ATTACK_METHOD', 'SAVE_TRIAL_DATA_TO_FILE', ...
        'EXPERIMENT_DIR', '-v7.3');
    clear all_results_array;  % メモリをクリア
    fprintf('最終結果を保存しました: %s\n', result_filename);
catch ME
    if isa(ME, 'MException')
        warning(ME.identifier, '最終結果の保存に失敗: %s', ME.message);
    else
        warning('最終結果の保存に失敗しました');
    end
    % チェックポイントから復元を試みる
    checkpoint_filename = fullfile(RESULT_DIR, sprintf('checkpoint_%s.mat', timestamp));
    if exist(checkpoint_filename, 'file')
        fprintf('チェックポイントから復元を試みます: %s\n', checkpoint_filename);
        load(checkpoint_filename);
        % チェックポイントから読み込んだ場合は all_results_array を all_results に変換
        if exist('all_results_array', 'var')
            all_results = all_results_array;
            save(result_filename, 'all_results', 'PARAM_ATTACKER_UPPERLIMIT', 'PARAM_SAMPLE_COUNT', ...
                'PARAM_SYSTEM_DIM', 'NUM_TRIALS', 'ATTACK_METHOD', 'SAVE_TRIAL_DATA_TO_FILE', ...
                'EXPERIMENT_DIR', '-v7.3');
        end
    end
end

% チェックポイントファイルを削除（正常終了時）
checkpoint_filename = fullfile(RESULT_DIR, sprintf('checkpoint_%s.mat', timestamp));
if exist(checkpoint_filename, 'file')
    try
        delete(checkpoint_filename);
        fprintf('チェックポイントファイルを削除しました\n');
    catch
        % 削除に失敗しても問題なし
    end
end

fprintf('\n=== 実験完了 ===\n');
fprintf('結果を保存しました: %s\n', result_filename);

% 結果のサマリーを表示
fprintf('\n=== 結果サマリー ===\n');
fprintf('%-8s %-6s %-6s %-6s %-12s %-12s %-12s\n', ...
    'eps', 'T', 'n', 'm', '不安定化率', '平均rho変化', 'std(rho変化)');
fprintf('%s\n', repmat('-', 1, 70));

for i = 1:total_conditions
    r = all_results{i};
    fprintf('%-8.4f %-6d %-6d %-6d %-12.1f%% %-12.4f %-12.4f\n', ...
        r.eps_att, r.T, r.n, r.m, ...
        r.unstable_rate*100, r.mean_rho_change, r.std_rho_change);
end

