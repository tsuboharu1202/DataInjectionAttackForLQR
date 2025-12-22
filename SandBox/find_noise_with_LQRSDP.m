function sol = find_noise_with_LQRSDP(sd, upper)
% LQRのSDPと組み合わせた、noiseを見つける。
% ただし、bufferは引数としてとり、feasibleの際は解なしを返す。

%% Problem data
A = sd.A;
B = sd.B;
Q = sd.Q;
R = sd.R;
V = sqrt(R);
V = (V+V')/2;
X = sd.X;
U = sd.U;
Z = sd.Z;

disp('A');
disp(A);

n = size(A,1);
T = size(X,2);
m = size(B,2);

%% YALMIP variables
% H is 2n x 2n symmetric (block: H11, H12; H12', H22)
S = sdpvar(m,m,'symmetric');
H11 = sdpvar(n,n,'symmetric');
H22 = sdpvar(n,n,'symmetric');
L = sdpvar(T,n,'full');
dx_L = sdpvar(n,n,'symmetric');
dz_L = sdpvar(n,n,'full');
du_L = sdpvar(m,n,'full');
XL = X*L;
ZL = Z*L;
UL = U*L;

X_for_sym = (XL+dx_L + (XL+dx_L)')/2;

H = [H11, X_for_sym;
     (X_for_sym)', H22];
unstable_contraint = H11 + H22 + Z*L+A*dx_L+B*du_L + (Z*L+A*dx_L+B*du_L)';

S_mat = [S , V*(UL+du_L);
         (V*(UL+du_L))', X_for_sym];
mat_constraints = [X_for_sym-eye(n), ZL + dz_L;
                    (ZL + dz_L)' , X_for_sym];


%% Constraints
Constraints = [];
Constraints = [Constraints, H >= 0]; 
Constraints = [Constraints, unstable_contraint <= 0];
Constraints = [Constraints, S_mat >= 0];    
Constraints = [Constraints, mat_constraints >= 0]; 
Constraints = [Constraints, norm(dx_L,2) <= upper]; 
Constraints = [Constraints, norm(dz_L,2) <= upper]; 
Constraints = [Constraints, norm(du_L,2) <= upper]; 
Constraints = [Constraints, XL + dx_L == (XL + dx_L)'];

%% Solver settings
% ops = sdpsettings('solver','sedumi','verbose',1);  % solver は環境に合わせて
ops = sdpsettings('solver','sedumi','verbose',0, 'sedumi.eps', 1e-8);

Objective = trace(Q*X_for_sym) + trace(S);
sol = optimize(Constraints, Objective, ops);

L = value(L);
dx = value(dx_L)*pinv(L);
dz = value(dz_L)*pinv(L);
du = value(du_L)*pinv(L);

sol.dx = dx;
sol.du = du;
sol.dz = dz;
sol.L = L;

