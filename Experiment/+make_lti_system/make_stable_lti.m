function [A, B, Q, R] = make_stable_lti(n, m)
% make_stable_lti - 数値的に安定なLTIシステムを生成
%
% 入力:
%   n: 状態次元
%   m: 入力次元
%
% 出力:
%   A: 安定なシステム行列（固有値が単位円内、条件数が小さい）
%   B: 入力行列（制御可能性を保証）
%   Q: 単位行列
%   R: 単位行列

% 1. 安定なAを生成（Schur分解を使用）
% ランダムな固有値を生成（単位円内、条件数が大きくなりすぎないように）
max_rho = 0.8;  % 最大スペクトル半径（安定性のマージン）
min_rho = 0.3;  % 最小スペクトル半径（数値的安定性のため）

% 固有値を生成（複素共役ペアも含む）
if mod(n, 2) == 0
    % nが偶数の場合、複素共役ペアで生成
    num_pairs = n / 2;
    eigvals = zeros(n, 1);
    for i = 1:num_pairs
        rho = min_rho + (max_rho - min_rho) * rand();
        theta = 2 * pi * rand();  % 位相
        eigvals(2*i-1) = rho * exp(1i * theta);
        eigvals(2*i) = rho * exp(-1i * theta);
    end
else
    % nが奇数の場合、1つの実固有値と複素共役ペア
    num_pairs = (n - 1) / 2;
    eigvals = zeros(n, 1);
    % 実固有値
    eigvals(1) = min_rho + (max_rho - min_rho) * rand();
    for i = 1:num_pairs
        rho = min_rho + (max_rho - min_rho) * rand();
        theta = 2 * pi * rand();
        eigvals(2*i) = rho * exp(1i * theta);
        eigvals(2*i+1) = rho * exp(-1i * theta);
    end
end

% Schur分解を使ってAを生成
[Q_schur, ~] = qr(randn(n, n));
A = Q_schur * diag(eigvals) * Q_schur';

% 条件数をチェック（大きすぎる場合は再生成）
max_attempts = 100;
attempt = 0;
while cond(A) > 1e3 && attempt < max_attempts
    [Q_schur, ~] = qr(randn(n, n));
    A = Q_schur * diag(eigvals) * Q_schur';
    attempt = attempt + 1;
end

% 2. 制御可能なBを生成
B = randn(n, m);
% 制御可能性を確認
Ctrb = ctrb(A, B);
if rank(Ctrb) < n
    % 制御不可能な場合はBを調整
    B = ones(n, m);  % フォールバック
    if rank(ctrb(A, B)) < n
        % それでも制御不可能な場合は警告
        warning('システムが制御不可能の可能性があります');
    end
end

% 3. 重み行列
Q = eye(n);
R = eye(m);

% 4. 数値的安定性の確認
rho_A = max(abs(eig(A)));
cond_A = cond(A);
cond_Ctrb = cond(ctrb(A, B));

% 警告を出す条件
if rho_A >= 0.95
    warning('Aのスペクトル半径が大きすぎます: %.4f', rho_A);
end
if cond_A > 1e3
    warning('Aの条件数が大きすぎます: %.2e', cond_A);
end
if cond_Ctrb > 1e6
    warning('制御可能性行列の条件数が大きすぎます: %.2e', cond_Ctrb);
end

end






