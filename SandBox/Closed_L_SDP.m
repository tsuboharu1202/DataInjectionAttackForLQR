function [Q_val, Tu_val] = Closed_L_SDP(L_star,sd)
    A = sd.A;
    X = sd.X;
    Z = sd.Z;

    %% Problem data
    n = size(A,1);    % state dimension
    T = size(X,2);    % input dimension
    
    %% YALMIP variables
    % H is 2n x 2n symmetric (block: H11, H12; H12', H22)
    S11 = sdpvar(n,n,'symmetric');
    S22 = sdpvar(n,n,'symmetric');
    Q = sdpvar(T,n,'full');
    Tu = sdpvar(n,n,'full');

    % overall H
    S_mat = [S11, (X*Q);
         (X*Q)', S22];
    
    Inequality = S11 + S22 + (Z*Q)' + (Z*Q);
    Tu_mat1 = [eye(n), Tu;
                Tu', eye(n)];
    Tu_mat2 = [eye(n), Tu';
                Tu, eye(n)];

    
    tolerance = 1e-3;
    %% Constraints
    Constraints = [];
    Constraints = [Constraints, S_mat >= tolerance];
    Constraints = [Constraints, Tu_mat1 >= tolerance, Tu_mat2 >= tolerance];
    Constraints = [Constraints, (X*Q+(X*Q)') >= tolerance];
    Constraints = [Constraints, norm(Tu - eye(n),2) <= 0.1];
    Constraints = [Constraints, Inequality <= tolerance];
    
    
    %% Solver settings
    ops = sdpsettings('solver','mosek','verbose',0);  % solver は環境に合わせて
    
    Objective = norm(Q - L_star*Tu,2);
    sol = optimize(Constraints, Objective, ops);
    
    if sol.problem ~= 0
        error('Initial SDP solve failed. problem code = %d, info = %s', ...
               sol.problem, sol.info);
    end


    Tu_val = value(Tu);
    Q_val = value(Q);
    disp("norm(Q - L_star*Tu,2)");disp(norm(Q_val - L_star*Tu_val,2));

