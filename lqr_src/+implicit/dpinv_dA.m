function J = dpinv_dA(A)
% dpinv_dA: Jacobian mapping vec(dA) -> vec(dA^+) for A^+=pinv(A).
% Implements Eq.(16) from the paper for the case A ∈ R^{r×T} with r<=T typical.
% NOTE: This assumes A has full row rank so that A^+ = A^T (A A^T)^{-1}.

    [r,T] = size(A);
    C = implicit.commutation(r, T);            % C_{r,T}

    G = A*A';                                  % r×r
    iG = inv(G);
    iGt = inv(G');                             % = iG' but keep explicit

    I_r = speye(r);
    I_T = speye(T);

    % First term: ((AA^T)^(-T) ⊗ I_T) C_{r,T}
    term1 = kron(iGt, I_T) * C;

    % Second term: (I_r ⊗ A^T) ((AA^T)^(-T) ⊗ (AA^T)^(-1)) ((A ⊗ I_r) + (I_r ⊗ A) C_{r,T})
    term2a = kron(I_r, A');
    term2b = kron(iGt, iG);
    term2c = kron(A, I_r) + kron(I_r, A) * C;

    J = term1 - term2a * term2b * term2c;
    J = sparse(J); % size: (T*r)×(r*T)
end



