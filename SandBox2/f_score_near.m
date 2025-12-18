function sol = f_score_near(sd,upper)

    V = sd.R;
    Q = sd.Q;
    A = sd.A;
    B = sd.B;
    X = sd.X;
    U = sd.U;
    Z = sd.Z;
    n = size(A,1);
    m = size(B,2);
    T = size(X,2);
    
    %% YALMIP variables
    % H is 2n x 2n symmetric (block: H11, H12; H12', H22)
    S = sdpvar(m,m,'symmetric');
    H11 = sdpvar(n,n,'symmetric');
    H22 = sdpvar(n,n,'symmetric');
    % dM = sdpvar(T,n,'full');
    L = sdpvar(T,n,'full');
    dx_L = sdpvar(n,n,'full');
    dz_L = sdpvar(n,n,'full');
    du_L = sdpvar(m,n,'full');
    
    delta = sdpvar(1,1,'full');
    
    XL = X*L;
    ZL = Z*L;
    UL = U*L;
    
    XL_for_sym = (XL+dx_L + (XL+dx_L)')/2;
    
    J_closed = trace(Q*X*L + Q*dx_L) + trace(S) - delta;
    S_mat = [S, V*U*L+V*du_L;
             (V*U*L+V*du_L)', XL_for_sym];
    mat_constraints = [XL_for_sym-eye(n), ZL + dz_L;
                        (ZL + dz_L)' , XL_for_sym];

    ZL_tilde = ZL + A*dx_L + B*du_L;
    
    unstable_contraint = H11 + H22 + (ZL+Z*dM+A*dx_L+B*du_L) + (ZL+Z*dM+A*dx_L+B*du_L)';
    
    
    H = [H11, XL+dx_L+X*dM;
         (XL+dx_L+X*dM)', H22];
    
    
    %% Constraints
    Constraints = [];
    Constraints = [Constraints, H >= 0]; 
    Constraints = [Constraints, unstable_contraint <= 0];
    Constraints = [Constraints, trace(H) >= 1e-2]; 
    Constraints = [Constraints, (XL + dx_L == (XL + dx_L)')];
    Constraints = [Constraints, J_closed <= 0];
    Constraints = [Constraints, XL_for_sym >= 0];
    Constraints = [Constraints, S_mat >= 0];
    Constraints = [Constraints, mat_constraints >= 0];  
    Constraints = [Constraints, norm(dx_L,2) <= upper]; 
    Constraints = [Constraints, norm(dz_L,2) <= upper]; 
    Constraints = [Constraints, norm(du_L,2) <= upper]; 
    
    %% Solver settings
    ops = sdpsettings('solver','mosek','verbose',0);
    ops.mosek.MSK_DPAR_INTPNT_CO_TOL_PFEAS = 1e-4; % 制約の許容誤差(Primal)
    ops.mosek.MSK_DPAR_INTPNT_CO_TOL_DFEAS = 1e-4; % 双対許容誤差
    ops.mosek.MSK_DPAR_INTPNT_CO_TOL_REL_GAP = 1e-4; % ギャップ許容誤差
    
    Objective = delta;
    sol = optimize(Constraints, Objective, ops);
    % diagnostics = optimize(Constraints, Objective);
    % if diagnostics.problem ~= 0
    %     disp(diagnostics.info); % なぜ失敗したか（Infeasibleなど）を表示
    %     check(Constraints);     % どの制約が満たされていないか数値で表示
    % end
    
    
    L_temp = value(L);
    dx = value(dx_L)*pinv(L_temp);
    dz = value(dz_L)*pinv(L_temp);
    du = value(du_L)*pinv(L_temp);
    
    K_temp = (U+du)*L_temp*((X+dx)*L_temp)^(-1);
    sol.dx = dx;
    sol.dz = dz;
    sol.du = du;
    sol.score = value(delta);
    sol.L = value(L);
    sol.K = K_temp;
    
end
