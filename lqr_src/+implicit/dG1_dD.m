function d = dG1_dD(sd, L, Lambda, dPi_dD, E1, E2)
% dG1_dD: ∂G1/∂D from Proposition 5.
% G1 corresponds to ∂Lagr/∂L = 0.

    X = sd.X; U = sd.U; %#ok<NASGU>
    n = size(X,1); T = size(X,2); m = size(sd.U,1);
    bar_n = 2*n + m;

    Q = sd.Q;
    gamma = cfg.Const.GAMMA;

    % EX selection (n×(2n+m))
    EX = [zeros(n,n), eye(n), zeros(n,m)];

    % First term: C_{n,T} (I_T ⊗ (Q EX))
    CnT = implicit.commutation(n, T); % C_{n,T} maps vec(A^T) etc
    term1 = CnT * kron(speye(T), Q*EX);

    % Second term: 2γ (L^T ⊗ I_T) dΠ/dD  (Π is T×T)
    term2 = 2*gamma * kron(L', speye(T)) * dPi_dD;

    % Third term: -(I_{nT} ⊗ vec(Λ)^T) ∂^2F/(∂D∂L)
    d2F = implicit.d2F_dDL(sd, L, E1, E2);              % (hatn^2)×(bar_n*T * T*n)? packed form
    % Our d2F_dDL returns mapping consistent with vec(F) wrt (D,L) as (hatn^2)×(bar_n*T * T*n) is too big.
    % We implemented it as (hatn^2)×((bar_n*T)*(?)) through structured terms; validate dims here.
    vecLamT = (Lambda(:))';
    term3 = kron(speye(n*T), vecLamT) * d2F;

    d = term1 + term2 - term3;

    if size(d,1) ~= n*T || size(d,2) ~= bar_n*T
        error('implicit:badSize','dG1_dD size mismatch.');
    end
end



