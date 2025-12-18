function J = dPi_dD(sd)
% dPi_dD: Jacobian mapping vec(dD) -> vec(dPi) for Pi = I - pinv(Gamma)*Gamma
% where Gamma = [X;U] ∈ R^{(n+m)×T} and D=[Z;X;U] ∈ R^{(2n+m)×T}.
% Implements Eq.(16) structure using commutation matrices and Kronecker products.

    X = sd.X; U = sd.U;
    n = size(X,1); T = size(X,2); m = size(U,1);
    bar_n = 2*n + m;
    r = n + m;

    Gamma = [X; U];                 % r×T
    Gp = pinv(Gamma);               % T×r

    % Build d vec(Gamma) / d vec(D): only X and U blocks affect Gamma.
    % vec(Gamma) stacks columns of [X;U]; this corresponds to rows:
    %  - X is rows (n+1:2n) in D, maps to first n rows in Gamma
    %  - U is rows (2n+1:2n+m) in D, maps to last m rows in Gamma
    JD_to_G = sparse(r*T, bar_n*T);
    % For each column t, map D rows -> Gamma rows
    for t = 1:T
        % column-major offsets
        col_off_D = (t-1)*bar_n;
        col_off_G = (t-1)*r;
        % X rows in D -> Gamma rows 1:n
        JD_to_G(col_off_G+(1:n), col_off_D+(n+1:2*n)) = speye(n);
        % U rows in D -> Gamma rows n+1:n+m
        JD_to_G(col_off_G+(n+1:n+m), col_off_D+(2*n+1:2*n+m)) = speye(m);
    end

    % dPi = -(dGp*Gamma + Gp*dGamma)
    % vec(dPi) = -( (Gamma^T ⊗ I_T) vec(dGp) + (I_T ⊗ Gp) vec(dGamma) )
    % Need vec(dGp) = (dGp/dGamma) vec(dGamma)
    dGp_dG = implicit.dpinv_dA(Gamma);              % maps vec(dGamma)->vec(dGp)

    JT = speye(T);
    vec_dGamma_from_dD = JD_to_G;
    vec_dGp_from_dGamma = dGp_dG;

    term1 = kron(Gamma', speye(T)) * vec_dGp_from_dGamma * vec_dGamma_from_dD;
    term2 = kron(JT, Gp) * vec_dGamma_from_dD;

    J = -(term1 + term2);
    J = sparse(J);
end



