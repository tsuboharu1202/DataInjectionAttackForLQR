function plot_idgsm_trajectory(experiment_dir, dataset_num, eps_idx, projection_method)
% plot_idgsm_trajectory: IDGSM攻撃の各ステップでのノイズ軌跡を可視化
%
% 入力:
%   experiment_dir: 実験ディレクトリのパス
%   dataset_num: データセット番号（例: 1）
%   eps_idx: ノイズインデックス（例: 1-5、省略時は1）
%   projection_method: 投影方法
%       'directional' (default): 目標方向を第1軸、それに直交する最大分散方向を第2軸
%       'pca': 主成分分析で2次元に投影
%       'gradient': 勾配の累積方向を第1軸
%
% 出力:
%   図を描画（ノイズ軌跡の散布図、色は各ステップでのspectral_radiusの変化率）

if nargin < 3 || isempty(eps_idx)
    eps_idx = 1;
end
if nargin < 4 || isempty(projection_method)
    projection_method = 'directional';
end

fprintf('=== IDGSM軌跡の可視化: データセット %d (eps_idx=%d) ===\n', dataset_num, eps_idx);
fprintf('投影方法: %s\n', projection_method);

% 攻撃データを読み込む
attack_file = fullfile(experiment_dir, sprintf('dataset_%03d', dataset_num), sprintf('attack_eps_%d.mat', eps_idx));
if ~isfile(attack_file)
    error('攻撃データファイルが見つかりません: %s', attack_file);
end

attack_data = load(attack_file, 'attack_data');
if ~isfield(attack_data, 'attack_data')
    error('attack_dataフィールドが見つかりません');
end

% ノイズ履歴を確認
if ~isfield(attack_data.attack_data, 'attack_history')
    error('ノイズ履歴が保存されていません。Main.mで SAVE_NOISE_HISTORY = true に設定して再実行してください。');
end

history = attack_data.attack_data.attack_history;
if isempty(history) || ~isfield(history, 'dX_history')
    error('ノイズ履歴が空です');
end

fprintf('ステップ数: %d\n', length(history.dX_history));

% 元のデータを読み込む（次元情報のため）
data_file = fullfile(experiment_dir, sprintf('dataset_%03d', dataset_num), 'data.mat');
if ~isfile(data_file)
    error('データファイルが見つかりません: %s', data_file);
end
data_ori = load(data_file, 'X', 'Z', 'U');
X_ori = data_ori.X;
Z_ori = data_ori.Z;
U_ori = data_ori.U;

% ノイズ履歴をベクトル化
num_steps = length(history.dX_history);
noise_vectors = zeros(num_steps, numel(X_ori) + numel(Z_ori) + numel(U_ori));

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
        % 方法A: 目標方向を第1軸、それに直交する最大分散方向を第2軸
        if num_steps < 2
            error('ステップ数が少なすぎます（最低2ステップ必要）');
        end
        
        % 第1軸: 最終ステップ - 初期ステップ（目標方向）
        target_direction = noise_vectors(end, :) - noise_vectors(1, :);
        target_direction = target_direction / (norm(target_direction) + eps);  % 正規化
        
        % データを第1軸に直交する空間に投影
        % noise_vectors の各ベクトルから第1軸方向の成分を除去
        noise_centered = noise_vectors - mean(noise_vectors, 1);  % 中心化
        proj_target = (noise_centered * target_direction') * target_direction;  % 第1軸への射影
        noise_orthogonal = noise_centered - proj_target;  % 直交成分
        
        % 第2軸: 直交成分の最大分散方向（PCA）
        if size(noise_orthogonal, 1) > 1
            [coeff, ~, ~] = pca(noise_orthogonal);
            if size(coeff, 2) > 0
                axis2 = coeff(:, 1);  % 第1主成分
            else
                axis2 = zeros(size(target_direction'));
            end
        else
            axis2 = zeros(size(target_direction'));
        end
        
        % 2次元座標を計算
        coords_2d = zeros(num_steps, 2);
        for i = 1:num_steps
            vec_centered = noise_vectors(i, :) - mean(noise_vectors, 1);
            coords_2d(i, 1) = vec_centered * target_direction';  % 第1軸への射影
            coords_2d(i, 2) = vec_centered * axis2;  % 第2軸への射影
        end
        
        axis_labels = {'目標方向への射影', '直交方向（最大分散）'};
        
    case 'pca'
        % 方法B: 純粋な主成分分析
        noise_centered = noise_vectors - mean(noise_vectors, 1);
        [coeff, score, ~] = pca(noise_centered);
        coords_2d = score(:, 1:2);  % 第1、第2主成分
        axis_labels = {'第1主成分', '第2主成分'};
        
    case 'gradient'
        % 方法C: 勾配の累積方向を第1軸
        % 注意: この方法は勾配情報が必要ですが、現在の履歴には含まれていません
        % 代わりに、各ステップ間の差分の累積方向を使用
        if num_steps < 2
            error('ステップ数が少なすぎます（最低2ステップ必要）');
        end
        
        % 各ステップ間の差分を累積
        cumulative_direction = zeros(1, size(noise_vectors, 2));
        for i = 2:num_steps
            cumulative_direction = cumulative_direction + (noise_vectors(i, :) - noise_vectors(i-1, :));
        end
        cumulative_direction = cumulative_direction / (norm(cumulative_direction) + eps);  % 正規化
        
        % 第1軸: 累積方向
        % 第2軸: 直交成分の最大分散方向
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

% 色付け: 各ステップでのspectral_radiusの変化率
spectral_radius_history = history.spectral_radius_history;
if length(spectral_radius_history) ~= num_steps
    warning('spectral_radius_historyの長さがステップ数と一致しません。色付けをスキップします。');
    color_values = 1:num_steps;  % ステップ番号で色付け
    color_label = 'ステップ番号';
else
    % 変化率を計算（前ステップからの変化量）
    rho_changes = [0, diff(spectral_radius_history)];  % 最初のステップは0
    color_values = rho_changes;
    color_label = 'Spectral Radius 変化率';
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
title(sprintf('IDGSM攻撃のノイズ軌跡 (データセット %d, eps_idx=%d)', dataset_num, eps_idx), 'FontSize', 14);
grid on;
hold on;

% 軌跡を線で結ぶ（時系列順）
plot(coords_2d(:, 1), coords_2d(:, 2), 'k--', 'LineWidth', 1, 'Color', [0.5, 0.5, 0.5], 'DisplayName', '軌跡');
% 開始点と終了点をマーク
plot(coords_2d(1, 1), coords_2d(1, 2), 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g', 'DisplayName', '開始');
plot(coords_2d(end, 1), coords_2d(end, 2), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r', 'DisplayName', '終了');
legend('Location', 'best');

% Spectral Radius の時系列プロット
subplot(2, 2, 2);
if length(spectral_radius_history) == num_steps
    plot(1:num_steps, spectral_radius_history, 'b-o', 'LineWidth', 2, 'MarkerSize', 4);
    hold on;
    yline(1.0, 'r--', 'LineWidth', 2, 'DisplayName', '安定境界 (rho=1.0)');
    xlabel('ステップ', 'FontSize', 12);
    ylabel('Spectral Radius', 'FontSize', 12);
    title('Spectral Radius の時系列', 'FontSize', 12);
    grid on;
    legend('Location', 'best');
else
    text(0.5, 0.5, 'Spectral Radius データが利用できません', 'HorizontalAlignment', 'center');
end

% 変化率の時系列プロット
subplot(2, 2, 4);
if length(spectral_radius_history) == num_steps
    bar(1:num_steps, rho_changes, 'FaceColor', 'flat', 'CData', color_values);
    colormap(gca, 'parula');
    xlabel('ステップ', 'FontSize', 12);
    ylabel('Spectral Radius 変化量', 'FontSize', 12);
    title('各ステップでの変化量', 'FontSize', 12);
    grid on;
else
    text(0.5, 0.5, '変化率データが利用できません', 'HorizontalAlignment', 'center');
end

sgtitle(sprintf('IDGSM攻撃の詳細分析 (投影方法: %s)', projection_method), 'FontSize', 16, 'FontWeight', 'bold');

fprintf('可視化完了\n');
end


