% check_dare_feasibility.m
% alpha=-1.2, alpha=1.2の場合にDAREの解が存在するか確認するスクリプト
%
% 確認事項:
% 1. Aの固有値
% 2. 制御可能性
% 3. dlqrが成功するか
% 4. DAREの解が存在するか

clear; clc; close all;
startup;

fprintf('=== DARE解の存在確認 ===\n\n');

% パラメータ設定
n = 6;
m = 1;
alpha_values = [-1.2, -0.6, -0.2, 0.2, 0.6, 1.2];
Q = eye(n);
R = 1;

% 各alpha値について確認
for alpha = alpha_values
    fprintf('----------------------------------------\n');
    fprintf('alpha = %.2f\n', alpha);
    fprintf('----------------------------------------\n');
    
    % システム生成（delta_iは小さい値として固定で確認）
    % 実際の実験ではランダムだが、ここでは代表的な値を使用
    delta = [-0.04, -0.02, 0.0, 0.02, 0.04, 0.03];  % 相異なる値、|delta_i| <= 0.05
    A = diag(alpha + delta);
    B = ones(n, m);
    
    % 1. Aの固有値
    eig_A = eig(A);
    rho_A = max(abs(eig_A));
    fprintf('Aの固有値: %s\n', mat2str(eig_A, 4));
    fprintf('Aのスペクトル半径: %.4f\n', rho_A);
    if rho_A >= 1.0
        fprintf('  → Aは不安定（|λ| >= 1）\n');
    else
        fprintf('  → Aは安定（|λ| < 1）\n');
    end
    
    % 2. 制御可能性の確認
    Ctrb = ctrb(A, B);
    rank_Ctrb = rank(Ctrb);
    fprintf('\n制御可能性行列のランク: %d / %d\n', rank_Ctrb, n);
    if rank_Ctrb == n
        fprintf('  → システムは制御可能\n');
    else
        fprintf('  → システムは制御不可能（ランク不足）\n');
    end
    
    % 3. dlqrの実行
    fprintf('\ndlqrの実行:\n');
    try
        [K, P, E] = dlqr(A, B, Q, R);
        fprintf('  → dlqr成功\n');
        fprintf('  ゲイン行列Kの最大要素: %.4f\n', max(abs(K(:))));
        fprintf('  Riccati解Pの最大要素: %.4f\n', max(abs(P(:))));
        fprintf('  閉ループ固有値: %s\n', mat2str(E, 4));
        rho_closed = max(abs(E));
        fprintf('  閉ループスペクトル半径: %.4f\n', rho_closed);
        if rho_closed < 1.0
            fprintf('  → 閉ループシステムは安定\n');
        else
            fprintf('  → 閉ループシステムは不安定\n');
        end
    catch ME
        fprintf('  → dlqr失敗: %s\n', ME.message);
        fprintf('  エラー識別子: %s\n', ME.identifier);
    end
    
    % 4. dareの直接実行（確認用）
    fprintf('\ndareの直接実行:\n');
    try
        [P_dare, K_dare, E_dare] = dare(A, B, Q, R);
        fprintf('  → dare成功\n');
        fprintf('  Riccati解Pの最大要素: %.4f\n', max(abs(P_dare(:))));
        fprintf('  ゲイン行列Kの最大要素: %.4f\n', max(abs(K_dare(:))));
        fprintf('  閉ループ固有値: %s\n', mat2str(E_dare, 4));
    catch ME
        fprintf('  → dare失敗: %s\n', ME.message);
        fprintf('  エラー識別子: %s\n', ME.identifier);
    end
    
    % 5. 可安定性の確認（不安定固有値が制御可能か）
    fprintf('\n可安定性の確認:\n');
    [V, D] = eig(A);
    eigvals = diag(D);
    unstable_modes = find(abs(eigvals) >= 1.0);
    if isempty(unstable_modes)
        fprintf('  → 不安定モードなし\n');
    else
        fprintf('  不安定固有値の数: %d\n', length(unstable_modes));
        % 対角行列の場合、固有ベクトルは標準基底
        % 可安定性のチェック: rank([A-λI, B]) = n であること
        for i = 1:length(unstable_modes)
            idx = unstable_modes(i);
            lambda = eigvals(idx);
            
            % rank([A-λI, B])のチェック
            M = [A - lambda*eye(n), B];
            rank_M = rank(M, 1e-10);
            fprintf('  固有値 %.4f: rank([A-λI, B]) = %d / %d\n', lambda, rank_M, n);
            
            if rank_M == n
                fprintf('    → この不安定モードは制御可能（可安定）\n');
            else
                fprintf('    → この不安定モードは制御不可能（可安定でない）\n');
            end
        end
    end
    
    % 6. 数値的安定性の確認
    fprintf('\n数値的安定性の確認:\n');
    try
        [K, P, E] = dlqr(A, B, Q, R);
        cond_P = cond(P);
        fprintf('  Riccati解Pの条件数: %.2e\n', cond_P);
        if cond_P > 1e12
            fprintf('  → Pは数値的に不安定（条件数が大きすぎる）\n');
        end
        
        max_K = max(abs(K(:)));
        fprintf('  ゲインKの最大要素: %.2e\n', max_K);
        if max_K > 1e6
            fprintf('  → Kは数値的に不安定（値が大きすぎる）\n');
            fprintf('  → これが攻撃後のSDPがinfeasibleになる原因の可能性\n');
        end
        
        % 閉ループシステムの数値的安定性
        A_cl = A - B*K;
        cond_A_cl = cond(A_cl);
        fprintf('  閉ループシステムA-BKの条件数: %.2e\n', cond_A_cl);
    catch
        fprintf('  → dlqrが失敗したため確認できません\n');
    end
    
    fprintf('\n');
end

fprintf('=== 確認完了 ===\n');

