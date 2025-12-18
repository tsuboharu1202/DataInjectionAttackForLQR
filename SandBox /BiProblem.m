clear; clc; rng();  % rng for reproducibility

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

%% 1st stage: solve for H11,H12,H22,Y (LMI)

H11 = sdpvar(n,n,'symmetric');
H22 = sdpvar(n,n,'symmetric');
H12 = sdpvar(n,n,'full');
H   = [H11, H12';
       H12, H22];

Y  = sdpvar(m,n,'full');

eps_val = 1e-4;

S = H11 + H22 + A*H12' + H12*A';
G = S + B*Y + Y'*B';

Constraints = [];
Constraints = [Constraints, H >= 0];
Constraints = [Constraints, G <= -eps_val*eye(n)];
Constraints = [Constraints, trace(H) == 10];

ops = sdpsettings('solver','mosek','verbose',0);

lambda = 1;
mu     = 1;

Objective = norm(Y - K_opt*H12', 'fro')^2 ...
            + lambda*norm(Y, 'fro')^2 ...
            + mu*norm(H12, 'fro')^2;

sol = optimize(Constraints, Objective, ops);
if sol.problem ~= 0
    error('1st SDP failed. problem code = %d, info = %s', ...
           sol.problem, sol.info);
end

H11_val = value(H11);
H12_val = value(H12);
H22_val = value(H22);
Y_val   = value(Y);

K1 = Y_val*(H12_val')^(-1);

disp("K (stage1)");disp(K1);
disp("opt_K");disp(K_opt);
disp("eig A+B*K1");disp(eig(A+B*K1));
disp("norm(Y - K_opt*H12'', 2)");disp(norm(Y_val - K_opt*H12_val', 2));

%% 2nd stage: fix H, optimize only K to be close to K_opt

%% 2nd stage: fix H, optimize only K to be close to K_opt

K2 = sdpvar(m,n,'full');

G2 = H11_val + H22_val ...
     + A*H12_val' + H12_val*A' ...
     + B*K2*H12_val' + H12_val*K2'*B';

Constraints2 = [];
Constraints2 = [Constraints2, G2 <= -eps_val*eye(n)];

Objective2 = norm(K2 - K_opt, 'fro')^2;

sol2 = optimize(Constraints2, Objective2, ops);
if sol2.problem ~= 0
    error('2nd SDP failed. problem code = %d, info = %s', ...
           sol2.problem, sol2.info);
end

K2_val = value(K2);

disp("K (stage2)");disp(K2_val);
disp("K_opt");disp(K_opt);
disp("eig A+B*K2");disp(eig(A+B*K2_val));
disp("norm(K2 - K_opt, 'fro')");disp(norm(K2_val - K_opt, 'fro'));

