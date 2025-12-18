function [K,P] = postprocess_K(U,L,X)
    % K = U*L*(X*L)^{-1},  P = X*L  （論文の記法に合わせる）
    XL = X*L;
    K  = (U*L) / (XL);   % K = U L (XL)^{-1}
    P  = XL;
end
