function out = kkt_linearization(sd, L, S, Lambda1, Lambda2, diagInfo)
% kkt_linearization: Build linear system blocks for the KKT implicit differentiation.
%
% This is the "augmented system" in Eq.(12) of the paper.
% We build matrices needed for the adjoint solve:
%   (∂G/∂y)^T * psi = rhs
% and the implicit data term:
%   gD_imp = -(∂G/∂D)^T * psi
%
% IMPORTANT:
% - This initial implementation provides the correct I-structure for ∂G4/∂Λ
%   and symmetry coupling, and scaffolds all blocks.
% - Full analytic expressions for all blocks follow Proposition 4/5 and (15)(16).
%   For now, we error if requested blocks are not implemented.

n = size(sd.X,1);
T = size(sd.X,2);
m = size(sd.U,1);

% Dimensions
dimL = T*n;
dimS = m*m;
% Paper uses Λ ∈ R^{hatn×hatn} with hatn := 3n+m (even though F is block-diagonal).
% We therefore embed the dual blocks into a full hatn×hatn matrix so vec(Λ) has hatn^2 entries.
hatn = 3*n + m;
dimLam = hatn*hatn;

% Placeholder: We will represent Lambda blocks separately to avoid huge kron assembly later
out = struct();
out.dimL = dimL;
out.dimS = dimS;
out.dimLam = dimLam;
out.n = n; out.m = m; out.T = T;

% ---- Convenience: block-diagonal F and embedded-full Λ ----
if ~isfield(diagInfo,'F1c_val') || ~isfield(diagInfo,'F2c_val')
    error('implicit:missingDiag','diagInfo must contain F1c_val and F2c_val from solveSDP.');
end
F1 = diagInfo.F1c_val;
F2 = diagInfo.F2c_val;
F  = blkdiag(F1, F2);                     % hatn×hatn (block diagonal)
Lambda = zeros(hatn,hatn);
Lambda(1:size(F1,1), 1:size(F1,2)) = Lambda1;
Lambda(size(F1,1)+1:end, size(F1,2)+1:end) = Lambda2;

% ---- Helper matrices: E1,E2 selecting the diagonal blocks ----
E1 = implicit.E_select(size(F1,1), size(F2,1), 1); % hatE1
E2 = implicit.E_select(size(F1,1), size(F2,1), 2); % hatE2
% "lifted" versions from paper: E1 := Ē1 ⊗ Ē1, E2 := Ē2 ⊗ Ē2
E1k = kron(E1, E1);
E2k = kron(E2, E2);

% ---- Build ∂F/∂L and ∂F/∂S (Eq.(14),(15)) ----
dF1_dL = implicit.dF1_dL(sd, L);         % vec(F1) wrt vec(L)
dF2_dL = implicit.dF2_dL(sd, L);         % vec(F2) wrt vec(L)
dF_dL  = E1k * dF1_dL + E2k * dF2_dL;    % vec(F)  wrt vec(L)

dF1_dS = implicit.dF1_dS(n,m);           % vec(F1) wrt vec(S)
dF2_dS = sparse((2*n)*(2*n), m*m);       % paper: zero
dF_dS  = E1k * dF1_dS + E2k * dF2_dS;

% ---- Π and its derivative w.r.t D (Eq.(16)) ----
if ~isfield(diagInfo,'Pi') || isempty(diagInfo.Pi)
    error('implicit:missingPi','diagInfo.Pi required.');
end
Pi = diagInfo.Pi;
dPi_dD = implicit.dPi_dD(sd); % matrix mapping vec(dD)->vec(dPi)

% ---- ∂G blocks from Proposition 5 ----
% G1 = ∂Lagr/∂L,  G2 = ∂Lagr/∂S,  G3 = tr(F Λ^T),  G4 = Λ-Λ^T
% Dimensions:
%  G1: (nT)×1, G2: (m^2)×1, G3: (hatn^2)×1 with hatn=3n+m, G4: (hatn^2)×1
dimG1 = dimL;
dimG2 = dimS;
dimG3 = hatn*hatn;
dimG4 = hatn*hatn;

% ∂G1/∂L, ∂G1/∂S, ∂G1/∂Λ, ∂G1/∂D
dG1_dL = 2*cfg.Const.GAMMA * kron(speye(n), Pi);                 % 2γ(In ⊗ Π)
dG1_dS = sparse(dimG1, dimS);                                    % 0
dG1_dLam = -dF_dL';                                              % -∂F^T/∂L
% ∂G1/∂D = C_{n,T}(I_T ⊗ (Q E_X)) + 2γ(L^T ⊗ I_T) dΠ/dD - (I_{nT} ⊗ vec(Λ)^T) ∂^2F/(∂D∂L)
dG1_dD = implicit.dG1_dD(sd, L, Lambda, dPi_dD, E1, E2);         % Proposition 5

% ∂G2/∂L, ∂G2/∂S, ∂G2/∂Λ, ∂G2/∂D
dG2_dL = sparse(dimG2, dimL);
dG2_dS = sparse(dimG2, dimS);
dG2_dLam = -dF_dS';                                              % -∂F^T/∂S
dG2_dD = implicit.dG2_dD(sd, L, Lambda, E1, E2);                 % uses ∂^2F/(∂D∂S)

% ∂G3/∂L, ∂G3/∂S, ∂G3/∂Λ, ∂G3/∂D
dG3_dL = kron(Lambda, speye(hatn)) * dF_dL;
dG3_dS = kron(Lambda, speye(hatn)) * dF_dS;
Cnn = implicit.commutation(hatn, hatn);
dG3_dLam = kron(speye(hatn), F) * Cnn;
dF_dD = implicit.dF_dD(sd, L, E1, E2);                           % Eq.(15)
dG3_dD = kron(Lambda, speye(hatn)) * dF_dD;

% ∂G4/∂Λ (Proposition 5) and others are zeros
dG4_dL = sparse(dimG4, dimL);
dG4_dS = sparse(dimG4, dimS);
dG4_dD = sparse(dimG4, (2*n+m)*T);
dG4_dLam = speye(hatn*hatn) - Cnn;

% ---- Assemble Jy = ∂G/∂y with y=[vec(L);vec(S);vec(Λ)] ----
Jy = [dG1_dL, dG1_dS, dG1_dLam;
    dG2_dL, dG2_dS, dG2_dLam;
    dG3_dL, dG3_dS, dG3_dLam;
    dG4_dL, dG4_dS, dG4_dLam];

JD = [dG1_dD;
    dG2_dD;
    dG3_dD;
    dG4_dD];

out.Jy = Jy;
out.JD = JD;
out.dimS = dimS;
end


