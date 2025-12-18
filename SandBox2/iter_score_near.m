clear;
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


% A = [ 0,    1,    0,    0;   % x1' = x2
%      -2,   -0.5,  0.5,  0;   % x2' = バネ1 + ダンパ1 + 結合
%       0,    0,    0,    1;   % x3' = x4
%       0.5,  0,   -2,   -0.5];% x4' = 結合 + バネ2 + ダンパ2
% 
% % B行列 (4x3): 入力が速度・加速度に作用する想定
% B = [ 1,    0,    0;    % 入力1は位置には直接効かない
%       1,    0.2,  0;    % 入力1が速度1に強く、入力2が弱く効く
%       0,    0,    0;
%       0,    1,    0.5]; % 入力2と入力3が速度2に効く

Q = eye(n);
R_root = eye(m);
R = (R_root+R_root')/2;

T = 7;

V = make_inputU(m,T);
[X,Z,U] = datasim.simulate_openloop_stable(A,B,V,ones(n,1));
sd = datasim.SystemData(A,B,Q,R,X,Z,U);
K_opt = sd.opt_K();

max_iter = 100;
score_before = 1e8;
same_cnt = 0;
for index = 1:max_iter
    upper = index*0.01;
    sol = f_score_near(sd,upper);
    if(sol.problem == 0)
        disp("feasible");
        disp(index );disp("times")
        dx = sol.dx;
        dz = sol.dz;
        du = sol.du;
        L_temp = sol.L;
        score_temp = sol.score;
        if(abs(score_temp - score_before)< 5*1e-1)
            same_cnt = same_cnt+1;
        else
            same_cnt = 0;
        end
      
        if(same_cnt > 1)
            break
        end
        [L_new, ~, J_new, ~] = sdp.solveSDP(X+dx, U+du, Z+dz, Q, R);
        disp("score_temp");disp(score_temp);
        disp("J_new");disp(J_new);
    
        Gamma = [X+dx; U+du];                       % (m+n)×T
        % s  = svd(Gamma,'econ');
        % tol_pinv = max(size(Gamma)) * eps(max(s));
        Pi = eye(T) - pinv(Gamma) * Gamma;   % T×T
        L_temp = pinv(Gamma) * Gamma*L_temp ;
        L_new = pinv(Gamma) * Gamma*L_new ;

        % disp("L_temp");disp(L_temp);
        % disp("L_new");disp(L_new);
        if(norm(score_temp - J_new,2) <= 5*1e-1)
            break
        end
        disp("not same");
        score_before = score_temp;
        continue
    end
    disp("infeasible");
    disp(index);
end

% max_iter = 100;
% coarse_step = 0.05;     % 粗いステップ
% fine_step = coarse_step / 100; % 細かいステップ (1/10の精度)
% 
% found_solution = false; % フラグ管理
% 
% % --- 第1段階：粗い探索 (Coarse Search) ---
% for index = 1:max_iter
%     upper = index * coarse_step;
%     sol = f_score_near(sd, upper);
% 
%     if(sol.problem == 0)
%         found_solution = true;
%         disp("Coarse search found feasible at: " + upper);
%         break % 見つかったので粗いループを抜ける
%     end
%     % disp("infeasible"); 
%     % disp(index);
% end
% 
% % --- 第2段階：細かい探索 (Fine Search) ---
% % 粗い探索で見つかった場合のみ実行
% if found_solution
%     % ひとつ前の「ダメだった値」からスタート
%     % (index=1の場合は0スタートになるのでマイナスにはならない)
%     base_upper = (index - 1) * coarse_step;
% 
%     disp("Starting fine search from: " + base_upper);
% 
%     % 1/10の刻みで最大10回（元の1ステップ分）回す
%     for k = 1:10
%         % 新しい細かいupper
%         fine_upper = base_upper + k * fine_step;
% 
%         sol_fine = f_score_near(sd, fine_upper);
% 
%         if(sol_fine.problem == 0)
%             % より小さい値で解が見つかったので、solとupperを更新
%             sol = sol_fine;
%             upper = fine_upper;
%             disp("Refined solution found at: " + upper);
%             break; % 精密な値が見つかったので終了
%         end
%     end
% end

% 最終結果の表示
disp("Final Upper Bound: " + upper);

dx = sol.dx;
dz = sol.dz;
du = sol.du;
% unstable_mat = sol.unstable_mat;
K_temp = sol.K;

[L_new, S_new, J_new, diagInfo_new] = sdp.solveSDP(X+dx, U+du, Z+dz, Q, R);
K_new = (U+du)*L_new*((X+dx)*L_new)^(-1);


visualize.plot_all_results(X, dx, U, du, Z, dz);

disp('dx');disp(dx);
disp('K_temp');disp(K_temp);
disp('K_new');disp(K_new);
disp('eig(A+B*K_temp)');disp(eig(A+B*K_temp));
disp('eig(A+B*K_new)');disp(eig(A+B*K_new));
disp('eig(A+B*K_opt)');disp(eig(A+B*K_opt));
disp('norm');disp(norm(K_new-K_temp,2));
% disp('eig(unstable_contraint)');disp(eig(unstable_mat));

