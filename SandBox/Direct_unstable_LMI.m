
clear; clc;  % rng for reproducibility

%% Problem data
n = 4;    % state dimension
m = 3;    % input dimension

A = rand(n,n);
disp("A");disp(A);
B = rand(n,m);
disp("B");disp(B);

Q = eye(n);
R = eye(m);

V = make_inputU(m,10);
[X,Z,U] = datasim.simulate_openloop_stable(A,B,V,zeros(n,1));
sd = datasim.SystemData(A,B,Q,R,X,Z,U);
K_opt = sd.opt_K();

%% YALMIP variables
% H is 2n x 2n symmetric (block: H11, H12; H12', H22)
H11 = sdpvar(n,n,'symmetric');
H22 = sdpvar(n,n,'symmetric');
H12 = sdpvar(n,n,'full');
V_temp = sdpvar(n,n,'full');


V1 = [eye(n), V_temp;
      V_temp' , eye(n)];
V2 = [eye(n), V_temp';
      V_temp , eye(n)];
% H12 = eye(n);
% overall H
H = [H11, H12;
     H12', H22];

% Z1 = randam_matrix * W  (enforces Z1 in Range(randam_matrix))
Y  = sdpvar(m,n,'full');         % m x n

eps_val = 1e-4;

S = H11 + H22 + A*H12 + H12'*A'; % "H, A" part
G = S + B*Y + Y'*B';                % full G

upper = 10;
norm_mat = [upper*eye(n), H12';
            H12     ,   eye(n)];


%% Constraints
Constraints = [];
Constraints = [Constraints, H >= 0];                     % H ⪰ 0
Constraints = [Constraints, G <= 0];       % G ⪯ -eps*I
Constraints = [Constraints, norm_mat >= 0];             % normalization
Constraints = [Constraints, trace(H) == 1];             % normalization
Constraints = [Constraints, V1 >= 0, V2 >= 0];             % normalization

%% Solver settings
ops = sdpsettings('solver','sedumi','verbose',0);  % solver は環境に合わせて

%%--------------------------------------------------------------
% 1. まず1つ適当な可行解を求める（初期のサンプル）
%--------------------------------------------------------------
% 適当な目的関数（例えば ||W||_F^2 を最小化）
lambda = 1;   % とか、様子見で小さい値から
mu     = 1;

Objective = norm(Y - K_opt*H12, 'fro')^2;
sol = optimize(Constraints, Objective, ops);

if sol.problem ~= 0
    error('Initial SDP solve failed. problem code = %d, info = %s', ...
           sol.problem, sol.info);
end


K = value(Y)*pinv(value(H12));
dK = K - K_opt;
[UdK,SdK,VdK] = svd(dK); 
disp("svd dK");disp(dK);
disp("svd SdK");disp(SdK);
disp("K");disp(K);
disp("eig H12");disp(eig(value(H12)'));
disp("eig Y");disp(svd(value(Y)'));
% disp("opt_K");disp(K_opt);
disp("value(H12)");disp(value(H12));
% disp("rank K");disp(rank(K));
% [UK,SK,VK] = svd(K); 
% disp("svd K");disp(SK);
disp("eig Ac");disp(eig(A+B*K));
V_val = value(V_temp);
disp("V'V");disp(V_val'*V_val);
disp("VV'");disp(V_val*V_val');
    
disp("norm(Y - K_opt*H12', 2)");disp(norm(value(Y) - K_opt*value(H12)', 2));
