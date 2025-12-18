function [X_adv, Z_adv, U_adv] = idgsm_score(ori_sd,direct_flag)
    
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
        is_continue = ~allDone && (iter < cfg.Const.MAX_ITERATION);
        current_sd = datasim.SystemData(ori_sd.A,ori_sd.B,ori_sd.Q,ori_sd.R,X_adv,Z_adv,U_adv);
        iter = iter + 1;  % Increment the iteration counter
    end


    % function B = add(A, D)
    %     if isempty(A), B = A; else, B = A + D; end
    % end

    function [X_grad, Z_grad, U_grad] = calc_grad(sd)
        if(direct_flag)
            [X_grad, Z_grad, U_grad] = grad.direct_score(sd);
        else
            [X_grad, Z_grad, U_grad] = grad.implicit_score(sd);
        end
    end
end
