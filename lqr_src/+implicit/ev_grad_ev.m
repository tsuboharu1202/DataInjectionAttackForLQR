function [gradX_pi, gradZ_pi, gradU_pi, dbg] = ev_grad_ev(sd)
% ev_grad_ev: Implicit gradient for dominant eigenvalue magnitude objective.
%
% This function is the main entry used by grad.implicit_ev().
% It computes gradients w.r.t. data matrices X, Z, U (same shapes),
% using implicit differentiation of the SDP KKT system.
%
% Notes:
% - Requires dual variables (Lambda1, Lambda2) from YALMIP (MOSEK).
% - Currently focuses on EV objective (dominant eigenvalue magnitude).

    arguments
        sd
    end

    % ---- Solve SDP once and obtain primal+dual ----
    [L,S,J,diagInfo] = sd.solveSDPBySystem();
    if isempty(diagInfo) || ~isfield(diagInfo,'Lambda1') || isempty(diagInfo.Lambda1)
        error('implicit:dualUnavailable', ...
            'Dual variables for PSD constraints are not available. Ensure YALMIP returns dual(F1c), dual(F2c).');
    end
    Lambda1 = diagInfo.Lambda1;
    Lambda2 = diagInfo.Lambda2;

    % Symmetrize duals (solver may return non-symmetric numerically)
    Lambda1 = (Lambda1 + Lambda1')/2;
    Lambda2 = (Lambda2 + Lambda2')/2;

    % ---- Controller and dominant eigenpair ----
    [K,P] = sdp.postprocess_K(sd.U, L, sd.X); %#ok<ASGLU>
    M = sd.A + sd.B*K;
    [lam, v, w] = implicit.dom_eig_pair(M);

    % ---- Gradient of |lam| wrt K (matrix) ----
    gradK = implicit.grad_dom_eig_wrt_K(sd.B, lam, v, w); % m×n

    % ---- Build gL = (∂Fk/∂L)^T vec(gradK) (Proposition 3) ----
    XL = sd.X*L;                 % n×n
    iXLt = (XL') \ eye(size(XL,1));  % (XL)^(-T) without inv()
    UminusKX = sd.U - K*sd.X;     % m×T
    dFk_dL = kron(iXLt, UminusKX);    % (mn) × (Tn)  with column-wise vec
    gL = dFk_dL' * gradK(:);          % (Tn)×1

    % ---- Direct term from U and X (K depends on U,X explicitly) ----
    % We avoid the E-matrix form and compute the linearization of K = U L (X L)^(-1).
    % vec(dK) = (I ⊗ (L*inv(XL))) vec(dU)  -  ( (inv(XL))^T ⊗ (U L inv(XL)) ) vec(dX)  + (∂Fk/∂L) vec(dL)
    % We only need gradients w.r.t dU and dX: gU_direct, gX_direct such that <gradK,dK> = <gU,dU>+<gX,dX>+<gL,dL>
    invXL = XL \ eye(size(XL,1));
    A_ULinv = (sd.U*L) * invXL;        % equals K (numerically)
    % dK from dU: dK = dU*L*invXL
    gU_direct = (gradK * invXL') * L'; % m×T (since <gradK, dU*L*invXL> = <gradK*invXL', dU*L> = <(gradK*invXL')*L', dU>)
    % dK from dX: dK = -K * (dX*L*invXL)
    % <gradK, -K*(dX*L*invXL)> = -<K'*gradK, dX*L*invXL> = -< (K'*gradK)*invXL', dX*L>
    % = -< ((K'*gradK)*invXL')*L', dX >
    gX_direct = -(((K'*gradK) * invXL') * L'); % n×T
    gZ_direct = zeros(size(sd.Z));             % K does not explicitly depend on Z

    % ---- Implicit term via KKT: solve (∂G/∂y)^T psi = [gL;0;0] ----
    % y = [vec(L); vec(S); vec(Lambda1); vec(Lambda2)] (we keep two blocks)
    kkt = implicit.kkt_linearization(sd, L, S, Lambda1, Lambda2, diagInfo);
    rhs = [gL; zeros(kkt.dimS,1); zeros(kkt.dimLam,1)];
    psi = kkt.JyT \ rhs;

    % ---- Total gradient wrt data: gD = gD_direct - (∂G/∂D)^T psi ----
    gD_implicit = -(kkt.JDT * psi);
    % D stacks [Z; X; U] as a (2n+m)×T matrix; we return gradients per block.
    [gZ_imp, gX_imp, gU_imp] = implicit.unstack_D(sd, gD_implicit);

    gradX = gX_direct + gX_imp;
    gradZ = gZ_direct + gZ_imp;
    gradU = gU_direct + gU_imp;

    % ---- Projected gradient Π_λ (match direct_ev convention) ----
    gradX_pi = real(lam)*real(gradX) + imag(lam)*imag(gradX);
    gradZ_pi = real(lam)*real(gradZ) + imag(lam)*imag(gradZ);
    gradU_pi = real(lam)*real(gradU) + imag(lam)*imag(gradU);

    if nargout > 3
        dbg = struct();
        dbg.L = L; dbg.S = S; dbg.J = J;
        dbg.Lambda1 = Lambda1; dbg.Lambda2 = Lambda2;
        dbg.K = K; dbg.lam = lam;
        dbg.gradK = gradK;
        dbg.gU_direct = gU_direct;
        dbg.gX_direct = gX_direct;
        dbg.psi = psi;
        dbg.kkt = kkt;
    end
end





