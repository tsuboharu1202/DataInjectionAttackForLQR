clear; clc;  % rng for reproducibility

%% Problem data
n = 4;    % state dimension
m = 3;    % input dimension

A = rand(n,n);
A = (A- ones(n,n)*0.5)*2;

disp("A");disp(A);
disp('eig A');disp(eig(A));
B = rand(n,m);
B = (B - ones(n,m)*0.5)*2;
disp("B");disp(B);

Q = eye(n);
R_root = eye(m);
R = (R_root+R_root')/2;

T = 10;

V = make_inputU(m,T);
[X,Z,U] = datasim.simulate_openloop_stable(A,B,V,zeros(n,1));
sd = datasim.SystemData(A,B,Q,R,X,Z,U);
V = R;
K_opt = sd.opt_K();
[L_opt, S_opt, J_opt, diagInfo] = sd.solveSDPBySystem();
disp("score_opt");disp(J_opt);

%% YALMIP variables
% H is 2n x 2n symmetric (block: H11, H12; H12', H22)
S = sdpvar(m,m,'symmetric');
H11 = sdpvar(n,n,'symmetric');
H22 = sdpvar(n,n,'symmetric');
L = sdpvar(T,n,'full');
dx_L = sdpvar(n,n,'symmetric');
dz_L = sdpvar(n,n,'full');
du_L = sdpvar(m,n,'full');

delta = sdpvar(1,1,'full');
theta = sdpvar(1,1,'full');

XL = X*L;
ZL = Z*L;
UL = U*L;


X_for_sym = (XL+dx_L + (XL+dx_L)')/2;

J_closed = trace(Q*X*L + Q*dx_L) + trace(S) - delta;
S_mat = [S, V*U*L+V*du_L;
         (V*U*L+V*du_L)', X_for_sym];
mat_constraints = [X_for_sym-eye(n), ZL + dz_L;
                    (ZL + dz_L)' , X_for_sym];


unstable_contraint = H11 + H22 + ZL+A*dx_L+B*du_L + (ZL+A*dx_L+B*du_L)';
H = [H11, X_for_sym;
     (X_for_sym)', H22];

upper = theta;

%% Constraints
Constraints = [];
Constraints = [Constraints, H >= 1e-6]; 
Constraints = [Constraints, (XL + dx_L == (XL + dx_L)')];
Constraints = [Constraints, J_closed <= 0];
Constraints = [Constraints, delta <= J_opt*10];
Constraints = [Constraints, unstable_contraint <= 0];
Constraints = [Constraints, S_mat >= 0];
Constraints = [Constraints, mat_constraints >= 0]; 
Constraints = [Constraints, upper <= 100]; 
Constraints = [Constraints, norm(dx_L,2) <= upper]; 
Constraints = [Constraints, norm(dz_L,2) <= upper]; 
Constraints = [Constraints, norm(du_L,2) <= upper]; 

%% Solver settings
% ops = sdpsettings('solver','sedumi','verbose',1);  % solver は環境に合わせて
% ops = sdpsettings('solver','mosek','verbose',1, 'sedumi.eps', 1e-8);
ops = sdpsettings('solver','mosek','verbose',1);
ops.mosek.MSK_DPAR_INTPNT_CO_TOL_PFEAS = 1e-4; % 制約の許容誤差(Primal)
ops.mosek.MSK_DPAR_INTPNT_CO_TOL_DFEAS = 1e-4; % 双対許容誤差
ops.mosek.MSK_DPAR_INTPNT_CO_TOL_REL_GAP = 1e-4; % ギャップ許容誤差

Objective = theta + 100*delta;
sol = optimize(Constraints, Objective, ops);

if sol.problem ~= 0
    error('Initial SDP solve failed. problem code = %d, info = %s', ...
           sol.problem, sol.info);
end

L_temp = value(L);
dx = value(dx_L)*pinv(L_temp);
dz = value(dz_L)*pinv(L_temp);
du = value(du_L)*pinv(L_temp);

disp("S_opt");disp(S_opt);
S_val = value(S);
disp("S_val");disp(S_val);
disp('dx');disp(dz);
delta = value(delta);
disp("delta");disp(delta);
theta = value(theta);
disp("theta");disp(theta);

K_temp = (U+du)*L_temp*((X+dx)*L_temp)^(-1);


% dx = value(dx_L)*pinv(L_temp);
% dz = value(dz_L)*pinv(L_temp)*0.6;
% du = value(du_L)*pinv(L_temp)*0.6;

[L_new, S_new, J_new, diagInfo_new] = sdp.solveSDP(X+dx, U+du, Z+dz, Q, R);
K_new = (U+du)*L_new*((X+dx)*L_new)^(-1);

visualize.plot_data(X,X+dx);


disp('L_temp');disp(L_temp);
disp('L_new');disp(L_new);
disp('K_temp');disp(K_temp);
disp('K_new');disp(K_new);
disp('eig(A+B*K_temp)');disp(eig(A+B*K_temp));
disp('eig(A+B*K_new)');disp(eig(A+B*K_new));
disp('eig(A+B*K_opt)');disp(eig(A+B*K_opt));
disp('norm');disp(norm(K_new-K_temp,2));
