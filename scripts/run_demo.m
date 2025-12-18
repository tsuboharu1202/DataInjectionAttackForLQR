% % U生成→データ生成→SDP→表示の最小デモ
% clear; clc; close all;

% % 1) 連続の種 or 再現性
% % rng(1);

% % 2) システム＆重み
% [n,m,T] = deal(4,3,cfg.Const.SAMPLE_COUNT);
% [A,B,Q,R] = datasim.make_lti(n,m);
% Q_sqrt = chol(Q, 'lower');
% Q_sqrt =Q_sqrt';
% R_sqrt = chol(R, 'lower');
% R_sqrt = R_sqrt';

% % 3) 入力とデータ取得
% V = make_inputU(m,T);
% [X,Z,U] = datasim.simulate_openloop_stable(A,B,V);

% % 4) SDPを解く（論文式(5)）
% gamma = 1e-2;

% sd = datasim.SystemData(A,B,Q,R,X,Z,U);
% [L_opt, S_opt, J_opt, diagInfo] = solveSDPBySystem(sd);

% % 5) 後処理（K = U*L*(X*L)^{-1} など）
% [K,P] = sdp.postprocess_K(U,L_opt,X);
% disp('P_ori');disp(P);

% % --------------------
% % temp = cross_matX - eye(n);
% % disp("eig(temp)");disp(eig(temp));
% % [U_temp, S_temp, V_temp] = svd(temp);
% % disp("U_temp'*V_temp");disp(U_temp'*V_temp);
% % for index = 1:10
% %     cross_mat = randn(m,m);
% %     [cross_mat,~] = qr(cross_mat);
% %     temp = cross_mat- eye(m);
% %     [U_temp, S_temp, V_temp] = svd(temp);
% %     disp("eig(temp");disp(eig(temp)+ones(m,1));
% %
% %     disp("S_temp");disp(S_temp);
% %     disp("U_temp'*V_temp");disp(U_temp'*V_temp);
% % end
% % --------------------
% cross_matX = rand(n,n);
% [cross_matX,~] = qr(cross_matX);
% cross_matU = rand(m,m);
% [cross_matU,~] = qr(cross_matU);
% cross_matX_right = rand(T,T);
% [cross_matX_right,~] = qr(cross_matX_right);


% T_U = U;
% T_Z = cross_matX*Z;
% T_X = cross_matX*X;


% disp("L_opt");disp(cross_matX_right'*L_opt*cross_matX');
% [L_new, S_new, J_new, diagInfo_new] = sdp.solveSDP(T_X, T_U, T_Z, Q, R);
% disp("L_new");disp(L_new);
% [K_new,P_new] = sdp.postprocess_K(T_U,L_new,T_X);


% visualize.plot_data(X,T_X)
% % disp("cross_matU");disp(cross_matU);
% temp = cross_matX - eye(n);
% disp("temp");disp(svd(temp));
% disp("cross_matX");disp(cross_matX);
% disp("cross_matX*cross_matX'");disp(cross_matX*cross_matX');
% disp('P_new');disp(P_new);



% Gamma = [T_U;T_X];
% Gamma_inverse = Gamma'*(Gamma*Gamma')^(-1);
% K_I = [K_new;eye(n)];
% disp('ZG');disp(T_Z*Gamma_inverse*K_I);
% disp('ZG eig');disp(eig(T_Z*Gamma_inverse*K_I));
% % disp('AT+BT*KT eig');disp(eig(A_T+B_T*K_new));

% % disp('K_new');disp(K_new);
% % disp('L_inv ='); disp(L_new*cross_matX');
% disp('K ='); disp(K);
% [UK,SK,VK] = svd(K);
% disp("UK");disp(UK);
% disp("SK");disp(SK);
% disp("VK");disp(VK);
% % disp('cross_matU^-1 *K_new*cross_mat.T');disp(((cross_matU)^(-1))*K_new*cross_matX);
% disp('eig');disp(eig(A+B*K_new));
% disp('svd L');disp(svd(L_opt));