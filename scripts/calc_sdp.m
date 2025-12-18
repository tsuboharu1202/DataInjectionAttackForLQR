% U生成→データ生成→SDP→表示の最小デモ
clear; clc; close all;

% 2) システム＆重み
[n,m,T] = deal(7,5,cfg.Const.SAMPLE_COUNT);
[A,B,Q,R] = datasim.make_lti(n,m);

% 3) 入力とデータ取得
V = make_inputU(m,T);
[X,Z,U] = datasim.simulate_openloop_stable(A,B,V);

sd = datasim.SystemData(A,B,Q,R,X,Z,U);
[L_opt, S_opt, J_opt, diagInfo] = solveSDPBySystem(sd);
[~,~,VL] = svd(L_opt);

% 5) 後処理（K = U*L*(X*L)^{-1} など）
[K,P] = sdp.postprocess_K(U,L_opt,X);
disp("ZL");disp(Z*L_opt);
disp("A+B*K");disp(A+B*K);
disp("(A+B*K)*P");disp((A+B*K)*P);
disp("L");disp(L_opt);