function [gradX_pi, gradZ_pi, gradU_pi] = implicit_score(sd)
% implicit_grad_ev: Alias for iterative attacks (IDGSM) to use implicit EV gradient.

[gradX_pi, gradZ_pi, gradU_pi] = implicit.grad_score(sd);
end





