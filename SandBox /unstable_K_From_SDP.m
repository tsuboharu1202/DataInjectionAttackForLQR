
% データドリブンなLQRのSDPにそのまま接続させる形で、
% 不安定なゲインLを設計させる手法を考える。


clear; clc;  % rng for reproducibility

%% Problem data
n = 6;    % state dimension
m = 4;    % input dimension

A = rand(n,n);
A = (A- ones(n,n)*0.5)*2;
A = eye(n)*0.8 + rand(n,n)*0.1;
disp("A");disp(A);
disp('eig A');disp(eig(A));
B = rand(n,m);
B = (B- ones(n,m)*0.5)*2;
disp("B");disp(B);

Q = eye(n);
R_root = eye(m);
R = (R_root+R_root')/2;

T = 10;

V = make_inputU(m,T);
[X,Z,U] = datasim.simulate_openloop_stable(A,B,V,zeros(n,1));
sd = datasim.SystemData(A,B,Q,R,X,Z,U);
K_opt = sd.opt_K();

%% YALMIP variables
% H is 2n x 2n symmetric (block: H11, H12; H12', H22)
S = sdpvar(m,m,'symmetric');
H11 = sdpvar(n,n,'symmetric');
H22 = sdpvar(n,n,'symmetric');
L = sdpvar(T,n,'full');
dx_L = sdpvar(n,n,'symmetric');
dz_L = sdpvar(n,n,'full');
du_L = sdpvar(m,n,'full');
XL = X*L;
ZL = Z*L;
UL = U*L;

X_for_sym = (XL+dx_L + (XL+dx_L)')/2;

H = [H11, X_for_sym;
     (X_for_sym)', H22];


unstable_contraint = H11 + H22 + Z*L+A*dx_L+B*du_L + (Z*L+A*dx_L+B*du_L)';
S_mat = [S , R_root*(UL+du_L);
         (R_root*(UL+du_L))', X_for_sym];
mat_constraints = [X_for_sym-eye(n), ZL + dz_L;
                    (ZL + dz_L)' , X_for_sym];

upper = 1e-1;

%% Constraints
Constraints = [];
Constraints = [Constraints, H >= 0]; 
Constraints = [Constraints, unstable_contraint <= 0];
Constraints = [Constraints, S_mat >= 0];    
Constraints = [Constraints, mat_constraints >= 0]; 
Constraints = [Constraints, norm(dx_L,2) <= upper]; 
Constraints = [Constraints, norm(dz_L,2) <= upper]; 
Constraints = [Constraints, norm(du_L,2) <= upper]; 
Constraints = [Constraints, XL + dx_L == (XL + dx_L)'];

%% Solver settings
% ops = sdpsettings('solver','sedumi','verbose',1);  % solver は環境に合わせて
ops = sdpsettings('solver','sedumi','verbose',1, 'sedumi.eps', 1e-8);

Objective = trace(Q*X_for_sym) + trace(S);
sol = optimize(Constraints, Objective, ops);

if sol.problem ~= 0
    error('Initial SDP solve failed. problem code = %d, info = %s', ...
           sol.problem, sol.info);
end

L_temp = value(L);
dx = value(dx_L)*pinv(L_temp);
dz = value(dz_L)*pinv(L_temp);
du = value(du_L)*pinv(L_temp);
disp('dx');disp(dz);

K_temp = (U+du)*L_temp*((X+dx)*L_temp)^(-1);

[L_new, S_new, J_new, diagInfo_new] = sdp.solveSDP(X+dx, U+du, Z+dz, Q, R);
K_new = (U+du)*L_new*((X+dx)*L_new)^(-1);

visualize.plot_data(X,X+dx);


disp('L_temp');disp(L_temp);
disp('K_temp');disp(K_temp);
disp('L_new');disp(L_new);
disp('K_new');disp(K_new);
disp('eig');disp(eig(A+B*K_temp));
disp('eig');disp(eig(A+B*K_new));
disp('eig');disp(eig(A+B*K_opt));
disp('norm');disp(norm(K_new-K_opt,2));
