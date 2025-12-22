function [A, B, Q, R] = make_structured_lti_diagonal(alpha, n, m)
% make_structured_lti_diagonal - 対角行列構造のLTIシステムを生成
%
% 入力:
%   alpha: スカラー、対角行列の基準値
%   n: 状態次元
%   m: 入力次元（現在は1のみ対応）
%
% 出力:
%   A: 対角行列 diag(alpha + delta_1, ..., alpha + delta_n)
%      delta_iは相異なる値、|delta_i| <= 0.05
%   B: 1_n (m=1の場合)
%   Q: 単位行列
%   R: 1 (m=1の場合)

if m ~= 1
    error('現在はm=1のみ対応しています');
end

% delta_iを生成（相異なる値、|delta_i| <= 0.05）
% 一様分布から生成し、相異なることを保証
% 制御可能性を確保するため、十分な差を保つ（最小差: 0.01）
max_attempts = 1000;
delta = zeros(n, 1);
min_diff = 0.01;  % 最小差を設定（数値安定性のため）

for i = 1:n
    attempts = 0;
    while attempts < max_attempts
        candidate = (rand() - 0.5) * 0.1;  % [-0.05, 0.05]の範囲
        % 既存のdeltaとの最小差をチェック
        if i == 1 || all(abs(delta(1:i-1) - candidate) >= min_diff)
            delta(i) = candidate;
            break;
        end
        attempts = attempts + 1;
    end
    if attempts >= max_attempts
        % フォールバック: 等間隔で生成（最小差を保証）
        delta(i) = (i - (n+1)/2) * 0.1 / (n-1);  % 等間隔で生成
    end
end

% Aを対角行列として生成
A = diag(alpha + delta);

% B = 1_n
B = ones(n, m);

% Q = I
Q = eye(n);

% R = 1
R = 1;

end

