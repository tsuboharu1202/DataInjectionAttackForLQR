function [gZ, gX, gU] = unstack_D(sd, gD_vec)
% unstack_D: reshape gradient vector w.r.t. D into (Z,X,U) blocks.
% D is the stacked data matrix: D = [Z; X; U] of size (2n+m)×T.

    n = size(sd.X,1);
    T = size(sd.X,2);
    m = size(sd.U,1);
    Drows = 2*n + m;
    if numel(gD_vec) ~= Drows*T
        error('implicit:badDSize','gD_vec size mismatch for D=(2n+m)×T.');
    end
    gD = reshape(gD_vec, Drows, T);
    gZ = gD(1:n, :);
    gX = gD(n+1:2*n, :);
    gU = gD(2*n+1:2*n+m, :);
end



