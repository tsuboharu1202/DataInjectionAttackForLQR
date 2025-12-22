function d = dF_dD(sd, L, E1, E2)
% 確認済み
% dF_dD: ∂ vec(F) / ∂ vec(D) using Eq.(15) with D=[Z;X;U].
% F = diag(F1,F2).

X = sd.X; U = sd.U; Z = sd.Z;
n = size(X,1); T = size(X,2); m = size(U,1);

R = (sd.R + sd.R')/2;
V = sqrtm(R); V = (V+V')/2;

p1 = m + n;
p2 = 2*n;
hatn = p1 + p2;
bar_n = 2*n + m;

% Selection matrices from paper:
EU = [zeros(m,n), zeros(m,n), eye(m)];     % m×(2n+m)
EX = [zeros(n,n), eye(n), zeros(n,m)];     % n×(2n+m)
EZ = [eye(n), zeros(n,n), zeros(n,m)];     % n×(2n+m)

% Convenience
VEU = V * EU;                              % m×(2n+m)

% ---- dF1/dD (Eq.(15)) ----
A = [zeros(m,T); L'];                      % (m+n)×T
B = [VEU; zeros(n,bar_n)];                 % (m+n)×bar_n
CbarT = implicit.commutation(bar_n, T);
% term: [0;L^T] ⊗ [VEU;0] + ([VEU;0] ⊗ [0;L^T]) C_{bar_n,T} + [0;L^T] ⊗ [0, EX]
Dblk = [zeros(m,bar_n); EX];               % (m+n)×bar_n
dF1_dD = kron(A, B) + kron(B, A) * CbarT + kron(A, Dblk);

% ---- dF2/dD (Eq.(15)) ----
A2 = [L'; zeros(n,T)];                     % (2n)×T
Bx = [EX; zeros(n,bar_n)];                 % (2n)×bar_n
Az = [zeros(n,T); L'];                     % (2n)×T
Bz = [EZ; zeros(n,bar_n)];                 % (2n)×bar_n
Dx = [zeros(n,bar_n); EX];                 % (2n)×bar_n
% term: [L^T;0]⊗[EX;0] + [0;L^T]⊗[EZ;0] + ([EZ;0]⊗[0;L^T]) C_{bar_n,T} + [0;L^T]⊗[0,EX]
dF2_dD = kron(A2, Bx) + kron(Az, Bz) + kron(Bz, Az) * CbarT + kron(Az, Dx);

% Lift to F=diag(F1,F2) using E1⊗E1 etc.
E1k = kron(E1,E1);
E2k = kron(E2,E2);
d = E1k * sparse(dF1_dD) + E2k * sparse(dF2_dD);

% Expected size: (hatn^2) × (bar_n*T)
if size(d,1) ~= hatn*hatn || size(d,2) ~= bar_n*T
    error('implicit:badSize','dF_dD size mismatch.');
end
end


