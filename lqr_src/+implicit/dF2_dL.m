function d = dF2_dL(sd, L)
% dF2_dL: ∂ vec(F2) / ∂ vec(L) from Eq.(15) in the paper.
% F2 = [ X L - I, Z L; (Z L)^T, X L ].

X = sd.X;
Z = sd.Z;
n = size(X,1);
T = size(X,2);
p = 2*n;                    % size of F2

A1 = [eye(n); zeros(n,n)];                 % (2n)×n
Bx = [X; zeros(n,T)];                      % (2n)×T

A2 = [zeros(n,n); eye(n)];                 % (2n)×n
Bz = [Z; zeros(n,T)];                      % (2n)×T

Cx = [zeros(n,T); X];                      % (2n)×T

CTn = implicit.commutation(T,n);

d = kron(A1, Bx) + kron(A2, Bz) + kron(Bz, A2) * CTn + kron(A2, Cx);
d = sparse(d);
if size(d,1) ~= p*p || size(d,2) ~= T*n
    error('implicit:badSize','dF2_dL size mismatch.');
end
end





