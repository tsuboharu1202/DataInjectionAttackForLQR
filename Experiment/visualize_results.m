function visualize_results(result_file)
% visualize_results: 実験結果を表やグラフで可視化
%
% 使用例:
%   visualize_results('Result/experiment_results_20251216_220332.mat')  % 旧形式
%   visualize_results('Result/experiment_20251216_220332')  % 新形式（実験ディレクトリ）
%   または
%   load('Result/experiment_results_20251216_220332.mat')
%   visualize_results()  % ワークスペースの変数を使用
%   または
%   cd Experiment
%   visualize_results()  % 現在のワークスペースの変数を使用

% ファイルが指定されている場合は読み込む
if nargin >= 1 && ~isempty(result_file)
    fprintf('結果ファイル/ディレクトリを読み込み中: %s\n', result_file);
    
    % パスの解決（相対パスの場合、Experimentディレクトリからの相対パスとして扱う）
    script_dir = fileparts(mfilename('fullpath'));
    
    if ~isfile(result_file) && ~isfolder(result_file)
        % 現在のディレクトリにない場合、Experimentディレクトリからの相対パスを試す
        full_path = fullfile(script_dir, result_file);
        if isfile(full_path) || isfolder(full_path)
            result_file = full_path;
        else
            error('ファイル/ディレクトリが見つかりません: %s\n試したパス: %s', result_file, full_path);
        end
    end
    
    % 新形式（実験ディレクトリ）か旧形式（.matファイル）かを判定
    if isfolder(result_file)
        % 新形式: 実験ディレクトリから読み込む
        experiment_dir = result_file;
        experiment_info_file = fullfile(experiment_dir, 'experiment_info.mat');
        
        if ~isfile(experiment_info_file)
            error('実験情報ファイルが見つかりません: %s', experiment_info_file);
        end
        
        % 実験情報を読み込む
        exp_info = load(experiment_info_file, 'experiment_info');
        experiment_info = exp_info.experiment_info;
        
        % 実験パラメータをワークスペースに設定（互換性のため）
        if isfield(experiment_info, 'num_trials')
            NUM_TRIALS = experiment_info.num_trials;
        end
        
        % 各条件のsummary.matから統計情報を読み込む
        all_results = [];
        condition_dirs = dir(fullfile(experiment_dir, 'condition_*'));
        condition_dirs = condition_dirs([condition_dirs.isdir]);
        
        for i = 1:length(condition_dirs)
            condition_dir = fullfile(experiment_dir, condition_dirs(i).name);
            summary_file = fullfile(condition_dir, 'summary.mat');
            
            if isfile(summary_file)
                cond_data = load(summary_file, 'condition_results');
                if isfield(cond_data, 'condition_results')
                    all_results = [all_results; cond_data.condition_results];
                end
            end
        end
        
        if isempty(all_results)
            error('条件データが見つかりませんでした。実験が完了していない可能性があります。');
        end
        
        fprintf('新形式の実験ディレクトリから読み込みました: %d条件\n', length(all_results));
        
    else
        % 旧形式: .matファイルから読み込む
        load(result_file);
    end
end

% ワークスペースに変数があるか確認（all_results または all_results_array をサポート）
if ~exist('all_results', 'var')
    if exist('all_results_array', 'var')
        all_results = all_results_array;
    elseif exist('all_results_checkpoint', 'var')
        all_results = all_results_checkpoint;
    else
        error('all_results変数が見つかりません。ファイルを読み込むか、ワークスペースに変数があることを確認してください。');
    end
end

fprintf('\n=== 実験結果の可視化 ===\n');
fprintf('条件数: %d\n', length(all_results));
if exist('NUM_TRIALS', 'var')
    fprintf('試行回数/条件: %d\n', NUM_TRIALS);
end
fprintf('\n');

% ========================================
% 1. 結果を表形式で表示
% ========================================
fprintf('=== 結果サマリーテーブル ===\n');
fprintf('%-8s %-6s %-6s %-6s %-12s %-12s %-12s %-12s\n', ...
    'eps', 'T', 'n', 'm', '不安定化率', '平均rho_ori', '平均rho_adv', '平均変化');
fprintf('%s\n', repmat('-', 1, 80));

for i = 1:length(all_results)
    r = all_results(i);
    fprintf('%-8.4f %-6d %-6d %-6d %-12.1f%% %-12.4f %-12.4f %-12.4f\n', ...
        r.eps_att, r.T, r.n, r.m, ...
        r.unstable_rate*100, ...
        r.mean_rho_ori, r.mean_rho_adv, r.mean_rho_change);
end
fprintf('\n');

% ========================================
% 2. 表形式のデータを作成（MATLABのtableとして）
% ========================================
fprintf('=== MATLAB Table形式 ===\n');
table_data = struct2table(all_results);

% 主要な列だけを選択
if ismember('eps_att', table_data.Properties.VariableNames)
    summary_table = table_data(:, {'eps_att', 'T', 'n', 'm', ...
        'unstable_rate', 'mean_rho_ori', 'mean_rho_adv', 'mean_rho_change', 'std_rho_change'});
    summary_table.Properties.VariableNames = {'eps', 'T', 'n', 'm', ...
        'UnstableRate', 'MeanRhoOri', 'MeanRhoAdv', 'MeanRhoChange', 'StdRhoChange'};
    disp(summary_table);
else
    disp(table_data);
end
fprintf('\n');

% ========================================
% 3. グラフの描画
% ========================================
fprintf('=== グラフを描画中... ===\n');

% 3-1. eps_att vs 不安定化率（対数スケール）
if length(all_results) > 1
    figure('Name', '攻撃制約 vs 不安定化率', 'Position', [100, 100, 800, 600]);
    eps_values = [all_results.eps_att];
    unstable_rates = [all_results.unstable_rate] * 100;
    semilogx(eps_values, unstable_rates, 'o-', 'LineWidth', 2, 'MarkerSize', 8);
    xlabel('攻撃制約 \epsilon (対数スケール)');
    ylabel('不安定化率 (%)');
    title('攻撃制約と不安定化率の関係');
    grid on;
end

% 3-2. eps_att vs 平均rho変化（対数スケール）
if length(all_results) > 1
    figure('Name', '攻撃制約 vs 平均固有値変化', 'Position', [150, 150, 800, 600]);
    eps_values = [all_results.eps_att];
    rho_changes = [all_results.mean_rho_change];
    semilogx(eps_values, rho_changes, 's-', 'LineWidth', 2, 'MarkerSize', 8);
    xlabel('攻撃制約 \epsilon (対数スケール)');
    ylabel('平均固有値変化 \Delta\rho');
    title('攻撃制約と固有値変化の関係');
    grid on;
    hold on;
    yline(0, 'r--', 'LineWidth', 1.5);  % 安定/不安定の境界線
    hold off;
end

% 3-3. 各条件でのrho_ori vs rho_adv（散布図）
figure('Name', '攻撃前後の固有値比較', 'Position', [200, 200, 800, 600]);
colors = lines(length(all_results));
hold on;
for i = 1:length(all_results)
    r = all_results(i);
    % 各試行のデータをプロット
    if isfield(r, 'rho_ori') && isfield(r, 'rho_adv')
        scatter(r.rho_ori, r.rho_adv, 100, colors(i,:), 'filled', 'DisplayName', ...
            sprintf('eps=%.4f, T=%d', r.eps_att, r.T));
    end
end
xlabel('攻撃前の固有値 \rho_{ori}');
ylabel('攻撃後の固有値 \rho_{adv}');
title('攻撃前後の固有値比較');
% 対角線（変化なし）と不安定化境界線を描画
xlim_range = xlim;
ylim_range = ylim;
plot([0, max(xlim_range(2), ylim_range(2))], [0, max(xlim_range(2), ylim_range(2))], ...
    'k--', 'LineWidth', 1, 'DisplayName', '変化なし');
yline(1.0, 'r--', 'LineWidth', 2, 'DisplayName', '不安定化境界');
xline(1.0, 'r--', 'LineWidth', 1);
grid on;
legend('Location', 'best');
hold off;

% 3-4. 箱ひげ図（各条件でのrho変化の分布）
% Statistics Toolboxがない場合に備えて、代替可視化を使用
if length(all_results) > 1 && isfield(all_results(1), 'rho_change')
    figure('Name', '各条件での固有値変化の分布', 'Position', [250, 250, 1000, 600]);
    rho_change_data = cell(length(all_results), 1);
    labels = cell(length(all_results), 1);
    for i = 1:length(all_results)
        r = all_results(i);
        if isfield(r, 'rho_change')
            rho_change_data{i} = r.rho_change(~isnan(r.rho_change));
            labels{i} = sprintf('eps=%.4f\nT=%d', r.eps_att, r.T);
        end
    end
    
    % Statistics Toolboxがない場合の代替：手動で箱ひげ図を描画
    try
        % boxplotが使える場合
        boxplot([rho_change_data{:}], 'Labels', labels);
    catch
        % boxplotが使えない場合：手動で箱ひげ図を描画
        num_conditions = length(rho_change_data);
        positions = 1:num_conditions;
        
        for i = 1:num_conditions
            data = rho_change_data{i};
            if ~isempty(data)
                % 統計量を計算
                q1 = prctile(data, 25);
                q2 = prctile(data, 50);  % 中央値
                q3 = prctile(data, 75);
                iqr = q3 - q1;
                lower_whisker = max(min(data), q1 - 1.5*iqr);
                upper_whisker = min(max(data), q3 + 1.5*iqr);
                
                % 箱を描画
                x_pos = positions(i);
                rectangle('Position', [x_pos-0.2, q1, 0.4, iqr], ...
                    'FaceColor', [0.7 0.7 0.9], 'EdgeColor', 'k', 'LineWidth', 1.5);
                % 中央値の線
                line([x_pos-0.2, x_pos+0.2], [q2, q2], 'Color', 'r', 'LineWidth', 2);
                % ひげを描画
                line([x_pos, x_pos], [lower_whisker, q1], 'Color', 'k', 'LineWidth', 1.5);
                line([x_pos, x_pos], [q3, upper_whisker], 'Color', 'k', 'LineWidth', 1.5);
                line([x_pos-0.1, x_pos+0.1], [lower_whisker, lower_whisker], 'Color', 'k', 'LineWidth', 1.5);
                line([x_pos-0.1, x_pos+0.1], [upper_whisker, upper_whisker], 'Color', 'k', 'LineWidth', 1.5);
                % 外れ値を描画
                outliers = data(data < lower_whisker | data > upper_whisker);
                if ~isempty(outliers)
                    scatter(repmat(x_pos, size(outliers)), outliers, 50, 'r', 'x', 'LineWidth', 1.5);
                end
            end
        end
        
        set(gca, 'XTick', positions, 'XTickLabel', labels);
        xlim([0.5, num_conditions + 0.5]);
    end
    
    ylabel('固有値変化 \Delta\rho');
    title('各条件での固有値変化の分布');
    grid on;
    hold on;
    yline(0, 'r--', 'LineWidth', 2);
    hold off;
end

fprintf('グラフの描画が完了しました。\n');
fprintf('\n');

% ========================================
% 4. 統計情報の表示
% ========================================
fprintf('=== 統計情報 ===\n');
if exist('NUM_TRIALS', 'var')
    num_trials_per_condition = NUM_TRIALS;
else
    num_trials_per_condition = 2;  % デフォルト値
end
total_unstable = sum([all_results.unstable_rate] .* num_trials_per_condition);
total_trials = length(all_results) * num_trials_per_condition;
fprintf('全体の不安定化率: %.1f%% (%d/%d試行)\n', ...
    total_unstable / total_trials * 100, total_unstable, total_trials);
fprintf('平均固有値変化: %.4f\n', mean([all_results.mean_rho_change], 'omitnan'));
fprintf('最大固有値変化: %.4f\n', max([all_results.mean_rho_change], [], 'omitnan'));
fprintf('最小固有値変化: %.4f\n', min([all_results.mean_rho_change], [], 'omitnan'));
fprintf('\n');

fprintf('可視化完了！\n');
end

