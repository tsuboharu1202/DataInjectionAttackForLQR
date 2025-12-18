function [X_adv, Z_adv, U_adv] = dgsm_ev(sd, direct_flag, eps_att)

[gradX_pi, gradZ_pi, gradU_pi] = calc_grad(sd);
[X_adv,Z_adv, U_adv] = attack.make_data_adv(sd,gradX_pi,gradZ_pi,gradU_pi, eps_att);

    function [X_grad, Z_grad, U_grad] = calc_grad(sd)
        if(direct_flag)
            [X_grad, Z_grad, U_grad] = grad.direct_ev(sd);
        else
            [X_grad, Z_grad, U_grad] = grad.implicit_ev(sd);
        end
    end
end
