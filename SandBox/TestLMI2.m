% 導いた不安定LMI (Kも設計vewr) が正しいかどうかの検証を行う。

clear; clc;

%% 1. システムとゲインの設計 (混合固有値を作る)
% 2次元の簡単な離散時間システム
A = [0.5  0.2;
     0    1.1]; % 元々少し不安定なシステム
% A = rand(2,2);
B = [0; 1];
% B = rand(2,1);

% ターゲットとする固有値 (混合状態)
% 絶対値 > 1 (不安定) と 絶対値 < 1 (安定) を混在させる
target_poles = [1.2, (rand()-0.5)*2]; 

%% 2. 双対LMI (不安定性の証明) の構築
n = size(A, 1);
m = size(B,2);

% 変数 H の定義 (2n x 2n の対称行列)

% ブロック行列の切り出し H = [H11 H12; H12' H22]
S11 = sdpvar(n, n, 'symmetric');
S22 = sdpvar(n, n, 'symmetric');
S12 = sdpvar(n, n, 'full');
Y = sdpvar(m, n, 'full');



% ユーザー定義の行列 G の計算
S = [S11, S12;
     S12', S22];

G = S11 + S22 + Y'*B'+S12'*A' +A*S12 + B*Y;

%% 3. 制約条件の設定と解決
% 条件1: H > 0 (正定対称) -> 数値誤差を防ぐため小さな正の値を下限に設定
% 条件2: G <= 0 (半負定値)
epsilon = 1e-6;
Constraints = [S >= 0, ...
                norm(Y,2) <= 1,...
               G <= 0]; % G < 0 にして厳密に探索

% ソルバーの設定 (sedumi, sdpt3, mosek 等、入っているものを使用)
options = sdpsettings('solver', '', 'verbose', 0); 

% 最適化 (実行可能性問題)
sol = optimize(Constraints, [], options);
S12 = value(S12);
Y = value(Y);
S = value(S);
G = value(G);
disp('G');disp(G);
disp('eig G');disp(eig(G));
disp('S');disp(S);
disp('S12');disp(S12);
disp('trace S12');disp(trace(S12));
disp('rank S12');disp(rank(S12));

K = Y*S12^(-1);
disp('K'); disp(K);
disp('eig A+BK');disp(eig(A+B*K));