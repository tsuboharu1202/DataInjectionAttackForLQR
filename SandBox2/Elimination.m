% T = (I-S)*(I+S)^(-1)
% として考えた。ただし、S = -S'
% を満たせない。

clear; clc;
n = 4;
m= 3;

% ランダムなターゲット A2 (ノルムの矛盾を避けるため使用しないか、射影する)
% 今回は純粋に「直交行列化」の実験のため、外部制約を弱めます
A = randn(n, n) + eye(n); % 正の固有値が出やすいようにシフト
B = randn(n, m);
Ann_B = null(B');
disp("Ann_B");disp(Ann_B);
Ann_A = null(A');
disp("Ann_A");disp(Ann_A);
Q = eye(n);
R = eye(m);
[~, ~, K_opt] = care(A, B, Q, R);
Ac = A+B*K_opt;

% 変数 H の定義
S11 = sdpvar(n, n, 'symmetric');
S22 = sdpvar(n, n, 'symmetric');
S12 = sdpvar(n, n, 'full');
mat_S = [S11, S12;
         (S12)', S22];
W = (S11 + S22 + S12'*Ac' + Ac*S12);

unstable_inequality = Ann_B'*W*Ann_B;

Constraints = [mat_S >= 0, unstable_inequality <= 0 ];

% ソルバーの設定
options = sdpsettings('solver', 'mosek', 'verbose', 0); % mosek指定推奨

% 目的関数: トレースの最大化 (マイナスの最小化)
% J = -trace(H);

% === 最適化実行 ===
sol = optimize(Constraints, [], options);

% === 結果の分かりやすい表示 ===
fprintf('\n==============================================\n');
if sol.problem == 0

    fprintf('  判定: ★ Feasible (成功) ★\n');
    fprintf('  H は制約条件を満たしました。\n');
    S12 = value(S12);
    W = value(W);
else
    fprintf('  判定: ❌ Infeasible (失敗: 実行不可能) \n');
    
end
fprintf('==============================================\n');

% === どの制約が破られているか一覧表示 ===
disp(' ');
disp('--- 各制約のクリア状況 (数値が負だと違反) ---');
% check関数は、各制約の「余裕」を表示します（負ならアウト）