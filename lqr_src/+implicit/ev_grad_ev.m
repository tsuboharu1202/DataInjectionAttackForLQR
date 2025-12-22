function [gradX, gradZ, gradU, dbg] = ev_grad_ev(sd)
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

% ========================================================================
% STEP 1: Compute partial derivatives (from paper's first image)
% ========================================================================
% Paper formulas:
%   ∂F_K/∂L = (XL)^-T ⊗ (U - F_K X)
%   ∂F_K/∂D = ((XL)^-T L^T) ⊗ (E_U - F_K E_X)
% where F_K = K (the control gain)

% ---- Gradient of |lam| wrt K (needed for chain rule) ----
dRho_dK = implicit.grad_dom_eig_wrt_K(sd.B, lam, v, w); % m×n

% ---- Compute ∂F_K/∂L (partial derivative w.r.t. L) ----
n = size(sd.X,1); T = size(sd.X,2); m = size(sd.U,1);
XL = sd.X*L;                 % n×n
iXLt = (XL') \ eye(size(XL,1));  % (XL)^(-T) without inv()
UminusKX = sd.U - K*sd.X;     % m×T
% Paper: ∂F_K/∂L = (XL)^-T ⊗ (U - F_K X)
dFk_dL = kron(iXLt, UminusKX);    % (mn) × (Tn)

% ---- Compute ∂F_K/∂D (partial derivative w.r.t. D) ----
% Selection matrices (matching dF_dD.m)
EU = [zeros(m,n), zeros(m,n), eye(m)];     % m×(2n+m)
EX = [zeros(n,n), eye(n), zeros(n,m)];     % n×(2n+m)
% Paper: ∂F_K/∂D = ((XL)^-T L^T) ⊗ (E_U - F_K E_X)
dFk_dD = kron(iXLt * L', EU - K*EX);  % (m*n) × (bar_n*T)

% ========================================================================
% STEP 2: Derive dL/dD from KKT system (Eq.(12))
% ========================================================================
% The KKT system (12) gives: (∂G/∂y)^T [dL/dD; dS/dD; dΛ/dD]^T = -[∂G/∂D]^T
% We solve: (∂G/∂y)^T psi = [gL; 0; 0]
% where gL = (∂F_K/∂L)^T vec(gradK) is the RHS for the L component
% Then: dL/dD, dS/dD, dΛ/dD are extracted from psi via (∂G/∂D)^T psi


% Build KKT system and solve for implicit derivatives
kkt = implicit.kkt_linearization(sd, L, S, Lambda1, Lambda2, diagInfo);
kkt_y = kkt.JD;
kkt_x = kkt.Jy \ (-kkt_y);  % Solve KKT system (12)

dL_dD = kkt_x(1:kkt.dimL, :);


% ========================================================================
% STEP 3: Compute total gradient using Eq.(8)
% ========================================================================
% Paper Eq.(8): dρ/dD = dρ/dK (∂F_K/∂L · dL/dD + ∂F_K/∂D)
% Using definition (18): dF/dX := dvec(F)/dvec(X)
dRho_dD = dRho_dK*(dFk_dL*dL_dD + dFk_dD);

% Reshape to match D structure: D = [Z; X; U] is (2*n+m) × T
% dRho_dD is dvec(ρ)/dvec(D), which is 1 × ((2*n+m)*T) after computation
bar_n = 2*n + m;
dRho_dD = reshape(dRho_dD, bar_n, T);  % (2*n+m) × T

% Extract gradients for each block: D = [Z; X; U]
gradZ = dRho_dD(1:n, :);           % n × T
gradX = dRho_dD(n+1:2*n, :);       % n × T
gradU = dRho_dD(2*n+1:2*n+m, :);   % m × T


if nargout > 3
    dbg = struct();
    dbg.L = L; dbg.S = S; dbg.J = J;
    dbg.Lambda1 = Lambda1; dbg.Lambda2 = Lambda2;
    dbg.K = K; dbg.lam = lam;
    dbg.dRho_dK = dRho_dK;
    dbg.dRho_dD = dRho_dD;
    dbg.kkt = kkt;
end
end





