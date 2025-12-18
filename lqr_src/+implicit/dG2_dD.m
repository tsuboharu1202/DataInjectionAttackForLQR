function d = dG2_dD(sd, L, Lambda, E1, E2) %#ok<INUSD>
% dG2_dD: ∂G2/∂D from Proposition 5.
% In this SDP, F depends on S but not jointly on (S,D), so ∂^2F/(∂D∂S)=0.
% Hence ∂G2/∂D = 0.

    n = size(sd.X,1); T = size(sd.X,2); m = size(sd.U,1);
    d = sparse(m*m, (2*n+m)*T);
end





