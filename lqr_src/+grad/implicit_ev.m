function [gradX_pi, gradZ_pi, gradU_pi] = implicit_ev(sd)
% implicit_ev: Implicit-differentiation gradient for dominant eigenvalue objective.
% This replaces expensive finite-difference (direct_ev) by leveraging KKT conditions
% of the SDP (paper: "Adversarial Destabilization Attacks to Direct Data-Driven Control").
%
% Output matches grad.direct_ev(): projected gradient Π_λ for X,Z,U.

[gradX_pi, gradZ_pi, gradU_pi] = implicit.ev_grad_ev(sd);
end





