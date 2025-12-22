function metrics = calc_metrics(A, B, X, Z, U, K_opt)
% calc_metrics: システムの各種指標を計算
%
% 入力:
%   A: システム行列 (n×n)
%   B: 入力行列 (n×m)
%   X: 状態データ (n×T)
%   Z: 出力データ (n×T)
%   U: 入力データ (m×T)
%   K_opt: 最適ゲイン行列 (m×n)
%
% 出力:
%   metrics: 構造体
%     - eig_A: Aの固有値
%     - eig_A_BK: A+BK_optの固有値
%     - rho_A: Aのスペクトル半径
%     - rho_A_BK: A+BK_optのスペクトル半径
%     - svd_X: Xの特異値
%     - svd_Z: Zの特異値
%     - svd_U: Uの特異値
%     - max_svd_A: Aの最大特異値
%     - max_svd_B: Bの最大特異値
%     - ratio_max_svd: Aの最大特異値/Bの最大特異値（謎指標）

    metrics = struct();
    
    % Aの固有値とスペクトル半径
    eig_A = eig(A);
    metrics.eig_A = eig_A;
    metrics.rho_A = max(abs(eig_A));
    
    % A+BK_optの固有値とスペクトル半径
    if nargin >= 6 && ~isempty(K_opt)
        eig_A_BK = eig(A + B*K_opt);
        metrics.eig_A_BK = eig_A_BK;
        metrics.rho_A_BK = max(abs(eig_A_BK));
    else
        metrics.eig_A_BK = [];
        metrics.rho_A_BK = NaN;
    end
    
    % X, Z, Uの特異値
    if nargin >= 3 && ~isempty(X)
        metrics.svd_X = svd(X);
    else
        metrics.svd_X = [];
    end
    
    if nargin >= 4 && ~isempty(Z)
        metrics.svd_Z = svd(Z);
    else
        metrics.svd_Z = [];
    end
    
    if nargin >= 5 && ~isempty(U)
        metrics.svd_U = svd(U);
    else
        metrics.svd_U = [];
    end
    
    % A, Bの最大特異値とその比
    svd_A = svd(A);
    metrics.max_svd_A = max(svd_A);
    
    svd_B = svd(B);
    metrics.max_svd_B = max(svd_B);
    
    if metrics.max_svd_B > 0
        metrics.ratio_max_svd = metrics.max_svd_A / metrics.max_svd_B;
    else
        metrics.ratio_max_svd = Inf;
    end
end

