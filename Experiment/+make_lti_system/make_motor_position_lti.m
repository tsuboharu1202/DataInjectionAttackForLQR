function [A, B, Q, R] = make_motor_position_lti(n, m, Ts)
% make_motor_position_lti - モータ位置制御システムを生成
%
% 入力:
%   n: 状態次元（2または3を推奨）
%   m: 入力次元（通常1）
%   Ts: サンプリング時間（秒、デフォルト: 0.1）
%
% 出力:
%   A: 離散時間システム行列
%   B: 入力行列
%   Q: 状態重み行列（位置に重み）
%   R: 入力重み行列

if nargin < 3 || isempty(Ts)
    Ts = 0.1;  % デフォルトサンプリング時間
end

% 連続時間モデル: モータの位置制御
% 状態: [位置; 速度]
% 入力: 電圧（またはトルク）

% モータパラメータ（標準的な値）
J = 0.01;      % 慣性モーメント [kg·m²]
b = 0.1;       % 粘性摩擦係数 [N·m·s/rad]
K = 0.01;      % モータ定数 [N·m/A] または [V·s/rad]
R = 1.0;       % 電気抵抗 [Ω]
L = 0.5;       % インダクタンス [H]

if n == 2
    % 2次システム: [位置; 速度]
    % 連続時間モデル: ẋ = Ac*x + Bc*u
    % 位置: θ, 速度: ω
    Ac = [0, 1;
          0, -b/J];  % 簡略化モデル（電流ダイナミクスを無視）
    Bc = [0; K/(J*R)];
    
    Q = diag([10, 1]);  % 位置に重み
    R_weight = 1;
    
elseif n == 3
    % 3次システム: [位置; 速度; 電流]
    % より詳細なモデル
    Ac = [0, 1, 0;
          0, -b/J, K/J;
          0, -K/L, -R/L];
    Bc = [0; 0; 1/L];
    
    Q = diag([10, 1, 0.1]);  % 位置に重み
    R_weight = 1;
    
else
    error('モータ位置制御システムはn=2または3のみ対応しています');
end

% 離散化（ゼロ次ホールド）
sys_c = ss(Ac, Bc, eye(n), zeros(n, m));
sys_d = c2d(sys_c, Ts, 'zoh');
A = sys_d.A;
B = sys_d.B;

% 数値的安定性の確認
rho_A = max(abs(eig(A)));
if rho_A >= 1.0
    warning('離散化後のシステムが不安定です（rho=%.4f）。Tsを小さくしてください。', rho_A);
end

% 重み行列
Q = Q;
R = R_weight * eye(m);

end






