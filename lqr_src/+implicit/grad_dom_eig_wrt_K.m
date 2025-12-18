function gradK = grad_dom_eig_wrt_K(B, lam, v, w)
% grad_dom_eig_wrt_K: gradient of |lam| wrt K where closed-loop matrix is A + B*K.
% Using dlam = (w' * (B*dK) * v) / (w' * v),
% and d|lam| = Re( conj(lam)/|lam| * dlam ).
%
% Output gradK is real m×n matrix.

    denom = (w' * v);
    if abs(denom) < 1e-12
        error('implicit:badEigenpair','Left/right eigenvectors nearly orthogonal; sensitivity ill-defined.');
    end
    if abs(lam) < 1e-12
        % |lam| not differentiable at 0; return zero (practically irrelevant for instability objective)
        gradK = zeros(size(B,2), numel(v));
        return;
    end
    c = conj(lam)/abs(lam) / denom;   % complex scalar
    % dlam from dK_{ij}: (w' * B(:,i)) * v(j)
    bw = (B' * w);                   % m×1 complex
    gradK_c = c * (bw * (v.'));      % m×n complex
    gradK = real(gradK_c);           % gradient of |lam| is real
end



