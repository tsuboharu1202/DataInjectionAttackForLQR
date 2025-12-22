function [X_adv, Z_adv, U_adv] = idgsm_ev(ori_sd,direct_flag)

iter = 0;

checkX = false(size(ori_sd.X));   % dX と同じ大きさの logical false
checkZ = false(size(ori_sd.Z));
checkU = false(size(ori_sd.U));

is_continue = true;

dX = zeros(size(ori_sd.X));
dZ = zeros(size(ori_sd.Z));
dU = zeros(size(ori_sd.U));
current_sd = ori_sd;

while is_continue
    disp("iter");disp(iter);
    [X_grad, Z_grad, U_grad] = calc_grad(current_sd);
    dX = dX + cfg.Const.IDGSM_ALPHA*X_grad;
    dZ = dZ + cfg.Const.IDGSM_ALPHA*Z_grad;
    dU = dU + cfg.Const.IDGSM_ALPHA*U_grad;
    
    [dX,dZ,dU,checkX,checkZ,checkU] = attack.projector(dX,dZ,dU,checkX,checkZ,checkU);
    
    okX = all(checkX(:));   % R2018b+ なら all(checkX,"all") でもOK
    okZ = all(checkZ(:));
    okU = all(checkU(:));
    
    X_adv = ori_sd.X + dX;
    Z_adv = ori_sd.Z + dZ;
    U_adv = ori_sd.U + dU;
    
    allDone = okX && okZ && okU;
    current_sd = datasim.SystemData(ori_sd.A,ori_sd.B,ori_sd.Q,ori_sd.R,X_adv,Z_adv,U_adv);
    K_temp = current_sd.opt_K();
    spectral_radius_temp = max(abs(eig(ori_sd.A+ori_sd.B*K_temp)));
    disp("spectral_radius_temp");disp(spectral_radius_temp);
    
    is_continue = ~allDone && (iter < cfg.Const.MAX_ITERATION) && (spectral_radius_temp < 1.0);
    
    iter = iter + 1;  % Increment the iteration counter
end


    function [X_grad, Z_grad, U_grad] = calc_grad(sd)
        if(direct_flag)
            [X_grad, Z_grad, U_grad] = grad.direct_ev(sd);
        else
            [X_grad, Z_grad, U_grad] = grad.implicit_ev(sd);
        end
    end
end
