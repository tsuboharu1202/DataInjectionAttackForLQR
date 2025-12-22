function d2 = d2F_dDL(sd, L, E1, E2)
% d2F_dDL: ∂^2 vec(F) / ∂ vec(D) ∂ vec(L) from Eq.(15) in the paper.
% Returns matrix mapping vec(dL) -> vec( d(∂F/∂D) ) or equivalently mapping vec(dD)→vec(d(∂F/∂L)).
% We use the explicit expressions provided for F1 and F2 and lift to F=diag(F1,F2).
% 確認済み
X = sd.X; U = sd.U; Z = sd.Z; %#ok<NASGU>
n = size(X,1); T = size(X,2); m = size(U,1);
bar_n = 2*n + m;

R = (sd.R + sd.R')/2;
V = sqrtm(R); V = (V+V')/2;

EU = [zeros(m,n), zeros(m,n), eye(m)];     % m×(2n+m)
EX = [zeros(n,n), eye(n), zeros(n,m)];     % n×(2n+m)
EZ = [eye(n), zeros(n,n), zeros(n,m)];     % n×(2n+m)
VEU = V * EU;

% Sizes
p1 = m+n; p2 = 2*n;

% Commutation & helper definitions from screenshot
C_T_mn = implicit.commutation(T, m+n);
C_T_2n = implicit.commutation(T, 2*n);
% NOTE: In Eq.(15), the commutation in the last term is C_{n,T} (NOT C_{\bar n,T}).
% Using C_{\bar n,T} breaks dimensions.
CnT = implicit.commutation(n, T);

% C1 := I_n ⊗ C_{T,m+n} ⊗ I_{m+n}
C1 = kron(speye(n), kron(C_T_mn, speye(m+n)));
% C2 := I_n ⊗ C_{T,2n} ⊗ I_{2n}
C2 = kron(speye(n), kron(C_T_2n, speye(2*n)));
% C~1 := I_T ⊗ C_{n,m+n} ⊗ I_{m+n}
Cn_mn = implicit.commutation(n, m+n);
Cn_2n = implicit.commutation(n, 2*n);
Ct1 = kron(speye(T), kron(Cn_mn, speye(m+n)));
Ct2 = kron(speye(T), kron(Cn_2n, speye(2*n)));

% --- d2F1/(dD dL) expression (compressed from screenshot) ---
A = [zeros(m,n); eye(n)];                      % (m+n)×n
B = [VEU; zeros(n,bar_n)];                     % (m+n)×bar_n
Dblk = [zeros(m,bar_n); EX];                   % (m+n)×bar_n
% Use the provided form:
% d2F1 = C1( vec(A) ⊗ I_{(m+n)T} ) (I_T ⊗ B) + C1( vec(A) ⊗ I_{(m+n)T} ) (I_T ⊗ Dblk)
%      + (C_{bar_n,T}^T ⊗ I_{(m+n)^2}) Ct1 ( I_{(m+n)T} ⊗ vec(A) ) (I_T ⊗ B)
vecA = A(:);
I_mnT = speye((m+n)*T);
termA = kron(vecA, I_mnT);
d2F1 = C1 * termA * kron(speye(T), B) + C1 * termA * kron(speye(T), Dblk) ...
    + kron(CnT', speye((m+n)^2)) * Ct1 * kron(I_mnT, vecA) * kron(speye(T), B);

% --- d2F2/(dD dL) expression (compressed from screenshot) ---
A2 = [eye(n); zeros(n,n)];                     % (2n)×n
Bx = [EX; zeros(n,bar_n)];                     % (2n)×bar_n
Az = [zeros(n,n); eye(n)];                     % (2n)×n
Bz = [EZ; zeros(n,bar_n)];                     % (2n)×bar_n
Dx = [zeros(n,bar_n); EX];                     % (2n)×bar_n
vecA2 = A2(:);
vecAz = Az(:);
I_2nT = speye((2*n)*T);
termA2 = kron(vecA2, speye((2*n)*T));
termAz = kron(vecAz, speye((2*n)*T));

% From screenshot, d2F2 is sum of three C2-terms + one Ct2-term; we keep the structure:
d2F2 = C2 * termA2 * kron(speye(T), Bx) ...
    + C2 * termAz * kron(speye(T), Bz) ...
    + C2 * termAz * kron(speye(T), Dx) ...
    + kron(CnT', speye((2*n)^2)) * Ct2 * kron(I_2nT, vecAz) * kron(speye(T), Bz);

% Lift to F=diag(F1,F2)
% Here, d2F1 and d2F2 are built in the "stacked over vec(L)" convention:
%   size(d2F1) = ( (m+n)^2 * (nT) ) × (bar_n*T)
%   size(d2F2) = ( (2n)^2   * (nT) ) × (bar_n*T)
% Therefore, the block-selection lift must be applied per each of the nT stacks:
%   kron(I_{nT}, E1⊗E1) and kron(I_{nT}, E2⊗E2).
E1k = kron(E1,E1);
E2k = kron(E2,E2);
E1big = kron(speye(n*T), E1k);
E2big = kron(speye(n*T), E2k);
d2 = E1big * sparse(d2F1) + E2big * sparse(d2F2);
end


