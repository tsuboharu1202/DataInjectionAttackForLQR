function [lam, v, w] = dom_eig_pair(M)
% dom_eig_pair: dominant eigenvalue (by magnitude) and corresponding right/left eigenvectors.
% For simple eigenvalue lam, sensitivity uses w'*v in denominator.

    [V,D] = eig(M);
    ev = diag(D);
    [~,ix] = max(abs(ev));
    lam = ev(ix);
    v = V(:,ix);

    % Left eigenvector of M: eigenvector of M' corresponding to conj(lam)
    [W,Dt] = eig(M');
    evt = diag(Dt);
    [~,jx] = min(abs(evt - conj(lam)));
    w = W(:,jx);
end



