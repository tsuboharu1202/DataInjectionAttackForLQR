clear; clc; rng();

%% Problem data
n = 4; m = 3;

A = rand(n,n);
disp("eig(A)");disp(eig(A));
B = rand(n,m);

Q = eye(n);
R = eye(m);

V = make_inputU(m,10);
[X,Z,U] = datasim.simulate_openloop_stable(A,B,V,zeros(n,1));
sd = datasim.SystemData(A,B,Q,R,X,Z,U);
K_opt = sd.opt_K();

eps_val = 1e-4;
ops = sdpsettings('solver','mosek','verbose',0);

%% Initial K (start from LQR solution)
K = zeros(m,n);
disp("eig(A+B*K)");disp(eig(A+B*K));

maxIter = 20;

for it = 1:maxIter
    %-------------------------
    % Step 1: fix K, solve H
    %-------------------------
    H11 = sdpvar(n,n,'symmetric');
    H22 = sdpvar(n,n,'symmetric');
    H12 = sdpvar(n,n,'full');
    H   = [H11, H12';
           H12, H22];

    G_H = H11 + H22 ...
          + (A+B*K)'*H12' ...
          + H12*(A+B*K);

    ConsH = [];
    ConsH = [ConsH, H >= 0];
    ConsH = [ConsH, G_H <= 0];

    solH = optimize(ConsH, 0, ops);
    if solH.problem ~= 0
        warning('Step H infeasible at iter %d: %s', it, solH.info);
        break;
    end

    H11_val = value(H11);
    H12_val = value(H12);
    H22_val = value(H22);
    H_val = value(H);
    disp("eig");disp(eig(H_val));
    disp("H_val");disp(H_val);

    %-------------------------
    % Step 2: fix H, solve K
    %-------------------------
    Kvar = sdpvar(m,n,'full');


    G_K = H11_val + H22_val ...
          + (A + B*Kvar)'*H12_val' ...
          + H12_val*(A + B*Kvar);

    % G_K = H11 + H22 ...
    %       + (A + B*Kvar)'*H12_val' ...
    %       + H12_val*(A + B*Kvar);
    % H_temp = [H11, H12_val;
    %           H12_val' , H22];
    ConsK = [];
    ConsK = [ConsK, G_K <= 0];
    % ConsK = [ConsK, G_K <= 0, H_temp >= 0];

    ObjK = norm(Kvar - K_opt, 'fro')^2;

    solK = optimize(ConsK, ObjK, ops);
    if solK.problem ~= 0
        warning('Step K infeasible at iter %d: %s', it, solK.info);
        break;
    end

    K = value(Kvar);
end

disp("H");disp(value(H));

disp('K (after alternating BMI)'); disp(K);
disp('opt_K'); disp(K_opt);
disp('eig(A+B*K)'); disp(eig(A+B*K));
disp('norm(K - K_opt, ''fro'')'); disp(norm(K - K_opt, 'fro'));
disp('norm(K_opt, ''fro'')'); disp(norm(K_opt, 'fro'));
