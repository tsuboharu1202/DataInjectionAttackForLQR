function d = dF1_dL(sd, L)
% dF1_dL: ∂ vec(F1) / ∂ vec(L) from Eq.(15) in the paper.
% F1 = [ S, V U L; (V U L)^T, X L ] (note: XL is symmetric in constraints).

X = sd.X;
U = sd.U;
R = (sd.R + sd.R')/2;
V = sqrtm(R); V = (V+V')/2;
VU = V*U;                 % m×T

n = size(X,1);
m = size(U,1);
T = size(X,2);
p = m + n;                % size of F1

% Blocks from Eq.(15)
A = [zeros(m,n); eye(n)];             % (m+n)×n
B = [VU; zeros(n,T)];                % (m+n)×T
C = [zeros(m,T); X];                 % (m+n)×T

CTn = implicit.commutation(T,n);

d = kron(A, B) + kron(B, A) * CTn + kron(A, C);
d = sparse(d);
% Size should be (p^2)×(Tn)
if size(d,1) ~= p*p || size(d,2) ~= T*n
    error('implicit:badSize','dF1_dL size mismatch.');
end
end





