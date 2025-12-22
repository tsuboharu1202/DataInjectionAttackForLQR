function plot_singular_values(metrics_ori, metrics_adv, varargin)
% plot_singular_values: X, Z, Uの特異値を描画
%
% 入力:
%   metrics_ori: 攻撃前の指標（calc_metricsの出力）
%   metrics_adv: 攻撃後の指標（calc_metricsの出力）
%   varargin: オプション引数
%     - 'figure_name': 図の名前
%     - 'show_legend': 凡例を表示するか（デフォルト: true）

    p = inputParser;
    addParameter(p, 'figure_name', '特異値の比較', @ischar);
    addParameter(p, 'show_legend', true, @islogical);
    parse(p, varargin{:});
    
    figure('Name', p.Results.figure_name, 'Position', [150, 150, 1200, 800]);
    
    % サブプロット1: Xの特異値
    subplot(2, 2, 1);
    hold on;
    if ~isempty(metrics_ori.svd_X)
        semilogy(1:length(metrics_ori.svd_X), metrics_ori.svd_X, 'b-o', ...
            'LineWidth', 1.5, 'MarkerSize', 6, 'DisplayName', '攻撃前');
    end
    if ~isempty(metrics_adv.svd_X)
        semilogy(1:length(metrics_adv.svd_X), metrics_adv.svd_X, 'r-x', ...
            'LineWidth', 1.5, 'MarkerSize', 6, 'DisplayName', '攻撃後');
    end
    xlabel('特異値のインデックス');
    ylabel('特異値（対数スケール）');
    title('Xの特異値');
    grid on;
    if p.Results.show_legend
        legend('Location', 'best');
    end
    hold off;
    
    % サブプロット2: Zの特異値
    subplot(2, 2, 2);
    hold on;
    if ~isempty(metrics_ori.svd_Z)
        semilogy(1:length(metrics_ori.svd_Z), metrics_ori.svd_Z, 'b-o', ...
            'LineWidth', 1.5, 'MarkerSize', 6, 'DisplayName', '攻撃前');
    end
    if ~isempty(metrics_adv.svd_Z)
        semilogy(1:length(metrics_adv.svd_Z), metrics_adv.svd_Z, 'r-x', ...
            'LineWidth', 1.5, 'MarkerSize', 6, 'DisplayName', '攻撃後');
    end
    xlabel('特異値のインデックス');
    ylabel('特異値（対数スケール）');
    title('Zの特異値');
    grid on;
    if p.Results.show_legend
        legend('Location', 'best');
    end
    hold off;
    
    % サブプロット3: Uの特異値
    subplot(2, 2, 3);
    hold on;
    if ~isempty(metrics_ori.svd_U)
        semilogy(1:length(metrics_ori.svd_U), metrics_ori.svd_U, 'b-o', ...
            'LineWidth', 1.5, 'MarkerSize', 6, 'DisplayName', '攻撃前');
    end
    if ~isempty(metrics_adv.svd_U)
        semilogy(1:length(metrics_adv.svd_U), metrics_adv.svd_U, 'r-x', ...
            'LineWidth', 1.5, 'MarkerSize', 6, 'DisplayName', '攻撃後');
    end
    xlabel('特異値のインデックス');
    ylabel('特異値（対数スケール）');
    title('Uの特異値');
    grid on;
    if p.Results.show_legend
        legend('Location', 'best');
    end
    hold off;
    
    % サブプロット4: 最大特異値の比較
    subplot(2, 2, 4);
    hold on;
    data_names = {'X', 'Z', 'U'};
    max_svd_ori = [max(metrics_ori.svd_X), max(metrics_ori.svd_Z), max(metrics_ori.svd_U)];
    max_svd_adv = [max(metrics_adv.svd_X), max(metrics_adv.svd_Z), max(metrics_adv.svd_U)];
    
    x_pos = 1:3;
    bar(x_pos - 0.2, max_svd_ori, 0.4, 'b', 'DisplayName', '攻撃前');
    bar(x_pos + 0.2, max_svd_adv, 0.4, 'r', 'DisplayName', '攻撃後');
    set(gca, 'XTick', x_pos, 'XTickLabel', data_names);
    ylabel('最大特異値');
    title('最大特異値の比較');
    grid on;
    if p.Results.show_legend
        legend('Location', 'best');
    end
    hold off;
end

