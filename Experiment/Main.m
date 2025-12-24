% Main.m - データインジェクション攻撃の実験スクリプト
% 同じシステムでデータ（U, X, Z）を変化させた時の挙動を調査

clear; clc; close all;
startup;

% ========================================
% 実験パラメータの設定
% ========================================
% 攻撃手法（固定）
ATTACK_METHOD = cfg.AttackType.IMPLICIT_DGSM_EV;

% システムパラメータ（固定）
n = 6;
m = 2;
T = 2 * (n + m);  % T = 2(n+m) = 16

% ノイズの大きさ（対数スケールで5つ、1/10に変更）
PARAM_ATTACKER_UPPERLIMIT = [0.0000001, 0.000000316, 0.000001, 0.00000316, 0.00001];

% 実験設定
NUM_DATASETS = 100;  % データセット数（乱数シードで変える）
NUM_EPS = length(PARAM_ATTACKER_UPPERLIMIT);  % 各データセットに対するノイズの種類数
TOTAL_TRIALS = NUM_DATASETS * NUM_EPS;  % 総試行数 = 100 × 5 = 500

RESULT_DIR = fullfile(fileparts(mfilename('fullpath')), 'Result');
if ~exist(RESULT_DIR, 'dir')
    mkdir(RESULT_DIR);
end

% メモリ効率化オプション
SAVE_TRIAL_DATA_TO_FILE = true;

% ノイズ履歴保存オプション（IDGSM攻撃の各ステップでのノイズを記録）
% 注意: 履歴データは大きくなるため、通常は false に設定
SAVE_NOISE_HISTORY = false;  % true にすると各ステップのノイズを保存（可視化用）

% ========================================
% システム生成（1回のみ、全データセットで同じ）
% ========================================
fprintf('=== システム生成 ===\n');
[A, B, Q, R] = make_lti_system.make_suspension_lti(n, m);

% システムの特性を確認
rho_A = max(abs(eig(A)));
fprintf('システム行列Aのスペクトル半径: %.4f\n', rho_A);
fprintf('システム次元: n=%d, m=%d\n', n, m);
fprintf('サンプル数: T=%d\n', T);
fprintf('\n');

% T >= n+m を満たすか確認
if T < n + m
    error('T (%d) < n+m (%d) のため、データ数の最小要件を満たしません', T, n+m);
end

% ========================================
% 実験開始
% ========================================
fprintf('=== 実験開始 ===\n');
fprintf('攻撃手法: %s\n', string(ATTACK_METHOD));
fprintf('データセット数: %d\n', NUM_DATASETS);
fprintf('各データセットのノイズ種類数: %d\n', NUM_EPS);
fprintf('総試行数: %d\n', TOTAL_TRIALS);
fprintf('ノイズの大きさ: %s\n', mat2str(PARAM_ATTACKER_UPPERLIMIT));
fprintf('システム: Suspension (n=%d, m=%d)\n', n, m);
fprintf('\n');

start_time = tic;
timestamp = datestr(now, 'yyyymmdd_HHMMSS');

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
experiment_info.matlab_release = version('-release');
experiment_info.attack_method = string(ATTACK_METHOD);
experiment_info.num_datasets = NUM_DATASETS;
experiment_info.num_eps = NUM_EPS;
experiment_info.param_attacker_upperlimit = PARAM_ATTACKER_UPPERLIMIT;
experiment_info.T = T;
experiment_info.n = n;
experiment_info.m = m;
experiment_info.system_gen_function = 'make_lti_system.make_suspension_lti';
experiment_info.system_A = A;
experiment_info.system_B = B;
experiment_info.system_Q = Q;
experiment_info.system_R = R;
experiment_info.rho_A = rho_A;
experiment_info.save_trial_data_to_file = SAVE_TRIAL_DATA_TO_FILE;
experiment_info.save_noise_history = SAVE_NOISE_HISTORY;

experiment_info_file = fullfile(EXPERIMENT_DIR, 'experiment_info.mat');
save(experiment_info_file, 'experiment_info', '-v7.3');
fprintf('実験情報を保存: %s\n', experiment_info_file);
fprintf('\n');

% 結果を保存する構造体配列
all_results = cell(TOTAL_TRIALS, 1);
trial_idx = 0;

% ========================================
% メインループ: データセット × ノイズ
% ========================================
for dataset = 1:NUM_DATASETS
    fprintf('データセット %d/%d\n', dataset, NUM_DATASETS);
    
    % データセットごとのディレクトリを作成
    dataset_dir = fullfile(EXPERIMENT_DIR, sprintf('dataset_%03d', dataset));
    if ~exist(dataset_dir, 'dir')
        mkdir(dataset_dir);
    end
    
    % 乱数シードを設定（データセットごとに異なる）
    rng(dataset);
    
    % データ生成
    V = make_inputU(m, T);
    try
        [X, Z, U] = datasim.simulate_openloop_stable(A, B, V);
    catch ME
        if contains(ME.message, 'LQR') || contains(ME.message, 'リカッチ')
            warning('データセット %d: LQRエラー（システムが制御不可能の可能性）: %s', dataset, ME.message);
            continue;  % このデータセットをスキップ
        else
            rethrow(ME);
        end
    end
    
    sd = datasim.SystemData(A, B, Q, R, X, Z, U);
    
    % 攻撃前のSDPを解いてfeasibilityを確認
    [L_ori, ~, ~, diagInfo_ori] = sd.solveSDPBySystem();
    is_feasible_ori = (diagInfo_ori.problem == 0);
    K_ori = sdp.postprocess_K(sd.U, L_ori, sd.X);
    [~,lambda_ori] = eigs((A+B*K_ori), 1, 'largestabs');
    rho_ori = abs(lambda_ori);  % A+B*K_optのスペクトル半径
    
    % データを保存
    if SAVE_TRIAL_DATA_TO_FILE
        data_file = fullfile(dataset_dir, 'data.mat');
        data_info = struct();
        data_info.dataset_number = dataset;
        data_info.rng_seed = dataset;
        data_info.A = A;
        data_info.B = B;
        data_info.Q = Q;
        data_info.R = R;
        data_info.rho_ori = rho_ori;
        data_info.is_feasible_ori = is_feasible_ori;
        data_info.sdp_problem_code_ori = diagInfo_ori.problem;
        save(data_file, 'X', 'Z', 'U', 'data_info', '-v7.3');
    end
    
    % 各ノイズ値に対して攻撃を実行
    for eps_idx = 1:NUM_EPS
        eps_att = PARAM_ATTACKER_UPPERLIMIT(eps_idx);
        trial_idx = trial_idx + 1;
        
        try
            % 攻撃実行
            if SAVE_NOISE_HISTORY
                [X_sdp_adv, Z_sdp_adv, U_sdp_adv, attack_history] = attack.execute_attack(sd, ATTACK_METHOD, eps_att, SAVE_NOISE_HISTORY);
            else
                [X_sdp_adv, Z_sdp_adv, U_sdp_adv] = attack.execute_attack(sd, ATTACK_METHOD, eps_att);
                attack_history = [];
            end
            
            % 攻撃後のSDPを解いて評価
            sd_adv = datasim.SystemData(A, B, Q, R, X_sdp_adv, Z_sdp_adv, U_sdp_adv);
            [L_adv, ~, ~, diagInfo_adv] = sd_adv.solveSDPBySystem();
            is_feasible_adv = (diagInfo_adv.problem == 0);
            K_adv = sdp.postprocess_K(sd_adv.U, L_adv, sd_adv.X);
            [~,lambda_adv] = eigs((A+B*K_adv), 1, 'largestabs');
            rho_adv = abs(lambda_adv);  % A+B*K_advのスペクトル半径
            
            % 結果を記録
            result = struct();
            result.dataset = dataset;
            result.eps_att = eps_att;
            result.rho_ori = rho_ori;
            result.rho_adv = rho_adv;
            result.rho_change = rho_adv - rho_ori;  % 変化幅（変化率ではない）
            result.is_unstable = (rho_adv >= 1.0);
            result.is_feasible_ori = is_feasible_ori;
            result.is_feasible_adv = is_feasible_adv;
            result.sdp_problem_code_ori = diagInfo_ori.problem;
            result.sdp_problem_code_adv = diagInfo_adv.problem;
            
            % ノイズ履歴を保存（オプション）
            if SAVE_NOISE_HISTORY && ~isempty(attack_history)
                result.attack_history = attack_history;
            end
            
            all_results{trial_idx} = result;
            
            % 攻撃データを保存
            if SAVE_TRIAL_DATA_TO_FILE
                trial_file = fullfile(dataset_dir, sprintf('attack_eps_%d.mat', eps_idx));
                attack_data = struct();
                attack_data.eps_att = eps_att;
                attack_data.X_adv = X_sdp_adv;
                attack_data.Z_adv = Z_sdp_adv;
                attack_data.U_adv = U_sdp_adv;
                attack_data.rho_ori = rho_ori;
                attack_data.rho_adv = rho_adv;
                attack_data.rho_change = rho_adv - rho_ori;
                attack_data.is_unstable = (rho_adv >= 1.0);
                attack_data.is_feasible_ori = is_feasible_ori;
                attack_data.is_feasible_adv = is_feasible_adv;
                attack_data.sdp_problem_code_ori = diagInfo_ori.problem;
                attack_data.sdp_problem_code_adv = diagInfo_adv.problem;
                
                % ノイズ履歴を保存（オプション）
                if SAVE_NOISE_HISTORY && ~isempty(attack_history)
                    attack_data.attack_history = attack_history;
                end
                
                save(trial_file, 'attack_data', '-v7.3');
            end
            
            % 進捗表示
            if mod(trial_idx, 50) == 0 || trial_idx == TOTAL_TRIALS
                progress = (trial_idx / TOTAL_TRIALS) * 100;
                fprintf('  進捗: %d/%d試行完了 (%.1f%%)\n', trial_idx, TOTAL_TRIALS, progress);
            end
            
            % メモリクリア
            clear X_sdp_adv Z_sdp_adv U_sdp_adv sd_adv K_adv lambda_adv L_adv diagInfo_adv;
            
        catch ME
            fprintf('  データセット %d, eps=%.5f でエラー: %s\n', dataset, eps_att, ME.message);
            % エラー時はNaNを記録
            result = struct();
            result.dataset = dataset;
            result.eps_att = eps_att;
            result.rho_ori = rho_ori;
            result.rho_adv = NaN;
            result.rho_change = NaN;
            result.is_unstable = false;
            result.is_feasible_ori = is_feasible_ori;
            result.is_feasible_adv = false;
            result.sdp_problem_code_ori = diagInfo_ori.problem;
            result.sdp_problem_code_adv = NaN;
            all_results{trial_idx} = result;
        end
    end
    
    % メモリクリア
    clear V X Z U sd K_ori lambda_ori L_ori diagInfo_ori;
end

% ========================================
% 結果の集計と保存
% ========================================
fprintf('\n=== 結果の集計 ===\n');

% cell配列を構造体配列に変換
valid_results = ~cellfun(@isempty, all_results);
all_results_array = [all_results{valid_results}];

% 最終結果を保存
result_filename = fullfile(EXPERIMENT_DIR, 'experiment_results.mat');
save(result_filename, 'all_results_array', 'experiment_info', '-v7.3');
fprintf('最終結果を保存しました: %s\n', result_filename);

% Free.txtの内容をexperimentフォルダにコピー
free_txt_path = fullfile(fileparts(mfilename('fullpath')), 'SandBox', 'Free.txt');
experiment_info_txt = fullfile(EXPERIMENT_DIR, 'experiment_info.txt');
if exist(free_txt_path, 'file')
    copyfile(free_txt_path, experiment_info_txt);
end

% 実行時間
elapsed_time = toc(start_time);
fprintf('\n=== 実験完了 ===\n');
fprintf('実行時間: %.1f秒 (%.1f分)\n', elapsed_time, elapsed_time/60);
fprintf('総試行数: %d\n', length(all_results_array));
fprintf('\n');
