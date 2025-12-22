function plot_rho(all_results, varargin)
% plot_rho: 横軸=ノイズ（eps_att）、縦軸=rho変化/変化率の期待値、攻撃成功率を描画
%   rhoはA+B*K_opt（元のシステム）およびA+B*K_adv（攻撃後のシステム）のスペクトル半径
%
% 入力:
%   all_results: 実験結果の構造体配列（各要素にeps_att, mean_rho_change, unstable_rateなどが含まれる）
%   varargin: オプション引数
%     - 'figure_name': 図の名前
%     - 'group_by_alpha': alphaでグループ化するか（デフォルト: false）
%     - 'alpha_values': alphaの値のリスト（group_by_alpha=trueの場合に必要）

    p = inputParser;
    addParameter(p, 'figure_name', 'ノイズ vs 攻撃効果', @ischar);
    addParameter(p, 'group_by_alpha', false, @islogical);
    addParameter(p, 'alpha_values', [], @isnumeric);
    parse(p, varargin{:});
    
    if isempty(all_results)
        error('all_resultsが空です');
    end
    
    % alphaでグループ化する場合
    if p.Results.group_by_alpha && ~isempty(p.Results.alpha_values)
        num_alphas = length(p.Results.alpha_values);
        colors = lines(num_alphas);
        
        figure('Name', p.Results.figure_name, 'Position', [200, 200, 1400, 900]);
        
        % サブプロット1: ノイズ vs 平均rho変化
        subplot(2, 2, 1);
        hold on;
        for i = 1:num_alphas
            alpha = p.Results.alpha_values(i);
            % 該当するalphaの結果を抽出
            idx = abs([all_results.alpha] - alpha) < 1e-6;
            if any(idx)
                results_alpha = all_results(idx);
                eps_values = [results_alpha.eps_att];
                rho_changes = [results_alpha.mean_rho_change];
                [eps_sorted, sort_idx] = sort(eps_values);
                rho_sorted = rho_changes(sort_idx);
                plot(eps_sorted, rho_sorted, 'o-', 'LineWidth', 2, 'MarkerSize', 8, ...
                    'Color', colors(i,:), 'DisplayName', sprintf('alpha=%.2f', alpha));
            end
        end
        set(gca, 'XScale', 'log');
        xlabel('ノイズ \epsilon (対数スケール)');
        ylabel('平均スペクトル半径変化 \Delta\rho (A+BK)');
        title('ノイズ vs 平均スペクトル半径変化 (A+BK_{opt} → A+BK_{adv})');
        grid on;
        yline(0, 'k--', 'LineWidth', 1);
        legend('Location', 'best');
        hold off;
        
        % サブプロット2: ノイズ vs 攻撃成功率
        subplot(2, 2, 2);
        hold on;
        for i = 1:num_alphas
            alpha = p.Results.alpha_values(i);
            idx = abs([all_results.alpha] - alpha) < 1e-6;
            if any(idx)
                results_alpha = all_results(idx);
                eps_values = [results_alpha.eps_att];
                unstable_rates = [results_alpha.unstable_rate] * 100;
                [eps_sorted, sort_idx] = sort(eps_values);
                rates_sorted = unstable_rates(sort_idx);
                plot(eps_sorted, rates_sorted, 's-', 'LineWidth', 2, 'MarkerSize', 8, ...
                    'Color', colors(i,:), 'DisplayName', sprintf('alpha=%.2f', alpha));
            end
        end
        set(gca, 'XScale', 'log');
        xlabel('ノイズ \epsilon (対数スケール)');
        ylabel('攻撃成功率 (%)');
        title('ノイズ vs 攻撃成功率');
        grid on;
        yline(50, 'k--', 'LineWidth', 1);
        legend('Location', 'best');
        hold off;
        
        % サブプロット3: ノイズ vs rho変化率（相対変化）
        subplot(2, 2, 3);
        hold on;
        for i = 1:num_alphas
            alpha = p.Results.alpha_values(i);
            idx = abs([all_results.alpha] - alpha) < 1e-6;
            if any(idx)
                results_alpha = all_results(idx);
                eps_values = [results_alpha.eps_att];
                % 変化率は各試行で計算してから平均を取った値を使用
                % (Main.mでmean_rho_change_rateとして計算済み)
                if isfield(results_alpha(1), 'mean_rho_change_rate')
                    change_rates = [results_alpha.mean_rho_change_rate];
                else
                    % 後方互換性: 古いデータの場合は従来の計算方法を使用
                    rho_changes = [results_alpha.mean_rho_change];
                    rho_ori = [results_alpha.mean_rho_ori];
                    change_rates = rho_changes ./ rho_ori * 100;  % パーセント
                end
                [eps_sorted, sort_idx] = sort(eps_values);
                rates_sorted = change_rates(sort_idx);
                plot(eps_sorted, rates_sorted, '^-', 'LineWidth', 2, 'MarkerSize', 8, ...
                    'Color', colors(i,:), 'DisplayName', sprintf('alpha=%.2f', alpha));
            end
        end
        set(gca, 'XScale', 'log');
        xlabel('ノイズ \epsilon (対数スケール)');
        ylabel('スペクトル半径変化率 (%) (A+BK)');
        title('ノイズ vs スペクトル半径変化率 (A+BK_{opt}の変化率)');
        grid on;
        yline(0, 'k--', 'LineWidth', 1);
        legend('Location', 'best');
        hold off;
        
        % サブプロット4: ノイズ vs rho変化幅（標準偏差）
        subplot(2, 2, 4);
        hold on;
        for i = 1:num_alphas
            alpha = p.Results.alpha_values(i);
            idx = abs([all_results.alpha] - alpha) < 1e-6;
            if any(idx)
                results_alpha = all_results(idx);
                eps_values = [results_alpha.eps_att];
                std_changes = [results_alpha.std_rho_change];
                [eps_sorted, sort_idx] = sort(eps_values);
                std_sorted = std_changes(sort_idx);
                plot(eps_sorted, std_sorted, 'd-', 'LineWidth', 2, 'MarkerSize', 8, ...
                    'Color', colors(i,:), 'DisplayName', sprintf('alpha=%.2f', alpha));
            end
        end
        set(gca, 'XScale', 'log');
        xlabel('ノイズ \epsilon (対数スケール)');
        ylabel('スペクトル半径変化の標準偏差 (A+BK)');
        title('ノイズ vs スペクトル半径変化幅 (A+BK)');
        grid on;
        legend('Location', 'best');
        hold off;
        
    else
        % alphaでグループ化しない場合（シンプルな可視化）
        figure('Name', p.Results.figure_name, 'Position', [200, 200, 1200, 800]);
        
        % 個別試行結果か集計済み結果かを判定
        if isfield(all_results(1), 'mean_rho_change')
            % 集計済み結果の場合（従来の形式）
            eps_values = [all_results.eps_att];
            [eps_sorted, sort_idx] = sort(eps_values);
            
            % サブプロット1: ノイズ vs 平均rho変化
            subplot(2, 2, 1);
            rho_changes = [all_results.mean_rho_change];
            plot(eps_sorted, rho_changes(sort_idx), 'o-', 'LineWidth', 2, 'MarkerSize', 8);
            set(gca, 'XScale', 'log');
            xlabel('ノイズ \epsilon (対数スケール)');
            ylabel('平均スペクトル半径変化 \Delta\rho (A+BK)');
            title('ノイズ vs 平均スペクトル半径変化 (A+BK_{opt} → A+BK_{adv})');
            grid on;
            yline(0, 'k--', 'LineWidth', 1);
            
            % サブプロット2: ノイズ vs 攻撃成功率
            subplot(2, 2, 2);
            unstable_rates = [all_results.unstable_rate] * 100;
            plot(eps_sorted, unstable_rates(sort_idx), 's-', 'LineWidth', 2, 'MarkerSize', 8);
            set(gca, 'XScale', 'log');
            xlabel('ノイズ \epsilon (対数スケール)');
            ylabel('攻撃成功率 (%)');
            title('ノイズ vs 攻撃成功率');
            grid on;
            yline(50, 'k--', 'LineWidth', 1);
            
            % サブプロット3: ノイズ vs rho変化率
            subplot(2, 2, 3);
            if isfield(all_results(1), 'mean_rho_change_rate')
                change_rates = [all_results.mean_rho_change_rate];
            else
                rho_ori = [all_results.mean_rho_ori];
                change_rates = rho_changes ./ rho_ori * 100;
            end
            plot(eps_sorted, change_rates(sort_idx), '^-', 'LineWidth', 2, 'MarkerSize', 8);
            set(gca, 'XScale', 'log');
            xlabel('ノイズ \epsilon (対数スケール)');
            ylabel('スペクトル半径変化率 (%) (A+BK)');
            title('ノイズ vs スペクトル半径変化率 (A+BK_{opt}の変化率)');
            grid on;
            yline(0, 'k--', 'LineWidth', 1);
        else
            % 個別試行結果の場合（今回の実験形式）
            % ノイズごとに集計
            eps_values = unique([all_results.eps_att]);
            eps_values = eps_values(isfinite(eps_values));
            [eps_sorted, ~] = sort(eps_values);
            
            num_eps = length(eps_sorted);
            mean_rho_changes = zeros(num_eps, 1);
            std_rho_changes = zeros(num_eps, 1);
            unstable_rates = zeros(num_eps, 1);
            mean_rho_change_rates = zeros(num_eps, 1);
            
            for i = 1:num_eps
                eps_val = eps_sorted(i);
                idx = abs([all_results.eps_att] - eps_val) < 1e-10;
                results_eps = all_results(idx);
                
                % rho変化の平均と標準偏差
                rho_changes_eps = [results_eps.rho_change];
                rho_changes_eps = rho_changes_eps(isfinite(rho_changes_eps));
                mean_rho_changes(i) = mean(rho_changes_eps);
                std_rho_changes(i) = std(rho_changes_eps);
                
                % 攻撃成功率
                unstable_count = sum([results_eps.is_unstable]);
                unstable_rates(i) = unstable_count / length(results_eps) * 100;
                
                % 変化率の平均
                rho_ori_eps = [results_eps.rho_ori];
                rho_ori_eps = rho_ori_eps(isfinite(rho_ori_eps));
                if ~isempty(rho_ori_eps) && all(rho_ori_eps > 0)
                    change_rates_eps = rho_changes_eps ./ rho_ori_eps(1:length(rho_changes_eps)) * 100;
                    mean_rho_change_rates(i) = mean(change_rates_eps(isfinite(change_rates_eps)));
                end
            end
            
            % サブプロット1: ノイズ vs 平均rho変化（エラーバー付き）
            subplot(2, 2, 1);
            errorbar(eps_sorted, mean_rho_changes, std_rho_changes, 'o-', 'LineWidth', 2, 'MarkerSize', 8);
            set(gca, 'XScale', 'log');
            xlabel('ノイズ \epsilon (対数スケール)');
            ylabel('平均スペクトル半径変化 \Delta\rho (A+BK)');
            title('ノイズ vs 平均スペクトル半径変化 (A+BK_{opt} → A+BK_{adv})');
            grid on;
            yline(0, 'k--', 'LineWidth', 1);
            
            % サブプロット2: ノイズ vs 攻撃成功率
            subplot(2, 2, 2);
            plot(eps_sorted, unstable_rates, 's-', 'LineWidth', 2, 'MarkerSize', 8);
            set(gca, 'XScale', 'log');
            xlabel('ノイズ \epsilon (対数スケール)');
            ylabel('攻撃成功率 (%)');
            title('ノイズ vs 攻撃成功率');
            grid on;
            yline(50, 'k--', 'LineWidth', 1);
            
            % サブプロット3: ノイズ vs rho変化率
            subplot(2, 2, 3);
            plot(eps_sorted, mean_rho_change_rates, '^-', 'LineWidth', 2, 'MarkerSize', 8);
            set(gca, 'XScale', 'log');
            xlabel('ノイズ \epsilon (対数スケール)');
            ylabel('スペクトル半径変化率 (%) (A+BK)');
            title('ノイズ vs スペクトル半径変化率 (A+BK_{opt}の変化率)');
            grid on;
            yline(0, 'k--', 'LineWidth', 1);
        
            % サブプロット4: ノイズ vs rho変化幅（標準偏差）
            subplot(2, 2, 4);
            plot(eps_sorted, std_rho_changes, 'd-', 'LineWidth', 2, 'MarkerSize', 8);
            set(gca, 'XScale', 'log');
            xlabel('ノイズ \epsilon (対数スケール)');
            ylabel('スペクトル半径変化の標準偏差 (A+BK)');
            title('ノイズ vs スペクトル半径変化の標準偏差 (A+BK)');
            grid on;
        end
    end
end

