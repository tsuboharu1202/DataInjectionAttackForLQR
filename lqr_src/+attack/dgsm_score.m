function [X_adv, Z_adv, U_adv] = dgsm_score(sd, direct_flag, eps_att)


[gradX, gradZ, gradU] = calc_grad(sd);
[X_adv,Z_adv, U_adv] = attack.make_data_adv(sd,gradX,gradZ,gradU, eps_att);


    function [X_grad, Z_grad, U_grad] = calc_grad(sd)
        if(direct_flag)
            [X_grad, Z_grad, U_grad] = grad.direct_score(sd);
        else
            [X_grad, Z_grad, U_grad] = grad.implicit_score(sd);
        end
    end
end
