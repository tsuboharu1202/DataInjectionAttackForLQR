function dK = compute_dK(dU,dL,dX,U,X,L_star)
% compute_dK: データの変化に対する最適ゲインK*の変化を計算
% dK = (dU*L + U*dL)/(X*L) - U*L/(X*L) * ((dX*L + X*dL)/(X*L))
% 
% 入力:
%   dU: Uの変化 (m×T)
%   dL: L*の変化 (T×n)
%   dX: Xの変化 (n×T)
%   U: 元の入力データ (m×T)
%   X: 元の状態データ (n×T)
%   L_star: SDPの最適解 (T×n)
% 
% 出力:
%   dK: K*の変化 (m×n)

    L = L_star;
    M = X*L;                    % n×n
    A1 = (dU*L + U*dL) / M;     % 右割り = *inv(M) 相当だが数値的に安定
    A2 = (dX*L + X*dL) / M;
    K0 = (U*L) / M;

    dK = A1 - K0*A2;
end
