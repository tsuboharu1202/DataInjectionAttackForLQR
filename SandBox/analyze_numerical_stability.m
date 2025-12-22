% analyze_numerical_stability.m
% 数値的不安定性の要因を分析し、定量化するスクリプト
%
% 分析項目:
% 1. Aの固有値と単位円の距離
% 2. 制御可能性の度合い（制御可能性行列の条件数）
% 3. Riccati解Pの条件数
% 4. ゲインKのノルム
% 5. 閉ループシステムの条件数
% 6. これらの指標の相関関係

clear; clc; close all;
startup;

fprintf('=== 数値的不安定性の要因分析 ===\n\n');

% パラメータ設定
n = 6;
m = 1;
alpha_values = [-1.2, -0.6, -0.2, 0.2, 0.6, 1.2];
Q = eye(n);
R = 1;

% 結果を保存する構造体
results = struct();
results.alpha = [];
results.rho_A = [];
results.max_eig_dist = [];  % 最大固有値と単位円の距離
results.cond_ctrb = [];     % 制御可能性行列の条件数
results.cond_P = [];        % Riccati解Pの条件数
results.norm_K = [];        % ゲインKのノルム
results.cond_A_cl = [];     % 閉ループシステムの条件数
results.max_K = [];         % ゲインKの最大要素

% 各alpha値について分析
for alpha = alpha_values
    fprintf('----------------------------------------\n');
    fprintf('alpha = %.2f\n', alpha);
    fprintf('----------------------------------------\n');
    
    % システム生成
    delta = [-0.04, -0.02, 0.0, 0.02, 0.04, 0.03];
    A = diag(alpha + delta);
    B = ones(n, m);
    
    % 1. Aの固有値と単位円の距離
    eig_A = eig(A);
    rho_A = max(abs(eig_A));
    max_eig_dist = abs(rho_A - 1.0);  % 単位円からの距離
    fprintf('Aのスペクトル半径: %.4f\n', rho_A);
    fprintf('最大固有値と単位円の距離: %.4f\n', max_eig_dist);
    
    % 2. 制御可能性行列の条件数
    Ctrb = ctrb(A, B);
    cond_ctrb = cond(Ctrb);
    fprintf('制御可能性行列の条件数: %.2e\n', cond_ctrb);
    
    % 3. Riccati解とゲインの数値的特性
    try
        [K, P, E] = dlqr(A, B, Q, R);
        cond_P = cond(P);
        norm_K = norm(K, 'fro');
        max_K = max(abs(K(:)));
        A_cl = A - B*K;
        cond_A_cl = cond(A_cl);
        
        fprintf('Riccati解Pの条件数: %.2e\n', cond_P);
        fprintf('ゲインKのFrobeniusノルム: %.2e\n', norm_K);
        fprintf('ゲインKの最大要素: %.2e\n', max_K);
        fprintf('閉ループシステムA-BKの条件数: %.2e\n', cond_A_cl);
        
        % 結果を保存
        results.alpha = [results.alpha, alpha];
        results.rho_A = [results.rho_A, rho_A];
        results.max_eig_dist = [results.max_eig_dist, max_eig_dist];
        results.cond_ctrb = [results.cond_ctrb, cond_ctrb];
        results.cond_P = [results.cond_P, cond_P];
        results.norm_K = [results.norm_K, norm_K];
        results.cond_A_cl = [results.cond_A_cl, cond_A_cl];
        results.max_K = [results.max_K, max_K];
        
    catch ME
        fprintf('dlqr失敗: %s\n', ME.message);
    end
    
    fprintf('\n');
end

% 相関分析
fprintf('=== 相関分析 ===\n');
if length(results.alpha) > 1
    % スペクトル半径とPの条件数の相関
    corr_rho_condP = corrcoef(results.rho_A, results.cond_P);
    fprintf('Aのスペクトル半径 vs Riccati解Pの条件数: %.4f\n', corr_rho_condP(1,2));
    
    % 単位円からの距離とPの条件数の相関
    corr_dist_condP = corrcoef(results.max_eig_dist, results.cond_P);
    fprintf('単位円からの距離 vs Riccati解Pの条件数: %.4f\n', corr_dist_condP(1,2));
    
    % スペクトル半径とKのノルムの相関
    corr_rho_normK = corrcoef(results.rho_A, results.norm_K);
    fprintf('Aのスペクトル半径 vs ゲインKのノルム: %.4f\n', corr_rho_normK(1,2));
    
    % 制御可能性とPの条件数の相関
    corr_ctrb_condP = corrcoef(results.cond_ctrb, results.cond_P);
    fprintf('制御可能性行列の条件数 vs Riccati解Pの条件数: %.4f\n', corr_ctrb_condP(1,2));
end

% 可視化
fprintf('\n=== 可視化 ===\n');
figure('Name', '数値的不安定性の要因分析', 'Position', [100, 100, 1400, 800]);

% サブプロット1: スペクトル半径 vs Riccati解Pの条件数
subplot(2, 3, 1);
semilogy(results.rho_A, results.cond_P, 'o-', 'LineWidth', 2, 'MarkerSize', 10);
xlabel('Aのスペクトル半径 \rho(A)');
ylabel('Riccati解Pの条件数 (対数スケール)');
title('スペクトル半径 vs Riccati解Pの条件数');
grid on;
xline(1.0, 'r--', 'LineWidth', 1, 'DisplayName', '単位円');
legend('Location', 'best');

% サブプロット2: 単位円からの距離 vs Riccati解Pの条件数
subplot(2, 3, 2);
semilogy(results.max_eig_dist, results.cond_P, 'o-', 'LineWidth', 2, 'MarkerSize', 10);
xlabel('最大固有値と単位円の距離');
ylabel('Riccati解Pの条件数 (対数スケール)');
title('単位円からの距離 vs Riccati解Pの条件数');
grid on;

% サブプロット3: スペクトル半径 vs ゲインKのノルム
subplot(2, 3, 3);
semilogy(results.rho_A, results.norm_K, 'o-', 'LineWidth', 2, 'MarkerSize', 10);
xlabel('Aのスペクトル半径 \rho(A)');
ylabel('ゲインKのFrobeniusノルム (対数スケール)');
title('スペクトル半径 vs ゲインKのノルム');
grid on;
xline(1.0, 'r--', 'LineWidth', 1, 'DisplayName', '単位円');
legend('Location', 'best');

% サブプロット4: 制御可能性 vs Riccati解Pの条件数
subplot(2, 3, 4);
semilogy(results.cond_ctrb, results.cond_P, 'o-', 'LineWidth', 2, 'MarkerSize', 10);
xlabel('制御可能性行列の条件数');
ylabel('Riccati解Pの条件数 (対数スケール)');
title('制御可能性 vs Riccati解Pの条件数');
grid on;

% サブプロット5: Riccati解Pの条件数 vs 閉ループシステムの条件数
subplot(2, 3, 5);
loglog(results.cond_P, results.cond_A_cl, 'o-', 'LineWidth', 2, 'MarkerSize', 10);
xlabel('Riccati解Pの条件数 (対数スケール)');
ylabel('閉ループシステムA-BKの条件数 (対数スケール)');
title('Riccati解P vs 閉ループシステムの条件数');
grid on;
hold on;
plot([1, 1e15], [1, 1e15], 'r--', 'LineWidth', 1);  % y=xの線
hold off;

% サブプロット6: 総合的な不安定性指標
subplot(2, 3, 6);
% 不安定性指標 = log10(cond_P) + log10(norm_K) + log10(cond_A_cl)
instability_index = log10(results.cond_P) + log10(results.norm_K) + log10(results.cond_A_cl);
plot(results.alpha, instability_index, 'o-', 'LineWidth', 2, 'MarkerSize', 10);
xlabel('Alpha');
ylabel('総合的不安定性指標 (log10スケール)');
title('Alpha vs 総合的不安定性指標');
grid on;

% 数値的不安定性の閾値
fprintf('\n=== 数値的不安定性の閾値 ===\n');
threshold_cond_P = 1e12;  % Riccati解Pの条件数の閾値
threshold_norm_K = 1e6;   % ゲインKのノルムの閾値

fprintf('Riccati解Pの条件数 > %.2e の場合、数値的に不安定と判定\n', threshold_cond_P);
fprintf('ゲインKのノルム > %.2e の場合、数値的に不安定と判定\n', threshold_norm_K);

fprintf('\n各alpha値の判定:\n');
for i = 1:length(results.alpha)
    alpha = results.alpha(i);
    cond_P = results.cond_P(i);
    norm_K = results.norm_K(i);
    
    is_unstable = (cond_P > threshold_cond_P) || (norm_K > threshold_norm_K);
    status = '不安定';
    if ~is_unstable
        status = '安定';
    end
    
    fprintf('alpha=%.2f: cond_P=%.2e, norm_K=%.2e → %s\n', ...
        alpha, cond_P, norm_K, status);
end

fprintf('\n=== 分析完了 ===\n');






