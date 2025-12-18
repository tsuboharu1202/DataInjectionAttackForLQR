% U生成→データ生成→SDP→表示の最小デモ
clear; clc; close all;
rehash toolboxcache;  % キャッシュをクリア

% 1) 連続の種 or 再現性
rng(1);

% 2) システム＆重み
[n,m,T] = deal(4,3,cfg.Const.SAMPLE_COUNT);
[A,B,Q,R] = datasim.make_lti(n,m);
disp('A');disp(A);

% 3) 入力とデータ取得
V = make_inputU(m,T);
[X,Z,U] = datasim.simulate_openloop_stable(A,B,V);
sd = datasim.SystemData(A,B,Q,R,X,Z,U);
K_ori =  sd.opt_K();
% Use full eig for robustness (small n), and compute spectral radius.
ev_ori = eig(A + B*K_ori);
rho_ori = max(abs(ev_ori));
disp('rho_ori');disp(rho_ori);


[X_sdp_adv, Z_sdp_adv, U_sdp_adv] = attack.execute_attack(sd, cfg.AttackType.IMPLICIT_DGSM_EV);

% 差分を計算（グラフ表示用）
dX = X_sdp_adv - X;
dZ = Z_sdp_adv - Z;
dU = U_sdp_adv - U;

sd_sdp_ev = datasim.SystemData(A,B,sd.Q,sd.R,X_sdp_adv,Z_sdp_adv,U_sdp_adv);
[L_opt,~, ~,~] = sd_sdp_ev.solveSDPBySystem();
K_sdp_ev = sd_sdp_ev.opt_K();
lambda_sdp_ev = max(abs(eig(A+B*K_sdp_ev)));
disp('lambda_sdp_ev');disp(lambda_sdp_ev);


% 6) 簡単表示
visualize.plot_all_results(X, dX, U, dU, Z, dZ);