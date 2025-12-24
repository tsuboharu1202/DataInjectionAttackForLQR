function [X_adv, Z_adv, U_adv, history] = idgsm_score(ori_sd, direct_flag, save_history)

if nargin < 3
    save_history = false;
end

iter = 0;

checkX = false(size(ori_sd.X));   % dX と同じ大きさの logical false
checkZ = false(size(ori_sd.Z));
checkU = false(size(ori_sd.U));

is_continue = true;

dX = zeros(size(ori_sd.X));
dZ = zeros(size(ori_sd.Z));
dU = zeros(size(ori_sd.U));
current_sd = ori_sd;

if save_history
    history = struct();
    history.dX_history = {};
    history.dZ_history = {};
    history.dU_history = {};
    history.score_history = [];
    history.iter_count = 0;
else
    history = [];
end

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
    score_temp = utils.real_score(current_sd, K_temp);
    disp("score_temp");disp(score_temp);
    
    % Save history if requested
    if save_history
        history.dX_history{end+1} = dX;
        history.dZ_history{end+1} = dZ;
        history.dU_history{end+1} = dU;
        history.score_history(end+1) = score_temp;
    end
    
    % Continue if not done, within iteration limit, and score is finite (system is stable)
    is_continue = ~allDone && (iter < cfg.Const.MAX_ITERATION) && isfinite(score_temp);
    
    iter = iter + 1;  % Increment the iteration counter
end

if save_history
    history.iter_count = iter;
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
