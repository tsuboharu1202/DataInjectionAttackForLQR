function J = dF1_dS(n, m)
% dF1_dS: derivative of vec(F1) w.r.t vec(S)
% F1 ∈ R^{(m+n)×(m+n)} has top-left block equal to S ∈ R^{m×m}.
% Therefore, vec(dF1) = J vec(dS) where J injects entries of dS into vec(dF1).

p = m + n;
J = sparse(p*p, m*m);
% Column-major mapping: vec(A) index = i + (j-1)*rows.
for j = 1:m
    for i = 1:m
        row = i + (j-1)*p;     % position in vec(F1)
        col = i + (j-1)*m;     % position in vec(S)
        J(row, col) = 1;
    end
end
end


