function plot_eigenvalues(metrics_ori, metrics_adv, varargin)
% plot_eigenvalues: Aの固有値とA+BK_optの固有値を描画
%
% 入力:
%   metrics_ori: 攻撃前の指標（calc_metricsの出力）
%   metrics_adv: 攻撃後の指標（calc_metricsの出力）
%   varargin: オプション引数
%     - 'figure_name': 図の名前
%     - 'show_legend': 凡例を表示するか（デフォルト: true）

    p = inputParser;
    addParameter(p, 'figure_name', '固有値の比較', @ischar);
    addParameter(p, 'show_legend', true, @islogical);
    parse(p, varargin{:});
    
    figure('Name', p.Results.figure_name, 'Position', [100, 100, 1200, 600]);
    
    % サブプロット1: Aの固有値（実部 vs 虚部）
    subplot(1, 2, 1);
    hold on;
    if ~isempty(metrics_ori.eig_A)
        scatter(real(metrics_ori.eig_A), imag(metrics_ori.eig_A), 100, 'b', 'filled', ...
            'DisplayName', '攻撃前');
    end
    if ~isempty(metrics_adv.eig_A)
        scatter(real(metrics_adv.eig_A), imag(metrics_adv.eig_A), 100, 'r', 'x', 'LineWidth', 2, ...
            'DisplayName', '攻撃後');
    end
    xlabel('実部');
    ylabel('虚部');
    title('Aの固有値');
    grid on;
    axis equal;
    if p.Results.show_legend
        legend('Location', 'best');
    end
    hold off;
    
    % サブプロット2: A+BK_optの固有値（実部 vs 虚部）
    subplot(1, 2, 2);
    hold on;
    if ~isempty(metrics_ori.eig_A_BK)
        scatter(real(metrics_ori.eig_A_BK), imag(metrics_ori.eig_A_BK), 100, 'b', 'filled', ...
            'DisplayName', '攻撃前');
    end
    if ~isempty(metrics_adv.eig_A_BK)
        scatter(real(metrics_adv.eig_A_BK), imag(metrics_adv.eig_A_BK), 100, 'r', 'x', 'LineWidth', 2, ...
            'DisplayName', '攻撃後');
    end
    % 単位円を描画
    theta = linspace(0, 2*pi, 100);
    plot(cos(theta), sin(theta), 'k--', 'LineWidth', 1, 'DisplayName', '単位円');
    xlabel('実部');
    ylabel('虚部');
    title('A+BK_{opt}の固有値');
    grid on;
    axis equal;
    if p.Results.show_legend
        legend('Location', 'best');
    end
    hold off;
end

