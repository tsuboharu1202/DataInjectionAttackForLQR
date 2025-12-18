
clear; clc; rng();  % rng for reproducibility

%% Problem data
n = 5;    % state dimension
m = 3;    % input dimension

A = (rand(n,n)-ones(n,n))*2;
disp("A");disp(A);
B = (rand(n,m)-ones(n,m))*2;
disp("B");disp(B);

Q = eye(n);
R = eye(m);

V = make_inputU(m,10);
[X,Z,U] = datasim.simulate_openloop_stable(A,B,V,zeros(n,1));
sd = datasim.SystemData(A,B,Q,R,X,Z,U);
K_opt = sd.opt_K();
disp("K_opt");disp(K_opt);
Ac_opt = A+B*K_opt;

%% YALMIP variables
% H is 2n x 2n symmetric (block: H11, H12; H12', H22)
H11 = sdpvar(n,n,'symmetric');
H22 = sdpvar(n,n,'symmetric');
H12 = sdpvar(n,n,'full');
Delta_squared = sdpvar(m,m,'symmetric');
Gamma = sdpvar(1,1,'symmetric');
% overall H
H = [H11, H12;
     H12', H22];

% Z1 = randam_matrix * W  (enforces Z1 in Range(randam_matrix))
Y  = sdpvar(m,n,'full');         % m x n

eps_val = 1e-4;

S = H11 + H22 + Ac_opt*H12 + H12'*Ac_opt' - Gamma*eye(n) ; % "H, A" part
G = [-S - B*Delta_squared*B', H12';
    H12, eye(n)];                % full G

tolerance = 1e-3;

%% Constraints
Constraints = [];
Constraints = [Constraints, Delta_squared >= 0]; 
Constraints = [Constraints, H >= 0];                     % H ⪰ 0
Constraints = [Constraints, G >= 0];
% Constraints = [Constraints, trace(H) == 1];


%% Solver settings
ops = sdpsettings('solver','mosek','verbose',0);  % solver は環境に合わせて


Objective = Gamma;
sol = optimize(Constraints, Objective, ops);

if sol.problem ~= 0
    error('Initial SDP solve failed. problem code = %d, info = %s', ...
           sol.problem, sol.info);
end

