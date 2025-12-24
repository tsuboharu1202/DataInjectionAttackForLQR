% plot_idgsm_trajectory: IDGSM攻撃の軌跡を可視化するお遊びスクリプト
%
% システム生成 → データ生成 → IDGSM攻撃 → 可視化 まで全部実行
% 実験フォルダには何も保存しません
%
% 使用方法:
%   cd scripts
%   plot_idgsm_trajectory

clear; clc; close all;
rehash toolboxcache;  % キャッシュをクリア

% ========================================
% パラメータ設定（最初に定義）
% ========================================
% システムパラメータ
n = 4;              % 状態次元
m = 2;              % 入力次元
T = 2 * (n + m);    % サンプル数 T = 2(n+m)

% システム生成方法
% 'suspension': Suspension system (推奨)
% 'motor': Motor Position system
% 'random': ランダムLTIシステム
system_type = 'random';

% 投影方法
projection_method = 'directional';  % 'directional', 'pca', 'gradient'

% 描画指標
% 'auto': 利用可能な指標を自動選択（score_history優先）
% 'score': score_historyを表示
% 'spectral_radius': spectral_radius_historyを表示
plot_metric = 'auto';  % 'auto', 'score', 'spectral_radius'

% 乱数シード（再現性のため）
% rng(1);  % コメントアウトすると毎回異なる結果

% ========================================
% パス設定
% ========================================
% スクリプトのディレクトリを取得
stack_info = dbstack('-completenames');
if ~isempty(stack_info)
    script_dir = fileparts(stack_info(end).file);
else
    script_dir = pwd;
end
proj_root = fileparts(script_dir);
startup_file = fullfile(proj_root, 'startup.m');
if isfile(startup_file)
    run(startup_file);
else
    addpath(genpath(proj_root));
end

fprintf('=== IDGSM攻撃の軌跡可視化（お遊び版） ===\n\n');

% ========================================
% 1. システム生成
% ========================================
fprintf('=== 1. システム生成 ===\n');
switch lower(system_type)
    case 'suspension'
        [A, B, Q, R] = make_lti_system.make_suspension_lti(n, m);
        fprintf('システム: Suspension (n=%d, m=%d)\n', n, m);
    case 'motor'
        [A, B, Q, R] = make_lti_system.make_motor_position_lti(n, m);
        fprintf('システム: Motor Position (n=%d, m=%d)\n', n, m);
    case 'random'
        [A, B, Q, R] = datasim.make_lti(n, m);
        fprintf('システム: Random LTI (n=%d, m=%d)\n', n, m);
    otherwise
        error('未知のシステムタイプ: %s', system_type);
end

rho_A = max(abs(eig(A)));
fprintf('システム行列Aのスペクトル半径: %.4f\n', rho_A);
fprintf('サンプル数: T=%d\n', T);
fprintf('\n');

% T >= n+m を満たすか確認
if T < n + m
    error('T (%d) < n+m (%d) のため、データ数の最小要件を満たしません', T, n+m);
end

% ========================================
% 2. オフラインデータの取得
% ========================================
fprintf('=== 2. オフラインデータの取得 ===\n');
V = make_inputU(m, T);
try
    [X, Z, U] = datasim.simulate_openloop_stable(A, B, V);
catch ME
    if contains(ME.message, 'LQR') || contains(ME.message, 'リカッチ')
        error('データ生成エラー（システムが制御不可能の可能性）: %s', ME.message);
    else
        rethrow(ME);
    end
end

sd = datasim.SystemData(A, B, Q, R, X, Z, U);

% 攻撃前のSDPを解いて評価
[L_ori, ~, ~, diagInfo_ori] = sd.solveSDPBySystem();
is_feasible_ori = (diagInfo_ori.problem == 0);
if ~is_feasible_ori
    warning('攻撃前のSDPがinfeasibleです。データ生成に問題がある可能性があります。');
end

K_ori = sdp.postprocess_K(sd.U, L_ori, sd.X);
ev_ori = eig(A + B*K_ori);
rho_ori = max(abs(ev_ori));
fprintf('攻撃前のスペクトル半径: %.6f\n', rho_ori);
fprintf('攻撃前のSDP feasibility: %s\n', string(is_feasible_ori));
fprintf('\n');

% ========================================
% 3. IDGSM攻撃の実行（履歴保存あり）
% ========================================
fprintf('=== 3. IDGSM攻撃の実行 ===\n');
fprintf('ノイズ履歴を保存しながら攻撃を実行します...\n');

% IDGSM攻撃を実行（履歴保存あり）
[X_adv, Z_adv, U_adv, attack_history] = attack.execute_attack(sd, cfg.AttackType.IMPLICIT_IDGSM_EV, [], true);

% 攻撃後の評価
sd_adv = datasim.SystemData(A, B, Q, R, X_adv, Z_adv, U_adv);
[L_adv, ~, ~, diagInfo_adv] = sd_adv.solveSDPBySystem();
is_feasible_adv = (diagInfo_adv.problem == 0);
K_adv = sdp.postprocess_K(sd_adv.U, L_adv, sd_adv.X);
ev_adv = eig(A + B*K_adv);
rho_adv = max(abs(ev_adv));

fprintf('攻撃後のスペクトル半径: %.6f\n', rho_adv);
fprintf('スペクトル半径の変化: %.6f\n', rho_adv - rho_ori);
fprintf('攻撃後のSDP feasibility: %s\n', string(is_feasible_adv));
fprintf('攻撃ステップ数: %d\n', attack_history.iter_count);
fprintf('\n');

% ========================================
% 4. 可視化
% ========================================
fprintf('=== 4. 可視化 ===\n');
fprintf('投影方法: %s\n', projection_method);
fprintf('\n');

% 一時的なデータ構造を作成（可視化関数のインターフェースに合わせる）
% 実際にはファイルに保存せず、メモリ上で処理
temp_experiment_dir = tempname;  % 一時ディレクトリ名（実際には作成しない）
temp_dataset_dir = fullfile(temp_experiment_dir, 'dataset_001');

% 可視化関数を直接呼び出す（履歴データを直接渡す）
% ただし、可視化関数はファイルから読み込む前提なので、一時的に構造体を作成
fprintf('ノイズ軌跡を可視化中...\n');

% 可視化関数を直接呼び出すために、履歴データを構造体にまとめる
history = attack_history;
X_ori_for_vis = X;
Z_ori_for_vis = Z;
U_ori_for_vis = U;

% 可視化関数を修正して、ファイルから読み込まずに直接データを受け取れるようにする
% または、一時的な構造体を作成して可視化関数を呼び出す

% 簡易版：可視化関数のロジックを直接実行
num_steps = length(history.dX_history);
noise_vectors = zeros(num_steps, numel(X_ori_for_vis) + numel(Z_ori_for_vis) + numel(U_ori_for_vis));

for i = 1:num_steps
    dX = history.dX_history{i};
    dZ = history.dZ_history{i};
    dU = history.dU_history{i};
    
    % D = [Z; X; U] の形式でベクトル化
    D = [dZ; dX; dU];
    noise_vectors(i, :) = D(:)';  % 行ベクトルとして保存
end

fprintf('ノイズベクトルの次元: %d\n', size(noise_vectors, 2));

% 投影を計算
switch lower(projection_method)
    case 'directional'
        if num_steps < 2
            error('ステップ数が少なすぎます（最低2ステップ必要）');
        end
        
        target_direction = noise_vectors(end, :) - noise_vectors(1, :);
        target_direction = target_direction / (norm(target_direction) + eps);
        
        noise_centered = noise_vectors - mean(noise_vectors, 1);
        proj_target = (noise_centered * target_direction') * target_direction;
        noise_orthogonal = noise_centered - proj_target;
        
        if size(noise_orthogonal, 1) > 1
            [coeff, ~, ~] = pca(noise_orthogonal);
            if size(coeff, 2) > 0
                axis2 = coeff(:, 1);
            else
                axis2 = zeros(size(target_direction'));
            end
        else
            axis2 = zeros(size(target_direction'));
        end
        
        coords_2d = zeros(num_steps, 2);
        for i = 1:num_steps
            vec_centered = noise_vectors(i, :) - mean(noise_vectors, 1);
            coords_2d(i, 1) = vec_centered * target_direction';
            coords_2d(i, 2) = vec_centered * axis2;
        end
        
        axis_labels = {'目標方向への射影', '直交方向（最大分散）'};
        
    case 'pca'
        noise_centered = noise_vectors - mean(noise_vectors, 1);
        [~, score, ~] = pca(noise_centered);
        coords_2d = score(:, 1:2);
        axis_labels = {'第1主成分', '第2主成分'};
        
    case 'gradient'
        if num_steps < 2
            error('ステップ数が少なすぎます（最低2ステップ必要）');
        end
        
        cumulative_direction = zeros(1, size(noise_vectors, 2));
        for i = 2:num_steps
            cumulative_direction = cumulative_direction + (noise_vectors(i, :) - noise_vectors(i-1, :));
        end
        cumulative_direction = cumulative_direction / (norm(cumulative_direction) + eps);
        
        noise_centered = noise_vectors - mean(noise_vectors, 1);
        proj_cumulative = (noise_centered * cumulative_direction') * cumulative_direction;
        noise_orthogonal = noise_centered - proj_cumulative;
        
        if size(noise_orthogonal, 1) > 1
            [coeff, ~, ~] = pca(noise_orthogonal);
            if size(coeff, 2) > 0
                axis2 = coeff(:, 1);
            else
                axis2 = zeros(size(cumulative_direction'));
            end
        else
            axis2 = zeros(size(cumulative_direction'));
        end
        
        coords_2d = zeros(num_steps, 2);
        for i = 1:num_steps
            vec_centered = noise_vectors(i, :) - mean(noise_vectors, 1);
            coords_2d(i, 1) = vec_centered * cumulative_direction';
            coords_2d(i, 2) = vec_centered * axis2;
        end
        
        axis_labels = {'累積更新方向', '直交方向（最大分散）'};
        
    otherwise
        error('未知の投影方法: %s', projection_method);
end

% 色付け: 各ステップでのspectral_radiusまたはscoreの変化率
% 描画指標の選択
has_score = isfield(history, 'score_history') && ~isempty(history.score_history);
has_rho = isfield(history, 'spectral_radius_history') && ~isempty(history.spectral_radius_history);

switch lower(plot_metric)
    case 'score'
        if ~has_score
            warning('score_historyが利用できません。利用可能な指標に切り替えます。');
            if has_rho
                plot_metric = 'spectral_radius';
            else
                plot_metric = 'none';
            end
        end
    case 'spectral_radius'
        if ~has_rho
            warning('spectral_radius_historyが利用できません。利用可能な指標に切り替えます。');
            if has_score
                plot_metric = 'score';
            else
                plot_metric = 'none';
            end
        end
    case 'auto'
        % 自動選択: score_history優先、なければspectral_radius_history
        if has_score
            plot_metric = 'score';
        elseif has_rho
            plot_metric = 'spectral_radius';
        else
            plot_metric = 'none';
        end
    otherwise
        error('未知の描画指標: %s (''auto'', ''score'', ''spectral_radius'' のいずれかを指定)', plot_metric);
end

% 選択された指標に基づいてデータを設定
switch plot_metric
    case 'score'
        score_history = history.score_history;
        if length(score_history) ~= num_steps
            warning('score_historyの長さがステップ数と一致しません。色付けをスキップします。');
            color_values = 1:num_steps;
            color_label = 'ステップ番号';
        else
            score_changes = [0, diff(score_history)];
            color_values = score_changes;
            color_label = 'Score 変化率';
        end
        value_history = score_history;
        value_label = 'Score';
        
    case 'spectral_radius'
        spectral_radius_history = history.spectral_radius_history;
        if length(spectral_radius_history) ~= num_steps
            warning('spectral_radius_historyの長さがステップ数と一致しません。色付けをスキップします。');
            color_values = 1:num_steps;
            color_label = 'ステップ番号';
        else
            rho_changes = [0, diff(spectral_radius_history)];
            color_values = rho_changes;
            color_label = 'Spectral Radius 変化率';
        end
        value_history = spectral_radius_history;
        value_label = 'Spectral Radius';
        
    case 'none'
        % どちらもない場合
        color_values = 1:num_steps;
        color_label = 'ステップ番号';
        value_history = [];
        value_label = '';
end

% 連続ステップ間のコサイン類似度を計算（勾配法の真っ直ぐさの評価）
cosine_similarities = [];
if num_steps >= 2
    % 各ステップの方向ベクトルを計算
    direction_vectors = zeros(num_steps - 1, size(noise_vectors, 2));
    for i = 1:(num_steps - 1)
        direction_vectors(i, :) = noise_vectors(i + 1, :) - noise_vectors(i, :);
    end
    
    % 連続する方向ベクトル間のコサイン類似度を計算
    cosine_similarities = zeros(num_steps - 2, 1);
    for i = 1:(num_steps - 2)
        v1 = direction_vectors(i, :);
        v2 = direction_vectors(i + 1, :);
        
        norm_v1 = norm(v1);
        norm_v2 = norm(v2);
        
        if norm_v1 > eps && norm_v2 > eps
            cosine_similarities(i) = dot(v1, v2) / (norm_v1 * norm_v2);
        else
            cosine_similarities(i) = NaN;  % ゼロベクトルの場合はNaN
        end
    end
end

% 図を描画
figure('Position', [100, 100, 1200, 800]);

% メインの散布図
subplot(2, 2, [1, 3]);
scatter(coords_2d(:, 1), coords_2d(:, 2), 50, color_values, 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 0.5);
colormap(gca, 'parula');
colorbar;
xlabel(axis_labels{1}, 'FontSize', 12);
ylabel(axis_labels{2}, 'FontSize', 12);
title('IDGSM攻撃のノイズ軌跡', 'FontSize', 14);
grid on;
hold on;

% 軌跡を線で結ぶ
plot(coords_2d(:, 1), coords_2d(:, 2), 'k--', 'LineWidth', 1, 'Color', [0.5, 0.5, 0.5], 'DisplayName', '軌跡');
plot(coords_2d(1, 1), coords_2d(1, 2), 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g', 'DisplayName', '開始');
plot(coords_2d(end, 1), coords_2d(end, 2), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r', 'DisplayName', '終了');
legend('Location', 'best');

% Spectral Radius または Score の時系列プロット
subplot(2, 2, 2);
if ~isempty(value_history) && length(value_history) == num_steps
    plot(1:num_steps, value_history, 'b-o', 'LineWidth', 2, 'MarkerSize', 4);
    hold on;
    if strcmp(value_label, 'Spectral Radius')
        yline(1.0, 'r--', 'LineWidth', 2, 'DisplayName', '安定境界 (rho=1.0)');
    end
    xlabel('ステップ', 'FontSize', 12);
    ylabel(value_label, 'FontSize', 12);
    title(sprintf('%s の時系列', value_label), 'FontSize', 12);
    grid on;
    legend('Location', 'best');
else
    text(0.5, 0.5, sprintf('%s データが利用できません', value_label), 'HorizontalAlignment', 'center');
end

% コサイン類似度の時系列プロット（勾配法の真っ直ぐさ）
subplot(2, 2, 4);
if ~isempty(cosine_similarities) && ~all(isnan(cosine_similarities))
    plot(2:(num_steps-1), cosine_similarities, 'b-o', 'LineWidth', 2, 'MarkerSize', 4);
    hold on;
    yline(1.0, 'g--', 'LineWidth', 1.5, 'DisplayName', '完全に真っ直ぐ (cos=1)');
    yline(0.0, 'k--', 'LineWidth', 1, 'DisplayName', '直交 (cos=0)');
    yline(-1.0, 'r--', 'LineWidth', 1.5, 'DisplayName', '逆方向 (cos=-1)');
    xlabel('ステップ', 'FontSize', 12);
    ylabel('コサイン類似度', 'FontSize', 12);
    title('連続ステップ間の方向の類似度', 'FontSize', 12);
    ylim([-1.1, 1.1]);
    grid on;
    legend('Location', 'best', 'FontSize', 8);
    
    % 平均値を表示
    valid_similarities = cosine_similarities(~isnan(cosine_similarities));
    if ~isempty(valid_similarities)
        mean_sim = mean(valid_similarities);
        text(0.02, 0.98, sprintf('平均: %.3f', mean_sim), ...
            'Units', 'normalized', 'VerticalAlignment', 'top', ...
            'FontSize', 10, 'BackgroundColor', 'white');
    end
else
    text(0.5, 0.5, 'コサイン類似度データが利用できません', 'HorizontalAlignment', 'center');
end

sgtitle(sprintf('IDGSM攻撃の詳細分析 (投影方法: %s)', projection_method), 'FontSize', 16, 'FontWeight', 'bold');

fprintf('\n=== 完了！ ===\n');
fprintf('可視化が完了しました。\n');
fprintf('実験フォルダには何も保存されていません（お遊び用）。\n');
