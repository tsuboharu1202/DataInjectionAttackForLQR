% 導いた不安定LMIが正しいかどうかの検証を行う。

clear; clc;

%% 1. システムとゲインの設計 (混合固有値を作る)
% 2次元の簡単な離散時間システム
A = [0.5  0.2;
     0    1.1]; % 元々少し不安定なシステム
B = [0; 1];

% ターゲットとする固有値 (混合状態)
% 絶対値 > 1 (不安定) と 絶対値 < 1 (安定) を混在させる
target_poles = [1.2, (rand()-0.5)*2]; 

% 固有値配置法でゲインKを設計
% ※ MATLABのplace関数は u = -Kx を前提とするため、
%   u = +Kx (A+BK) の形式にするために符号を反転します。
K_place = place(A, B, target_poles);
K = -K_place;

% 確認: A+BK の固有値を表示
A_cl = A + B*K;
eig_vals = eig(A_cl);
disp('Designed Eigenvalues of A+BK:');
disp(eig_vals);

%% 2. 双対LMI (不安定性の証明) の構築
n = size(A, 1);

% 変数 H の定義 (2n x 2n の対称行列)
H11 = sdpvar(n, n, 'symmetric');
H12 = sdpvar(n, n, 'full');



% ユーザー定義の行列 G の計算
% G := H11 + H22 + (A+BK)'*H12' + H12*(A+BK)
G = H11  + H12 * A_cl' + A_cl * H12';

%% 3. 制約条件の設定と解決
% 条件1: H > 0 (正定対称) -> 数値誤差を防ぐため小さな正の値を下限に設定
% 条件2: G <= 0 (半負定値)
epsilon = 1e-6;
Constraints = [H11 >= 0, ...
                trace(H11) >= 1e-6, ...
               G <= 0]; % G < 0 にして厳密に探索

% ソルバーの設定 (sedumi, sdpt3, mosek 等、入っているものを使用)
options = sdpsettings('solver', '', 'verbose', 0); 

% 最適化 (実行可能性問題)
sol = optimize(Constraints, [], options);
H12 = value(H12);
disp('H12');disp(H12);
disp('rank H12');disp(rank(H12));
%% 4. 結果の表示
disp('------------------------------------------------');
if sol.problem == 0
    disp('Result: Feasible (LMI成立)');
    disp('意味: 双対定理より「安定LMIの解Pが存在しない」ことが証明されました。');
    disp('      つまり、システムは不安定(少なくとも1つの固有値 >= 1)です。');
else
    disp('Result: Infeasible (LMI不成立)');
    disp('意味: 不安定性を証明する H を見つけられませんでした。');
end
disp('------------------------------------------------');