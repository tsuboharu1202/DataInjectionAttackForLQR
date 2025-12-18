function [K_star, Ac, P_star] = compute_closedloop_P(A,B,Q,R,X,U,L_star)
% compute_closedloop_P: 閉ループシステムの最適ゲインとLyapunov行列を計算
% 
% 入力:
%   A, B: システム行列
%   Q, R: 重み行列
%   X, U: データ
%   L_star: SDPの最適解
% 
% 出力:
%   K_star: 最適ゲイン (m×n)
%   Ac: 閉ループ行列 A+B*K_star (n×n)
%   P_star: Lyapunov行列 (n×n)

    % 形を整える
    n = size(A,1);
    M = X*L_star;             % n×n（F2で可逆を担保）
    K_star = (U*L_star) / M;  % 安定な右割り

    Ac = A + B*K_star;
    Qbar = Q + K_star'*R*K_star;

    % まずそのまま解く
    try
        P_star = lyap(Ac', Qbar);   % Ac' P + P Ac = -Qbar
    catch
        % うまくいかない場合は微小正則化
        epsL = 1e-8;
        P_star = lyap(Ac', Qbar + epsL*eye(n));
    end
end
