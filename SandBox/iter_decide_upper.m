% U生成→データ生成→SDP→表示の最小デモ
clear; clc; close all;

% 1) 連続の種 or 再現性
% rng(1);

% 2) システム＆重み
[n,m,T] = deal(4,3,7);
[A,B,Q,R] = datasim.make_lti(n,m);

% 3) 入力とデータ取得
V = make_inputU(m,T);
[X,Z,U] = datasim.simulate_openloop_stable(A,B,V);
sd = datasim.SystemData(A,B,Q,R,X,Z,U);
K_opt = sd.opt_K();


for iter = 1:1e6
    upper = iter; 
    sol = find_noise_with_LQRSDP(sd, upper);
    if(sol.problem ~= 0)
        disp('upper = ');disp(upper);
        disp('not feasible');
        continue
    end
    dx = sol.dx;
    du = sol.du;
    dz = sol.dz;
    L = sol.L;
    disp('upper = ');disp(upper);
    disp('feasible');
    K_temp = (U+du)*L*((X+dx)*L)^(-1);
    break
end

U_adv = U + du;
X_adv = X + dx;
Z_adv = Z + dz;

visualize.plot_data(X,X_adv)

[L_new, S_new, J_new, diagInfo_new] = sdp.solveSDP(X_adv, U_adv, Z_adv, Q, R);
disp("L_new");disp(L_new);
[K_new,P_new] = sdp.postprocess_K(U_adv,L_new,X_adv);



disp('norm');disp(norm(K_temp-K_new,2));
disp('eig A+BK');disp(eig(A+B*K_new));
disp('eig A+BK');disp(eig(A+B*K_temp));
disp('eig A+BK');disp(eig(A+B*K_opt));

